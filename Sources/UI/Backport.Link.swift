//
//  Link.swift
//  Compatibility
//

#if canImport(SwiftUI) && canImport(Foundation) && compiler(>=5.9)
import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif
#if canImport(WatchKit)
import WatchKit
#endif

// MARK: - Link

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Backport where Content == Any {
	/// A control for navigating to a URL on every SwiftUI deployment target supported by Compatibility.
	///
	/// On newer systems this type delegates to `SwiftUI.Link`. On earlier systems it opens the URL
	/// from a plain button while retaining the supplied label's layout and accessibility information.
	/// The native view honors the environment's `openURL` action; the iOS 13 and equivalent legacy
	/// fallbacks open the URL with the platform's system URL handler.
	///
	/// Use the title initializer for a text label, or provide a custom label when the link should
	/// display an icon or another view:
	///
	///     Backport<Any>.Link("View Our Terms of Service", destination: termsURL)
	///     Backport<Any>.Link(destination: websiteURL) {
	///         Label("Visit Our Site", systemImage: "safari")
	///     }
	struct Link<Label: View>: View {
		private let destination: URL
		private let label: () -> Label

		/// Creates a link with a custom view label.
		///
		/// - Parameters:
		///   - destination: The URL to open when the user activates the link.
		///   - label: A view builder that creates the link's visible and accessible label.
		public init(
			destination: URL,
			@ViewBuilder label: @escaping () -> Label
		) {
			self.destination = destination
			self.label = label
		}

		/// Creates a link from a string-like title.
		///
		/// - Parameters:
		///   - title: A `String`, `Substring`, `LocalizedStringKey`, or conforming custom string value.
		///   - destination: The URL to open when the user activates the link.
		///
		/// String values render verbatim; localized keys retain SwiftUI localization and fall back to their key text.
		@_disfavoredOverload
		public init<S: StringLikeProtocol>(_ title: S, destination: URL) where Label == Text {
			self.destination = destination
			self.label = { title.text }
		}

		/// Creates a link with a localized string-key title, including when inferring a string literal.
		///
		/// - Parameters:
		///   - titleKey: The localized title to display as the link's label.
		///   - destination: The URL to open when the user activates the link.
		public init(_ titleKey: LocalizedStringKey, destination: URL) where Label == Text {
			self.destination = destination
			self.label = { Text(titleKey) }
		}

		/// The native link or a legacy button that opens the destination URL.
		@ViewBuilder
		public var body: some View {
			if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
				SwiftUI.Link(destination: destination, label: label)
			} else {
				legacyBody
			}
		}

		/// Builds the pre-native Button path explicitly for coverage on modern test hosts.
		var legacyBody: some View {
			Button(action: openDestination, label: label)
				.buttonStyle(PlainButtonStyle())
		}

		/// Opens the URL through the current platform's system URL handler.
		@MainActor
		private func openDestination() {
#if canImport(UIKit) && !os(watchOS)
			UIApplication.shared.open(destination, options: [:], completionHandler: nil)
#elseif canImport(AppKit)
			NSWorkspace.shared.open(destination)
#elseif canImport(WatchKit)
			WKExtension.shared().openSystemURL(destination)
#else
			debug("Unable to open URL in this environment: \(destination)", .WARNING)
#endif
		}
	}
}
#endif
