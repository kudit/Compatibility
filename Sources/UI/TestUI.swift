#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation)
import SwiftUI

// MARK: - TestCase UI
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct TestRow: View {
    @ObservedObject public var test: TestCase
    
    // only necessary since in module and otherwise inaccessible outside package
    public init(test: TestCase) {
        self.test = test
    }
    
    public var body: some View {
        VStack {
            HStack(alignment: .top) {
                Text(test.progress.symbol)
                Text(test.title)
                Spacer()
                Button("▶️") {
                    test.run()
                }
            }
            if let errorMessage = test.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .backport.textSelection(.enabled)
            }
        }
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
struct TestsRowsView: View {
    var tests: [TestCase]
    var body: some View {
        ForEach(tests, id: \.title) { item in
            TestRow(test: item)
        }
    }
}

@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
@MainActor
final class AllTestsListModel: ObservableObject {
    let modules: [Module.Type]
    let additionalTests: OrderedDictionary<String, [TestCase]>
    private var didStartTests = false

    init(modules: [Module.Type]? = nil, additionalTests: OrderedDictionary<String, [TestCase]> = [:]) {
        // Registration already handles recursive discovery, stable-identifier deduplication, and dependency order.
        // Reverse that shared result so the UI presents specific modules before their foundational dependencies.
        self.modules = modules ?? Array(Build.allModules.reversed())
        self.additionalTests = additionalTests
    }

    func startAllTestsOnce() {
        guard !didStartTests else { return }
        didStartTests = true
        // Starting is synchronous and cheap; each TestCase immediately moves its actual work off the main actor.
        let moduleTests = modules.flatMap { $0.tests.values.flatMap { $0 } }
        for test in additionalTests.values.flatMap({ $0 }) + moduleTests {
            if case .notStarted = test.progress {
                test.run()
            }
        }
    }
}

// use this to test the local file tests only.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct TestsListView: View {
    public var tests: [TestCase]
    
    // only necessary since in module and otherwise inaccessible outside package
    public init(tests: [TestCase]) {
        self.tests = tests
    }
    
    public var body: some View {
        List {
            Text("Tests:")
            TestsRowsView(tests: tests)
        }
    }
}

@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
@MainActor // unnecessary in Swift 6
public struct ModuleTestsListView: View {
    /// Holds the test instances for the life of the view so background tasks don't outlive constantly recreated rows.
    @StateObject private var model: AllTestsListModel
    
    // only necessary since in module and otherwise inaccessible outside package
    public init(module: Module.Type, additionalTests: OrderedDictionary<String, [TestCase]> = [:]) {
        _model = StateObject(wrappedValue: AllTestsListModel(modules: [module], additionalTests: additionalTests))
        self.module = module
    }
    private let module: Module.Type
    public var body: some View {
        List {
            ModuleTestSectionsView(modules: [module], additionalTests: model.additionalTests)
        }
        // test replacing background
        .backport.scrollContentBackground(.hidden)
        .background(.linearGradient(colors: [.red, .yellow, .green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
        .onAppear { model.startAllTestsOnce() }
    }
}

/// Renders registered modules without owning execution, allowing both public list views to share presentation.
@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
private struct ModuleTestSectionsView: View {
    let modules: [Module.Type]
    let additionalTests: OrderedDictionary<String, [TestCase]>

    var body: some View {
        ForEach(additionalTests.keys.elements, id: \.self) { sectionName in
            Section(sectionName) {
                TestsRowsView(tests: additionalTests[sectionName] ?? [])
            }
        }
        // Enumerated offsets avoid relying on metatype key paths while Build guarantees unique module identifiers.
        ForEach(Array(modules.enumerated()), id: \.offset) { _, module in
            Section {
                if module.tests.isEmpty {
                    Text("No tests provided")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(module.tests.keys.elements, id: \.self) { sectionName in
                        VStack(alignment: .leading) {
                            Text(sectionName)
                                .font(.headline)
                            TestsRowsView(tests: module.tests[sectionName] ?? [])
                        }
                    }
                }
            } header: {
                Text("\(module.moduleName) v\(module.version)")
            }
        }
    }
}

/// Every reusable test exposed by the modules already registered with ``Build``.
///
/// ``Build/register(_:)`` recursively discovers dependencies and deduplicates them by stable module identifier.
/// This view reverses that existing dependency-first registration order so application-specific modules appear
/// first and foundational modules appear last. Use ``ModuleTestsListView`` for a focused single-module screen.
@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
@MainActor
public struct AllTestsListView: View {
    @StateObject private var model: AllTestsListModel

    /// Creates Compatibility's complete test screen, optionally prefixed by application tests.
    public init(additionalTests: OrderedDictionary<String, [TestCase]> = [:]) {
        _model = StateObject(wrappedValue: AllTestsListModel(additionalTests: additionalTests))
    }

    @available(*, deprecated, renamed: "init(additionalTests:)")
    public init(additionalNamedTests: OrderedDictionary<String, [TestCase]>) {
        _model = StateObject(wrappedValue: AllTestsListModel(additionalTests: additionalNamedTests))
    }

    public var body: some View {
        List {
            ModuleTestSectionsView(modules: model.modules, additionalTests: model.additionalTests)
        }
        .backport.scrollContentBackground(.hidden)
        .background(.linearGradient(colors: [.red, .yellow, .green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
        .onAppear { model.startAllTestsOnce() }
    }
}

@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
#Preview("Tests") {
    AllTestsListView()
}
#endif
