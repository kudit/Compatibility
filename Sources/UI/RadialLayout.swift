#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation)

import SwiftUI

// Used in Monetization

// from https://designcode.io/swiftui-handbook-radial-layout

//public protocol ContainerView: View {
//    associatedtype Content
//    init(content: @escaping () -> Content)
//}
//public extension ContainerView {
//    public init(@ViewBuilder _ content: @escaping () -> Content) {
//        self.init(content: content)
//    }
//}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct RadialStack<Content:View>: View {
    public var content: () -> Content
    public init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }
    public var body: some View {
        RadialLayout {
            content()
        }
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct RadialLayout<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        _VariadicView.Tree(RadialLayoutRoot()) {
            content
        }
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct RadialLayoutRoot: _VariadicView_MultiViewRoot {
    @ViewBuilder
    func body(children: _VariadicView.Children) -> some View {
        GeometryReader { geometry in
            let bounds = geometry.frame(in: .local)
            let count = max(children.count, 1)
            let radius = min(bounds.width, bounds.height) / 3.0
            let angle = Angle.degrees(360.0 / Double(count)).radians

            ZStack {
                ForEach(0..<children.count, id: \.self) { index in
                    let point = radialPoint(in: bounds, radius: radius, angle: angle, index: index)
                    ZStack {
                        children[index]
                            .position(point)
                    }
                    .frame(width: bounds.width, height: bounds.height)
                    .mask(radialMask(for: index, children: children, in: bounds, radius: radius, angle: angle))
                }
            }
            .frame(width: bounds.width, height: bounds.height)
        }
    }

    private func radialPoint(in bounds: CGRect, radius: Double, angle: Double, index: Int) -> CGPoint {
        var point = CGPoint(x: 0, y: -radius)
            .applying(CGAffineTransform(rotationAngle: CGFloat(angle) * CGFloat(index)))
        point.x += bounds.midX
        point.y += bounds.midY
        return point
    }

    @ViewBuilder
    private func radialMask(
        for index: Int,
        children: _VariadicView.Children,
        in bounds: CGRect,
        radius: Double,
        angle: Double
    ) -> some View {
        let maskingIndices = wrappedMaskingIndices(for: index, count: children.count)
        if maskingIndices.isEmpty {
            Color.white
        } else {
            ZStack {
                Color.white
                ForEach(maskingIndices, id: \.self) { maskingIndex in
                    children[maskingIndex]
                        .position(radialPoint(in: bounds, radius: radius, angle: angle, index: maskingIndex))
                        .blendMode(.destinationOut)
                }
            }
            .frame(width: bounds.width, height: bounds.height)
            .compositingGroup()
        }
    }

    private func wrappedMaskingIndices(for index: Int, count: Int) -> Range<Int> {
        // Later views past the halfway point can visually wrap over the first views at the seam.
        let visibleIndexCount = max(0, index - count / 2)
        return 0..<visibleIndexCount
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("Radial") {
    RadialLayout {
        ForEach(0 ..< 24) { item in
            Circle()
                .fill([Color].rainbow[nth: item])
                .frame(width: 64)
                .overlay(Backport.Image(systemName: "calendar")
                    .foregroundColor(.white)
                )
        }
    }
    .aspectRatio(contentMode: .fit)
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("Colors") {
    RadialStack {
        Group {
            ForEach([Color].rainbow, id: \.self) { color in
                Circle().fill(color)
            }
        }
        .frame(size: 80)
    }
}

// For #Previews
// Color framework provides better rainbow variable with 7 colors.  This is 6 colors.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension Array where Element == Color {
    /// 6 color ROYGBV(purple for violet)
    static var rainbow: [Color] {
        [.red, .orange, .yellow, .green, .blue, .purple]
    }
}
#endif
