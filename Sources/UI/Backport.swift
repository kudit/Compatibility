// This has been a godsend!  Backport instructions https://davedelong.com/blog/2021/10/09/simplifying-backwards-compatibility-in-swift/

#if canImport(SwiftUI)
import SwiftUI

public struct Backport<Content> {
    public let content: Content

    public init(_ content: Content) {
        self.content = content
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
public extension View {
    var backport: Backport<Self> { Backport(self) }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
extension Backport where Content == Any {
    /// Usage: Backport.AsyncImage(url: URL)
    @ViewBuilder static func AsyncImage(url: URL?) -> some View {
        if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
            if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
                SwiftUI.AsyncImage(url: url)
            } else {
                //MyCustomAsyncImage(url: url)
                ProgressView()
            }
        } else {
            Text(url?.lastPathComponent ?? "?")
        }
    }
}

// MARK: - Backport View compatibility functions
@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {
    // MARK: - .onChange
    
    /// Adds a modifier for this view that fires an action when a specific
    /// value changes.
    ///
    /// You can use `onChange` to trigger a side effect as the result of a
    /// value changing, such as an `Environment` key or a `Binding`.
    ///
    /// The system may call the action closure on the main actor, so avoid
    /// long-running tasks in the closure. If you need to perform such tasks,
    /// detach an asynchronous background task.
    ///
    /// When the value changes, the new version of the closure will be called,
    /// so any captured values will have their values from the time that the
    /// observed value has its new value. In the following code example,
    /// `PlayerView` calls into its model when `playState` changes model.
    ///
    ///     struct PlayerView: View {
    ///         var episode: Episode
    ///         @State private var playState: PlayState = .paused
    ///
    ///         var body: some View {
    ///             VStack {
    ///                 Text(episode.title)
    ///                 Text(episode.showTitle)
    ///                 PlayButton(playState: $playState)
    ///             }
    ///             .onChange(of: playState) {
    ///                 model.playStateDidChange(state: playState)
    ///             }
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - value: The value to check against when determining whether
    ///     to run the closure.
    ///   - initial: Whether the action should be run when this view initially
    ///     appears.
    ///   - action: A closure to run when the value changes.
    ///
    /// - Returns: A view that fires an action when the specified value changes.
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
    func onChange<V>(
        of value: V,
        initial: Bool = false,
        _ action: @escaping () -> Void
    ) -> some View where V : Equatable {
        onChange(of: value, initial: initial) { _,_ in
            action()
        }
    }

    /// Adds a modifier for this view that fires an action when a specific
    /// value changes.
    ///
    /// You can use `onChange` to trigger a side effect as the result of a
    /// value changing, such as an `Environment` key or a `Binding`.
    ///
    /// The system may call the action closure on the main actor, so avoid
    /// long-running tasks in the closure. If you need to perform such tasks,
    /// detach an asynchronous background task.
    ///
    /// When the value changes, the new version of the closure will be called,
    /// so any captured values will have their values from the time that the
    /// observed value has its new value. The old and new observed values are
    /// passed into the closure. In the following code example, `PlayerView`
    /// passes both the old and new values to the model.
    ///
    ///     struct PlayerView: View {
    ///         var episode: Episode
    ///         @State private var playState: PlayState = .paused
    ///
    ///         var body: some View {
    ///             VStack {
    ///                 Text(episode.title)
    ///                 Text(episode.showTitle)
    ///                 PlayButton(playState: $playState)
    ///             }
    ///             .onChange(of: playState) { oldState, newState in
    ///                 model.playStateDidChange(from: oldState, to: newState)
    ///             }
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - value: The value to check against when determining whether
    ///     to run the closure.
    ///   - initial: Whether the action should be run when this view initially
    ///     appears.
    ///   - action: A closure to run when the value changes.
    ///   - oldValue: The old value that failed the comparison check (or the
    ///     initial value when requested).
    ///   - newValue: The new value that failed the comparison check.
    ///
    /// - Returns: A view that fires an action when the specified value changes.
    @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
    func onChange<V>(
        of value: V,
        initial: Bool = false,
        _ action: @escaping (_ oldValue: V, _ newValue: V) -> Void
    ) -> some View where V : Equatable {
        Group {
            if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
                content.onChange(of: value, initial: initial) { oldState, newState in
                    action(oldState, newState)
                }
            } else {
                content.onChange(of: value) { newState in
                    action(value, newState) // in the closure, `value` will be the old value.
                }
                .onAppear {
                    if initial {
                        action(value, value)
                    }
                }
            }
        }
    }
    /*
     try this for iOS 13??
     .onReceive(Just(value)) {
       }

     */
    
    
    // MARK: - Background/foreground/overlay and styling
    func backgroundStyle<S>(_ style: S) -> some View where S : ShapeStyle {
        Group {
            if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
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
            if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
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
            if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
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
            if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
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
            if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
                content.ignoresSafeArea(regions.convert, edges: edges)
            } else {
                // Fallback on earlier versions
                content
            }
        }
    }
    func background(_ color: Color) -> some View {
        background { color }
    }
    enum SafeAreaRegions: Sendable {
        case all, container, keyboard
        
        @available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
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
    
    enum Visibility : Hashable, CaseIterable {

        /// The element may be visible or hidden depending on the policies of the
        /// component accepting the visibility configuration.
        ///
        /// For example, some components employ different automatic behavior
        /// depending on factors including the platform, the surrounding container,
        /// user settings, etc.
        case automatic

        /// The element may be visible.
        ///
        /// Some APIs may use this value to represent a hint or preference, rather
        /// than a mandatory assertion. For example, setting list row separator
        /// visibility to `visible` using the
        /// ``View/listRowSeparator(_:edges:)`` modifier may not always
        /// result in any visible separators, especially for list styles that do not
        /// include separators as part of their design.
        case visible

        /// The element may be hidden.
        ///
        /// Some APIs may use this value to represent a hint or preference, rather
        /// than a mandatory assertion. For example, setting confirmation dialog
        /// title visibility to `hidden` using the
        /// ``View/confirmationDialog(_:isPresented:titleVisibility:actions:)``
        /// modifier may not always hide the dialog title, which is required on
        /// some platforms.
        case hidden

        @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
        var swiftuiValue: SwiftUI.Visibility {
            switch self {
            case .automatic: return .automatic
            case .visible: return .visible
            case .hidden: return .hidden
            }
        }
    }

    /// Specifies the visibility of the background for scrollable views within
    /// this view.
    ///
    /// The following example hides the standard system background of the List.
    ///
    ///     List {
    ///         Text("One")
    ///         Text("Two")
    ///         Text("Three")
    ///     }
    ///     .scrollContentBackground(.hidden)
    ///
    /// On macOS 15.0 and later, the visibility of the scroll background helps
    /// achieve the seamless window/titlebar appearance for scroll views that
    /// fill the window's content view, or a pane's full width and height.
    /// `List` and `Form` have the seamless appearance by default, configurable
    /// by hiding the scroll background. `ScrollView` can become seamless by
    /// making the background visible.
    ///
    /// - Parameters:
    ///    - visibility: the visibility to use for the background.
    nonisolated func scrollContentBackground(_ visibility: Visibility) -> some View {
#if os(tvOS)
        content // this is specifically unavailable on tvOS
#else
        Group {
            if #available(iOS 16, macOS 13, watchOS 9, *) {
                content.scrollContentBackground(visibility.swiftuiValue)
            } else {
                // Fallback on earlier versions
                content // ignore
            }
        }
#endif
    }
    
    
    /// Adds the provided insets into the safe area of this view.
    ///
    /// Use this modifier when you would like to add a fixed amount
    /// of space to the safe area a view sees.
    ///
    ///     ScrollView(.horizontal) {
    ///         HStack(spacing: 10.0) {
    ///             ForEach(items) { item in
    ///                 ItemView(item)
    ///             }
    ///         }
    ///     }
    ///     .safeAreaPadding(.horizontal, 20.0)
    ///
    /// See the ``View/safeAreaInset(edge:alignment:spacing:content)``
    /// modifier for adding to the safe area based on the size of a
    /// view.
    func safeAreaPadding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View {
        Group {
            if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
                content.safeAreaPadding(edges, length)
            } else {
                // Fallback on earlier versions
                content // ignore
            }
        }
    }

    
    
    /// Configures the ``fileExporter``, ``fileImporter``, or ``fileMover`` to
    /// open with the specified default directory.
    ///
    /// - Parameter defaultDirectory: The directory to show when
    ///   the system file dialog launches. If the given file dialog has
    ///   a `fileDialogCustomizationID` if stores the user-chosen directory and subsequently
    ///   opens with it, ignoring the default value provided in this modifier.
    func fileDialogDefaultDirectory(_ defaultDirectory: URL?) -> some View {
#if os(tvOS) || os(watchOS)
        content // do nothing - does not apply in tvOS or watchOS
#else
        Group {
            if #available(iOS 17, macOS 14, *) {
                content.fileDialogDefaultDirectory(defaultDirectory)
            } else {
                content
            }
        }
#endif
    }
}

// MARK: Presentation Detents
@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {
    enum BackportPresentationDetent: Sendable {
        case large, medium
        
        @available(iOS 16, macOS 13, tvOS 16, watchOS 9,  *)
        var converted: PresentationDetent {
            switch self {
            case .large:
                return .large
            case .medium:
                return .medium
            }
        }
    }
    
    @available(iOS 16, macOS 13, tvOS 16, watchOS 9,  *)
    private func convert(_ detents: Set<BackportPresentationDetent>) -> Set<PresentationDetent> {
        return Set(detents.map { $0.converted })
    }
    
    func presentationDetents(_ detents: Set<BackportPresentationDetent>) -> some View {
        Group {
            if #available(iOS 16, macOS 13, tvOS 16, watchOS 9,  *) {
                content.presentationDetents(convert(detents))
            } else {
                // Fallback on earlier versions
                content // do nothing
            }
        }
    }
}

// MARK: scrollClipDisabled()
@available(iOS 13, tvOS 13, watchOS 6, *)
extension Backport where Content: View {
    /// Sets whether a scroll view clips its content to its bounds.
    ///
    /// By default, a scroll view clips its content to its bounds, but you can
    /// disable that behavior by using this modifier. For example, if the views
    /// inside the scroll view have shadows that extend beyond the bounds of the
    /// scroll view, you can use this modifier to avoid clipping the shadows:
    ///
    ///     struct ContentView: View {
    ///         var disabled: Bool
    ///         let colors: [Color] = [.red, .green, .blue, .mint, .teal]
    ///
    ///         var body: some View {
    ///             ScrollView(.horizontal) {
    ///                 HStack(spacing: 20) {
    ///                     ForEach(colors, id: \.self) { color in
    ///                         Rectangle()
    ///                             .frame(width: 100, height: 100)
    ///                             .foregroundStyle(color)
    ///                             .shadow(color: .primary, radius: 20)
    ///                     }
    ///                 }
    ///             }
    ///             .scrollClipDisabled(disabled)
    ///         }
    ///     }
    ///
    /// The scroll view in the above example clips when the
    /// content view's `disabled` input is `false`, as it does
    /// if you omit the modifier, but not when the input is `true`:
    ///
    /// @TabNavigator {
    ///     @Tab("True") {
    ///         ![A horizontal row of uniformly sized, evenly spaced, vertically aligned squares inside a bounding box that's about twice the height of the squares, and almost four times the width. From left to right, three squares appear in full, while only the first quarter of a fourth square appears at the far right. All the squares have shadows that fade away before reaching the top or the bottom of the bounding box.](View-scrollClipDisabled-1-iOS)
    ///     }
    ///     @Tab("False") {
    ///         ![A horizontal row of uniformly sized, evenly spaced, vertically aligned squares inside a bounding box that's about twice the height of the squares, and almost four times the width. From left to right, three squares appear in full, while only the first quarter of a fourth square appears at the far right. All the squares have shadows that are visible in between squares, but clipped at the top and bottom of the squares.](View-scrollClipDisabled-2-iOS)
    ///     }
    /// }
    ///
    /// While you might want to avoid clipping parts of views that exceed the
    /// bounds of the scroll view, like the shadows in the above example, you
    /// typically still want the scroll view to clip at some point.
    /// Create custom clipping by using the ``View/clipShape(_:style:)``
    /// modifier to add a different clip shape. The following code disables
    /// the default clipping and then adds rectangular clipping that exceeds
    /// the bounds of the scroll view by the default padding amount:
    ///
    ///     ScrollView(.horizontal) {
    ///         // ...
    ///     }
    ///     .scrollClipDisabled()
    ///     .padding()
    ///     .clipShape(Rectangle())
    ///
    /// - Parameter disabled: A Boolean value that specifies whether to disable
    ///   scroll view clipping.
    ///
    /// - Returns: A view that disables or enables scroll view clipping.
    public func scrollClipDisabled(_ disabled: Bool = true) -> some View {
        Group {
            if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
                content.scrollClipDisabled(disabled)
            } else {
                // Fallback on earlier versions
                content
            }
        }
    }
}


// MARK: Navigation Title
@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {
    //TODO: find a way to better consolidate code?  Possibly a protocol?)
    func navigationTitle(_ title: Text) -> some View {
        Group {
            if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
                content.navigationTitle(title)
            } else {
                // Fallback on earlier versions
                #if !os(macOS) // macOS 10.5 doesn't support this
                    content.navigationBarTitle(title)
                #else
                    content
                #endif
            }
        }
    }

    func navigationTitle(_ titleKey: LocalizedStringKey) -> some View {
        Group {
            if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
                content.navigationTitle(titleKey)
            } else {
                // Fallback on earlier versions
                #if !os(macOS) // macOS 10.5 doesn't support this
                    content.navigationBarTitle(titleKey)
                #else
                    content
                #endif
            }
        }
    }

    func navigationTitle<S>(_ title: S) -> some View where S : StringProtocol {
        Group {
            if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
                content.navigationTitle(title)
            } else {
                // Fallback on earlier versions
                #if !os(macOS) // macOS 10.5 doesn't support this
                    content.navigationBarTitle(title)
                #else
                    content
                #endif
            }
        }
    }

//    func navigationTitle(_ title: Binding<String>) -> some View {
//        Group {
//            if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
//                content.navigationTitle(title)
//            } else {
//                // Fallback on earlier versions
//                #if !os(macOS) // macOS 10.5 doesn't support this
//                content.navigationBarTitle(title.wrappedValue)
//                #else
//                    content
//                #endif
//            }
//        }
//    }

    // ONLY AVAILABLE IN WATCHOS 7
//    func navigationTitle<V>(@ViewBuilder _ title: () -> V) -> some View where V : View {
}

// MARK: - Missing Styles

// MARK: Segmented PickerStyle
#if os(watchOS)
@available(watchOS 6, *)
public extension PickerStyle where Self == DefaultPickerStyle {
    // can't just name segmented because marked as explicitly unavailable
    static var segmentedBackport: DefaultPickerStyle {
        return .automatic
    }
}
#else
@available(iOS 13, tvOS 13, *)
public extension PickerStyle where Self == SegmentedPickerStyle {
    // can't just name segmented because marked as explicitly unavailable
    static var segmentedBackport: SegmentedPickerStyle {
        return .segmented
    }
}
#endif

// MARK: TabView
@available(iOS 13, tvOS 13, watchOS 6, *)
extension Backport where Content == Any {
    /// Usage: Backport.AsyncImage(url: URL)
    @ViewBuilder static func TabView<C: View>(@ViewBuilder content: () -> C) -> some View {
        if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
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
        @available(iOS 14, tvOS 14, watchOS 7, *)
        public var converted: PageTabViewStyle.IndexDisplayMode {
            switch self {
            case .always:
                if #available(watchOS 8, *) {
                    return .always
                } else {
                    // Fallback on earlier versions
                    return .automatic
                }
            case .automatic:
                return .automatic
            case .never:
                if #available(watchOS 8, *) {
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
//        @available(watchOS 10, *)
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
@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {
    /// Sets the style for the tab view within the current environment.
    ///
    /// - Parameter style: The style to apply to this tab view.
    @ViewBuilder func tabViewStyle(_ style: BackportTabViewStyle) -> some View {
        Group {
            #if os(macOS)
                content
            #else
            if #available(iOS 14, tvOS 14, watchOS 7, *) {
                switch style {
                case .automatic:
                    content
                case .page:
                    content.tabViewStyle(.page)
//                case .pageIndex(let backportIndexDisplayMode):
//                    content//.tabViewStyle(.page(backportIndexDisplayMode.converted))
//                case .verticalPage: // only supported on watchOS
//                    //if #unavailable(watchOS 10) { // doesn't really work
//                    if availables
//                        // Fallback on earlier versions
//                        content.tabViewStyle(.page)
//                    } else {
//                        content.tabViewStyle(.verticalPage)
//                    }
//                case .verticalPageTransition(let backportTransitionStyle):
//                    if #available(watchOS 10, *) {
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

// https://stackoverflow.com/questions/78472655/swiftui-tabview-safe-area
// Apparently this doesn't work easily.  May need to custom develop a PageView.
@available(iOS 13, tvOS 13, watchOS 7, *)
#Preview("Page Backgrounds") {
    TabView {
        Color.red
        Color.green
        Color.blue
    }.backport.tabViewStyle(.page)
}
//
//
//#if os(macOS) && !targetEnvironment(macCatalyst)
//@available(macOS 11, *)
//public extension TabViewStyle where Self == DefaultTabViewStyle {
//    // can't just name segmented because marked as explicitly unavailable
//    static var pageBackport: DefaultTabViewStyle {
//        return .automatic
//    }
//}
//#else
//@available(watchOS 7, tvOS 14, *)
//public extension TabViewStyle where Self == PageTabViewStyle {
//    // can't just name segmented because marked as explicitly unavailable
//    static var pageBackport: PageTabViewStyle {
//        return .page
//    }
//}
//#endif


// MARK: - Container Views & Backport Navigation Stack
// https://www.swiftbysundell.com/tips/creating-custom-swiftui-container-views/
/**
Example implementation of a ContainerView:
 
```
 struct Carousel<Content: View>: ContainerView {
     var content: () -> Content
     // init automatically synthesized
     var body: some View {
         ScrollView(.horizontal) {
             HStack(content: content).padding()
         }
     }
 }
```
 */
@available(iOS 13, tvOS 13, watchOS 6, *)
public protocol ContainerView: View {
    associatedtype Content
    init(content: @escaping () -> Content)
}
@available(iOS 13, tvOS 13, watchOS 6, *)
public extension ContainerView {
    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.init(content: content)
    }
}

// Try just re-definiing NavigationStack here and in this, do the check and show the appropriate SwiftUI implementation if that makes sense.
@available(iOS 13, tvOS 13, watchOS 7, *)
@MainActor
public struct NavigationStack<Root: View>: View {
    var root: () -> Root

    @MainActor
    public init(@ViewBuilder root: @escaping () -> Root) {
        self.root = root
    }

    public var body: some View {
        Group {
            if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
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


@available(iOS 13, tvOS 13, watchOS 6, *)
#Preview("Page Tabs") {
    Backport.TabView {
        Color.red
        Color.green
        Color.blue
    }.backport.tabViewStyle(.page)
}
@available(iOS 13, tvOS 13, watchOS 6, *)
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
