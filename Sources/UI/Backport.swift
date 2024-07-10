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

extension Backport where Content == Any {
    /// Usage: Backport.AsyncImage(url: URL)
    @ViewBuilder static func AsyncImage(url: URL?) -> some View {
        if #available(iOS 15, macOS 12, watchOS 8, tvOS 15, *) {
            SwiftUI.AsyncImage(url: url)
        } else if #available(watchOS 7, macOS 11, tvOS 14, *) {
            //MyCustomAsyncImage(url: url)
            ProgressView()
        } else {
            Text(url?.lastPathComponent ?? "?")
        }
    }
}

// MARK: - Backport View compatibility functions
public extension Backport where Content: View {
    @available(tvOS 14, macOS 11, iOS 14, watchOS 7, *)
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
    func backgroundStyle<S>(_ style: S) -> some View where S : ShapeStyle {
        Group {
            if #available(watchOS 9.0, tvOS 16.0, macOS 13.0, iOS 16.0, *) {
                content.backgroundStyle(style)
            } else {
                // Fallback on earlier versions
                if let color = style as? Color {
                    content.background(color)
                } else {
                    content // don't apply style if watchOS 6 or 7 or older tvOS
                }
            }
        }
    }
    func foregroundStyle<S>(_ style: S) -> some View where S : ShapeStyle {
        Group {
            if #available(watchOS 9.0, tvOS 16.0, macOS 13.0, iOS 16.0, *) {
                content.foregroundStyle(style)
            } else {
                // Fallback on earlier versions
                if let color = style as? Color {
                    content.foregroundColor(color)
                } else {
                    content // don't apply style if watchOS 6 or 7 or older tvOS
                }
            }
        }
    }
    
    func background<V>(alignment: Alignment = .center, @ViewBuilder content: @escaping () -> V) -> some View where V : View {
        Group {
            if #available(tvOS 15.0, macOS 12, watchOS 8, iOS 15, *) {
                self.content.background(alignment: alignment) {
                    content()
                }
            } else {
                // Fallback on earlier versions
                ZStack(alignment: alignment) {
                    self.content
                    content()
                }
            }
        }
    }
    func overlay<V>(alignment: Alignment = .center, @ViewBuilder content: @escaping () -> V) -> some View where V : View {
        Group {
            if #available(tvOS 15.0, macOS 12, watchOS 8, iOS 15, *) {
                self.content.overlay(alignment: alignment) {
                    content()
                }
            } else {
                // Fallback on earlier versions
                ZStack(alignment: alignment) {
                    self.content
                    content()
                }
            }
        }
    }
    func ignoresSafeArea(_ regions: SafeAreaRegions = .all, edges: Edge.Set = .all) -> some View {
        Group {
            if #available(tvOS 14.0, macOS 11, watchOS 7, iOS 14, *) {
                content.ignoresSafeArea(regions.convert, edges: edges)
            } else {
                // Fallback on earlier versions
                content
            }
        }
    }
    func background<V>(_ color: Color) -> some View where V : View {
        background { color }
    }
    enum SafeAreaRegions: Sendable {
        case all, container, keyboard
        
        @available(tvOS 14.0, macOS 11, iOS 14, watchOS 7, *)
        public var convert: SwiftUI.SafeAreaRegions {
            switch self {
            case .all:
                    .all
            case .container:
                    .container
            case .keyboard:
                    .keyboard
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

// MARK: TabView
extension Backport where Content == Any {
    /// Usage: Backport.AsyncImage(url: URL)
    @ViewBuilder static func TabView<C: View>(@ViewBuilder content: () -> C) -> some View {
        if #available(watchOS 7, iOS 14, tvOS 14, macOS 11, *) {
            SwiftUI.TabView(content: content)
        } else {
            VStack(content: content)
        }
    }
}
public enum BackportTabViewStyle: Sendable {
    public enum BackportIndexDisplayMode: Sendable {
        case always, automatic, never
        #if !os(macOS)
        @available(watchOS 7.0, iOS 14, tvOS 14, *)
        public var converted: PageTabViewStyle.IndexDisplayMode {
            switch self {
            case .always:
                if #available(watchOS 8.0, *) {
                    return .always
                } else {
                    // Fallback on earlier versions
                    return .automatic
                }
            case .automatic:
                return .automatic
            case .never:
                if #available(watchOS 8.0, *) {
                    return .never
                } else {
                    // Fallback on earlier versions
                    return .automatic
                }
            }
        }
        #endif
    }
//    public enum BackportTransitionStyle: Sendable {
//        /// Automatic transition style
//        case automatic
//
//        /// A transition style that blurs content between each tab
//        case blur
//
//        /// A transition style that has no animation between each tab
//        case identity
//
//        @available(watchOS 10.0, *)
//        @available(iOS, unavailable)
//        @available(macOS, unavailable)
//        @available(tvOS, unavailable)
//        @available(visionOS, unavailable)
//        public var converted: VerticalPageTabViewStyle.TransitionStyle {
//            switch self {
//            case .automatic:
//                return .automatic
//            case .blur:
//                return .blur
//            case .identity:
//                return .identity
//            }
//        }
//    }
    case automatic, page//, verticalPage
    // compound cases (problematic for switch below
//    case pageIndex(BackportIndexDisplayMode), verticalPageTransition(BackportTransitionStyle)
  // 2024 cases
//    case grouped, sidebarAdaptable, tabBarOnly
}
public extension Backport where Content: View {
    /// Sets the style for the tab view within the current environment.
    ///
    /// - Parameter style: The style to apply to this tab view.
    @ViewBuilder func tabViewStyle(_ style: BackportTabViewStyle) -> some View {
        Group {
            #if os(macOS)
                content
            #else
            if #available(watchOS 7.0, tvOS 14, iOS 14, *) {
                switch style {
                case .automatic:
                    content
                case .page:
                    content.tabViewStyle(.page)
//                case .pageIndex(let backportIndexDisplayMode):
//                    content//.tabViewStyle(.page(backportIndexDisplayMode.converted))
//                case .verticalPage: // only supported on watchOS
//                    //if #unavailable(watchOS 10.0) { // doesn't really work
//                    if availables
//                        // Fallback on earlier versions
//                        content.tabViewStyle(.page)
//                    } else {
//                        content.tabViewStyle(.verticalPage)
//                    }
//                case .verticalPageTransition(let backportTransitionStyle):
//                    if #available(watchOS 10.0, *) {
//                        content//.tabViewStyle(.verticalPage(backportTransitionStyle.converted))
//                    } else {
//                        // Fallback on earlier versions
//                        content.tabViewStyle(.page)
//                    }
        //        case .grouped:
        //            if #unavailable(macOS 15) {
        //                // Fallback on alternate versions
        //                return .automatic
        //            } else {
        //                return .grouped
        //            }
        //        case .sidebarAdaptable:
        //            return .sidebarAdaptable
        //        case .tabBarOnly:
        //            return .tabBarOnly
                }
            } else {
                // Fallback on earlier versions
                content
            }
            #endif
        }
    }
}

//
//
//#if os(macOS) && !targetEnvironment(macCatalyst)
//@available(macOS 11.0, *)
//public extension TabViewStyle where Self == DefaultTabViewStyle {
//    // can't just name segmented because marked as explicitly unavailable
//    static var pageBackport: DefaultTabViewStyle {
//        return .automatic
//    }
//}
//#else
//@available(watchOS 7.0, tvOS 14, *)
//public extension TabViewStyle where Self == PageTabViewStyle {
//    // can't just name segmented because marked as explicitly unavailable
//    static var pageBackport: PageTabViewStyle {
//        return .page
//    }
//}
//#endif


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
@available(watchOS 7.0, *)
@MainActor
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


#Preview("Page Tabs") {
    Backport.TabView {
        Color.red
        Color.green
        Color.blue
    }.backport.tabViewStyle(.page)
}
#Preview("Automatic Tabs") {
    Backport.TabView {
        Color.red
        Color.green
        Color.blue
    }.backport.tabViewStyle(.automatic)
}
//#Preview("Vertical Page Tabs") {
//    Backport.TabView {
//        Color.red
//        Color.green
//        Color.blue
//    }.backport.tabViewStyle(.verticalPage)
//}

#endif
