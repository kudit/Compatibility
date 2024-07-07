// This has been a godsend! https://davedelong.com/blog/2021/10/09/simplifying-backwards-compatibility-in-swift/

#if canImport(SwiftUI)
import SwiftUI

public struct Backport<Content> {
    public let content: Content

    public init(_ content: Content) {
        self.content = content
    }
}

public extension View {
    var backport: Backport<Self> { Backport(self) }
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
public extension Backport where Content: View {
    func onChange<V>(
        of value: V,
        perform action: @escaping () -> Void
    ) -> some View where V : Equatable {
        Group {
            if #available(iOS 17.0, macOS 14.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
                content.onChange(of: value) {
                    action()
                }
            } else {
                content.onChange(of: value) { _ in
                    action()
                }
            }
        }
    }
    func backgroundStyle(_ style: some ShapeStyle) -> some View {
        Group {
            if #available(watchOS 9.0, tvOS 16.0, macOS 13.0, iOS 16.0, *) {
                content.backgroundStyle(style)
            } else {
                // Fallback on earlier versions
                if let color = style as? Color {
                    content.background(color)
                } else {
                    content // don't apply style if watchOS 6 or 7
                }
            }
        }
    }
}

// MARK: - Missing Styles

// MARK: Segmented PickerStyle
#if os(watchOS)
public extension PickerStyle where Self == DefaultPickerStyle {
    // can't just name segmented because marked as explicitly unavailable
    static var segmentedBackport: DefaultPickerStyle {
        return .automatic
    }
}
#else
public extension PickerStyle where Self == SegmentedPickerStyle {
    // can't just name segmented because marked as explicitly unavailable
    static var segmentedBackport: SegmentedPickerStyle {
        return .segmented
    }
}
#endif

// MARK: Page TabViewStyle
#if os(macOS) && !targetEnvironment(macCatalyst)
@available(macOS 11.0, *)
public extension TabViewStyle where Self == DefaultTabViewStyle {
    // can't just name segmented because marked as explicitly unavailable
    static var pageBackport: DefaultTabViewStyle {
        return .automatic
    }
}
#else
@available(watchOS 7.0, *)
public extension TabViewStyle where Self == PageTabViewStyle {
    // can't just name segmented because marked as explicitly unavailable
    static var pageBackport: PageTabViewStyle {
        return .page
    }
}
#endif


// MARK: - Container Views & Backport Navigation Stack
public protocol ContainerView: View {
    associatedtype Content
    init(content: @escaping () -> Content)
}
public extension ContainerView {
    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.init(content: content)
    }
}

// Try just re-definiing NavigationStack here and in this, do the check and show the appropriate SwiftUI implementation if that makes sense.
@MainActor
@available(watchOS 7.0, *)
public struct NavigationStack<Root: View>: View {
    var root: () -> Root

    @MainActor
    public init(@ViewBuilder root: @escaping () -> Root) {
        self.root = root
    }

    public var body: some View {
        Group {
            if #available(iOS 16, macOS 13, macCatalyst 16, tvOS 16, watchOS 9, visionOS 1, *) {
                SwiftUI.NavigationStack {
                    root()
                }
            } else {
                // Fallback on earlier versions
                NavigationView {
                    root()
                }
#if !os(macOS)
                .navigationViewStyle(.stack)
#endif
            }
        }
#if os(macOS)
        // default to the parent window size on macOS
        .frame(idealWidth: NSApp.keyWindow?.contentView?.bounds.width ?? 500, idealHeight: NSApp.keyWindow?.contentView?.bounds.height ?? 500)
#endif
    }
}

#endif
