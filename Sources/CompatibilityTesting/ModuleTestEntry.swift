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
    /// Flattens the supplied modules and their dependencies into individually named test arguments.
    ///
    /// Test discovery intentionally builds a local module list instead of mutating `Build.allModules`.
    /// A test process may have already finished application module registration before Swift Testing
    /// evaluates parameterized arguments; relying on that process-global registry could therefore
    /// produce an empty argument list and cause the entire parameterized test to be skipped.
    @MainActor
    static func entries(including modules: Module.Type...) -> [ModuleTestEntry] {
        var orderedModules = [Module.Type]()
        var includedIdentifiers = Set<String>()
        var visitingIdentifiers = Set<String>()

        func include(_ module: Module.Type) {
            let identifier = module.moduleIdentifier

            // Ignore modules already emitted and stop circular dependency traversal.
            guard !includedIdentifiers.contains(identifier),
                  !visitingIdentifiers.contains(identifier) else {
                return
            }

            visitingIdentifiers.insert(identifier)
            for dependency in module.dependencies {
                include(dependency)
            }
            visitingIdentifiers.remove(identifier)

            // A sibling dependency may have emitted this module during recursive traversal.
            guard includedIdentifiers.insert(identifier).inserted else {
                return
            }
            orderedModules.append(module)
        }

        for module in modules {
            include(module)
        }

        return orderedModules.flatMap { module in
            module.tests.flatMap { section, tests in
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
    }
}
#endif
