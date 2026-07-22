#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation) && !(os(WASM) || os(WASI))
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
                Text(errorMessage).font(.caption)
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
                .onAppear {
                    if !item.isFinished() {
                        item.run()
                    }
                }
        }
    }
}

@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
@MainActor
final class AllTestsListModel: ObservableObject {
    let module: Module.Type
    let namedTests: OrderedDictionary<String, [TestCase]>

    init(module: Module.Type, additionalTests: OrderedDictionary<String, [TestCase]> = [:]) {
        self.module = module
        // Put caller-supplied checks first while retaining the module's declared section order.
        self.namedTests = additionalTests.merging(module.tests) { additionalTests, moduleTests in
            additionalTests + moduleTests
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
        _model = StateObject(wrappedValue: AllTestsListModel(module: module, additionalTests: additionalTests))
    }
    public var body: some View {
        List {
            Section {
                // A compact summary gives the module header real content on every SwiftUI List implementation.
                Text(model.namedTests.isEmpty ? "No test sections" : "\(model.namedTests.count) test sections")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("\(model.module.moduleName) v\(model.module.version)")
            }
            if model.namedTests.isEmpty {
                // Keep an explicit section for modules without tests so the screen is never ambiguous.
                Section(model.module.moduleName) {
                    Text("No tests provided")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(model.namedTests.keys.elements, id: \.self) { key in
                    let tests = model.namedTests[key] ?? []
                    Section(key) {
                        TestsRowsView(tests: tests)
                    }
                }
            }
        }
        // test replacing background
        .backport.scrollContentBackground(.hidden)
        .background(.linearGradient(colors: [.red, .yellow, .green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}

/// Compatibility's complete reusable test catalog.
///
/// Use ``ModuleTestsListView`` when presenting another module or composing additional sections.
@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
@MainActor
public struct AllTestsListView: View {
    private let additionalTests: OrderedDictionary<String, [TestCase]>

    public init(additionalTests: OrderedDictionary<String, [TestCase]> = [:]) {
        self.additionalTests = additionalTests
    }

    @available(*, deprecated, renamed: "init(additionalTests:)")
    public init(additionalNamedTests: OrderedDictionary<String, [TestCase]>) {
        self.additionalTests = additionalNamedTests
    }

    public var body: some View {
        // Preserve the familiar all-tests entry point while using the module-oriented presentation.
        ModuleTestsListView(module: Compatibility.self, additionalTests: additionalTests)
    }
}

@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
#Preview("Tests") {
    AllTestsListView()
}
#endif
