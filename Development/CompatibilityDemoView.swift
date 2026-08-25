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
@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
@MainActor
struct VisualShowcaseView: View {
    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                NavigationLink {
                    TriangleShowcaseView()
                        .accessibilityIdentifier("showcase.triangles.destination")
                } label: {
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
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("showcase.triangles.link")

                NavigationLink {
                    PlacardShowcaseView()
                        .accessibilityIdentifier("showcase.placards.destination")
                } label: {
                    GroupBox("Placards") {
                        HStack(spacing: 12) {
                            ForEach(0..<4) { index in
                                Placard()
                                    .fill(colors[nth: index], strokeBorder: .primary, lineWidth: 2)
                                    .aspectRatio(1.4, contentMode: .fit)
                            }
                        }
                        .frame(height: 80)
                        .padding()
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("showcase.placards.link")

                NavigationLink {
                    FillAndStrokeTest()
                        .accessibilityIdentifier("showcase.fillStroke.destination")
                } label: {
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
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("showcase.fillStroke.link")

                NavigationLink {
                    EmbossedShowcaseView()
                        .accessibilityIdentifier("showcase.embossed.destination")
                } label: {
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
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("showcase.embossed.link")

                NavigationLink {
                    OverlappingStackShowcaseView()
                        .accessibilityIdentifier("showcase.overlapping.destination")
                } label: {
                    GroupBox("Overlapping Stacks") {
                        VStack(spacing: 16) {
                            OverlappingHStack {
                                ForEach(0..<8) { index in
                                    Circle()
                                        .fill(colors[nth: index])
                                        .frame(size: 54)
                                }
                            }
                            .frame(height: 60)

                            OverlappingHStack(alignment: .bottom) {
                                ForEach(0..<6) { index in
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(colors[nth: index])
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
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("showcase.overlapping.link")

                NavigationLink {
                    AdaptiveLayoutsShowcaseView()
                        .accessibilityIdentifier("showcase.adaptive.destination")
                } label: {
                    GroupBox("Adaptive Layouts") {
                        VStack(spacing: 12) {
                            AdaptiveLayout(orientation: .horizontal) {
                                layoutSample("Portrait branch", color: .blue)
                            } landscape: {
                                layoutSample("Landscape branch", color: .green)
                            }
                            .frame(height: 44)

                            AdaptiveLayout(orientation: .vertical) {
                                layoutSample("Portrait branch", color: .blue)
                            } landscape: {
                                layoutSample("Landscape branch", color: .green)
                            }
                            .frame(height: 44)

                            HStack {
                                AdaptiveLayout {
                                    layoutSample("Adaptive portrait", color: .orange)
                                } landscape: {
                                    layoutSample("Adaptive landscape", color: .purple)
                                }
                                .frame(width: 90, height: 130)

                                AdaptiveLayout {
                                    layoutSample("Adaptive portrait", color: .orange)
                                } landscape: {
                                    layoutSample("Adaptive landscape", color: .purple)
                                }
                                .frame(width: 180, height: 70)
                            }

                            AStack(alignment: .topOrLeading, orientation: .horizontal) { orientation in
                                layoutSample("Top/Leading \(String(describing: orientation))", color: .red)
                                layoutSample("Second item", color: .yellow)
                            }
                            .frame(height: 50)

                            AStack(alignment: .center, orientation: .adaptive) {
                                layoutSample("Adaptive", color: .cyan)
                                layoutSample("Center", color: .mint)
                            }
                            .frame(height: 60)

                            AStack(alignment: .bottomOrTrailing, orientation: .vertical) {
                                layoutSample("Vertical", color: .indigo)
                                layoutSample("Bottom/Trailing", color: .pink)
                            }
                            .frame(height: 90)
                        }
                        .padding()
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("showcase.adaptive.link")
            }
            .padding()
        }
        .navigationWrapper()
    }

    @ViewBuilder
    private func overlappingVertical(alignment: HorizontalAlignment) -> some View {
        OverlappingVStack(alignment: alignment) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(colors[nth: index])
                    .frame(width: CGFloat(32 + index * 5), height: 48)
            }
        }
    }

    private func layoutSample(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.caption)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(4)
            .background(color.opacity(0.18))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(color, lineWidth: 2)
            }
    }
}

/// Interactive examples for APIs implemented in `Backport.swift`. Keeping these examples in their own
/// tab makes the compatibility behavior easier to understand and lets UI tests exercise the controls
/// without first traversing the much taller visual-layout showcase.
@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
@MainActor
struct BackportShowcaseView: View {
    @State private var symbolName: String? = "cloud.rainbow.crop"
    @State private var backportSelection = 0
    @State private var backportScrollDisabled = false
    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("Backport.TabView") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This example uses Compatibility's Backport.TabView without a selection binding. On current platforms it displays the native SwiftUI TabView; the backport also supplies a usable fallback on older systems such as watchOS 6.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Backport.TabView {
                            Text("First unbound tab")
                                .tabItem { Text("First") }
                            Text("Second unbound tab")
                                .tabItem { Text("Second") }
                        }
                        .frame(height: 72)
                    }
                    .padding()
                }

                GroupBox("Selection-bound Backport.TabView") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This version supplies a Binding. The button changes the selected tag programmatically so you can see that the same backported container participates in SwiftUI selection state.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Backport.TabView(selection: $backportSelection) {
                            Text("Bound tab zero")
                                .tag(0)
                                .tabItem { Text("Zero") }
                            Text("Bound tab one")
                                .tag(1)
                                .tabItem { Text("One") }
                        }
                        .frame(height: 72)

                        HStack {
                            Text("Bound selection: \(backportSelection)")
                                .accessibilityIdentifier("backport.selection.status")
                            Spacer()
                            Button("Select \(backportSelection == 0 ? "one" : "zero")") {
                                backportSelection = backportSelection == 0 ? 1 : 0
                            }
                            .accessibilityIdentifier("backport.selection.toggle")
                        }
                    }
                    .padding()
                }

                GroupBox("Backported SF Symbol image") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Enter an SF Symbol name. Backport.Image uses the native symbol image where available and a text fallback on older macOS versions. The field is also a live ClearableTextField example.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ClearableTextField(label: "SF Symbol name", text: $symbolName)
                            .accessibilityIdentifier("backport.symbol.field")

                        HStack {
                            SwiftUI.Image(backportSystemName: symbolName ?? "questionmark")
                                .renderingMode(.original)
                                .font(.largeTitle)
                                .foregroundStyle(.blue)
                                .accessibilityIdentifier("backport.symbol.preview")
                            Text("Current symbol: \(symbolName ?? "<empty>")")
                                .accessibilityIdentifier("backport.symbol.status")
                        }
                    }
                    .padding()
                }

                GroupBox("Backported scrollDisabled") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("The numbered items are simply a horizontal scrolling strip. Toggle scrolling off and on to exercise Compatibility's scrollDisabled backport while confirming the content itself is unchanged.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Toggle("Disable numbered-strip scrolling", isOn: $backportScrollDisabled)
                            .accessibilityIdentifier("backport.scroll.toggle")

                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(0..<12) { index in
                                    Text("\(index)")
                                        .frame(size: 32)
                                        .background(colors[nth: index].opacity(0.25))
                                        .accessibilityIdentifier("backport.scroll.item.\(index)")
                                }
                            }
                        }
                        .accessibilityIdentifier("backport.scroll.strip")
                        // Keep the viewport deliberately narrower than the numbered content so enabled
                        // and disabled scrolling are both visually obvious and mechanically testable.
                        .frame(width: 220, height: 40, alignment: .leading)
                        .backport.scrollDisabled(backportScrollDisabled)
                    }
                    .padding()
                }
            }
            .padding()
        }
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
        RadialTestView()
            .accessibilityIdentifier("demo.radialLayout")
            .tabItem {
                Text("Radial Layout")
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
        BackportShowcaseView()
            .accessibilityIdentifier("demo.backport")
            .tabItem {
                Text("Backport")
            }
        MaterialTestView()
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
