//
//  CompatibilityDemoView.swift
//  Compatibility
//
//  Created by Ben Ku on 7/13/24.
//

#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation)
import SwiftUI
import Foundation
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
    static let additionalTests: OrderedDictionary<String, [TestCase]> = [
        "Injected Test": [
            TestCase("FoObar") {
                let foo = "bar"
                try expect(foo == "bar")
            },
            TestCase("Fail Test (should fail)") {
                let runCount = DemoFailureCounter.shared.next()
                try expect(false, "This has run \(runCount) times")
            },
            TestCase("Availability Test") {
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
        TabView {
            if #available(watchOS 9, *) {
                CompatibilityEnvironmentTestView()
                    .accessibilityIdentifier("demo.compatibility")
                    .tabItem {
                        Text("Compatibility")
                    }
                DataStoreTestView()
                    .accessibilityIdentifier("demo.datastore")
                    .tabItem {
                        Text("DataStore")
                    }
            }
            // Application tracking has already registered the complete ordered module graph consumed here.
            AllTestsListView(additionalTests: Self.additionalTests)
                .accessibilityIdentifier("demo.allTests")
                .tabItem {
                    Text("All Tests")
                }
            ClosureTestView()
                .accessibilityIdentifier("demo.closure")
                .tabItem {
                    Text("Closure")
                }
            RandomBytesTestView()
                .accessibilityIdentifier("demo.randomBytes")
                .tabItem {
                    Text("Random Bytes")
                }
            ConvertTestView()
                .accessibilityIdentifier("demo.convert")
                .tabItem {
                    Text("Convert")
                }
            TriangleShowcaseView()
                .accessibilityIdentifier("demo.triangle")
                .tabItem {
                    Text("Triangle Showcase")
                }
            FillAndStrokeTest()
                .accessibilityIdentifier("demo.fillAndStroke")
                .tabItem {
                    Text("Fill & Stroke")
                }
            PlacardShowcaseView()
                .accessibilityIdentifier("demo.placard")
                .tabItem {
                    Text("Placard Showcase")
                }
            MaterialTestView()
                .accessibilityIdentifier("demo.material")
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
