//
//  BackportHierarchicalShapeStyle.swift
//  Compatibility
//

/// A semantic hierarchical foreground tier and its shared fixed-color opacity.
///
/// This type lives in the platform-neutral Core target so the Color package can reuse its opacity
/// values even when SwiftUI is unavailable. SwiftUI-specific rendering is defined separately.
public enum BackportHierarchicalShapeStyle: Sendable, CaseIterable { // since possibly used outside of Backport views, build in Backport to the name so we don't have to deal with Backport's generic weirdness.
	case primary
	case secondary
	case tertiary
	case quaternary
	
	/// The opacity used to generate a fixed color for this hierarchical tier.
	public var opacity: Double {
		switch self {
		case .primary: return 0.90
		case .secondary: return 0.60
		case .tertiary: return 0.35
		case .quaternary: return 0.18
		}
	}
}

#if canImport(SwiftUI) && compiler(>=5.9)
import SwiftUI

/// Converts a backported tier to SwiftUI's native hierarchical style where that API exists.
@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
public extension BackportHierarchicalShapeStyle {
	/// The corresponding native SwiftUI hierarchical style.
	var swiftUIValue: SwiftUI.HierarchicalShapeStyle {
		switch self {
		case .primary: return .primary
		case .secondary: return .secondary
		case .tertiary: return .tertiary
		case .quaternary: return .quaternary
		}
	}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {
	/// Applies a semantic hierarchical foreground tier.
	///
	/// SwiftUI renders the native hierarchical style on supported systems. Older systems use a
	/// black or white fixed color selected from the environment, with the opacity shared with Color.
	@ViewBuilder
	func foregroundStyle(_ style: BackportHierarchicalShapeStyle) -> some View {
		if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
			content.foregroundStyle(style.swiftUIValue)
		} else {
			BackportHierarchicalStyleFallback(content: content, style: style)
		}
	}
}

/// Applies a color-scheme-aware fixed color for hierarchical styles on older SwiftUI versions.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
struct BackportHierarchicalStyleFallback<Content: View>: View {
	@Environment(\.colorScheme) private var colorScheme
	let content: Content
	let style: BackportHierarchicalShapeStyle

	var body: some View {
		let baseColor: Color = colorScheme == .dark ? .white : .black
		content.foregroundColor(baseColor.opacity(style.opacity))
	}
}
#endif
