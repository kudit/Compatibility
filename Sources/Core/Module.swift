//
//  Module.swift
//  Compatibility
//
//  Created by Ben Ku on 7/14/26.
//

/// A framework or package that exposes consistent version and support-reporting metadata.
///
/// Conforming modules provide their version and immediately available diagnostic fields. Open-source
/// modules can also advertise a repository and lazily load its license, while modules on concurrency-capable
/// platforms may add asynchronously generated details.
public protocol Module {
    /// Module version.
    static var version: Version { get }

    /// Public source repository for an open-source module, or `nil` for modules that do not opt in to publishing one.
    ///
    /// This remains a string rather than Foundation's `URL` so module metadata is available in WASM,
    /// WASI, embedded Swift, and other builds where Foundation is unavailable.
    static var openSourceRepository: String? { get }

    /// Modules that must be registered before this module.
    ///
    /// The default is empty. A high-level module can list its direct dependencies and registration will
    /// recursively discover the complete dependency graph.  This is so that users only need to register
    /// top-level dependencies and automatically include down-stream Modules.  Also, this helps to order
    /// the modules for debug output so the more specific information can be listed and the more foundational
    /// information can be listed last.
    static var dependencies: [Module.Type] { get }

#if compiler(>=5.9)
    /// Reusable module tests grouped into ordered sections for test runners and live test UIs.
    ///
    /// The default is empty, so production-only modules do not need to declare tests. TestCase UI still
    /// presents the module identity and an empty state, making installed-module diagnostics complete.
    @MainActor
    @available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
    static var tests: OrderedDictionary<String, [TestCase]> { get }
#endif

    /// Structured module information that is immediately available without actor hops or deferred work.
    ///
    /// Keep portable values here so command-line tools, older Apple operating systems, WASM, and other
    /// environments without a usable concurrency runtime can still produce a meaningful report.
    static var moduleInfo: [Field] { get }

    /// Loads complete structured information that may require actor isolation, calculation, or deferred work.
    ///
    /// This requirement is separately availability-gated so the rest of ``Module`` remains usable before
    /// Swift concurrency became available on Apple platforms. The default returns ``moduleInfo`` unchanged.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    static func loadDetailedModuleInfo() async -> [Field]

    /// Project or package name.
    ///
    /// The default uses the reflected module type name so most modules do not need to provide this explicitly.
    static var moduleName: String { get }

    /// Stable identifier used to register the module only once.
    ///
    /// The default uses the fully qualified conforming type name so most modules do not need to provide
    /// an identifier explicitly.
    static var moduleIdentifier: String { get }

    /// License text loaded lazily from the module's public source repository, or `nil` when unavailable.
    ///
    /// The asynchronous getter permits network suspension without blocking its caller, but async alone does
    /// not select a background executor. The default recognizes GitHub repository URLs and asks GitHub's
    /// license API for the repository's detected license.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    static var openSourceLicense: String? { get async }
}

public extension [Module.Type] {
    /// Immediate human-readable information for the registered modules (in reverse order), separated by newlines.
    ///
    /// Each module contributes its synchronous ``Module/moduleInfo`` followed by its version field. Use
    /// ``loadDetailedDescription()`` when deferred or actor-isolated module information is also required.
    var description: String {
        self.reversed().map { $0.description }.joined(separator: "\n")
    }

    /// Loads human-readable detailed information for every module in reverse registration order.
    ///
    /// Modules are awaited serially so the returned text retains dependency ordering and remains deterministic.
    ///
    /// - Returns: Newline-separated detailed module descriptions.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    func loadDetailedDescription() async -> String {
        var results = [String]()
        for module in self.reversed() {
            results += [await module.loadDetailedDescription()]
        }
        return results.joined(separator: "\n")
    }
}

public extension Module {
    /// Project or package name.
    static var moduleName: String { // feel free to override with custom definition if needed but most should be able to just use this default implementation
        return "\(Self.self)"
    }

    /// Stable default identifier derived from the fully qualified conforming type name.
    static var moduleIdentifier: String {
        return String(reflecting: Self.self)
    }

    /// Registers this module and its dependencies for build and support reporting.
    @MainActor
    static func include() {
        // Delegate traversal and uniqueness checks to Build so every registration entry point behaves identically.
        Build.register(Self.self)
    }

    /// Modules have no dependencies unless the conformer explicitly declares them.
    static var dependencies: [Module.Type] {
        return []
    }

#if compiler(>=5.9)
    /// Modules expose no tests unless the conformer provides ordered test sections.
    @MainActor
    @available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
    static var tests: OrderedDictionary<String, [TestCase]> {
        return [:]
    }
#endif

    /// Modules are private by default so conformers must deliberately advertise a public source repository.
    static var openSourceRepository: String? {
        return nil
    }

    /// Don't include any info by default.  Callers that process multiple modules should include the version information and name automatically so this does not need to be included here.
    static var moduleInfo: [Field] {
        return []
    }

    /// Returns the portable fields when a module has no deferred details to add.  This allows customization but you should include moduleInfo so callers can use either function depending on context, but usually not both.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    static func loadDetailedModuleInfo() async -> [Field] {
        return moduleInfo
    }

    /// Lazily fetches the detected license for a public GitHub repository.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    static var openSourceLicense: String? {
        get async {
            guard let repository = openSourceRepository else {
                return nil
            }
            let unfetchableLicense = "Look for the project license at \(repository)"
#if canImport(Foundation) && !(os(WASM) || os(WASI))
            guard let endpoint = githubLicenseEndpoint(for: repository) else {
                return unfetchableLicense
            }

            do {
                // Preserve useful repository guidance when GitHub returns no license or a non-success response.
                return try await fetchGitHubLicense(from: endpoint) ?? unfetchableLicense
            } catch {
                // License metadata is optional, so a network or decoding failure should not prevent support information from loading.
                debug("Unable to load the open-source license for \(moduleName): \(error)", level: .WARNING)
                return unfetchableLicense
            }
#else
            // Network-backed license discovery is unavailable when Foundation is not present.
            return unfetchableLicense
#endif
        }
    }

    /// Standard version field appended to the module's immediate and detailed descriptions.
    static var descriptionField: Field {
        Field("\(moduleName) Framework Version", "\(version)")
    }

    /// Immediate human-readable module information followed by the module version.
    ///
    /// This uses only ``moduleInfo`` and is therefore suitable for synchronous and portable reporting.
    static var description: String {
        let info = moduleInfo + [descriptionField]
        return info.description
    }

    /// Loads the module's human-readable detailed information followed by its version.
    ///
    /// - Returns: Newline-separated detailed fields ending with ``descriptionField``.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    static func loadDetailedDescription() async -> String {
        let info = await loadDetailedModuleInfo() + [descriptionField]
        return info.description
    }
}

#if canImport(Foundation) && !(os(WASM) || os(WASI))
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

private extension Module {
    /// Converts a normal GitHub repository URL into the API endpoint that follows the default branch and detects common license filenames.
    static func githubLicenseEndpoint(for repository: String) -> URL? {
        guard let url = URL(string: repository),
              url.host?.lowercased() == "github.com" else {
            return nil
        }
        let components = url.pathComponents.filter { $0 != "/" }
        guard components.count >= 2 else {
            return nil
        }
        let owner = components[0]
        let repositoryName = components[1].hasSuffix(".git") ? String(components[1].dropLast(4)) : components[1]
        return URL(string: "https://api.github.com/repos/\(owner)/\(repositoryName)/license")
    }

    /// Loads and decodes the Base64 license payload returned by GitHub's repository-license API.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    static func fetchGitHubLicense(from endpoint: URL) async throws -> String? {
        var request = URLRequest(url: endpoint)
        // Bound optional metadata loading so offline support reports reach repository guidance promptly.
        request.timeoutInterval = 10
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Compatibility/\(Compatibility.version)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data, URLResponse), Error>) in
            // Use the completion-handler API so license loading remains available on the package's older deployment targets.
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data, let response {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                }
            }.resume()
        }
        guard let response = response as? HTTPURLResponse,
              (200..<300).contains(response.statusCode) else {
            return nil
        }
        let payload = try JSONDecoder().decode(GitHubLicensePayload.self, from: data)
        guard payload.encoding.lowercased() == "base64",
              let decoded = Data(base64Encoded: payload.content.filter { !$0.isWhitespace }) else {
            return nil
        }
        return String(data: decoded, encoding: .utf8)
    }
}

/// Minimal response shape needed from GitHub's license endpoint.
private struct GitHubLicensePayload: Decodable {
    let content: String
    let encoding: String
}
#endif

#if compiler(>=5.9)
/// A private conformer verifies the protocol defaults without exposing test-only API to package clients.
private enum ModuleTestFixture: Module {
    static let version: Version = "1.2.3"

    static let moduleInfo = [Field("Fixture", "Available")]
}

/// A private dependent conformer verifies recursive registration without exposing test-only API.
private enum DependentModuleTestFixture: Module {
    static let version: Version = "2.0.0"

    static let dependencies: [Module.Type] = [ModuleTestFixture.self]
}

/// Shared Module tests used by both the in-app All Tests UI and the Swift Testing bridge.
@available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
@MainActor
private func testModuleMetadataAndDefaults() async throws {
        // Verify the default name remains derived from the conforming type so modules do not need boilerplate.
        try expect(ModuleTestFixture.moduleName == "ModuleTestFixture", "Unexpected default module name: \(ModuleTestFixture.moduleName)")
        let defaultLicense = await ModuleTestFixture.openSourceLicense
        try expect(defaultLicense == nil, "The default open-source license should be nil")
        // Private modules should not advertise a repository unless they explicitly opt in.
        try expect(ModuleTestFixture.openSourceRepository == nil, "The default open-source repository should be nil")
        try expect(ModuleTestFixture.version == "1.2.3", "Unexpected fixture version: \(ModuleTestFixture.version)")
        try expect(ModuleTestFixture.moduleInfo == [Field("Fixture", "Available")], "Unexpected fixture module information")
        try expect(ModuleTestFixture.tests.isEmpty, "Modules without declared tests should receive an empty ordered catalog")
        try expect(Compatibility.tests.keys.elements.first == "Expectation Tests", "Compatibility should expose its complete ordered test catalog through Module.tests")
        try expect(await ModuleTestFixture.loadDetailedModuleInfo() == ModuleTestFixture.moduleInfo, "The default detailed information should return the portable fields")
        // Compatibility is open source and should provide stable metadata for Support framework reports.
        try expect(Compatibility.openSourceRepository == "https://github.com/kudit/Compatibility", "Unexpected Compatibility repository: \(Compatibility.openSourceRepository ?? "nil")")
        if let compatibilityLicense = await Compatibility.openSourceLicense {
            // Online runs verify GitHub's text; offline and rate-limited runs verify the documented repository fallback.
            let fetchedLicense = compatibilityLicense.contains("Apache License") && compatibilityLicense.contains("Version 2.0")
            let repositoryFallback = compatibilityLicense.contains(Compatibility.openSourceRepository ?? "")
            try expect(fetchedLicense || repositoryFallback, "Should return either the Apache 2.0 license or repository guidance")
        } else {
            try expect(false, "License info should fall back to repository guidance when it cannot be fetched")
        }
        let compatibilityInfo = Compatibility.moduleInfo
        try expect(compatibilityInfo.contains { $0.label == "Swift Version" }, "Compatibility module information should include the Swift version")
        try expect(compatibilityInfo.contains { $0.label == "Compiler Version" }, "Compatibility module information should include the compiler version")
        let detailedCompatibilityInfo = await Compatibility.loadDetailedModuleInfo()
        try expect(detailedCompatibilityInfo.ends(with: compatibilityInfo), "Detailed information should preserve the portable Compatibility fields last")
#if canImport(Foundation)
        try expect(detailedCompatibilityInfo.contains { $0.label == "App Identifier" }, "Detailed Compatibility information should include application fields when Foundation is available")
#endif

        let originalModules = Build.allModules
        let originalRegistrationFinished = Build.isModuleRegistrationFinished
        defer {
            // Restore global registration so running this shared test does not affect later app or UI tests.
            Build.replaceRegisteredModulesForTesting(with: originalModules, registrationFinished: originalRegistrationFinished)
        }
        Build.replaceRegisteredModulesForTesting(with: [])
        DependentModuleTestFixture.include()
        DependentModuleTestFixture.include()
        // Avoid a metatype key path here because older Swift frontends cannot reliably lower it.
        var registeredIdentifiers = [String]()
        for module in Build.allModules {
            registeredIdentifiers.append(module.moduleIdentifier)
        }
        try expect(registeredIdentifiers == [ModuleTestFixture.moduleIdentifier, DependentModuleTestFixture.moduleIdentifier], "Dependencies should be registered once before their dependent module: \(registeredIdentifiers)")
}

/// Preserve the module test's actor boundary on every concurrency-capable target, including WebAssembly.
@available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
private let moduleMetadataTest: TestClosure = { @MainActor in
    try await testModuleMetadataAndDefaults()
}

/// The collection remains main-actor isolated on every supported platform, including WebAssembly.
@available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
@MainActor
internal let moduleTests: [TestCase] = [
    TestCase("Module metadata and defaults", moduleMetadataTest),
]
#endif
