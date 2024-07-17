//
//  CompatibilityDemoView.swift
//  Compatibility
//
//  Created by Ben Ku on 7/13/24.
//

import SwiftUI
import Compatibility

@available(iOS 15.0, macOS 12, tvOS 17, watchOS 8, *)
struct CompatibilityDemoView: View {
    var body: some View {
        TabView {
            AllTestsListView(additionalNamedTests: [
                "Injected Test": [Test("Dummy test") {
                    debug("Debug test", level: .DEBUG)
                    try expect(true)
                }]
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
            FillAndStrokeTest()
                .tabItem {
                    Text("Fill & Stroke")
                }
            MaterialTestView()
                .tabItem {
                    Text("Material")
                }
        }
        .backport.tabViewStyle(.page)
    }
}

@available(iOS 15.0, macOS 12, tvOS 17, watchOS 8, *)
#Preview {
    CompatibilityDemoView()
}
