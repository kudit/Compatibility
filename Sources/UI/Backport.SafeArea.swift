#if canImport(SwiftUI) && compiler(>=5.9)
import SwiftUI

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {
	/// Native safe-area reservation on modern systems. On original SwiftUI, a stack
	/// reserves the inset's actual layout size within the hosting view's safe area.
	/// The fallback cannot alter ScrollView indicator insets or expose newer fold regions.
	@ViewBuilder
	func safeAreaInset<V: View>(edge: VerticalEdge, alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content inset: () -> V) -> some View {
		if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
			content.safeAreaInset(edge: edge, alignment: alignment, spacing: spacing, content: inset)
		} else {
			LegacyVerticalSafeAreaInset(base: content, edge: edge, alignment: alignment, spacing: spacing ?? 0, inset: inset())
		}
	}
	/// Horizontal counterpart; original SwiftUI continues to respect host safe areas.
	@ViewBuilder
	func safeAreaInset<V: View>(edge: HorizontalEdge, alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content inset: () -> V) -> some View {
		if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
			content.safeAreaInset(edge: edge, alignment: alignment, spacing: spacing, content: inset)
		} else {
			LegacyHorizontalSafeAreaInset(base: content, edge: edge, alignment: alignment, spacing: spacing ?? 0, inset: inset())
		}
	}
	/// More-specific explicit-length overload avoids Compatibility's older no-op fallback.
	/// Actual host safe areas remain in force; padding reserves additional content space.
	@ViewBuilder
	func safeAreaPadding(_ edges: Edge.Set = .all, _ length: CGFloat) -> some View {
		if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) { content.safeAreaPadding(edges, length) }
		else { content.padding(edges, length) }
	}
	func safeAreaPadding(_ length: CGFloat) -> some View { safeAreaPadding(.all, length) }
}

/// Geometry reports zero insets inside a safe area and nonzero insets when a
/// caller extends this container into it, avoiding duplicate system padding.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct SafeAreaMeasurements: PreferenceKey {
	static var defaultValue = EdgeInsets()
	static func reduce(value: inout EdgeInsets, nextValue: () -> EdgeInsets) { value = nextValue() }
}
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct LegacyVerticalSafeAreaInset<Base: View, Inset: View>: View {
	let base: Base
	let edge: VerticalEdge
	let alignment: HorizontalAlignment
	let spacing: CGFloat
	let inset: Inset
	@State private var safe = EdgeInsets()
	var body: some View {
		VStack(alignment: alignment, spacing: spacing) {
			if edge == .top { inset.padding(.top, safe.top) }
			base
			if edge == .bottom { inset.padding(.bottom, safe.bottom) }
		}
		.background(GeometryReader { geometry in Color.clear.preference(key: SafeAreaMeasurements.self, value: geometry.safeAreaInsets) })
		.onPreferenceChange(SafeAreaMeasurements.self) { if safe != $0 { safe = $0 } }
	}
}
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct LegacyHorizontalSafeAreaInset<Base: View, Inset: View>: View {
	let base: Base
	let edge: HorizontalEdge
	let alignment: VerticalAlignment
	let spacing: CGFloat
	let inset: Inset
	@State private var safe = EdgeInsets()
	var body: some View {
		HStack(alignment: alignment, spacing: spacing) {
			if edge == .leading { inset.padding(.leading, safe.leading) }
			base
			if edge == .trailing { inset.padding(.trailing, safe.trailing) }
		}
		.background(GeometryReader { geometry in Color.clear.preference(key: SafeAreaMeasurements.self, value: geometry.safeAreaInsets) })
		.onPreferenceChange(SafeAreaMeasurements.self) { if safe != $0 { safe = $0 } }
	}
}
#endif
