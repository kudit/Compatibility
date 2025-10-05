#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation) && !(os(WASM) || os(WASI))
import SwiftUI
// from https://www.sgade.de/blog/2023-02-28-swift-layout-overlapping-hstack/

// NOTE: Used in Monetization

@available(iOS 13, tvOS 13, watchOS 6, *)
private enum OrientationAlignment {
    case horizontal(VerticalAlignment)
    case vertical(HorizontalAlignment)
    
    var isHorizontal: Bool {
        switch self {
        case .horizontal:
            return true
        case .vertical:
            return false
        }
    }
    var alongKeypath: KeyPath<CGSize,CGFloat> {
        if isHorizontal {
            return \.width
        } else {
            return \.height
        }
    }
    var crossKeypath: KeyPath<CGSize,CGFloat> {
        if isHorizontal {
            return \.height
        } else {
            return \.width
        }
    }
    var alongPointKeypath: WritableKeyPath<CGPoint,CGFloat> {
        if isHorizontal {
            return \.x
        } else {
            return \.y
        }
    }
    var crossPointKeypath: WritableKeyPath<CGPoint,CGFloat> {
        if isHorizontal {
            return \.y
        } else {
            return \.x
        }
    }
    
    enum ExcessHandling {
        case zero
        case split
        case max
    }
    var excessHandling: ExcessHandling {
        switch self {
        case .horizontal(let verticalAlignment):
            switch verticalAlignment {
            case .center:
                return .split
            case .bottom:
                return .max
            default:
                return .zero
            }
        case .vertical(let horizontalAlignment):
            switch horizontalAlignment {
            case .center:
                return .split
            case .trailing:
                return .max
            default:
                return .zero
            }
        }
    }
}
@available(iOS 13, tvOS 13, watchOS 6, *)
private struct OverlappingStackContainer<StackContent:View>: View {
    public var alignment: OrientationAlignment
    public var content: () -> StackContent
    init(alignment: OrientationAlignment, @ViewBuilder content: @escaping () -> StackContent) {
        self.alignment = alignment
        self.content = content
    }
    public var body: some View {
        if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
            OverlappingStack(orientation: alignment) {
                content()
            }
        } else {
            switch alignment {
            case .horizontal(let verticalAlignment):
                HStack(alignment: verticalAlignment) { // TODO: negative spacing?
                    content()
                }
            case .vertical(let horizontalAlignment):
                VStack(alignment: horizontalAlignment) {
                    content()
                }
            }
        }
    }
}
@available(iOS 13, tvOS 13, watchOS 6, *)
public struct OverlappingHStack<Content:View>: View {
    var alignment: VerticalAlignment
    var content: () -> Content
    public init(alignment: VerticalAlignment = .center, @ViewBuilder content: @escaping () -> Content) {
        self.alignment = alignment
        self.content = content
    }
    public var body: some View {
        OverlappingStackContainer(alignment: .horizontal(alignment), content: content)
    }
}
@available(iOS 13, tvOS 13, watchOS 6, *)
public struct OverlappingVStack<Content:View>: View {
    var alignment: HorizontalAlignment = .center
    var content: () -> Content
    public init(alignment: HorizontalAlignment = .center, @ViewBuilder content: @escaping () -> Content) {
        self.alignment = alignment
        self.content = content
    }
    public var body: some View {
        OverlappingStackContainer(alignment: .vertical(alignment), content: content)
    }
}

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
private struct OverlappingStack: Layout {
    var orientation: OrientationAlignment
    
    /// Determine the max a subview can take up along the axis with a minimum of 1 px visible overlap
    func subviewAlongMax(proposal: ProposedViewSize, subviewCount: Int) -> CGFloat? {
        let axisPath = (orientation.isHorizontal ? \ProposedViewSize.width : \.height)
        guard let axisProposal = proposal[keyPath: axisPath] else {
            return nil
        }
        let largest: CGFloat = axisProposal - CGFloat(subviewCount) + 1 // if only one item, no overlap needed
        return max(largest, 0)
    }
    func proposalForSubview(proposal: ProposedViewSize, subviewCount: Int) -> ProposedViewSize {
        return ProposedViewSize(
            width: orientation.isHorizontal ? subviewAlongMax(proposal: proposal, subviewCount: subviewCount) : proposal.width,
            height: orientation.isHorizontal ? proposal.height : subviewAlongMax(proposal: proposal, subviewCount: subviewCount)
        )
    }
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let shrunkenSubviewProposal = proposalForSubview(proposal: proposal, subviewCount: subviews.count)
        let sizes = subviews.map { $0.sizeThatFits(shrunkenSubviewProposal) }
        let crossSize = sizes.reduce(0, { max($0, $1[keyPath: orientation.crossKeypath]) })
        
        if orientation.isHorizontal {
            return CGSize(
                width: proposal.width ?? .infinity,
                height: crossSize
            )
        } else {
            return CGSize(
                width: crossSize,
                height: proposal.height ?? .infinity
            )
        }
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        guard subviews.count > 1 else {
            if subviews.count == 1 {
                subviews.first!.place(at: bounds.origin, anchor: .topLeading, proposal: proposal)
            } // don't do anything if 0 subviews
            return
        }
        let shrunkenSubviewProposal = proposalForSubview(proposal: proposal, subviewCount: subviews.count)
        let sizes = subviews.map { $0.sizeThatFits(shrunkenSubviewProposal) }
        let subviewAlong = sizes.reduce(0, { $0 + $1[keyPath: orientation.alongKeypath] })
        let availableAlong = bounds.size[keyPath: orientation.alongKeypath]
        let availableCross = bounds.size[keyPath: orientation.crossKeypath]
        
        let totalOverlap = subviewAlong - availableAlong
        let overlapBetween = totalOverlap / CGFloat(subviews.count - 1)
        
        // start upper left
        var currentAnchor = bounds.origin
        
        // go through and lay out subviews
        for index in 0..<subviews.count {
            let subview = subviews[index]
            let subviewSize = sizes[index]
            // modify anchor cross position based on the alignment
            let excess = availableCross - subviewSize[keyPath: orientation.crossKeypath]
            let crossOffset: CGFloat
            switch orientation.excessHandling {
            case .zero:
                crossOffset = 0
            case .split:
                crossOffset = excess / 2
            case .max:
                crossOffset = excess
            }
            currentAnchor[keyPath: orientation.crossPointKeypath] = bounds.origin[keyPath: orientation.crossPointKeypath] + crossOffset
            subview.place(
                at: currentAnchor,
                anchor: .topLeading,
                proposal: ProposedViewSize(subviewSize)
            )
            // shift anchor
            currentAnchor[keyPath: orientation.alongPointKeypath] += subviewSize[keyPath: orientation.alongKeypath] - overlapBetween
        }
    }
}

@available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
#Preview("OverlappingHStack") {
    VStack {
        Text("All of these should be the same height.")
        OverlappingHStack {
            ForEach(0..<3) { index in
                Circle().fill([Color].rainbow[nth: index])
            }
        }
        .frame(height: 60)
        OverlappingHStack {
            ForEach(0..<6) { index in
                Circle().fill([Color].rainbow[nth: index])
            }
        }
        .frame(height: 60)
        OverlappingHStack(alignment: .bottom) {
            ForEach(0..<6) { index in
                Circle().fill([Color].rainbow[nth: index])
            }
            Capsule().fill(.foreground)
                .frame(width: 150, height: 10)
        }
        .frame(height: 60)
        OverlappingHStack {
            ForEach(0..<20) { index in
                Circle().fill([Color].rainbow[nth: index])
            }
        }
        .frame(height: 60)
        HStack {
            OverlappingVStack {
                ForEach(0..<3) { index in
                    Circle().fill([Color].rainbow[nth: index])
                }
            }
            OverlappingVStack {
                ForEach(0..<6) { index in
                    Circle().fill([Color].rainbow[nth: index])
                }
            }
            OverlappingVStack {
                ForEach(0..<12) { index in
                    Circle().fill([Color].rainbow[nth: index])
                }
            }
            OverlappingVStack {
                ForEach(0..<20) { index in
                    Circle().fill([Color].rainbow[nth: index])
                }
            }
        }
        .frame(height: 200)
    }
}
#endif
