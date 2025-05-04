//
//  Pasteboard.swift
//  Compatibility
//
//  Created by Ben Ku on 5/4/25.
//

/// Pasteboard manipulation
#if canImport(UIKit) || canImport(AppKit)
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public extension Compatibility {
    static func copyToPasteboard(_ string: String) {
#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
        // macCatalyst < 13 doesn't support UIPasteboard and doesn't support NSPasteboard at all.
        UIPasteboard.general.string = string
#elseif canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
#endif
    }
}
#endif

