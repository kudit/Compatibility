//
//  CompatibilityDemoView.swift
//  Compatibility
//
//  Created by Ben Ku on 7/13/24.
//

#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation) && !(os(WASM) || os(WASI))
import SwiftUI
import Compatibility

final class DemoFailureCounter: @unchecked Sendable {
    static let shared = DemoFailureCounter()
    private let lock = NSLock()
    private var count = 0

    func next() -> Int {
        lock.lock()
        defer { lock.unlock() }
        count += 1
        return count
    }
}

@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
@MainActor
struct CompatibilityDemoView: View {
    static let additionalTests: OrderedDictionary<String, [Test]> = [
        "Injected Test": [
            Test("FoObar") {
                let foo = "bar"
                try expect(foo == "bar")
            },
            Test("Fail Test (should fail)") {
                let runCount = DemoFailureCounter.shared.next()
                try expect(false, "This has run \(runCount) times")
            },
            Test("Availability Test") {
                let success: Bool
                if #available(iOS 11, *) {
                    success = true
                } else {
                    debug("Version too old", level: .ERROR)
                    success = false
                }
                try expect(success, "Availability check failed!  Should not be possible to run on older than iOS 11.")
            },
         ]
    ]

    var body: some View {
        Backport.TabView {
            if #available(watchOS 9, *) {
                CompatibilityEnvironmentTestView()
                    .tabItem {
                        Text("Compatibility")
                    }
                DataStoreTestView()
                    .tabItem {
                        Text("DataStore")
                    }
            }
            AllTestsListView(additionalNamedTests: Self.additionalTests)
                .tabItem {
                    Text("All Tests")
                }
            ClosureTestView()
                .tabItem {
                    Text("Closure")
                }
            RandomBytesTestView()
                .tabItem {
                    Text("Random Bytes")
                }
            ConvertTestView()
                .tabItem {
                    Text("Convert")
                }
            TriangleShowcaseView()
                .tabItem {
                    Text("Triangle Showcase")
                }
            FillAndStrokeTest()
                .tabItem {
                    Text("Fill & Stroke")
                }
            PlacardShowcaseView()
                .tabItem {
                    Text("Placard Showcase")
                }
            MaterialTestView()
                .tabItem {
                    Text("Material")
                }
        }
        .backport.tabViewStyle(.page)
    }
}

@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
#Preview {
    CompatibilityDemoView()
}
#endif
