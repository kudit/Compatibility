//
//  Backport.Menu.swift
//  Compatibility
//
//  Created by Ben Ku on 7/5/24.
//

#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation)
import SwiftUI

// MARK: - Menu

/// Provides a menu-style control across SwiftUI platforms and deployment targets.
///
/// Native SwiftUI menus are used on iOS 14 or later, macOS 11 or later, and tvOS 17 or later.
/// Earlier systems and watchOS use a navigation link that presents the menu actions in a
/// scrollable destination, matching the package's existing watchOS and tvOS fallback.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Backport where Content == Any {
	/// Creates a menu with a custom label.
	///
	/// - Parameters:
	///   - content: The actions and controls shown after activating the menu.
	///   - onOpen: An optional callback invoked as activation begins, before the legacy fallback navigates.
	///   - label: The view that identifies and activates the menu.
	/// - Returns: A native menu where supported, or a navigation-based menu fallback.
	@ViewBuilder
	static func Menu<MenuContent: View, LabelView: View>(
		@ViewBuilder content: @escaping () -> MenuContent,
		onOpen: (() -> Void)? = nil,
		@ViewBuilder label: @escaping () -> LabelView
	) -> some View {
#if os(watchOS)
		LegacyMenuView(content: content, onOpen: onOpen, label: label)
#elseif os(iOS)
		if #available(iOS 14, *) {
			SwiftUI.Menu(content: content, label: { MenuOpenTrigger(onOpen: onOpen, label: label) })
		} else {
			LegacyMenuView(content: content, onOpen: onOpen, label: label)
		}
#elseif os(macOS)
		if #available(macOS 11, *) {
			SwiftUI.Menu(content: content, label: { MenuOpenTrigger(onOpen: onOpen, label: label) })
		} else {
			LegacyMenuView(content: content, onOpen: onOpen, label: label)
		}
#elseif os(tvOS)
		if #available(tvOS 17, *) {
			SwiftUI.Menu(content: content, label: { MenuOpenTrigger(onOpen: onOpen, label: label) })
		} else {
			LegacyMenuView(content: content, onOpen: onOpen, label: label)
		}
#else
		if #available(iOS 14, macOS 11, tvOS 17, *) {
			SwiftUI.Menu(content: content, label: { MenuOpenTrigger(onOpen: onOpen, label: label) })
		} else {
			LegacyMenuView(content: content, onOpen: onOpen, label: label)
		}
#endif
	}

	/// Creates a menu with a localized title label.
	///
	/// A string literal resolves to `LocalizedStringKey`, preserving SwiftUI's normal localization
	/// behavior. Use a typed `String` or another `StringLikeProtocol` value for verbatim text.
	///
	/// - Parameters:
	///   - titleKey: The localized menu title.
	///   - content: The actions and controls shown after activating the menu.
	/// - Returns: A native menu where supported, or a navigation-based menu fallback.
	static func Menu<MenuContent: View>(
		_ titleKey: LocalizedStringKey,
		onOpen: (() -> Void)? = nil,
		@ViewBuilder content: @escaping () -> MenuContent
	) -> some View {
		Self.Menu(content: content, onOpen: onOpen, label: { Text(titleKey) })
	}

	/// Creates a menu from a string-like title value.
	///
	/// - Parameters:
	///   - title: The menu title.
	///   - content: The actions and controls shown after activating the menu.
	/// - Returns: A native menu where supported, or a navigation-based menu fallback.
	@_disfavoredOverload
	static func Menu<Title: StringLikeProtocol, MenuContent: View>(
		_ title: Title,
		onOpen: (() -> Void)? = nil,
		@ViewBuilder content: @escaping () -> MenuContent
	) -> some View {
		Self.Menu(content: content, onOpen: onOpen, label: { title.text })
	}
}

/// Runs the pre-presentation callback from the menu label's activation gesture.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
private struct MenuOpenTrigger<LabelView: View>: View {
	let onOpen: (() -> Void)?
	let label: () -> LabelView

	var body: some View {
#if os(tvOS)
		if #available(tvOS 16, *) {
			label().simultaneousGesture(TapGesture().onEnded { _ in onOpen?() })
		} else if #available(tvOS 14, *) {
			label().simultaneousGesture(LongPressGesture(minimumDuration: 0).onEnded { _ in onOpen?() })
		} else {
			label()
		}
#else
		label().simultaneousGesture(TapGesture().onEnded { _ in onOpen?() })
#endif
	}
}

/// Navigation-based menu used on platforms and releases without native SwiftUI menus.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
private struct LegacyMenuView<MenuContent: View, LabelView: View>: View {
	@State private var isPresented = false
	let content: () -> MenuContent
	let onOpen: (() -> Void)?
	let label: () -> LabelView

	var body: some View {
#if os(visionOS)
		Button {
			// Fire before changing the navigation binding so clients can capture the current screen.
			onOpen?()
			isPresented = true
		} label: {
			label()
		}
		.buttonStyle(.plain)
		.navigationDestination(isPresented: $isPresented) {
			content().scrollWrapper()
		}
#elseif os(watchOS)
		if #available(watchOS 9, *) {
			Button {
				// Fire before changing the navigation binding so clients can capture the current screen.
				onOpen?()
				isPresented = true
			} label: {
				label()
			}
		.buttonStyle(.plain)
		.navigationDestination(isPresented: $isPresented) {
			content().scrollWrapper()
		}
		} else {
			Button {
				onOpen?()
				isPresented = true
			} label: {
				label()
			}
		.buttonStyle(.plain)
		.sheet(isPresented: $isPresented) {
			content().scrollWrapper()
		}
		}
#else
		ZStack {
			NavigationLink(destination: content().scrollWrapper(), isActive: $isPresented) {
				EmptyView()
			}
			.hidden()
			Button {
				// Fire before changing the navigation binding so clients can capture the current screen.
				onOpen?()
				isPresented = true
			} label: {
				label()
			}
			.buttonStyle(.plain)
		}
#endif
	}
}


// Keep the original unqualified menu type available on watchOS and tvOS for source compatibility.
#if os(watchOS) || os(tvOS)
@available(tvOS 13, watchOS 6, *)
public struct Menu<Content: View, LabelView: View>: View {
	private let content: () -> Content
	private let label: () -> LabelView

	public init(
		@ViewBuilder content: @escaping () -> Content,
		@ViewBuilder label: @escaping () -> LabelView
	) {
		self.content = content
		self.label = label
	}

	public var body: some View {
		Backport.Menu(content: content, label: label)
	}
}

@available(tvOS 13, watchOS 6, *)
public extension Menu where LabelView == Text {
	init(
		_ title: some StringProtocol,
		@ViewBuilder content: @escaping () -> Content
	) {
		self.init(content: content, label: { Text(title) })
	}
}

@available(tvOS 13, watchOS 6, *)
public extension Menu where LabelView == Image {
	init(
		_ title: some StringProtocol,
		symbolName: String,
		@ViewBuilder content: @escaping () -> Content
	) {
		self.init(content: content, label: { Image(systemName: symbolName) })
	}
}
#endif

/*
#if canImport(UIKit)
import UIKit
@available(iOS 15, macOS 10.15, tvOS 17, *)
class MenuButton: UIButton {

    var onDismissMenu: (() -> Void)?
    var onShowMenu: (() -> Void)?

    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        super.contextMenuInteraction(interaction, willEndFor: configuration, animator: animator)

        onDismissMenu?()
    }

    override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willDisplayMenuFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        super.contextMenuInteraction(interaction, willDisplayMenuFor: configuration, animator: animator)

        onShowMenu?()
    }
}
#endif
*/

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct MenuTest: View {
    @Binding var symbol: String
    private let accessibilityIdentifier: String

    public init(symbol: Binding<String>, accessibilityIdentifier: String = "radial.symbols.menu") {
        self._symbol = symbol
        self.accessibilityIdentifier = accessibilityIdentifier
    }
    
    public var body: some View {
		Backport.Menu("Symbols", onOpen: {
			// Capture the pre-menu state here before SwiftUI presents native or legacy menu content.
			debug("Menu opening; capture screenshot now")
		}) {
            Text("TestCase menu with symbols")
                .onAppear {
                    debug("The menu is open! (via Text) - appears when menu first loads (view loads for toolbar, menu is first opened when in content")
                }
                .onDisappear {
                    debug("The menu is closed! (via Text")
                }
            
            // Keep choices as direct menu actions. A Picker nests its options in a submenu on macOS,
            // whose accessibility elements have zero-sized frames in macOS 27 and cannot be activated
            // reliably by UI automation. The explicit checkmark retains the Picker's selection cue.
            ForEach(["suit.diamond", "star", "suit.spade.fill", "suit.heart", "suit.club", "star.fill"], id: \.self) { selection in
                Button {
                    symbol = selection
                } label: {
                    HStack {
                        Backport.Label(selection, systemImage: selection)
                        Spacer()
                        if symbol == selection {
                            Backport.Image(systemName: "checkmark")
                        }
                    }
                }
                .accessibilityLabel(selection)
                .backport.accessibilityIdentifier("radial.symbol.\(selection)")
            }
        }
        .onAppear {
            debug("The Menu appeared")
        }
        .onDisappear {
            debug("The Menu disappeared")
        }
		.backport.accessibilityIdentifier(accessibilityIdentifier)
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("Watch Menu test") {
    MenuTest(symbol: .constant("calendar")).navigationWrapper()
}

#endif
