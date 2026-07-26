#if compiler(>=5.9) && canImport(Testing)
import Compatibility
import Testing

/// One reusable Compatibility `TestCase` presented as an individual Swift Testing argument.
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

extension ModuleTestEntry: CustomTestStringConvertible {
    public var testDescription: String {
        "\(moduleName) › \(section) › \(testTitle)"
    }
}

extension ModuleTestEntry: CustomTestArgumentEncodable {
    public func encodeTestArgument(to encoder: some Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }
}

public extension ModuleTestEntry {
    /// Registers the supplied top-level modules and flattens every module test into a named argument.
    @MainActor
    static func entries(including modules: Module.Type...) -> [ModuleTestEntry] {
        Build.register(modules)
        return Build.allModules.flatMap { module in
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
