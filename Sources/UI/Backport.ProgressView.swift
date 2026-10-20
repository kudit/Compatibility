//
//  Backport.ProgressView.swift
//  Compatibility
//

#if canImport(SwiftUI) && compiler(>=5.9)
import SwiftUI
#if canImport(UIKit) && !os(watchOS)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension Backport where Content == Any {
	/// Displays an indeterminate progress indicator, using SwiftUI's native view where available.
	@ViewBuilder
	public static func ProgressView(_ title: StringLikeProtocol? = nil) -> some View {
		if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
			if let titleKey = title as? LocalizedStringKey {
				SwiftUI.ProgressView(titleKey)
			} else if let title = title as? any StringProtocol {
				SwiftUI.ProgressView(title)
			} else {
				SwiftUI.ProgressView()
			}
		} else {
			LegacyProgressIndicator()
		}
	}

	/// Builds the legacy indicator for visual comparison in Compatibility's UI tests.
	@_spi(BackportTesting)
	public static func legacyProgressViewForTesting() -> some View {
		LegacyProgressIndicator()
	}
}

/// A small animated ring shared by legacy progress and asynchronous-image loading states.
/// Keeping one implementation ensures forced legacy previews match the older-system fallback.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
struct LegacyProgressIndicator: View {
	@State private var isAnimating = false

	var body: some View {
		// watchOS can import UIKit but does not expose UIActivityIndicatorView or UIViewRepresentable;
		// use the lightweight SwiftUI ring there instead of selecting the UIKit branch.
		#if canImport(UIKit) && !os(watchOS)
		LegacyUIKitProgressIndicator()
		#elseif canImport(AppKit)
		LegacyAppKitProgressIndicator()
		#else
		Circle()
			.trim(from: 0.18, to: 0.82)
			.stroke(Color.primary.opacity(0.75), style: StrokeStyle(lineWidth: 2, lineCap: .round))
			.frame(width: 20, height: 20)
			.rotationEffect(.degrees(isAnimating ? 360 : 0))
			.animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
			.onAppear {
				isAnimating = true
			}
		#endif
		}
}

#if canImport(UIKit) && !os(watchOS)
/// Uses UIKit's system activity indicator so the legacy fallback matches the platform spinner.
@available(iOS 13, tvOS 13, *)
private struct LegacyUIKitProgressIndicator: UIViewRepresentable {
	func makeUIView(context: Context) -> UIActivityIndicatorView {
		let indicator = UIActivityIndicatorView(style: .medium)
		indicator.startAnimating()
		return indicator
	}

	func updateUIView(_ indicator: UIActivityIndicatorView, context: Context) {
		if !indicator.isAnimating {
			indicator.startAnimating()
		}
	}
}
#elseif canImport(AppKit)
/// Uses AppKit's system spinning indicator to match macOS ProgressView appearance.
@available(macOS 10.15, *)
private struct LegacyAppKitProgressIndicator: NSViewRepresentable {
	func makeNSView(context: Context) -> NSProgressIndicator {
		let indicator = NSProgressIndicator()
		indicator.style = .spinning
		indicator.isIndeterminate = true
		indicator.controlSize = .small
		indicator.startAnimation(nil)
		return indicator
	}

	func updateNSView(_ indicator: NSProgressIndicator, context: Context) {
		if !indicator.isIndeterminate {
			indicator.isIndeterminate = true
		}
		indicator.startAnimation(nil)
	}
}
#endif
#endif
