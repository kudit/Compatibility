#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation)
import SwiftUI

// Font-size reference:
// https://www.iosfontsizes.com

// MARK: - Padding and spacing

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension EdgeInsets {
    static let zero = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension View {
    func padding(size: Double) -> some View {
        padding(EdgeInsets(top: size, leading: size, bottom: size, trailing: size))
    }

    func frame(size: Double, alignment: Alignment = .center) -> some View {
        frame(width: size, height: size, alignment: alignment)
    }
}

// MARK: - Conditional modifier
/// https://www.avanderlee.com/swiftui/conditional-view-modifier/
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    ///
    /// The transform is a `ViewBuilder`, so it can use normal SwiftUI branching without requiring
    /// `Group` or `AnyView` solely to reconcile different view types.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, @ViewBuilder transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension View {
    func disableSmartQuotes() -> some View {
#if canImport(UIKit) && !os(watchOS)
        self.keyboardType(.asciiCapable) // prevent converting quotes to "smart" quotes which breaks parsing.
#else
        self
#endif
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension View {
    /// Applies the given transform to this view.
    ///
    /// The transform is a `ViewBuilder`, so it can use conditional compilation, availability checks,
    /// and normal SwiftUI branching without requiring `Group` or `AnyView` solely for type erasure.
    /// - Parameters:
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: The modified `View`.
    @ViewBuilder func closure<Content: View>(@ViewBuilder transform: (Self) -> Content) -> some View {
        transform(self)
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
public struct RadialTestView: View {
    @State var symbol = "calendar"
    
    public init() {}
    public var body: some View {
        VStack {
            Text("Open Source projects used include [Compatibility](https://github.com/kudit/Compatibility) v\(Compatibility.version)")
                .font(.caption)
            if #available(tvOS 17, *) {
                MenuTest(symbol: $symbol)
                    .accessibilityIdentifier("radial.inline.symbols.menu")
            } else {
                // Fallback on earlier versions
                // toolbars are not shown in tvOS?
            }
            Text("Selected symbol: \(symbol)")
                .font(.caption)
                .accessibilityIdentifier("radial.symbol.status")
            
            RadialLayout {
                ForEach(0..<24, id: \.self) { item in
                    Circle()
                        .fill([Color].rainbow[nth: item])
                        .frame(width: 64)
                        .overlay(Image(systemName: symbol)
                            .foregroundColor(.white)
                        )
                }
            }
            .aspectRatio(contentMode: .fit)
        }
        .toolbar {
            if #available(tvOS 17, *) {
                MenuTest(symbol: $symbol)
                    .padding()
                    .accessibilityIdentifier("radial.toolbar.symbols.menu")
            } else {
                // Fallback on earlier versions
                // toolbars are not shown in tvOS?
            }
        }
        .backport.navigationTitle("RadialLayout/Menu Tests")
        .navigationWrapper()
    }
}
@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview("RadialLayout TestCase") {
    RadialTestView()
}


// MARK: - For sliders with Ints (and other binding conversions)
/// https://stackoverflow.com/questions/65736518/how-do-i-create-a-slider-in-swiftui-for-an-int-type-property
/// Slider(value: .convert(from: $count), in: 1...8, step: 1)
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Binding {
    static func convert<TInt: Sendable, TFloat: Sendable>(from intBinding: Binding<TInt>) -> Binding<TFloat>
        where TInt:   BinaryInteger, TFloat: BinaryFloatingPoint {
            
        Binding<TFloat> (
            get: { TFloat(intBinding.wrappedValue) },
            set: { intBinding.wrappedValue = TInt($0) }
        )
    }
    
    static func convert<TFloat: Sendable, TInt: Sendable>(from floatBinding: Binding<TFloat>) -> Binding<TInt>
        where TFloat: BinaryFloatingPoint, TInt:   BinaryInteger {
            
        Binding<TInt> (
            get: { TInt(floatBinding.wrappedValue) },
            set: { floatBinding.wrappedValue = TFloat($0) }
        )
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
public struct ConvertTestView: View {
    public init() {}
    @State private var count: Int = 3
    public var body: some View {
        VStack{
            HStack {
                ForEach(1...count, id: \.self) { n in
                    Text("\(n)")
                        .font(.title).bold().foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.blue)
                }
            }
            .frame(maxHeight: 64)
            HStack {
                Text("Count: \(count)")
#if os(tvOS)
                Group {
                    Button("Decrease") {
                        count--
                    }.disabled(count < 2)
                    Button("Increase") {
                        count++
                    }
                }.buttonStyle(.bordered)
#else
                Slider(value: .convert(from: $count), in: 1...8, step: 1)
#endif
            }
        }
        .padding()
    }
}
@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview("Convert TestCase") {
    ConvertTestView()
}

// Support fill and stroke
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Shape {
    /// Compatibility backport fill and stroke on shapes.
    func fill<Fill: ShapeStyle, Stroke: ShapeStyle>(_ fillStyle: Fill, strokeBorder strokeStyle: Stroke, lineWidth: Double = 1) -> some View {
        self
            .stroke(strokeStyle, lineWidth: lineWidth)
            .background(self.fill(fillStyle))
    }
}

// TODO: is the below necessary??
/*
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension InsettableShape {
    func fill<Fill: ShapeStyle, Stroke: ShapeStyle>(_ fillStyle: Fill, strokeBorder strokeStyle: Stroke, lineWidth: Double = 1) -> some View {
        self
            .strokeBorder(strokeStyle, lineWidth: lineWidth)
            .background(self.fill(fillStyle))
    }
}

// TODO: Deprecate this in favor of above??
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension InsettableShape {
    /// Fills and strokes this shape with a color or gradient in a compatible way for iOS 17 and earlier.
    ///
    /// - Parameters:
    ///   - content: The color or gradient to use when filling this shape.
    ///   - style: The style options that determine how the fill renders.
    ///   - strokeContent: The color or gradient with which to stroke this shape.
    ///   - lineWidth: The width of the stroke that outlines this shape.
    /// - Returns: A shape view filled with the color or gradient you supply and stroked with the content and line width specified.
    func fillAndStroke<F: ShapeStyle,S: ShapeStyle>(_ content: F = .foreground, style: FillStyle = FillStyle(), _ strokeContent: S, lineWidth: CGFloat = 1, antialiased: Bool = true) -> some View {
        if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
            return self
                .fill(content, style: style)
                .stroke(strokeContent, lineWidth: lineWidth, antialiased: antialiased)
        } else {
            return self
                .strokeBorder(strokeContent, lineWidth: lineWidth, antialiased: antialiased)
                .background(self.fill(content, style: style))
        }
    }
}
// TODO: Use the top syntax but the bottom compatibility
@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview("Fill & Stroke") {
    VStack {
        Circle()
            .fill(.green, strokeBorder: .blue, lineWidth: 20)
        RoundedRectangle(cornerRadius: 25)
            .fill(.tertiary, strokeBorder: .tint, lineWidth: 5)
    }.padding()
}
@available(iOS 13, macOS 10.15, watchOS 6, tvOS 13, *)
#Preview("Fill and Stroke") {
    VStack {
        Circle()
            .fillAndStroke(.green, .blue, lineWidth: 3)
        RoundedRectangle(cornerRadius: 10)
            .fillAndStroke(.red, .orange, lineWidth: 5)
    }
}
 */
@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
public struct FillAndStrokeTest: View {
    public init() {}
    public var body: some View {
        VStack {
            Circle()
                .fill(.green, strokeBorder: .blue, lineWidth: 20)
                .backport.overlay {
                    Image(systemName: "applelogo")
                        .imageScale(.large)
                        .foregroundColor(.white)
                }
            RoundedRectangle(cornerRadius: 25)
                .fill(.tertiary, strokeBorder: .tint, lineWidth: 5)
        }.padding()
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview("Fill & Stroke") {
    FillAndStrokeTest()
}


// MARK: - Material
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension View {
    @MainActor
    func backgroundMaterial() -> some View {
        self
            .padding()
            .backport.background {
                if #available(iOS 15, macOS 12, tvOS 15, watchOS 10, *) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.regularMaterial)
                } else {
                    // Fallback on earlier versions
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.gray.opacity(0.5))
                }
            }
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
public struct MaterialTestView: View {
    @State private var showNavigationDetail = false
    @State private var conditionalEnabled = true
    @State var showSheet: Bool = false
    public init() {}
    public var body: some View {
        ZStack {
            Color.clear
            HStack {
                Button {
                        showNavigationDetail = true
                    } label: {
                        Text("Material Navigation")
                            .backgroundMaterial()
                            // Keep the identifier on the rendered label as well as the Button because
                            // older SwiftUI accessibility bridges sometimes expose only the label node.
                            .accessibilityIdentifier("material.navigation.trigger")
                    }
                    // Use a real Button so SwiftUI publishes one unambiguous actionable accessibility element;
                    // the previous tappable Text could collide with the Material tab label in UI tests.
                    .accessibilityIdentifier("material.navigation.trigger")
                    .accessibilityLabel("Material Navigation")
                Button {
                    showSheet = true
                } label: {
                    Text("Glass")
                        .padding()
                }
                .accessibilityIdentifier("material.glass.button")
                .accessibilityLabel("Glass")
                .backport.glassEffect(.regular.interactive())
            }
            // Recreate the Material controls after navigation dismisses so the sheet trigger is not left
            // in a stale accessibility subtree retained by the navigation backport.
            .id(showNavigationDetail ? "material-navigation" : "material-root")
        }
        .background(.conicGradient(colors: [.red, .green, .blue], center: .center))
        .sheet(isPresented: $showSheet) {
            ZStack {
                //                    Color.blue
//                AStack {
//                    Color.yellow
//                    Color.green
//                }.padding()
                AdaptiveLayoutsShowcaseView()
            }
            .toolbar {
                ToolbarItem(placement: .bottomBackport) {
                    Button("Close") {
                        showSheet = false
                    }
                }
            }
            .navigationWrapper()
            .backport.presentationDetents([.fraction(1/3), .medium, .large])
            .backport.presentationBackground(.ultraThinMaterial)
        }
        .backport.navigationDestination(isPresented: $showNavigationDetail) {
            ScrollView {
                VStack(spacing: 20) {
                    // Keep the destination itself tappable so this continues to exercise the binding-based
                    // navigation backport while also providing useful content to inspect before returning.
                    Button("Navigation Destination TestCase") {
                        showNavigationDetail = false
                    }

                    GroupBox("Other View Utilities") {
                        VStack(spacing: 12) {
                            Text("RadialStack arranges its children around a circle using the same compact utility that can be embedded in other views.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            RadialStack {
                                Circle().fill(.red)
                                Circle().fill(.orange)
                                Circle().fill(.yellow)
                                Circle().fill(.green)
                                Circle().fill(.blue)
                                Circle().fill(.purple)
                            }
                            .frame(width: 180, height: 180)

                            Toggle("Apply conditional modifier", isOn: $conditionalEnabled)
                                .accessibilityIdentifier("material.conditional.toggle")

                            Text(conditionalEnabled ? "Conditional modifier applied" : "Conditional modifier not applied")
                                .if(conditionalEnabled) { view in
                                    view
                                        .padding(size: 6)
                                        .background(.yellow.opacity(0.25))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(.orange, lineWidth: 2)
                                        }
                                }
                                .closure { content in
                                    if #available(iOS 999, macOS 999, tvOS 999, watchOS 999, visionOS 999, *) {
                                        content.italic()
                                    } else if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
                                        content.bold().foregroundStyle(.blue)
                                    } else {
                                        // Fallback on earlier versions
                                        content.foregroundStyle(.red)
                                    }
                                }
                                .accessibilityIdentifier("material.conditional.result")
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .accessibilityIdentifier("material.navigation.destination")
        }
        .navigationWrapper()
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview("Material TestCase") {
    MaterialTestView()
}

// MARK: - Wrappers
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension View {
    @MainActor
    func navigationWrapper() -> some View {
        BackportNavigationStack { // possibly BackportNavigationStack to avoid naming confusion and unintended conflicts
            self
        }
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension View {
    func scrollWrapper() -> some View {
        ScrollView {
            self
        }
    }
}

#endif
