//
//  AdaptiveLayouts.swift
//  Compatibility
//
//  Created by Ben Ku on 7/26/25.
//

#if canImport(SwiftUI) && compiler(>=5.9)

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
    let portrait: () -> PContent
    let landscape: () -> LContent

    public init(@ViewBuilder portrait: @escaping () -> PContent, @ViewBuilder landscape: @escaping () -> LContent) {
        self.portrait = portrait
        self.landscape = landscape
    }
    
    public var body: some View {
        GeometryReader { proxy in
            if proxy.size.width > proxy.size.height {
                // landscape
                landscape()
            } else {
                portrait()
            }
        }
    }
}

/// Adaptable Stack (uses HStack if the available space is wider than it is tall and VStack otherwise).
@available(iOS 13, tvOS 13, watchOS 6, *)
public struct AStack<Content>: View where Content: View {
    let alignment: Alignment
    let spacing: CGFloat?
    let content: () -> Content
    
    public init(alignment: Alignment = .center,
         spacing: CGFloat? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content
    }
    
    public var body: some View {
        AdaptiveLayout {
            VStack(alignment: alignment.horizontal,
                   spacing: spacing,
                   content: content)
        } landscape: {
            HStack(alignment: alignment.vertical,
                   spacing: spacing,
                   content: content)
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
    AStack {
        ZStack {
            Color.yellow
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
