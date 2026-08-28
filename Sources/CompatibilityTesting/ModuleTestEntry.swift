#if compiler(>=5.9) && canImport(Testing)
import Compatibility
import Testing

/// One reusable Compatibility `TestCase` presented as an individual Swift Testing argument.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct ModuleTestEntry: Sendable, Identifiable {
    public let moduleIdentifier: String
    public let moduleName: String
    public let section: String
    public let testTitle: String
    public let index: Int

    private let testCase: TestCase

    public var id: String {
        "\(moduleIdentifier)/\(section)/\(index)"
    }

    @MainActor
    init(module: Module.Type, section: String, index: Int, testCase: TestCase) {
        self.moduleIdentifier = module.moduleIdentifier
        self.moduleName = module.moduleName
        self.section = section
        self.testTitle = testCase.title
        self.index = index
        self.testCase = testCase
    }

    /// Executes the original shared test and propagates its detailed error into Swift Testing and Xcode.
    @MainActor
    public func execute() async throws {
        try await testCase.execute()
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension ModuleTestEntry: CustomTestStringConvertible {
    public var testDescription: String {
        "\(moduleName) › \(section) › \(testTitle)"
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension ModuleTestEntry: CustomTestArgumentEncodable {
    public func encodeTestArgument(to encoder: some Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension ModuleTestEntry {
    /// Flattens every module currently registered with `Build` into test arguments.
    ///
    /// Root packages should call their module's `include()` or `Application.track(...)` first.
    /// This keeps submodule test suites automatic while leaving app-specific injected tests to
    /// the app's own test suite.
    @MainActor
    static func entries() -> [ModuleTestEntry] {
        entries(including: Build.allModules)
    }

    /// Flattens an explicitly supplied module test catalog into individually named test arguments.
    ///
    /// The caller supplies the concrete module's `tests` value so Swift does not fall back to a
    /// protocol-extension default when a downstream package has an overly restrictive availability
    /// annotation. Dependency traversal remains the responsibility of Compatibility's existing
    /// `Build` registration graph rather than being duplicated in the testing adapter.
    @MainActor
    static func entries(
        for module: Module.Type,
        tests: OrderedDictionary<String, [TestCase]>
    ) -> [ModuleTestEntry] {
        tests.flatMap { section, tests in
            tests.enumerated().map { index, testCase in
                ModuleTestEntry(
                    module: module,
                    section: section,
                    index: index,
                    testCase: testCase
                )
            }
        }
    }

    /// Flattens each supplied module's protocol-visible catalog.
    ///
    /// This convenience remains useful once conforming modules expose `tests` at the same
    /// availability as the `Module` requirement. Call ``entries(for:tests:)`` while migrating an
    /// older conformer whose test catalog has a stricter availability annotation.
    @MainActor
    static func entries(including modules: Module.Type...) -> [ModuleTestEntry] {
        entries(including: modules)
    }

    /// Flattens an existing module collection into individually named test arguments.
    ///
    /// This overload is intended for packages that discover their dependency graph at runtime,
    /// such as a package that first calls `Module.include()` and then reads `Build.allModules`.
    @MainActor
    static func entries(including modules: [Module.Type]) -> [ModuleTestEntry] {
        modules.flatMap { module in
            entries(for: module, tests: module.tests)
        }
    }

    /// Flattens one module's reusable test catalog without requiring callers to repeat its tests property.
    @MainActor
    static func entries(for module: Module.Type) -> [ModuleTestEntry] {
        entries(for: module, tests: module.tests)
    }
}
#endif
