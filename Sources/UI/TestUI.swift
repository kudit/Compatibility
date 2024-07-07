#if canImport(SwiftUI)
import SwiftUI

// MARK: - Test UI
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

struct TestsRowsView: View {
    var tests: [Test]
    var body: some View {
        ForEach(tests, id: \.title) { item in
            TestRow(test: item)
                .onAppear {
                    item.run()
                }
        }
    }
}

// use this to test the local file tests only.
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

@available(macOS 12.0, watchOS 8, *)
public struct AllTestsListView: View {
    // only necessary since in module and otherwise inaccessible outside package
    public init() {}
    public var body: some View {
        List {
            Section("Threading Tests") {
                TestsRowsView(tests: KuThreading.tests)
            }
            Section("Int Tests") {
                TestsRowsView(tests: Int.tests)
            }
            Section("Collection Tests") {
                TestsRowsView(tests: collectionTests)
            }
            Section("Date Tests") {
                TestsRowsView(tests: Date.tests)
            }
            Section("String Tests") {
                TestsRowsView(tests: String.tests)
            }
            Section("CharacterSet Tests") {
                TestsRowsView(tests: CharacterSet.tests)
            }
            Section {
                Divider()
            } footer: {
                Text("Compatibility v\(Compatibility.version) © 2024 Kudit LLC").font(.caption).padding()
            }
        }
        .toolbar {
            MenuTest()
        }
        .navigationTitle("Unit Tests")
        .navigationWrapper()
    }
}

@available(macOS 12.0, watchOS 8, *)
#Preview("Tests") {
    AllTestsListView()
}

#endif
