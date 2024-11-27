#if canImport(SwiftUI)
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
                    item.run()
                }
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
    /// Ordered set of section names and list of tests.  Similar to an ordered set but we do care about the order so that's why it's an array of tuples rather than a simple dictionary.  TODO: Should we change this to an ordered dictionary for clarity?  Means adding a dependency of swift-collections which isn't necessarily a problem.
    // TODO: Have this be some singleton shared state so that it's not tied to the view so it won't re-create when view changes.
    public var namedTests: OrderedDictionary = [
        "Version Tests": Version.tests,
        "Int Tests": Int.tests,
        "Collection Tests": collectionTests,
        "Date Tests": Date.tests,
        "String Tests": String.tests,
        "CharacterSet Tests": CharacterSet.tests,
        "Threading Tests": KuThreading.tests,
        "Network Tests": PostData.tests,
    ]
    // only necessary since in module and otherwise inaccessible outside package
    public init(additionalNamedTests: OrderedDictionary<String, [Test]> = [:]) {
        // put additional up front
        self.namedTests = additionalNamedTests.merging(namedTests) { additionalTests, baseTests in
            return additionalTests + baseTests
        }
    }
    public var body: some View {
        List {
            ForEach(namedTests.keys.elements, id: \.self) { key in
                let tests = namedTests[key] ?? []
                Section(key) {
                    TestsRowsView(tests: tests)
                }
            }
            Section {
                Divider()
            } footer: {
                Text("Compatibility v\(Compatibility.version) © 2024 Kudit LLC").font(.caption).padding()
            }
        }
        // test replacing background
        .backport.scrollContentBackground(.hidden)
        .background(.linearGradient(colors: [.red, .yellow, .green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}

#if swift(>=5.9)
@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
#Preview("Tests") {
    AllTestsListView()
}
#endif

#endif
