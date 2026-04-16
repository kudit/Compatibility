#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation) && !(os(WASM) || os(WASI))
import SwiftUI

// MARK: - Test UI
@available(iOS 13, tvOS 13, watchOS 6, *)
public struct TestRow: View {
    @ObservedObject public var test: Test
    
    // only necessary since in module and otherwise inaccessible outside package
    public init(test: Test) {
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

@available(iOS 13, tvOS 13, watchOS 6, *)
struct TestsRowsView: View {
    var tests: [Test]
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
    let namedTests: OrderedDictionary<String, [Test]>

    init(additionalNamedTests: OrderedDictionary<String, [Test]> = [:]) {
        self.namedTests = additionalNamedTests.merging(Test.namedTests) { additionalTests, baseTests in
            additionalTests + baseTests
        }
    }
}

// use this to test the local file tests only.
@available(iOS 13, tvOS 13, watchOS 6, *)
public struct TestsListView: View {
    public var tests: [Test]
    
    // only necessary since in module and otherwise inaccessible outside package
    public init(tests: [Test]) {
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
public struct AllTestsListView: View {
    /// Holds the test instances for the life of the view so background tasks don't outlive constantly recreated rows.
    @StateObject private var model: AllTestsListModel
    
    // only necessary since in module and otherwise inaccessible outside package
    public init(additionalNamedTests: OrderedDictionary<String, [Test]> = [:]) {
        _model = StateObject(wrappedValue: AllTestsListModel(additionalNamedTests: additionalNamedTests))
    }
    public var body: some View {
        List {
            ForEach(model.namedTests.keys.elements, id: \.self) { key in
                let tests = model.namedTests[key] ?? []
                Section(key) {
                    TestsRowsView(tests: tests)
                }
            }
            Section {
                Divider()
            } footer: {
                Text("Compatibility v\(Compatibility.version) © \(String(Date.now.year)) Kudit LLC").font(.caption).padding()
            }
        }
        // test replacing background
        .backport.scrollContentBackground(.hidden)
        .background(.linearGradient(colors: [.red, .yellow, .green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}

@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
#Preview("Tests") {
    AllTestsListView()
}
#endif
