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
                    Backport.Image(systemName: "play.fill")
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
        .backport.onTapGesture {
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

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
final class AllTestsListModel: ObservableObject {
    /// An explicit module list is stable; otherwise the registry is intentionally resolved lazily on appearance.
    private let explicitModules: [Module.Type]?
    // Publish the refreshed registry so the observing list redraws after startup registration
    // completes; without this, the model contains module tests but the view remains on its initial
    // injected-tests-only snapshot.
    @Published private(set) var modules: [Module.Type]
    let additionalTests: OrderedDictionary<String, [TestCase]>
    private var didStartTests = false

    init(modules: [Module.Type]? = nil, additionalTests: OrderedDictionary<String, [TestCase]> = [:]) {
        // Do not snapshot Build.allModules here: SwiftUI may construct state-backed views before the
        // hosting application's App initializer has registered its top-level modules. The registry is read
        // by refreshRegisteredModules() immediately before the view starts displaying and running tests.
        self.explicitModules = modules
        self.modules = modules ?? []
        self.additionalTests = additionalTests
    }

    /// Refreshes the implicit registry just before presentation so consuming apps have completed startup registration.
    func refreshRegisteredModules() {
        if explicitModules == nil && Build.allModules.isEmpty {
            // Keep the standalone Compatibility test screen useful when a host app has not
            // called Application.track yet; injected tests must not replace module tests.
            Compatibility.include()
        }
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
        .background(LinearGradient(colors: [.red, .yellow, .green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
        .onAppear { model.startAllTestsOnce() }
    }
}

/// Renders registered modules without owning execution, allowing both public list views to share presentation.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct ModuleTestSectionsView: View {
    let modules: [Module.Type]
    let additionalTests: OrderedDictionary<String, [TestCase]>

    var body: some View {
        ForEach(additionalTests.keys.elements, id: \.self) { sectionName in
			Backport.Section(sectionName) {
                TestsRowsView(tests: additionalTests[sectionName] ?? [])
            }
        }
        // Enumerated offsets avoid relying on metatype key paths while Build guarantees unique module identifiers.
        ForEach(Array(modules.enumerated()), id: \.offset) { _, module in
            Section {
                DetailedModuleInfoRows(module: module)
                if module.tests.isEmpty {
                    Text("No tests provided")
                        .foregroundColor(.secondary)
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

/// Loads and displays a module's complete diagnostic fields before its reusable tests.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct DetailedModuleInfoRows: View {
    let module: Module.Type
    @State private var fields: [Field]?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let fields {
                ForEach(fields.indices, id: \.self) { index in
                    FieldView(fields[index])
                }
            } else {
                HStack {
                    Backport<Any>.ProgressView()
                    Text("Loading module information…")
                        .font(.caption)
                }
            }
        }
        .onAppear {
            guard fields == nil, !isLoading else { return }
            isLoading = true
            Task { @MainActor in
                fields = await module.loadDetailedModuleInfo()
                isLoading = false
            }
        }
    }
}

/// Every reusable test exposed by the modules already registered with ``Build``.
///
/// ``Build/register(_:)`` recursively discovers dependencies and deduplicates them by stable module identifier.
/// This view reverses that existing dependency-first registration order so application-specific modules appear
/// first and foundational modules appear last. Use ``ModuleTestsListView`` for a focused single-module screen.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
public struct AllTestsListView: View {
    /// Retains the observable model on iOS 13; its private content view observes updates directly.
    @State private var model: AllTestsListModel

    /// Creates Compatibility's complete test screen, optionally prefixed by application tests.
    public init(additionalTests: OrderedDictionary<String, [TestCase]> = [:]) {
        _model = State(initialValue: AllTestsListModel(additionalTests: additionalTests))
    }

    @available(*, deprecated, renamed: "init(additionalTests:)")
    public init(additionalNamedTests: OrderedDictionary<String, [TestCase]>) {
        _model = State(initialValue: AllTestsListModel(additionalTests: additionalNamedTests))
    }

    public var body: some View {
        AllTestsListContent(model: model)
    }
}

/// Observes the state-owned model and draws the shared list on iOS 13 and later.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
private struct AllTestsListContent: View {
    @ObservedObject var model: AllTestsListModel

    var body: some View {
        List {
            ModuleTestSectionsView(modules: model.modules, additionalTests: model.additionalTests)
        }
        .backport.scrollContentBackground(.hidden)
        .background(LinearGradient(colors: [.red, .yellow, .green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
        .onAppear { model.startAllTestsOnce() }
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("Tests") {
    AllTestsListView()
}
#endif
