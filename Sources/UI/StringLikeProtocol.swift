//
//  StringLikeProtocol.swift
//  Compatibility
//

#if canImport(SwiftUI) && compiler(>=5.9)
import SwiftUI

/// A string-like value that can create a SwiftUI text view without losing localization information.
///
/// `String` and `Substring` receive a default implementation. `LocalizedStringKey` preserves its
/// localization key. Custom `StringProtocol` types can adopt this protocol to use the same generic
/// initializer in controls such as ``Backport<Any>.Link``.
@MainActor
public protocol StringLikeProtocol {
	/// The SwiftUI text representation of this value.
	@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
	var text: Text { get }
}

/// Supplies the plain-text implementation for values backed by Swift's string protocol.
@MainActor
public extension StringLikeProtocol where Self: StringProtocol {
	@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
	var text: Text { Text(String(self)) }
}

@MainActor
extension String: StringLikeProtocol {}

@MainActor
extension Substring: StringLikeProtocol {}

/// Preserves localized rendering for an explicitly supplied key.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
extension LocalizedStringKey: StringLikeProtocol {
	public var text: Text { Text(self) }
}
#endif
