//
//  Backport.Toolbar.swift
//  Compatibility
//

#if canImport(SwiftUI) && compiler(>=5.9)
import SwiftUI

/// Adds toolbar actions across SwiftUI platforms and deployment targets.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
public extension Backport where Content: View {
	/// Places view content in the platform toolbar where available, or in an overlaid action bar.
	///
	/// Pass toolbar content such as `ToolbarItem` values in the content builder. On platforms with
	/// native toolbar support, the builder is forwarded directly to SwiftUI so its placement and
	/// grouping are preserved. tvOS uses a bottom action bar because a navigation toolbar is not
	/// consistently presented there. Older iOS, macOS, and watchOS versions use the same fallback.
	///
	/// The builder is evaluated directly for the legacy fallback because toolbar content cannot be
	/// inspected and converted into ordinary views on systems where the native toolbar API is
	/// unavailable. Supply ordinary views there so they can be rendered in the fallback action bar.
	///
	/// - Parameter content: Toolbar content to add, or ordinary views for the legacy action bar.
	/// - Returns: The content view with native toolbar actions or an overlaid action bar.
	@ViewBuilder
	func toolbar<ToolbarView: View>(
		@ViewBuilder content toolbarContent: @escaping () -> ToolbarView
	) -> some View {
#if os(tvOS)
		legacyToolbar(content: toolbarContent)
#elseif os(macOS)
		if #available(macOS 11, *) {
			self.content.toolbar(content: toolbarContent)
		} else {
			legacyToolbar(content: toolbarContent)
		}
#elseif os(watchOS)
		if #available(watchOS 7, *) {
			self.content.toolbar(content: toolbarContent)
		} else {
			legacyToolbar(content: toolbarContent)
		}
#elseif os(iOS)
		if #available(iOS 14, *) {
			self.content.toolbar(content: toolbarContent)
		} else {
			legacyToolbar(content: toolbarContent)
		}
#else
		if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
			self.content.toolbar(content: toolbarContent)
		} else {
			legacyToolbar(content: toolbarContent)
		}
#endif
	}

	/// Adds existing native toolbar content without inserting another `ToolbarItem` around it.
	///
	/// This overload preserves placements and grouping supplied by `ToolbarItem`,
	/// `ToolbarItemGroup`, and other `ToolbarContent` values. Older systems cannot display
	/// `ToolbarContent` outside SwiftUI's toolbar, so this overload leaves the view unchanged there;
	/// use the view-based overload above when a visible action-bar fallback is needed.
	///
	/// - Parameter content: Native toolbar content to forward unchanged where supported.
	/// - Returns: The view with native toolbar content on supported versions.
	@available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
	@ViewBuilder
	func toolbar<ToolbarItems: SwiftUI.ToolbarContent>(
		@ToolbarContentBuilder content toolbarContent: @escaping () -> ToolbarItems
	) -> some View {
		self.content.toolbar(content: toolbarContent)
	}

	/// Builds the view-based action bar directly so its pre-native fallback can be tested on modern OSes.
	@ViewBuilder
	func legacyToolbar<ToolbarView: View>(
		@ViewBuilder content toolbarContent: @escaping () -> ToolbarView
	) -> some View {
		self.content.backport.overlay(alignment: .bottom) {
			LegacyToolbarBar(content: toolbarContent())
		}
	}
}

/// A visible, focusable action row for platforms without a usable navigation toolbar.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
struct LegacyToolbarBar<Content: View>: View {
	@Environment(\.colorScheme) private var colorScheme
	let content: Content

	var body: some View {
		HStack(spacing: 12) {
			content
		}
		.frame(maxWidth: .infinity)
		.padding()
		.background(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.9))
	}
}

#endif
