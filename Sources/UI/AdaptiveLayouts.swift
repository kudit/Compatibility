//
//  AdaptiveLayouts.swift
//  Compatibility
//
//  Created by Ben Ku on 7/26/25.
//

#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation)

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
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct AdaptiveLayout<PContent, LContent>: View where PContent: View, LContent: View {
    let orientation: AdaptiveOrientation
    let portrait: () -> PContent
    let landscape: () -> LContent

    public init(orientation: AdaptiveOrientation = .adaptive, @ViewBuilder portrait: @escaping () -> PContent, @ViewBuilder landscape: @escaping () -> LContent) {
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
                    landscape()
                } else {
                    portrait()
                }
            }
        }
    }
}

/// Adaptable Stack (uses HStack if the available space is wider than it is tall and VStack otherwise).
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct AStack<Content: View>: View {
    let alignment: Alignment
    let spacing: CGFloat?
    let orientation: Orientation
    /// Content will be provided horizontal = true or false depending on the chosen alignment
    /// Stores the builder's concrete view type so the stack does not need `AnyView` type erasure.
    let content: (Orientation) -> Content
    
    public typealias Orientation = AdaptiveOrientation

    public enum Alignment {
        case topOrLeading, center, bottomOrTrailing

        var vertical: VerticalAlignment {
            switch self {
            case .topOrLeading: return .top
            case .center: return .center
            case .bottomOrTrailing: return .bottom
            }
        }

        var horizontal: HorizontalAlignment {
            switch self {
            case .topOrLeading: return .leading
            case .center: return .center
            case .bottomOrTrailing: return .trailing
            }
        }
    }

    public init(alignment: Alignment = .center,
         spacing: CGFloat? = nil,
         orientation: Orientation = .adaptive,
         @ViewBuilder content: @escaping (Orientation) -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.orientation = orientation
        // Retain the concrete builder result; `AdaptiveLayout` reconciles the two orientation branches.
        self.content = content
    }

    // if we don't care about the orientation, we can call this without the parameter
    public init(alignment: Alignment = .center,
         spacing: CGFloat? = nil,
         orientation: Orientation = .adaptive,
         @ViewBuilder content: @escaping () -> Content) {
        self.init(alignment: alignment, spacing: spacing, orientation: orientation, content: { _ in content() })
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
}

/// The orientation values shared by `AdaptiveLayout` and `AStack`.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public enum AdaptiveOrientation: CaseIterable, Sendable {
    case horizontal
    case vertical
    case adaptive

    fileprivate func resolved(for proxy: GeometryProxy) -> AdaptiveOrientation {
            // `.adaptive` preserves the original width-vs-height behavior while the concrete
            // cases give callers a stable layout when the surrounding view already knows best.
            if self == .adaptive {
                return proxy.size.width > proxy.size.height ? .horizontal : .vertical
            }
            return self
        }
}

/// Shows the adaptive stack and layout behaviors used by the preview and demo application.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct AdaptiveLayoutsShowcaseView: View {
    public init() {}

    public var body: some View {
        AStack { orientation in
            ZStack {
                Group {
                    if orientation == .horizontal {
                        Color.yellow
                            .backport.overlay { Text("1h") }
                    } else {
                        Color.yellow.opacity(0.5)
                            .backport.overlay { Text("1v") }
                    }
                }
                HStack {
                    AStack {
                        Color.red
                            .backport.overlay { Text("2.1") }
                        Color.blue
                            .backport.overlay { Text("2.2") }
                    }
                    AStack {
                        Color.red
                            .backport.overlay { Text("3.1") }
                        Color.yellow
                            .backport.overlay { Text("3.2") }
                        Color.green
                            .backport.overlay { Text("3.3") }
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
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("Adpative Layouts") {
    AdaptiveLayoutsShowcaseView()
}

#endif
