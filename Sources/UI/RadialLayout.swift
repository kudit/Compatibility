#if canImport(SwiftUI)
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

@available(iOS 13, tvOS 13, watchOS 6, *)
public struct RadialStack<Content:View>: View {
    public var content: () -> Content
    public init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }
    public var body: some View {
        if #available(macOS 13.0, iOS 16.0, tvOS 20.0, watchOS 9.0, *) {
            RadialLayout {
                content()
            }
        } else {
            ZStack {
                content()
            }
        }
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 20.0, watchOS 9.0, *)
public struct RadialLayout: Layout {
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let radius = bounds.width / 3.0
        let angle = Angle.degrees(360.0 / Double(subviews.count)).radians
        // Place subviews
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

@available(macOS 13.0, iOS 16.0, tvOS 20.0, watchOS 9.0, *)
#Preview("Radial") {
    RadialLayout {
        ForEach(0 ..< 24) { item in
            Circle()
                .fill([Color].rainbow[nth: item])
                .frame(width: 64)
                .overlay(Image(systemName: "calendar")
                    .foregroundColor(.white)
                )
        }
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 20.0, watchOS 9.0, *)
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

#endif
