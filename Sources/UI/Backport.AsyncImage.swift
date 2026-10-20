//
//  Backport.AsyncImage.swift
//  Compatibility
//

#if canImport(SwiftUI) && canImport(Foundation) && compiler(>=5.9)
import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension Backport where Content == Any {
	/// Displays an image downloaded from a URL, using the native asynchronous image view where available.
	///
	/// On iOS 13 and equivalent systems, this compatibility implementation displays the URL's final
	/// path component. SwiftUI's native view is used on iOS 15 and equivalent systems; intermediate
	/// releases retain the package's ProgressView fallback.
	///
	/// - Parameter url: The URL of the image to display, or `nil` when no image is available.
	@ViewBuilder
	public static func AsyncImage(url: URL?) -> some View {
		if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
			SwiftUI.AsyncImage(url: url)
		} else {
			LegacyAsyncImage(url: url)
		}
	}

	/// Builds the legacy asynchronous image view for visual comparison on modern systems.
	///
	/// - Parameter url: The URL of the image to load, or `nil` to display the empty placeholder.
	@_spi(BackportTesting)
	public static func legacyAsyncImageForTesting(url: URL?) -> some View {
		LegacyAsyncImage(url: url)
	}

	/// Downloads and displays an image using the platform image type on systems without AsyncImage.
	struct LegacyAsyncImage: View {
		let url: URL?
		@State private var loadedImage: SwiftUI.Image?

		init(url: URL?, initialImage: SwiftUI.Image? = nil) {
			self.url = url
			self._loadedImage = State(initialValue: initialImage)
		}

		var body: some View {
			Group {
				if let loadedImage {
					loadedImage.resizable().aspectRatio(contentMode: .fit)
				} else {
					LegacyProgressIndicator()
				}
			}
			.onAppear(perform: load)
		}

		func load() {
			guard let url else { return }
			URLSession.shared.dataTask(with: url) { data, _, _ in
				guard let data else { return }
#if canImport(UIKit)
				guard let image = UIImage(data: data) else { return }
				DispatchQueue.main.async { loadedImage = SwiftUI.Image(uiImage: image) }
#elseif canImport(AppKit)
				guard let image = NSImage(data: data) else { return }
				DispatchQueue.main.async { loadedImage = SwiftUI.Image(nsImage: image) }
#endif
			}.resume()
		}
	}
}
#endif
