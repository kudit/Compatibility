//
//  Symbols.swift
//  Compatibility
//
//  Created by Ben Ku on 6/28/26.
//

import Foundation

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

/// Alias for String but designed for storing SFSymbol strings.  Adding additional functions and adding `ForSymbol` to make it clear these should be done on SFSymbols rather than any String since technically that is supported too.
public extension SFSymbol {
    static var unknownSymbolCharacter = "⍰"
    static let defaultUnknownSymbol = "questionmark.square.fill"

    /// Maps a missing SF Symbol name to an older symbol name.
    ///
    /// Mutate the map directly when customizing fallbacks, for example:
    ///
    ///     SFSymbol.fallbackSymbolMap["triangle"] = "circle"
    @MainActor
    static var fallbackSymbolMap: [SFSymbol: SFSymbol] = [
        "rectangle.portrait": "rectangle"
    ]

    /// attempts to provide a fallback for a missing SF Symbol
    @MainActor
    var fallbackForSymbol: String? {
        if let fallback = Self.fallbackSymbolMap[self] {
            return fallback
        }
        let fallback = self
            .replacingOccurrences(of: ".fill", with: "")
        if fallback == self {
            return nil
        }
        return fallback
    }
    
    /// Maps a symbol to an emoji character.  Can be modified to add or change mapings.
    @MainActor
    static var symbolEmojiMap: [SFSymbol: String] = [
        "calendar": "📅",
        "applelogo": "",
        "heart.fill": "❤️",
        "star.fill": "⭐",
        "checkmark": "✓",
        "xmark": "✖️",
        "play.fill": "▶️",
    ]

    /// Returns a small, deterministic emoji approximation for common SF Symbol names.
    /// The map is intentionally local so symbol fallback behavior is stable on legacy platforms.
    @MainActor
    var emojiForSymbol: String? {
        Self.symbolEmojiMap[self]
    }

    /// Maps a symbol to a unicode character.  Can be modified to add or change mapings.
    @MainActor
    static var symbolUnicodeMap: [SFSymbol: String] = [
        "multiply.circle.fill": "×",
        "questionmark": "?",
        "plus": "+",
        "minus": "−",
        "chevron.left": "‹",
        "chevron.right": "›",
        "questionmark.square.fill": "⍰",
        "play.fill": "▸",
    ]

    /// Returns a Unicode approximation when no emoji approximation is available.
    @MainActor
    var unicodeForSymbol: String? {
        Self.symbolUnicodeMap[self]
    }

    @MainActor
    var bestTextApproximationForSymbol: String {
        return self.emojiForSymbol ?? self.unicodeForSymbol ?? self.fallbackForSymbol?.bestTextApproximationForSymbol ?? .unknownSymbolCharacter
    }
}

#if canImport(SwiftUI) && canImport(Foundation) && compiler(>=5.9)
import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Adds runtime SF Symbol and asset lookup to the shared symbol-name type.
public extension SFSymbol {
    /// Returns the legacy asset name commonly paired with a newer SF Symbol.
    var legacy: SFSymbol { "\(self).legacy" }

    /// Indicates whether the current platform can create this SF Symbol or find a matching image asset.
    ///
    /// Pass a package resource bundle to check assets outside the main application bundle.
    /// UIKit checks both the system symbol catalog and named image assets. AppKit checks system
    /// symbols and named images, using its bundle-aware symbol asset lookup where available.
    ///
    /// - Parameter bundle: The bundle containing a custom image asset, or `nil` for the main bundle.
    func available(in bundle: Bundle? = nil) -> Bool {
        if isSystemSymbolAvailable() {
            return true
        }
        return Self.localImageAvailable(self, in: bundle ?? .main)
    }

    /// Indicates whether this name resolves specifically to a native SF Symbol.
    ///
    /// Use this when choosing between `Image(systemName:)` and a named image asset initializer.
    func isSystemSymbolAvailable() -> Bool {
        Self.nativeSymbolAvailable(self)
    }

    /// Returns a safe symbol or named image using the main bundle.
    @MainActor
    var safe: SFSymbol { safe(in: nil) }

    /// Returns an available image name, preferring this native symbol, then its `.legacy` asset,
    /// then a registered or conventional fallback, and finally the default unknown symbol.
    ///
    /// - Parameter bundle: The bundle containing custom image assets, or `nil` for the main bundle.
    @MainActor
    func safe(in bundle: Bundle? = nil) -> SFSymbol {
        let bundle = bundle ?? .main
        return Self.resolveSafeSymbol(
            self,
            in: bundle,
            nativeSymbolAvailable: { Self.nativeSymbolAvailable($0) },
            localImageAvailable: { Self.localImageAvailable($0, in: $1) }
        )
    }

	@MainActor
    static func resolveSafeSymbol(
        _ symbol: SFSymbol,
        in bundle: Bundle,
        nativeSymbolAvailable: (SFSymbol) -> Bool,
        localImageAvailable: (SFSymbol, Bundle) -> Bool
    ) -> SFSymbol {
        if nativeSymbolAvailable(symbol) {
            return symbol
        }
        let legacyName = symbol.legacy
        if localImageAvailable(legacyName, bundle) {
            return legacyName
        }
        if localImageAvailable(symbol, bundle) {
            return symbol
        }

        var candidate = symbol
        var visited = Set<SFSymbol>()

        while visited.insert(candidate).inserted {
            if nativeSymbolAvailable(candidate) || localImageAvailable(candidate, bundle) {
                return candidate
            }
            let candidateLegacy = candidate.legacy
            if localImageAvailable(candidateLegacy, bundle) {
                return candidateLegacy
            }

            if let conventionalFallback = candidate.fallbackForSymbol {
                candidate = conventionalFallback
            } else {
                candidate = Self.defaultUnknownSymbol
            }
        }

        return Self.defaultUnknownSymbol
    }

    private static func nativeSymbolAvailable(_ symbol: SFSymbol) -> Bool {
#if canImport(UIKit)
        if #available(iOS 13, tvOS 13, watchOS 6, *) {
            return UIImage(systemName: symbol) != nil
        }
#endif
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
        if #available(macOS 11, *) {
            return NSImage(systemSymbolName: symbol, accessibilityDescription: nil) != nil
        }
#endif
        return false
    }

    private static func localImageAvailable(_ name: SFSymbol, in bundle: Bundle) -> Bool {
#if canImport(UIKit)
        if #available(iOS 13, tvOS 13, watchOS 6, *) {
            return UIImage(named: name, in: bundle, with: nil) != nil
        }
#endif
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
        if #available(macOS 13, *) {
            return NSImage(symbolName: name, bundle: bundle, variableValue: 1) != nil
        }
        if NSImage(named: name) != nil {
            return true
        }
#endif
        return false
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Backport where Content == Any {
    /// Creates an image for an SF Symbol, with a text approximation on macOS 10.15.
    ///
    /// The native SwiftUI image is used on iOS, tvOS, watchOS, and macOS 11 or later. macOS 10.15
    /// predates SwiftUI's `Image(systemName:)`, so it displays a readable emoji, Unicode, or symbol
    /// name approximation instead.
    ///
    /// - Parameter systemName: The SF Symbol name.
    @ViewBuilder
    static func Image(systemName: SFSymbol, bundle: Bundle? = nil) -> some View {
#if os(macOS)
        if #available(macOS 11, *) {
            let safeName = systemName.safe(in: bundle)
            if safeName.isSystemSymbolAvailable() {
                SwiftUI.Image(systemName: safeName)
            } else {
                SwiftUI.Image(safeName, bundle: bundle)
            }
        } else {
            LegacySystemImage(systemName: systemName)
        }
#else
        let safeName = systemName.safe(in: bundle)
        if safeName.isSystemSymbolAvailable() {
            SwiftUI.Image(systemName: safeName)
        } else {
            SwiftUI.Image(safeName, bundle: bundle)
        }
#endif
    }

#if os(macOS)
    /// Builds the macOS 10.15 text substitute directly for comparison and coverage tests.
    static func legacySystemImageForTesting(systemName: SFSymbol) -> some View {
        LegacySystemImage(systemName: systemName)
    }

    /// Produces an accessible text approximation where the native SF Symbol initializer is unavailable.
    private struct LegacySystemImage: View {
        let systemName: SFSymbol

        var body: some View {
            Text(systemName.bestTextApproximationForSymbol)
//                .backport.accessibilityLabel(Text(systemName)) // ideal but not available on macOS 10.15 anyways
        }
    }
#endif
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
enum SymbolCompatibilityTests {
    @MainActor
    static let tests: [TestCase] = [
        TestCase("Symbol text fallbacks and names") { @MainActor in
            try expectEqual("rectangle.portrait".fallbackForSymbol, "rectangle")
            try expectEqual("custom.fill".fallbackForSymbol, "custom")
            try expectEqual("custom".fallbackForSymbol, nil)
            try expectEqual("heart.fill".emojiForSymbol, "❤️")
            try expectEqual("multiply.circle.fill".unicodeForSymbol, "×")
            try expectEqual("heart.fill".bestTextApproximationForSymbol, "❤️")
            try expectEqual("plus".bestTextApproximationForSymbol, "+")
            try expectEqual("missing.symbol".bestTextApproximationForSymbol, SFSymbol.unknownSymbolCharacter)
            try expectEqual("heart.fill".legacy, "heart.fill.legacy")

            // Exercise platform symbol and asset lookups without assuming the OS symbol catalog version.
            _ = "circle".isSystemSymbolAvailable()
            _ = "circle".available(in: .main)
            _ = "compatibility.coverage.missing.symbol".available(in: .main)
            _ = Backport<Any>.Image(systemName: "heart.fill")
#if os(macOS)
            let legacyImage = Backport<Any>.legacySystemImageForTesting(systemName: "heart.fill")
            _ = legacyImage.body
#endif
        },
        TestCase("Symbol safe resolution native and local paths") { @MainActor in
            let symbol = "compatibility.coverage.symbol"
            @MainActor
            func resolve(native: Set<SFSymbol> = [], images: Set<SFSymbol> = []) -> SFSymbol {
                SFSymbol.resolveSafeSymbol(
                    symbol,
                    in: .main,
                    nativeSymbolAvailable: { native.contains($0) },
                    localImageAvailable: { name, _ in images.contains(name) }
                )
            }

            try expectEqual(resolve(native: [symbol]), symbol, "An available native system symbol should win.")
            try expectEqual(resolve(images: [symbol.legacy]), symbol.legacy, "A legacy-named image should precede fallback symbols.")
            try expectEqual(resolve(images: [symbol]), symbol, "A matching named image should be retained.")
        },
        TestCase("Symbol safe resolution fallback and cycle paths") { @MainActor in
            let symbol = "compatibility.coverage.symbol.fallback"
            let firstCycle = "compatibility.coverage.symbol.cycle.first"
            let secondCycle = "compatibility.coverage.symbol.cycle.second"
            let keys = [symbol, firstCycle, secondCycle]
            let oldValues = Dictionary(uniqueKeysWithValues: keys.map { ($0, SFSymbol.fallbackSymbolMap[$0]) })
            defer {
                for key in keys {
                    if let oldValue = oldValues[key] ?? nil {
                        SFSymbol.fallbackSymbolMap[key] = oldValue
                    } else {
                        SFSymbol.fallbackSymbolMap.removeValue(forKey: key)
                    }
                }
            }

            SFSymbol.fallbackSymbolMap[symbol] = "circle"
            let mappedFallback = SFSymbol.resolveSafeSymbol(
                symbol,
                in: .main,
                nativeSymbolAvailable: { $0 == "circle" },
                localImageAvailable: { _, _ in false }
            )
            try expectEqual(mappedFallback, "circle", "A registered fallback should resolve to the first available candidate.")

            let legacyFallback = SFSymbol.resolveSafeSymbol(
                symbol,
                in: .main,
                nativeSymbolAvailable: { _ in false },
                localImageAvailable: { name, _ in name == "circle.legacy" }
            )
            try expectEqual(legacyFallback, "circle.legacy", "A fallback candidate's legacy asset should be checked.")

            SFSymbol.fallbackSymbolMap[firstCycle] = secondCycle
            SFSymbol.fallbackSymbolMap[secondCycle] = firstCycle
            let cycleResult = SFSymbol.resolveSafeSymbol(
                firstCycle,
                in: .main,
                nativeSymbolAvailable: { _ in false },
                localImageAvailable: { _, _ in false }
            )
            try expectEqual(cycleResult, SFSymbol.defaultUnknownSymbol, "A fallback cycle should stop at the default symbol.")

            let unknownResult = SFSymbol.resolveSafeSymbol(
                "compatibility.coverage.symbol.unknown",
                in: .main,
                nativeSymbolAvailable: { _ in false },
                localImageAvailable: { _, _ in false }
            )
            try expectEqual(unknownResult, SFSymbol.defaultUnknownSymbol)
        },
    ]
}

#endif
