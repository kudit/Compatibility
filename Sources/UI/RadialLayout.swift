#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation) && !(os(WASM) || os(WASI))

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
        if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
            _RadialLayout {
                content
            }
        } else {
            _VariadicView.Tree(RadialLayoutBackportRoot()) {
                content
            }
        }
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct RadialLayoutBackportRoot: _VariadicView_MultiViewRoot {
    @ViewBuilder
    func body(children: _VariadicView.Children) -> some View {
        GeometryReader { geometry in
            let bounds = geometry.frame(in: .local)
            let count = max(children.count, 1)
            let radius = min(bounds.width, bounds.height) / 3.0
            let angle = Angle.degrees(360.0 / Double(count)).radians

            ZStack {
                ForEach(Array(children.enumerated()), id: \.offset) { index, child in
                    let point = radialPoint(in: bounds, radius: radius, angle: angle, index: index)
                    child
                        .position(point)
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
}

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
private struct _RadialLayout: Layout {
    init() {}

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }
        // Place subviews

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let radius = min(bounds.width, bounds.height) / 3.0
        let angle = Angle.degrees(360.0 / Double(max(subviews.count, 1))).radians
        for (index, subview) in subviews.enumerated() {
            // Position
            var point = CGPoint(x: 0, y: -radius).applying(CGAffineTransform(rotationAngle: CGFloat(angle) * CGFloat(index)))
            
            // Center
            point.x += bounds.midX
            point.y += bounds.midY
            
            // Place subviews
            subview.place(at: point, anchor: .center, proposal: .unspecified)
        }
        // TODO: Figure out how to duplicate half of the 0 index subview so in case of overlap it doesn't double overlap at top
        // TODO: Add a mask to the last image with the first image
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
