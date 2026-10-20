//
//  Backport.AttributedString.swift
//  Compatibility
//

#if canImport(SwiftUI) && canImport(Foundation) && compiler(>=5.9)
import Foundation
import SwiftUI

/// Provides a SwiftUI rendering of Markdown text when Foundation's AttributedString is available.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension View {
	/// Parses Markdown into styled, interactive SwiftUI text where supported.
	///
	/// On iOS 15, macOS 12, tvOS 15, and watchOS 8 or later, this uses Foundation's Markdown
	/// `AttributedString` parser and SwiftUI's attributed-text renderer. It returns `nil` on older
	/// systems, allowing the caller to display its ordinary `Text` fallback without referencing an
	/// API that is unavailable on those systems. A parsing failure also returns `nil`.
	///
	/// SwiftUI renders the supported inline attributes, including link attributes, while other
	/// Foundation attributes may be ignored by `Text`.
	///
	/// - Parameter markdown: The Markdown source to parse.
	/// - Returns: A styled `Text` view, or `nil` when Markdown attributed text is unavailable or
	///   the source cannot be parsed.
	func AttributedStringText(markdown: String) -> Text {
		if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *), let attributedString = try? Foundation.AttributedString(markdown: markdown) {
			// Rendering Markdown as an AttributedString preserves link attributes so each module
			// repository is clickable instead of displaying the Markdown syntax literally.
			Text(attributedString)
		} else {
			// Keep the diagnostic visible if a platform's Markdown parser cannot decode a URL.
			Text(markdown)
		}
	}
}

#endif
