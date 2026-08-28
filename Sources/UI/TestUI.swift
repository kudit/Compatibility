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
                Button {
                    test.run()
                } label: {
                    Image(backportSystemName: "play.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 28, height: 28)
                }
                .backport.buttonStyle(.glass)
                .accessibility(label: Text("Run test"))
            }
            if let errorMessage = test.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .backport.textSelection(.enabled)
            }
        }
        // Make the complete row an activation target so rerunning a test does not require
        // precision tapping the small play control. The explicit play button remains available
        // for discoverability and accessibility, while this gesture covers the surrounding row.
        .contentShape(Rectangle())
        .onTapGesture {
            test.run()
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
    /// An explicit module list is stable; otherwise the registry is intentionally resolved lazily on appearance.
    private let explicitModules: [Module.Type]?
    // Publish the refreshed registry so a StateObject-backed list redraws after startup registration
    // completes; without this, the model contains module tests but the view remains on its initial
    // injected-tests-only snapshot.
    @Published private(set) var modules: [Module.Type]
    let additionalTests: OrderedDictionary<String, [TestCase]>
    private var didStartTests = false

    init(modules: [Module.Type]? = nil, additionalTests: OrderedDictionary<String, [TestCase]> = [:]) {
        // Do not snapshot Build.allModules here: SwiftUI may construct StateObject-backed views before the
        // hosting application's App initializer has registered its top-level modules. The registry is read
        // by refreshRegisteredModules() immediately before the view starts displaying and running tests.
        self.explicitModules = modules
        self.modules = modules ?? []
        self.additionalTests = additionalTests
    }

    /// Refreshes the implicit registry just before presentation so consuming apps have completed startup registration.
    func refreshRegisteredModules() {
        // Dependencies are registered first; reverse that order so specific modules appear
        // before Compatibility. This refresh is deliberately independent of injected tests:
        // AllTestsListView must show both catalogs, including when either one is empty.
        modules = explicitModules ?? [] + Array(Build.allModules.reversed())
    }

    func startAllTestsOnce() {
        // Refresh before the one-time execution guard because the app registry may finish after model creation.
        refreshRegisteredModules()
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
            // A stable bottom marker lets UI automation stop as soon as the end is actually visible instead
            // of issuing a fixed number of expensive swipe gestures after the list is already at the bottom.
            Color.clear
                .frame(height: 1)
                .accessibilityIdentifier("allTests.bottom")
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
