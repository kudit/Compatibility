//
//  AdaptiveLayouts.swift
//  Compatibility
//
//  Created by Ben Ku on 7/26/25.
//

#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation) && !(os(WASM) || os(WASI))

import SwiftUI

/// Display alternate views if the width is wider than the height.
/// Usage:
/// ```swift
/// AdaptiveLayout {
///     MyVerticalView()
/// } landscape: {
///     MyLandscapeView()
/// }
/// ```
@available(iOS 13, tvOS 13, watchOS 6, *)
public struct AdaptiveLayout<PContent, LContent>: View where PContent: View, LContent: View {
    let orientation: AStack.Orientation
    let portrait: () -> PContent
    let landscape: () -> LContent

    public init(orientation: AStack.Orientation = .adaptive, @ViewBuilder portrait: @escaping () -> PContent, @ViewBuilder landscape: @escaping () -> LContent) {
        self.orientation = orientation
        self.portrait = portrait
        self.landscape = landscape
    }
    
    public var body: some View {
        switch orientation {
        case .horizontal:
            // Explicit landscape mode avoids GeometryReader so fixed-orientation uses do
            // not unexpectedly expand inside compact parent layouts.
            landscape()
        case .vertical:
            // Explicit portrait mode avoids GeometryReader so fixed-orientation uses do
            // not unexpectedly expand inside compact parent layouts.
            portrait()
        case .adaptive:
            GeometryReader { proxy in
                if orientation.resolved(for: proxy) == .horizontal {
                    // landscape
                    landscape()
                } else {
                    portrait()
                }
            }
        }
    }
}

/// Adaptable Stack (uses HStack if the available space is wider than it is tall and VStack otherwise).
@available(iOS 13, tvOS 13, watchOS 6, *)
public struct AStack: View {
    let alignment: Alignment
    let spacing: CGFloat?
    let orientation: Orientation
    /// Content will be provided horizontal = true or false depending on the chosen alignment
    let content: (Orientation) -> AnyView
    
    public enum Orientation: CaseIterable, Sendable {
        case horizontal
        case vertical
        case adaptive

        fileprivate func resolved(for proxy: GeometryProxy) -> Orientation {
            // `.adaptive` preserves the original width-vs-height behavior while the concrete
            // cases give callers a stable layout when the surrounding view already knows best.
            if self == .adaptive {
                return proxy.size.width > proxy.size.height ? .horizontal : .vertical
            }
            return self
        }
    }
    
    public init<Content: View>(alignment: Alignment = .center,
         spacing: CGFloat? = nil,
         orientation: Orientation = .adaptive,
         @ViewBuilder content: @escaping (Orientation) -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.orientation = orientation
        self.content = { orientation in AnyView(content(orientation)) }
    }
    // if we don't care about the orientation, we can call this without the parameter
    public init<Content: View>(alignment: Alignment = .center,
         spacing: CGFloat? = nil,
                orientation: Orientation = .adaptive,
                @ViewBuilder content: @escaping () -> Content) {
        self.init(alignment: alignment, spacing: spacing, orientation: orientation, content: { _ in content() } )
    }

    public var body: some View {
        AdaptiveLayout(orientation: orientation) {
            VStack(alignment: alignment.horizontal,
                   spacing: spacing) {
                content(.vertical)
            }
        } landscape: {
            HStack(alignment: alignment.vertical,
                   spacing: spacing) {
                content(.horizontal)
            }
        }
    }
    
    public enum Alignment {
        case topOrLeading, center, bottomOrTrailing
        
        var vertical: VerticalAlignment {
            switch self {
            case .topOrLeading:
                return .top
            case .center:
                return .center
            case .bottomOrTrailing:
                return .bottom
            }
        }
        
        var horizontal: HorizontalAlignment {
            switch self {
            case .topOrLeading:
                return .leading
            case .center:
                return .center
            case .bottomOrTrailing:
                return .trailing
            }
        }
    }
}

@available(iOS 15, macOS 12, tvOS 17, watchOS 8, *)
#Preview("Adpative Layouts") {
    AStack { orientation in
        ZStack {
            if orientation == .horizontal {
                Color.yellow
            } else {
                Color.yellow.opacity(0.5)
            }
            HStack {
                AStack {
                    Color.red
                    Color.blue
                }
                AStack {
                    Color.red
                    Color.yellow
                    Color.green
                }
            }.padding()
        }
        ZStack {
            Color.orange
            VStack {
                LinearGradient(colors: .rainbow, startPoint: .leading, endPoint: .trailing)
                LinearGradient(colors: [.blue, .white, .red], startPoint: .leading, endPoint: .trailing)
            }.padding()
        }
    }
}

#endif
