//
//  Backport.Section.swift
//  Compatibility
//

#if canImport(SwiftUI) && compiler(>=5.9)
import SwiftUI

/// Provides a consistently namespaced title initializer for SwiftUI sections.
///
/// SwiftUI's localized-title initializer starts at iOS 15, macOS 12, tvOS 15, and watchOS 8.
/// This wrapper adapts it to the older header initializer while returning the native
/// `SwiftUI.Section` type so `List` and `Form` retain their section behavior. The separate
/// `LocalizedStringKey` overload preserves SwiftUI's localized interpretation of string literals;
/// the generic overload handles already-typed strings and other `StringLikeProtocol` values.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Backport where Content == Any {
	/// Creates a section with a localized title and content.
	///
	/// - Parameters:
	///   - titleKey: The localized section title.
	///   - content: The views displayed in the section.
	static func Section<SectionContent: View>(
		_ titleKey: LocalizedStringKey,
		@ViewBuilder content: () -> SectionContent
	) -> SwiftUI.Section<Text, SectionContent, EmptyView> {
		if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
			SwiftUI.Section(titleKey, content: content)
		} else {
			SwiftUI.Section(header: Text(titleKey), content: content)
		}
	}

	/// Creates a section from any value supported by Compatibility's localized/text labels.
	///
	/// String literals prefer the `LocalizedStringKey` overload above. String values and other
	/// `StringLikeProtocol` values retain their own text representation, including localization
	/// when the value is already a `LocalizedStringKey`.
	///
	/// - Parameters:
	///   - title: The section title.
	///   - content: The views displayed in the section.
	@_disfavoredOverload
	static func Section<Title: StringLikeProtocol, SectionContent: View>(
		_ title: Title,
		@ViewBuilder content: () -> SectionContent
	) -> SwiftUI.Section<Text, SectionContent, EmptyView> {
		SwiftUI.Section(content: content, header: { title.text })
	}
}

#endif
