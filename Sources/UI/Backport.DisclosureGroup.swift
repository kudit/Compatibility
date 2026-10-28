//
//  Backport.DisclosureGroup.swift
//  Device
//
//  Created by Ben Ku on 10/23/26.
//

#if canImport(SwiftUI)
import SwiftUI

/// Supplies `Backport.DisclosureGroup` on platforms where SwiftUI's native
/// `DisclosureGroup` is unavailable or has not yet been introduced.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Backport where Content == Any {
	/// Creates a disclosure group with the same call-site shape as SwiftUI's initializer.
	///
	/// Native `DisclosureGroup` is used on iOS 14, macOS 11, and later supported
	/// systems. On earlier systems and tvOS/watchOS, a button toggles the content.
	@MainActor
	@ViewBuilder
	static func DisclosureGroup<Label: View, GroupContent: View>(
		isExpanded: Binding<Bool>,
		@ViewBuilder content: @escaping () -> GroupContent,
		@ViewBuilder label: @escaping () -> Label
	) -> some View {
		BackportDisclosureGroupView(isExpanded: isExpanded, content: content, label: label)
	}
}

/// Keeps the generic content type separate from `Backport`'s own generic parameter.
/// This prevents ambiguous generic inference at `Backport.DisclosureGroup` call sites.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct BackportDisclosureGroupView<Label: View, GroupContent: View>: View {
	@Binding var isExpanded: Bool
	let content: () -> GroupContent
	let label: () -> Label

	@ViewBuilder
	var body: some View {
#if os(tvOS) || os(watchOS)
		fallback
#else
		if #available(iOS 14, macOS 11, *) {
			SwiftUI.DisclosureGroup(isExpanded: $isExpanded, content: content, label: label)
		} else {
			fallback
		}
#endif
	}

	/// tvOS and watchOS lack native DisclosureGroup, so a button preserves toggle behavior.
	@ViewBuilder
	fileprivate var fallback: some View {
		VStack(alignment: .leading, spacing: 8) {
			Button {
				toggleExpanded()
			} label: {
				HStack(alignment: .top, spacing: 8) {
					label()
					Backport.Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
						.font(.caption.weight(.semibold))
						.accessibilityHidden(true)
				}
				.contentShape(Rectangle())
			}
			.buttonStyle(.plain)

			if isExpanded {
				content()
					.padding(.leading, 16)
			}
		}
	}

	fileprivate func toggleExpanded() {
		isExpanded.toggle()
	}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Backport where Content == Any {
	@MainActor
	internal static let disclosureGroupTests: [TestCase] = [
		TestCase("Backport DisclosureGroup fallback state") { @MainActor in
			let state = DisclosureGroupTestState()
			let binding = Binding(
				get: { state.isExpanded },
				set: { state.isExpanded = $0 }
			)
			let fallback = BackportDisclosureGroupView<Text, Text>(
				isExpanded: binding,
				content: { Text("Expanded content") },
				label: { Text("Disclosure label") }
			)
			_ = fallback.fallback
			fallback.toggleExpanded()
			try expect(state.isExpanded, "The legacy disclosure control should expand its binding.")
			_ = fallback.fallback
			fallback.toggleExpanded()
			try expect(!state.isExpanded, "The legacy disclosure control should collapse its binding.")

			let publicFactory = Backport<Any>.DisclosureGroup(
				isExpanded: binding,
				content: { Text("Factory content") },
				label: { Text("Factory label") }
			)
			_ = publicFactory
		},
	]
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
private final class DisclosureGroupTestState {
	var isExpanded = false
}

#endif
