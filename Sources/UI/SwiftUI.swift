#if canImport(SwiftUI)
import SwiftUI

// Font-size reference:
// https://www.iosfontsizes.com

// MARK: - Padding and spacing

@available(iOS 13, tvOS 13, watchOS 6, *)
public extension EdgeInsets {
    static let zero = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
}

@available(iOS 13, tvOS 13, watchOS 6, *)
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
@available(iOS 13, tvOS 13, watchOS 6, *)
public extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
public extension View {
    func disableSmartQuotes() -> some View {
#if canImport(UIKit) && !os(watchOS)
        self.keyboardType(.asciiCapable) // prevent converting quotes to "smart" quotes which breaks parsing.
#else
        self
#endif
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
public extension View {
    /// Applies the given transform.  If using a branching call, both views must be the identical type or use `AnyView(erasing: VIEWCODE)` or a `Group { }` wrapper..
    /// - Parameters:
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: The modified `View`.
    @ViewBuilder func closure<Content: View>(transform: (Self) -> Content) -> some View {
        transform(self)
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
public struct ClosureTestView: View {
    public init() {}
    public var body: some View {
        VStack {
            Text("Test for availability")
            Text("conditional inclusion")
                .closure { content in
                    if #available(iOS 999, macOS 999, tvOS 999, watchOS 999, visionOS 999, *) {
                        AnyView(erasing: content.padding().background(.red).border(.yellow, width: 4))
                    } else {
                        AnyView(erasing: content.padding().background(.blue).border(.green, width: 4))
                    }
                }
            Text("Open Source projects used include [Compatibility](https://github.com/kudit/Compatibility) v\(Compatibility.version)")
                .font(.caption)
        }
        .toolbar {
            if #available(tvOS 17, *) {
                MenuTest()
                    .padding()
            } else {
                // Fallback on earlier versions
                // toolbars are not shown in tvOS?
            }
        }
        .backport.navigationTitle("Compatibility/Menu Test")
        .navigationWrapper()
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview("Closure Test") {
    ClosureTestView()
}


// MARK: - For sliders with Ints (and other binding conversions)
/// https://stackoverflow.com/questions/65736518/how-do-i-create-a-slider-in-swiftui-for-an-int-type-property
/// Slider(value: .convert(from: $count), in: 1...8, step: 1)
@available(iOS 13, tvOS 13, watchOS 6, *)
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
#Preview("Convert Test") {
    ConvertTestView()
}

// Support fill and stroke
@available(iOS 13, tvOS 13, watchOS 6, *)
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
@available(iOS 13, tvOS 13, watchOS 6, *)
public extension InsettableShape {
    func fill<Fill: ShapeStyle, Stroke: ShapeStyle>(_ fillStyle: Fill, strokeBorder strokeStyle: Stroke, lineWidth: Double = 1) -> some View {
        self
            .strokeBorder(strokeStyle, lineWidth: lineWidth)
            .background(self.fill(fillStyle))
    }
}

// TODO: Deprecate this in favor of above??
@available(iOS 13, tvOS 13, watchOS 6, *)
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
@available(iOS 13, watchOS 6, tvOS 13, *)
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
@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
public extension View {
    func backgroundMaterial() -> some View {
        self
            .padding()
            .background {
                if #available(watchOS 10, *) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.regularMaterial)
                } else {
                    // Fallback on earlier versions
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.gray)
                }
            }
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
public struct MaterialTestView: View {
    @State var showSheet: Bool = false
    public init() {}
    public var body: some View {
        ZStack {
            Color.clear
            Button {
                showSheet = true
            } label: {
                Text("Test Material View")
                    .backgroundMaterial()
            }
        }.background(.conicGradient(colors: [.red, .green, .blue], center: .center))
            .sheet(isPresented: $showSheet) {
                ZStack {
                    Color.blue
                    VStack {
                        Color.yellow
                        Color.green
                    }.padding()
                }
                .backport.presentationDetents([.fraction(1/3), .medium, .large])
            }
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview("Material Test") {
    MaterialTestView()
}

// MARK: - Wrappers
@available(iOS 13, tvOS 13, watchOS 7, *)
public extension View {
    @MainActor
    func navigationWrapper() -> some View {
        NavigationStack { // possibly BackportNavigationStack if there is a conflict
            self
        }
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
public extension View {
    func scrollWrapper() -> some View {
        ScrollView {
            self
        }
    }
}

#endif
