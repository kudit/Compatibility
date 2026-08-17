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

/// Collects representative visual Compatibility APIs in one scrollable screen so the demo and UI
/// coverage tour exercise the real layouts/modifiers without maintaining a separate tab for each one.
@available(iOS 15, macOS 12, tvOS 17, watchOS 9, *)
@MainActor
struct VisualShowcaseView: View {
    @State private var clearableText: String? = "Clearable text"

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                GroupBox("Triangles") {
                    HStack {
                        ForEach(Edge.allCases, id: \.self) { edge in
                            Triangle(flatEdge: edge)
                                .fill(.green, strokeBorder: .yellow, lineWidth: 3)
                                .frame(size: 64)
                        }
                    }
                    .padding()
                }

                GroupBox("Placard") {
                    Placard()
                        .fill(.blue, strokeBorder: .primary, lineWidth: 2)
                        .frame(height: 120)
                        .padding()
                }

                GroupBox("Fill & Stroke") {
                    HStack {
                        Circle()
                            .fill(.green, strokeBorder: .blue, lineWidth: 8)
                        RoundedRectangle(cornerRadius: 18)
                            .fill(.tertiary, strokeBorder: .tint, lineWidth: 5)
                    }
                    .frame(height: 100)
                    .padding()
                }

                GroupBox("Embossed") {
                    HStack(spacing: 24) {
                        Text("Raised")
                            .padding()
                            .background(.gray.opacity(0.25))
                            .embossed()
                        Text("Sharp")
                            .padding()
                            .background(.gray.opacity(0.25))
                            .embossed(offset: 2, blur: 0)
                    }
                    .padding()
                }

                GroupBox("Overlapping Stacks") {
                    VStack(spacing: 16) {
                        OverlappingHStack {
                            ForEach(0..<8) { index in
                                Circle()
                                    .fill([Color].rainbow[nth: index])
                                    .frame(size: 54)
                            }
                        }
                        .frame(height: 60)

                        OverlappingHStack(alignment: .bottom) {
                            ForEach(0..<6) { index in
                                RoundedRectangle(cornerRadius: 8)
                                    .fill([Color].rainbow[nth: index])
                                    .frame(width: 70, height: CGFloat(24 + index * 6))
                            }
                        }
                        .frame(height: 70)

                        HStack(spacing: 20) {
                            overlappingVertical(alignment: .leading)
                            overlappingVertical(alignment: .center)
                            overlappingVertical(alignment: .trailing)
                        }
                        .frame(height: 150)

                        // Exercise the layout's zero- and one-child placement paths as well.
                        OverlappingHStack {
                            ForEach(0..<0) { _ in
                                Color.clear
                            }
                        }
                        .frame(height: 1)
                        OverlappingHStack {
                            Circle().fill(.secondary).frame(size: 30)
                        }
                        .frame(height: 32)
                    }
                    .padding()
                }

                GroupBox("Adaptive Layouts") {
                    VStack(spacing: 12) {
                        AdaptiveLayout(orientation: .horizontal) {
                            Text("Portrait")
                        } landscape: {
                            HStack { Text("Landscape"); Spacer() }
                        }
                        .frame(height: 30)

                        AdaptiveLayout(orientation: .vertical) {
                            VStack { Text("Portrait") }
                        } landscape: {
                            Text("Landscape")
                        }
                        .frame(height: 30)

                        HStack {
                            AdaptiveLayout {
                                Text("Adaptive portrait")
                            } landscape: {
                                Text("Adaptive landscape")
                            }
                            .frame(width: 90, height: 130)

                            AdaptiveLayout {
                                Text("Adaptive portrait")
                            } landscape: {
                                Text("Adaptive landscape")
                            }
                            .frame(width: 180, height: 70)
                        }

                        AStack(alignment: .topOrLeading, orientation: .horizontal) { orientation in
                            Text("Top/Leading \(String(describing: orientation))")
                            Text("Horizontal")
                        }
                        AStack(alignment: .center, orientation: .adaptive) {
                            Text("Adaptive")
                            Text("Center")
                        }
                        .frame(height: 50)
                        AStack(alignment: .bottomOrTrailing, orientation: .vertical) {
                            Text("Vertical")
                            Text("Bottom/Trailing")
                        }
                    }
                    .padding()
                }

                GroupBox("Other View Utilities") {
                    VStack(spacing: 12) {
                        RadialStack {
                            ForEach(0..<6) { index in
                                Circle().fill([Color].rainbow[nth: index])
                            }
                        }
                        .frame(width: 180, height: 180)

                        Text("Conditional modifier")
                            .if(true) { view in
                                view.bold()
                            }
                            .padding(size: 6)

                        ClearableTextField(label: "Clearable", text: $clearableText)
                    }
                    .padding()
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func overlappingVertical(alignment: HorizontalAlignment) -> some View {
        OverlappingVStack(alignment: alignment) {
            ForEach(0..<5) { index in
                Circle()
                    .fill([Color].rainbow[nth: index])
                    .frame(width: CGFloat(32 + index * 5), height: 48)
            }
        }
    }
}

/// Keeps the Material demo and navigation-destination compatibility check together now that the
/// visual-only shape demos share a single showcase tab.
@available(iOS 15, macOS 12, tvOS 17, watchOS 9, *)
@MainActor
struct MaterialNavigationTestView: View {
    @State private var showNavigationDetail = false

    var body: some View {
        VStack(spacing: 12) {
            MaterialTestView()
            Button("Navigation Test") {
                showNavigationDetail = true
            }
        }
        .backport.navigationDestination(isPresented: $showNavigationDetail) {
            Button("Navigation Destination TestCase") {
                showNavigationDetail = false
            }
        }
        .navigationWrapper()
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

    @ViewBuilder
    private var demoTabs: some View {
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
        VisualShowcaseView()
            .accessibilityIdentifier("demo.visualShowcase")
            .tabItem {
                Text("Visual Showcase")
            }
        MaterialNavigationTestView()
            .accessibilityIdentifier("demo.material")
            .tabItem {
                Text("Material")
            }
    }

    var body: some View {
        TabView {
            demoTabs
        }.closure { view in
#if os(macOS)
            // Use SwiftUI's native macOS tab presentation. Page style collapses many pages behind a
            // Navigation Tab Bar menu, which is less useful for this desktop test/demo application.
            if #available(macOS 15.0, *) {
//                view.tabViewStyle(.tabBarOnly)
                view.tabViewStyle(.sidebarAdaptable)
            } else {
                // Fallback on earlier versions
                view.tabViewStyle(.automatic)
            }
#else
            view.backport.tabViewStyle(.page)
#endif
        }
    }
}

@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
#Preview {
    CompatibilityDemoView()
}
#endif
