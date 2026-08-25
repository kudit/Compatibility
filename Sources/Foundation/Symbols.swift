//
//  Symbols.swift
//  Compatibility
//
//  Created by Ben Ku on 6/28/26.
//

/** Symbol Versions:

 There are now twelve different sets of symbols to consider:
 SF Symbols v1.0 available in iOS 13.0, watchOS 6.0 and macOS 11.0
 SF Symbols v1.1 available in iOS 13.1, watchOS 6.1 and macOS 11.0
 SF Symbols v2.0 available in iOS 14.0, watchOS 7.0 and macOS 11.0
 SF Symbols v2.1 available in iOS 14.2, watchOS 7.1 and macOS 11.0
 SF Symbols v2.2 available in iOS 14.5, watchOS 7.4 and macOS 11.3
 SF Symbols v3.0 available in iOS 15.0, watchOS 8.0 and macOS 12.0
 SF Symbols v3.1 available in iOS 15.1, watchOS 8.1 and macOS 12.0
 SF Symbols v3.2 available in iOS 15.2, watchOS 8.3 and macOS 12.1
 SF Symbols v3.3 available in iOS 15.4, watchOS 8.5 and macOS 12.3
 SF Symbols v4.0 available in iOS 16.0, watchOS 9.0 and macOS 13.0
 SF Symbols v4.1 available in iOS 16.1, watchOS 9.1 and macOS 13.0
 SF Symbols v4.2 available in iOS 16.4, watchOS 9.4 and macOS 13.3
 SF Symbols v5 available in iOS 17, watchOS 10 and macOS 14
 SF Symbols v6 available in iOS 18, watchOS 11 and macOS 15

 */

/// Primarily for Enums which can be represented by an SF Symbol.
public protocol SymbolRepresentable {
    /// An SF Symbol name string.
    var symbolName: SFSymbol { get }
}

public typealias SFSymbol = String
public extension SFSymbol {
    /// attempts to provide a fallback for a missing SF Symbol
    var fallbackForSymbol: String? {
        // Could include other fallback logic here
        let fallback = self
            .replacingOccurrences(of: ".fill", with: "")
            .replacingOccurrences(of: ".", with: " ")
        if fallback == self {
            return nil
        }
        return fallback
    }
    
    /// Returns a small, deterministic emoji approximation for common SF Symbol names.
    /// The map is intentionally local so symbol fallback behavior is stable on legacy platforms.
    var emojiForSymbol: String? {
        [
            "calendar": "📅",
            "applelogo": "",
            "heart.fill": "❤️",
            "star.fill": "⭐",
            "checkmark": "✓",
            "xmark": "✖️",
            "play.fill": "▶️",
            // TODO: Expand this
        ][self]
    }

    /// Returns a Unicode approximation when no emoji approximation is available.
    var unicodeForSymbol: String? {
        [
            "multiply.circle.fill": "×",
            "questionmark": "?",
            "plus": "+",
            "minus": "−",
            "chevron.left": "‹",
            "chevron.right": "›",
            "questionmark.square.fill": "⍰",
            "play.fill": "▸",
            // TODO: Expand this
        ][self]
    }

    static let defaultUnknownSymbol = "questionmark.square.fill"
}
