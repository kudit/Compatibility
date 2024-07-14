#if canImport(SwiftUI)
import SwiftUI

// MARK: - Padding and spacing

@available(watchOS 6.0, iOS 13, tvOS 13, *)
public extension EdgeInsets {
    static let zero = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
}

@available(watchOS 6.0, iOS 13, tvOS 13, *)
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
@available(watchOS 6.0, iOS 13, tvOS 13, *)
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
@available(watchOS 6.0, iOS 13, tvOS 13, *)
public extension View {
    /// Applies the given transform.  If using a branching call, both views must be the identical type or use `AnyView(erasing: VIEWCODE)` or a `Group { }` wrapper..
    /// - Parameters:
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: The modified `View`.
    @ViewBuilder func closure<Content: View>(transform: (Self) -> Content) -> some View {
        transform(self)
    }
}

@available(macOS 12, watchOS 8.0, iOS 15, tvOS 15, *)
public struct ClosureTestView: View {
    public init() {}
    public var body: some View {
        VStack {
            Text("Test for availability")
            Text("conditional inclusion")
                .closure { content in
                    if #available(iOS 999, watchOS 888, *) {
                        AnyView(erasing: content.padding().background(.red).border(.yellow, width: 4))
                    } else {
                        AnyView(erasing: content.padding().background(.blue))
                    }
                }
        }
    }
}

@available(macOS 12, watchOS 8.0, iOS 15, tvOS 15, *)
#Preview("Closure Test") {
    ClosureTestView()
}


// MARK: - For sliders with Ints (and other binding conversions)
/// https://stackoverflow.com/questions/65736518/how-do-i-create-a-slider-in-swiftui-for-an-int-type-property
/// Slider(value: .convert(from: $count), in: 1...8, step: 1)
@available(watchOS 6.0, iOS 13, tvOS 13, *)
public extension Binding {
    static func convert<TInt, TFloat>(from intBinding: Binding<TInt>) -> Binding<TFloat>
        where TInt:   BinaryInteger, TFloat: BinaryFloatingPoint {
            
        Binding<TFloat> (
            get: { TFloat(intBinding.wrappedValue) },
            set: { intBinding.wrappedValue = TInt($0) }
        )
    }
    
    static func convert<TFloat, TInt>(from floatBinding: Binding<TFloat>) -> Binding<TInt>
        where TFloat: BinaryFloatingPoint, TInt:   BinaryInteger {
            
        Binding<TInt> (
            get: { TInt(floatBinding.wrappedValue) },
            set: { floatBinding.wrappedValue = TFloat($0) }
        )
    }
}

@available(macOS 12, watchOS 8.0, iOS 15, tvOS 15, *)
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
@available(macOS 12, watchOS 8, iOS 15, tvOS 15, *)
#Preview("Convert Test") {
    ConvertTestView()
}

// Support fill and stroke
@available(watchOS 6.0, iOS 13, tvOS 13, *)
public extension Shape {
    func fill<Fill: ShapeStyle, Stroke: ShapeStyle>(_ fillStyle: Fill, strokeBorder strokeStyle: Stroke, lineWidth: Double = 1) -> some View {
        self
            .stroke(strokeStyle, lineWidth: lineWidth)
            .background(self.fill(fillStyle))
    }
}

// TODO: is the below necessary??
/*
@available(watchOS 6.0, iOS 13, tvOS 13, *)
public extension InsettableShape {
    func fill<Fill: ShapeStyle, Stroke: ShapeStyle>(_ fillStyle: Fill, strokeBorder strokeStyle: Stroke, lineWidth: Double = 1) -> some View {
        self
            .strokeBorder(strokeStyle, lineWidth: lineWidth)
            .background(self.fill(fillStyle))
    }
}

// TODO: Deprecate this in favor of above??
@available(watchOS 6.0, iOS 13, tvOS 13, *)
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
        if #available(iOS 17.0, macOS 14.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, *) {
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
@available(iOS 15, macOS 12, watchOS 8, tvOS 15, *)
#Preview("Fill & Stroke") {
    VStack {
        Circle()
            .fill(.green, strokeBorder: .blue, lineWidth: 20)
        RoundedRectangle(cornerRadius: 25)
            .fill(.tertiary, strokeBorder: .tint, lineWidth: 5)
    }.padding()
}
@available(iOS 13, watchOS 6.0, tvOS 13, *)
#Preview("Fill and Stroke") {
    VStack {
        Circle()
            .fillAndStroke(.green, .blue, lineWidth: 3)
        RoundedRectangle(cornerRadius: 10)
            .fillAndStroke(.red, .orange, lineWidth: 5)
    }
}
 */
@available(iOS 15, macOS 12, watchOS 6.0, tvOS 15, *)
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

@available(iOS 15, macOS 12, watchOS 6.0, tvOS 15, *)
#Preview("Fill & Stroke") {
    FillAndStrokeTest()
}


// MARK: - Material
@available(macOS 12, watchOS 8, iOS 15, tvOS 15, *)
public extension View {
    func backgroundMaterial() -> some View {
        self
            .padding()
            .background {
                if #available(watchOS 10.0, *) {
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

@available(macOS 12, watchOS 8, iOS 15, tvOS 15, *)
public struct MaterialTestView: View {
    public init() {}
    public var body: some View {
        ZStack {
            Color.clear
            Text("Test Material View")
                .backgroundMaterial()
        }.background(.conicGradient(colors: [.red, .green, .blue], center: .center))
    }
}

@available(macOS 12, watchOS 8, iOS 15, tvOS 15, *)
#Preview("Material Test") {
    MaterialTestView()
}

// MARK: - Wrappers
@available(watchOS 7.0, iOS 13, tvOS 13, *)
public extension View {
    @MainActor
    func navigationWrapper() -> some View {
        NavigationStack { // possibly BackportNavigationStack if there is a conflict
            self
        }
    }
}

@available(watchOS 6.0, iOS 13, tvOS 13, *)
public extension View {
    func scrollWrapper() -> some View {
        ScrollView {
            self
        }
    }
}

#endif
