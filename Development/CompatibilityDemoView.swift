//
//  CompatibilityDemoView.swift
//  Compatibility
//
//  Created by Ben Ku on 7/13/24.
//

#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation)
import SwiftUI
import Compatibility

@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
@MainActor
struct CompatibilityDemoView: View {
    @State var runCount = 0
    var body: some View {
        TabView {
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
            AllTestsListView(additionalNamedTests: [
                "Injected Test": [
                    Test("FoObar") {
                        let foo = "bar"
                        try expect(foo == "bar")
                    },
                    Test("Fail Test (should fail)") { @MainActor in // this must be main actor isolated since self is main actor isolated.
                        self.runCount++
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
            ])
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
//        .backport.safeAreaPadding(.bottom, 300)
        .backport.tabViewStyle(.page)
//        .ignoresSafeArea()
    }
}

@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
#Preview {
    CompatibilityDemoView()
}
#endif
