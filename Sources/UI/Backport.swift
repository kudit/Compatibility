// This has been a godsend!  Backport instructions https://davedelong.com/blog/2021/10/09/simplifying-backwards-compatibility-in-swift/

#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation) && !(os(WASM) || os(WASI))
import SwiftUI

@MainActor // for swift6 compliance and since this is SwiftUI, should be @MainActor anyways.
public struct Backport<Content> {
    public let content: Content

    public init(_ content: Content) {
        self.content = content
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
public extension View {
    @MainActor
    var backport: Backport<Self> { Backport(self) }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
extension Backport where Content == Any {
    /// Usage: Backport.AsyncImage(url: URL)
    @ViewBuilder public static func AsyncImage(url: URL?) -> some View {
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

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
extension Backport where Content == Any {
    @ViewBuilder public static func LabeledContent(_ titleKey: String, value: some StringProtocol) -> some View {
        if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
            SwiftUI.LabeledContent(LocalizedStringKey(titleKey), value: value)
        } else {
            HStack {
                Text(titleKey)
                Spacer()
                Text(value)
                    .backport.foregroundStyle(.gray)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}

// MARK: - Backport View compatibility functions
@available(iOS 13, tvOS 13, watchOS 6, *)
@MainActor
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
#if compiler(>=5.9)
                content.onChange(of: value, initial: initial) { oldState, newState in
                    action(oldState, newState)
                }
#else
                // probably never can be executed but just in case
                content.onChange(of: value) { newState in
                    action(value, newState) // in the closure, `value` will be the old value.
                }
                .onAppear {
                    if initial {
                        action(value, value)
                    }
                }
#endif
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
    
    @MainActor
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
                content.ignoresSafeArea(regions.swiftUIValue, edges: edges)
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
        public var swiftUIValue: SwiftUI.SafeAreaRegions {
            switch self {
            case .all:
                return .all
            case .container:
                return .container
            case .keyboard:
                return .keyboard
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
        public var swiftUIValue: SwiftUI.Visibility {
            switch self {
            case .automatic: return .automatic
            case .visible: return .visible
            case .hidden: return .hidden
            }
        }
        
#if canImport(UIKit) && !os(watchOS) && !os(tvOS)
        var legacyColor: UIColor {
            if self == .hidden {
                return .clear
            } else {
                return .systemGroupedBackground
            }
        }
#endif
    }

    /// Sets the preferred visibility of the non-transient system views
    /// overlaying the app.
    ///
    /// Use this modifier to influence the appearance of system overlays
    /// in your app. The behavior varies by platform.
    ///
    /// In iOS, the following example hides every persistent system overlay.
    /// In visionOS 2 and later, the SharePlay Indicator hides if the
    /// scene is shared through SharePlay, or not shared at all.
    /// During screen sharing, the indicator always remains visible.
    /// The Home indicator doesn't appear without specific user intent
    /// when you set visibility to ``hidden``. For a ``WindowGroup``,
    /// the modifier affects the visibility of the window chrome. For an
    /// ``ImmersiveSpace``, it affects the Home indicator.
    ///
    ///     struct ImmersiveView: View {
    ///         var body: some View {
    ///             Text("Maximum immersion")
    ///                 .persistentSystemOverlays(.hidden)
    ///         }
    ///     }
    ///
    /// > Note: You can indicate a preference with this modifier, but the system
    /// might or might not be able to honor that preference.
    ///
    /// Affected non-transient system views can include, but are not limited to:
    /// - The Home indicator.
    /// - The SharePlay indicator.
    /// - The Multitasking Controls button and Picture in Picture on iPad.
    ///
    /// - Parameter visibility: A value that indicates the visibility of the
    /// non-transient system views overlaying the app.
    func persistentSystemOverlays(_ visibility: Visibility) -> some View {
        Group {
            if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
                content.persistentSystemOverlays(visibility.swiftUIValue)
            } else {
                // Fallback on earlier versions (just ignore since home indicator doesn't exist on touchID devices).
                content
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
    func scrollContentBackground(_ visibility: Visibility) -> some View {
#if os(tvOS)
        content // this is specifically unavailable on tvOS
#else
        Group {
            if #available(iOS 16, macOS 13, watchOS 9, *) {
                content.scrollContentBackground(visibility.swiftUIValue)
            } else {
#if canImport(UIKit) && !os(watchOS) && !os(tvOS)
                // Fallback on earlier versions
                content
                    .onAppear {
                        UITableView.appearance().backgroundColor = visibility.legacyColor
                    }
                    .onDisappear {
                        UITableView.appearance().backgroundColor = .systemGroupedBackground
                    }
#else
                content // ignore
#endif
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

    /// Sets the size for controls within this view.
    ///
    /// Use `controlSize(_:)` to override the system default size for controls
    /// in this view. In this example, a view displays several typical controls
    /// at `.mini`, `.small` and `.regular` sizes.
    ///
    ///     struct ControlSize: View {
    ///         var body: some View {
    ///             VStack {
    ///                 MyControls(label: "Mini")
    ///                     .controlSize(.mini)
    ///                 MyControls(label: "Small")
    ///                     .controlSize(.small)
    ///                 MyControls(label: "Regular")
    ///                     .controlSize(.regular)
    ///             }
    ///             .padding()
    ///             .frame(width: 450)
    ///             .border(Color.gray)
    ///         }
    ///     }
    ///
    ///     struct MyControls: View {
    ///         var label: String
    ///         @State private var value = 3.0
    ///         @State private var selected = 1
    ///         var body: some View {
    ///             HStack {
    ///                 Text(label + ":")
    ///                 Picker("Selection", selection: $selected) {
    ///                     Text("option 1").tag(1)
    ///                     Text("option 2").tag(2)
    ///                     Text("option 3").tag(3)
    ///                 }
    ///                 Slider(value: $value, in: 1...10)
    ///                 Button("OK") { }
    ///             }
    ///         }
    ///     }
    ///
    /// ![A screenshot showing several controls of various
    /// sizes.](SwiftUI-View-controlSize.png)
    ///
    /// - Parameter controlSize: One of the control sizes specified in the
    ///   ``ControlSize`` enumeration.
    func controlSize(_ controlSize: BackportControlSize) -> some View {
        Group {
            #if os(tvOS)
            content
            #else
            if #available(iOS 15, macOS 11, tvOS 15, watchOS 9.0, *) { // supported on macOS 10.5 but 11 required for availability checking...
                content.controlSize(controlSize.controlSize)
            } else {
                // Fallback on earlier versions
                content
            }
            #endif
        }
    }
}

/// The size classes, like regular or small, that you can apply to controls
/// within a view.
public enum BackportControlSize : CaseIterable, Sendable {

    /// A control version that is minimally sized.
    case mini

    /// A control version that is proportionally smaller size for space-constrained views.
    case small

    /// A control version that is the default size.
    case regular

    /// A control version that is prominently sized.
    case large

    /// A control version that is substantially sized. The largest control size.
    /// Resolves to ``ControlSize/large`` on platforms other than visionOS.
    case extraLarge
    
    @available(iOS 15, macOS 10.15, tvOS 15, watchOS 9, *)
    @available(tvOS, unavailable) // apparently this is marked as unavailable??
    var controlSize: ControlSize {
        switch self {
        case .mini: return .mini
        case .small: return .small
        case .regular: return .regular
        case .large:
            if #available(macOS 11, *) {
                return .large
            } else {
                return .regular
            }
        case .extraLarge:
            if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
                return .extraLarge
            } else {
                // Fallback on earlier versions
                return Self.large.controlSize // to handle fallback appropriately
            }
        }
    }
}

#if canImport(WidgetKit)
import WidgetKit
#endif

@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {
    /// Adds the view and all of its subviews to the accented group.
    ///
    /// When the system renders the widget using the
    /// ``WidgetKit/WidgetRenderingMode/accented`` mode, it divides the widget's
    /// view hierarchy into two groups: the accented group and the default
    /// group. It then applies a different color to each group.
    ///
    /// When applying the colors, the system treats the widget's views as if
    /// they were template images. It ignores the view's color --- rendering the
    /// new colors based on the view's alpha channel.
    ///
    /// To control your view's appearance, add the `widgetAccentable(_:)`
    /// modifier to part of your view's hierarchy. If the `accentable` parameter
    /// is `true`, the system adds that view and all of its subviews to the
    /// accent group. It puts all other views in the default group.
    ///
    /// ``` swift
    /// var body: some View {
    ///     VStack {
    ///         Text("MON")
    ///             .font(.caption)
    ///             .widgetAccentable()
    ///         Text("6")
    ///             .font(.title)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// > Important: After you call `widgetAccentable(true)` on a view moving it
    /// into the accented group, calling `widgetAccentable(false)` on its
    /// subviews doesn't move the subviews back into the default group.
    ///
    /// - Parameter accentable: A Boolean value that indicates whether to add
    /// the view and its subviews to the accented group.
    func widgetAccentable(_ accentable: Bool = true) -> some View {
        Group {
#if os(tvOS) || !canImport(WidgetKit)
            content
#else
            if #available(iOS 16, macOS 13, watchOS 9, visionOS 26, *) {
                content.widgetAccentable(accentable)
            } else {
                // Fallback on earlier versions
                content
            }
#endif
        }
    }
}

// MARK: Presentation Detents
@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {
    enum BackportPresentationDetent: Sendable, Hashable {
        case large, medium, fraction(CGFloat)

        @available(iOS 16, macOS 13, tvOS 16, watchOS 9,  *)
        var converted: PresentationDetent {
            switch self {
            case .large:
                return .large
            case .medium:
                return .medium
            case .fraction(let fraction):
                return .fraction(fraction)
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

@available(iOS 13, tvOS 13, watchOS 6, *)
extension Backport where Content: View {
    /// Specifies if the view is focusable.
    ///
    /// - Parameter isFocusable: A Boolean value that indicates whether this
    ///   view is focusable.
    ///
    /// - Returns: A view that sets whether a view is focusable.
    public func focusable(_ isFocusable: Bool = true) -> some View {
        Group {
            if #available(iOS 17, macOS 12, tvOS 15, watchOS 8, *) {
                content.focusable(isFocusable)
            } else {
                content // ignore - okay to do nothing since this is all really just for tvOS anyways and all tvOS supports tvOS 15. (NOTE: the documentation says tvOS 17+ but the actual code has availability tvOS 15)
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

// MARK: - Navigation Destination
@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {

    /// Associates a destination view with a binding that can be used to push
    /// the view onto a ``NavigationStack``.
    ///
    /// In general, favor binding a path to a navigation stack for programmatic
    /// navigation. Add this view modifier to a view inside a ``NavigationStack``
    /// to programmatically push a single view onto the stack. This is useful
    /// for building components that can push an associated view. For example,
    /// you can present a `ColorDetail` view for a particular color:
    ///
    ///     @State private var showDetails = false
    ///     var favoriteColor: Color
    ///
    ///     NavigationStack {
    ///         VStack {
    ///             Circle()
    ///                 .fill(favoriteColor)
    ///             Button("Show details") {
    ///                 showDetails = true
    ///             }
    ///         }
    ///         .navigationDestination(isPresented: $showDetails) {
    ///             ColorDetail(color: favoriteColor)
    ///         }
    ///         .navigationTitle("My Favorite Color")
    ///     }
    ///
    /// Do not put a navigation destination modifier inside a "lazy" container,
    /// like ``List`` or ``LazyVStack``. These containers create child views
    /// only when needed to render on screen. Add the navigation destination
    /// modifier outside these containers so that the navigation stack can
    /// always see the destination.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that indicates whether
    ///     `destination` is currently presented.
    ///   - destination: A view to present.
    func navigationDestination<V: View>(isPresented: Binding<Bool>, @ViewBuilder destination: () -> V) -> some View {
        Group {
            if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
                content.navigationDestination(isPresented: isPresented, destination: destination)
            } else {
                // Fallback on earlier versions (bury in the background)
                ZStack {
                    NavigationLink(isActive: isPresented, destination: destination) { EmptyView() }
                    content
                }
            }
        }
    }
}

// MARK: - TextSelectability
public enum BackportTextSelectability {
    case enabled
    case disabled
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
public extension Backport where Content: View {
    /// Controls whether people can select text within this view.
    ///
    /// People sometimes need to copy useful information from ``Text`` views ---
    /// including error messages, serial numbers, or IP addresses --- so they
    /// can then paste the text into another context. Enable text selection
    /// to let people select text in a platform-appropriate way.
    ///
    /// You can apply this method to an individual text view, or to a
    /// container to make each contained text view selectable. In the following
    /// example, the person using the app can select text that shows the date of
    /// an event or the name or email of any of the event participants:
    ///
    ///     var body: some View {
    ///         VStack {
    ///             Text("Event Invite")
    ///                 .font(.title)
    ///             Text(invite.date.formatted(date: .long, time: .shortened))
    ///                 .textSelection(.enabled)
    ///
    ///             List(invite.recipients) { recipient in
    ///                 VStack (alignment: .leading) {
    ///                     Text(recipient.name)
    ///                     Text(recipient.email)
    ///                         .foregroundStyle(.secondary)
    ///                 }
    ///             }
    ///             .textSelection(.enabled)
    ///         }
    ///         .navigationTitle("New Invitation")
    ///     }
    ///
    /// On macOS, people use the mouse or trackpad to select a range of text,
    /// which they can quickly copy by choosing Edit > Copy, or with the
    /// standard keyboard shortcut.
    ///
    /// ![A macOS window titled New Invitation, with header Event Invite and
    /// the date and time of the event below it. The date --- July 31, 2022 ---
    /// is selected. Below this, a list of invitees by name and
    /// email.](View-textSelection-1)
    ///
    /// On iOS, the person using the app touches and holds on a selectable
    /// `Text` view, which brings up a system menu with menu items appropriate
    /// for the current context. These menu items operate on the entire contents
    /// of the `Text` view; the person can't select a range of text like they
    /// can on macOS.
    ///
    /// ![A portion of an iOS view, with header Event Invite and
    /// the date and time of the event below it. Below the date and time, a
    /// menu shows two items: Copy and Share. Below this, a list of invitees by
    /// name and email.](View-textSelection-2)
    ///
    /// - Note: ``Button`` views don't support text selection.
    /// - Note: This is completely ignored in watchOS and tvOS but is here for simplified code compatibility.
    func textSelection(_ selectability: BackportTextSelectability) -> some View {
        Group {
#if os(watchOS) || os(tvOS)
            content
#else
            switch selectability {
            case .enabled:
                content.textSelection(.enabled)
            case .disabled:
                content.textSelection(.disabled)
            }
#endif
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


#if canImport(_StoreKit_SwiftUI)
import _StoreKit_SwiftUI
#endif

// MARK: - Glass effects
@available(iOS 13, tvOS 13, watchOS 6, *)
public struct Glass : Equatable, Sendable {
    var color: Color?
    var isInteractive: Bool?

    /// The regular variant of glass.
    public static let regular: Glass = Glass()

    /// Returns a copy of the glass with the provided tint color.
    public func tint(_ color: Color?) -> Glass {
        var copy = self
        copy.color = color
        return copy
    }

    /// Returns a copy of the glass configured to be interactive.
    public func interactive(_ isEnabled: Bool = true) -> Glass {
        var copy = self
        copy.isInteractive = isEnabled
        return copy
    }

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (a: Glass, b: Glass) -> Bool {
        return a.color == b.color && a.isInteractive == b.isInteractive
    }
    
#if compiler(>=6.2)
    @available(iOS 26, macOS 26, tvOS 26, watchOS 26, *)
    @available(visionOS, unavailable)
    public var swiftUIValue: SwiftUI.Glass {
        if self == .regular {
            return .regular
        }
        var modern = SwiftUI.Glass.regular
        if let color {
            modern = modern.tint(color)
        }
        if let isInteractive {
            modern = modern.interactive(isInteractive)
        }
        return modern
    }
#endif
}

@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {
    /// Applies a glass effect to this view.
    ///
    /// When you use a glass effect, the platform:
    ///   - Renders a shape anchored behind this view filled with
    ///     the physical glass material
    ///   - Applies the foreground effects of the glass over this view.
    ///
    /// For example, you could add a glass effect to a ``Label``:
    ///
    ///     Label("Flag", systemImage: "flag.fill")
    ///         .padding()
    ///         .glassEffect()
    ///
    /// SwiftUI uses the ``Glass/regular`` variant by default along with
    /// a ``Capsule`` shape.
    ///
    /// SwiftUI anchors the glass to the view's bounds. For the example
    /// above, the physical glass material fills the entirety of the label's
    /// frame, which includes the padding.
    ///
    /// You typically use this modifier with a ``GlassEffectContainer``
    /// to combine multiple glass shapes into a single shape that
    /// can morph shapes into one another.
    func glassEffect(_ glass: Glass = .regular, in shape: some Shape = .capsule) -> some View {
        Group {
#if !os(visionOS)
            if #available(iOS 26, macOS 26, tvOS 26, watchOS 26, *) {
#if compiler(>=6.2)
                content.glassEffect(glass.swiftUIValue, in: shape)
#else
                content.backgroundMaterial()
#endif
            } else {
                content.backgroundMaterial()
            }
#else
            content
#endif
        }
    }
}

// MARK: - Materials
public extension Backport {
    enum MaterialEnum: Sendable {
        /// A material that's somewhat translucent.
        case regular

        /// A material that's more opaque than translucent.
        case thick

        /// A material that's more translucent than opaque.
        case thin

        /// A mostly translucent material.
        case ultraThin

        /// A mostly opaque material.
        case ultraThick

        // For some reason, they have both .regular and .regularMaterial shape styles so include both.
        /// A material that's somewhat translucent.
        case regularMaterial
        
        /// A material that's more opaque than translucent.
        case thickMaterial
        
        /// A material that's more translucent than opaque.
        case thinMaterial
        
        /// A mostly translucent material.
        case ultraThinMaterial
        
        /// A mostly opaque material.
        case ultraThickMaterial
        
        @available(iOS 15, macOS 12, tvOS 15, watchOS 10, *)
        var swiftUIValue: SwiftUI.Material {
            switch self {
            case .regular: return .regular
            case .thick: return .thick
            case .thin: return .thin
            case .ultraThin: return .ultraThin
            case .ultraThick: return .ultraThick
            case .regularMaterial: return .regularMaterial
            case .thickMaterial: return .thickMaterial
            case .thinMaterial: return .thinMaterial
            case .ultraThinMaterial: return .ultraThinMaterial
            case .ultraThickMaterial: return .ultraThickMaterial
            }
        }
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {
    /// Sets the presentation background of the enclosing sheet using a shape
    /// style.
    ///
    /// The following example uses the ``Material/thick`` material as the sheet
    /// background:
    ///
    ///     struct ContentView: View {
    ///         @State private var showSettings = false
    ///
    ///         var body: some View {
    ///             Button("View Settings") {
    ///                 showSettings = true
    ///             }
    ///             .sheet(isPresented: $showSettings) {
    ///                 SettingsView()
    ///                     .presentationBackground(.thickMaterial)
    ///             }
    ///         }
    ///     }
    ///
    /// The `presentationBackground(_:)` modifier differs from the
    /// ``View/background(_:ignoresSafeAreaEdges:)`` modifier in several key
    /// ways. A presentation background:
    ///
    /// * Automatically fills the entire presentation.
    /// * Allows views behind the presentation to show through translucent
    ///   styles.
    ///
    /// - Parameter style: The shape style to use as the presentation
    ///   background.
    func presentationBackground<S>(_ style: S) -> some View where S : ShapeStyle {
        Group {
            if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
                content.presentationBackground(style)
            } else {
                // Fallback on earlier versions
                if let color = style as? Color {
                    content.background(color)
                } else {
                    content // ignore if older and unsupported
                }
            }
        }
    }
    func presentationBackground(_ style: MaterialEnum) -> some View {
        Group {
            if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 10, *) {
                content.presentationBackground(style.swiftUIValue)
            } else {
                // Fallback on earlier versions
                content // ignore if older and unsupported - likely only on watchOS < 10
            }
        }
    }


    /// The criteria that determines when an animation is considered finished.
    enum AnimationCompletionCriteria : Sendable {
        
        /// The animation has logically completed, but may still be in its long
        /// tail.
        ///
        /// If a subsequent change occurs that creates additional animations on
        /// properties with `logicallyComplete` completion callbacks registered,
        /// then those callbacks will fire when the animations from the change that
        /// they were registered with logically complete, ignoring the new
        /// animations.
        case logicallyComplete
        
        /// The entire animation is finished and will now be removed.
        ///
        /// If a subsequent change occurs that creates additional animations on
        /// properties with `removed` completion callbacks registered, then those
        /// callbacks will only fire when *all* of the created animations are
        /// complete.
        case removed
        
#if compiler(>=5.9)
        @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
        var swiftUIValue: SwiftUI.AnimationCompletionCriteria {
            switch self {
            case .logicallyComplete:
                return .logicallyComplete
            case .removed:
                return .removed
            }
        }
#endif
    }
    /// Returns the result of recomputing the view's body with the provided
    /// animation, and runs the completion when all animations are complete.
    ///
    /// This function sets the given ``Animation`` as the ``Transaction/animation``
    /// property of the thread's current ``Transaction`` as well as calling
    /// ``Transaction/addAnimationCompletion`` with the specified completion.
    ///
    /// The completion callback will always be fired exactly one time. If no
    /// animations are created by the changes in `body`, then the callback will be
    /// called immediately after `body`.
    func withAnimation<Result>(_ animation: Animation? = .default, completionCriteria: AnimationCompletionCriteria = .logicallyComplete, duration: TimeInterval = 0.35, _ body: () throws -> Result, completion: @MainActor @Sendable @escaping () -> Void) rethrows -> Result {
#if compiler(>=5.9)
        if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
            return try SwiftUI.withAnimation(animation, completionCriteria: completionCriteria.swiftUIValue, body, completion: completion)
        }
#endif
        // Fallback on earlier versions
        let results = try SwiftUI.withAnimation(animation) {
            try body()
        }
        
        delay(duration) { // This should pull the duration from the animation but this is just for compatibility so we'll hard-code since there's no good way to pull the duration from the animation.
            main { // force back on the main actor since delay doesn't seem to want to have a version to support this
                completion()
            }
        }
        
        return results
    }
    

    enum ProductViewStyle {
        case automatic
        case compact
    }
    /// Sets the style for product views within a view.
    ///
    /// This modifier styles any ``ProductView`` or ``StoreView`` instances within a view.
    func productViewStyle(_ style: Backport.ProductViewStyle) -> some View {
        Group {
            if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
#if os(visionOS) || os(watchOS)
                    content.productViewStyle(.automatic)
#else
                switch style {
                case .automatic:
                    content.productViewStyle(AutomaticProductViewStyle.automatic)
                case .compact:
                    content.productViewStyle(CompactProductViewStyle.compact)
                }
#endif
            } else {
                // Fallback on earlier versions (do nothing)
                content
            }
        }
    }
    
    
    
    /// Presents a modal view that covers as much of the screen as
    /// possible when binding to a Boolean value you provide is true.
    ///
    /// Use this method to show a modal view that covers as much of the screen
    /// as possible. The example below displays a custom view when the user
    /// toggles the value of the `isPresenting` binding:
    ///
    ///     struct FullScreenCoverPresentedOnDismiss: View {
    ///         @State private var isPresenting = false
    ///         var body: some View {
    ///             Button("Present Full-Screen Cover") {
    ///                 isPresenting.toggle()
    ///             }
    ///             .fullScreenCover(isPresented: $isPresenting,
    ///                              onDismiss: didDismiss) {
    ///                 VStack {
    ///                     Text("A full-screen modal view.")
    ///                         .font(.title)
    ///                     Text("Tap to Dismiss")
    ///                 }
    ///                 .onTapGesture {
    ///                     isPresenting.toggle()
    ///                 }
    ///                 .foregroundColor(.white)
    ///                 .frame(maxWidth: .infinity,
    ///                        maxHeight: .infinity)
    ///                 .background(Color.blue)
    ///                 .ignoresSafeArea(edges: .all)
    ///             }
    ///         }
    ///
    ///         func didDismiss() {
    ///             // Handle the dismissing action.
    ///         }
    ///     }
    ///
    /// ![A full-screen modal view with the text A full-screen modal view
    /// and Tap to Dismiss.](SwiftUI-FullScreenCoverIsPresented.png)
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether
    ///     to present the sheet.
    ///   - onDismiss: The closure to execute when dismissing the modal view.
    ///   - content: A closure that returns the content of the modal view.
    func fullScreenCover<CoverContent>(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> CoverContent) -> some View where CoverContent : View {
        Group {
            if #available(iOS 14, macOS 99, tvOS 14, watchOS 7, *) {
#if !os(macOS)
                self.content.fullScreenCover(isPresented: isPresented, onDismiss: onDismiss, content: content)
#endif
            } else {
                // Fallback on earlier versions
                self.content.sheet(isPresented: isPresented, onDismiss: onDismiss, content: content)
            }
        }
    }
}

// MARK: - Toolbar Placement & Status Bar
@available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
public extension ToolbarItemPlacement {
    @MainActor // for swift6 compliance and since this is SwiftUI, should be @MainActor anyways.
    static let bottomBackport: ToolbarItemPlacement = {
#if os(tvOS)
        return .automatic // won't actually show up
#elseif os(macOS)
        return .confirmationAction
#else
        if #available(iOS 1, watchOS 10, *) {
            return .bottomBar
        } else {
            // Fallback on earlier versions
            #if os(watchOS)
            return .automatic
            #else
            return .status
            #endif
        }
#endif
    }()
}

@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {
    /// Sets the visibility of the status bar.
    ///
    /// - Parameter hidden: A Boolean value that indicates whether to hide the
    ///   status bar.
    func statusBarHidden(_ hidden: Bool = true) -> some View {
#if os(iOS)
        content.statusBarHidden(hidden)
#else
        content // do nothing
#endif
    }
}


// MARK: - User Interaction

@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {
    /// Adds an action to perform when this view recognizes a tap gesture.
    ///
    /// Use this method to perform the specified `action` when the user clicks
    /// or taps on the view or container `count` times.
    ///
    /// > Note: If you create a control that's functionally equivalent
    /// to a ``Button``, use ``ButtonStyle`` to create a customized button
    /// instead.
    ///
    /// In the example below, the color of the heart images changes to a random
    /// color from the `colors` array whenever the user clicks or taps on the
    /// view twice:
    ///
    ///     struct TapGestureExample: View {
    ///         let colors: [Color] = [.gray, .red, .orange, .yellow,
    ///                                .green, .blue, .purple, .pink]
    ///         @State private var fgColor: Color = .gray
    ///
    ///         var body: some View {
    ///             Image(systemName: "heart.fill")
    ///                 .resizable()
    ///                 .frame(width: 200, height: 200)
    ///                 .foregroundColor(fgColor)
    ///                 .onTapGesture(count: 2) {
    ///                     fgColor = colors.randomElement()!
    ///                 }
    ///         }
    ///     }
    ///
    /// ![A screenshot of a view of a heart.](SwiftUI-View-TapGesture.png)
    ///
    /// - Parameters:
    ///    - count: The number of taps or clicks required to trigger the action
    ///      closure provided in `action`. Defaults to `1`.
    ///    - action: The action to perform.
    func onTapGesture(count: Int = 1, perform action: @escaping () -> Void) -> some View {
        Group {
            if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) { // 10.15 but macOS 11 required for availability checks.  Same with iOS 13.  Same with watchOS 6.  Gives warning on Swift Playgrounds.
                // have to re-order this way because apparently `else if #available` creates weird warnings.
                if #available(tvOS 16, *) {
                    content.onTapGesture(count: count, perform: action)
                } else {
                    // Fallback on earlier versions
                    content.onLongPressGesture(minimumDuration: 0.01, pressing: { _ in }) {
                        action()
                    }
                }
            } else {
                // Fallback on earlier versions
                // ignore for earlier tvOS since we won't be supporting tvOS <17 realistically anyways.
                content
            }
        }
    }
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
            #if os(macOS) || os(tvOS) // no longer supported in tvOS 17.2+?
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
@available(iOS 13, tvOS 13, watchOS 6, *)
@MainActor
public struct BackportNavigationStack<Root: View>: View {
    var root: () -> Root

    @MainActor
    public init(@ViewBuilder root: @escaping () -> Root) {
        self.root = root
    }

    public var body: some View {
        Group {
            if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
                NavigationStack { // SwiftUI.NavigationStack
                    root()
                }
            } else if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
                // Fallback on earlier versions
                NavigationView {
                    root()
                }
//#if !os(macOS)
//                .navigationViewStyle(.stack) // seems to cause crash on iOS 15 (also leads to undefined behavior...)
//#endif
            } else {
                root() // forget about wrapping...
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

@available(iOS 13, tvOS 13, watchOS 6, *)
@MainActor
public extension Backport where Content: View {
    /// Disables or enables scrolling in scrollable views.
    ///
    /// Use this modifier to control whether a ``ScrollView`` can scroll:
    ///
    ///     @State private var isScrollDisabled = false
    ///
    ///     var body: some View {
    ///         ScrollView {
    ///             VStack {
    ///                 Toggle("Disable", isOn: $isScrollDisabled)
    ///                 MyContent()
    ///             }
    ///         }
    ///         .scrollDisabled(isScrollDisabled)
    ///     }
    ///
    /// SwiftUI passes the disabled property through the environment, which
    /// means you can use this modifier to disable scrolling for all scroll
    /// views within a view hierarchy. In the following example, the modifier
    /// affects both scroll views:
    ///
    ///      ScrollView {
    ///          ForEach(rows) { row in
    ///              ScrollView(.horizontal) {
    ///                  RowContent(row)
    ///              }
    ///          }
    ///      }
    ///      .scrollDisabled(true)
    ///
    /// You can also use this modifier to disable scrolling for other kinds
    /// of scrollable views, like a ``List`` or a ``TextEditor``.
    ///
    /// - Parameter disabled: A Boolean that indicates whether scrolling is
    ///   disabled.
    func scrollDisabled(_ disabled: Bool = true) -> some View {
        if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
            return content.scrollDisabled(disabled)
        } else {
            // Fallback on earlier versions
            return content
        }
    }
    
}

#endif
