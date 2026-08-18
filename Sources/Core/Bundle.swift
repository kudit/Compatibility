//
//  Bundle.swift
//  Compatibility
//
//  Created by Ben Ku on 6/30/16.
//  Copyright © 2016 Kudit. All rights reserved.
//

#if canImport(Foundation)
// get current version:
// Bundle.main.version
public extension Bundle {
    /// A user-visible short name for the bundle.
    var name: String { getInfo("CFBundleName") ?? "Unknown App Name" }
    
    /// The user-visible name for the bundle, used by Siri and visible on the iOS Home screen.
    var displayName: String { getInfo("CFBundleDisplayName") ?? "⚠️" }
    
    /// The name of the bundle’s executable file.
    var appName: String { getInfo("CFBundleExecutable") ?? "⚠️" }
    
    /// The default language and region for the bundle, as a language ID.
    var language: String { getInfo("CFBundleDevelopmentRegion") ?? "en" }
    
    /** A unique identifier for a bundle.
     A bundle ID uniquely identifies a single app throughout the system. The bundle ID string must contain only alphanumeric characters (A–Z, a–z, and 0–9), hyphens (-), and periods (.). Typically, you use a reverse-DNS format for bundle ID strings. Bundle IDs are case-insensitive.
     **/
    var identifier: String { getInfo("CFBundleIdentifier") ?? "unknown.bundle.identifier"}
    
    /// A human-readable copyright notice for the bundle.
    var copyright: String { getInfo("NSHumanReadableCopyright")?.replacingOccurrences(of: "\\\\n", with: "\n") ?? "©⚠️" }
    
    /// The version of the build that identifies an iteration of the bundle. (1-3 period separated integer notation.  only integers and periods supported).  In Swift, this may return the build number.
    var build: String { getInfo("CFBundleVersion") ?? "⚠️"}
    /// The version of the build that identifies an iteration of the bundle. (1-3 period separated integer notation.  only integers and periods supported)
    var version: Version { Version(string: getInfo("CFBundleShortVersionString"), defaultValue: .zero) } // "⚠️.⚠️" - not a valid version
    //public var appVersionShort: String { getInfo("CFBundleShortVersion") }
    
    /// Returns an approximation of when this bundle was built using bundle-file modification metadata.
    ///
    /// The `Info.plist` modification date is preferred. Some modern app bundles do not expose `Info.plist`
    /// as a normal resource path, so the executable modification date is used as a secondary approximation.
    /// Installation and compatibility runtimes can preserve or rewrite either timestamp, so callers should
    /// treat this as diagnostic metadata rather than an embedded compiler timestamp.
    ///
    /// If neither timestamp can be read, `.distantPast` is returned rather than `Date()`. Returning the
    /// current time would make an unknown build date falsely look like a freshly built application.
    var buildDate: Date {
        if let infoPath = path(forResource: "Info", ofType: "plist"),
           let infoAttr = try? FileManager.default.attributesOfItem(atPath: infoPath),
           let infoDate = infoAttr[.modificationDate] as? Date {
            return infoDate
        }
        if let executablePath = executableURL?.path,
           let executableAttr = try? FileManager.default.attributesOfItem(atPath: executablePath),
           let executableDate = executableAttr[.modificationDate] as? Date {
            return executableDate
        }
        return .distantPast
    }
    
    /// Returns a number representing the time that this bundle was built.
    var buildNumber: Int {
        Int(string: buildDate.numericDateTime, defaultValue: -1)
    }
    
    fileprivate func getInfo(_ str: String) -> String? { infoDictionary?[str] as? String }
    
#if compiler(>=5.9)
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    @MainActor
    static var tests: [TestCase] = [
        TestCase("Bundle Tests", {
            // Report every active runtime classification before checking bundle metadata.
            // SF Symbols are named vector assets rather than Unicode characters, so use each
            // environment's portable emoji when configured and retain a text-only fallback.
            let environmentLabels = await Build.environments().map { environment in
                Compatibility.settings.debugEmojiSupported ? "\(environment.emoji) \(environment.label)" : environment.label
            }.joined(separator: "\n  ")
            debug("Active Build environments:\n  \(environmentLabels)", level: .DEBUG)

            try expect(!Bundle.main.name.isEmpty, "Expected bundle name but got: \(Bundle.main.name)")
            try expect(!Bundle.main.displayName.isEmpty, "Expected bundle display name but got: \(Bundle.main.displayName)")
            try expect(!Bundle.main.appName.isEmpty, "Expected bundle app name but got: \(Bundle.main.appName)")
            try expect(!Bundle.main.language.isEmpty, "Expected bundle language but got: \(Bundle.main.language)")
            try expect(!Bundle.main.identifier.isEmpty, "Expected bundle identifier but got: \(Bundle.main.identifier)")
            try expect(!Bundle.main.copyright.isEmpty, "Expected bundle copyright but got: \(Bundle.main.copyright)")
            try expect(!Bundle.main.build.isEmpty, "Expected bundle build but got: \(Bundle.main.build)")
            // SwiftPM's generated PackageTests runner is not an app bundle and does not
            // carry CFBundleShortVersionString, so its documented fallback is Version.zero.
            // Only require a release-style version when Bundle.main is an actual app.
            if Build.isApp {
                try expect(Bundle.main.version > "0.1", "Expected app bundle version but got: \(Bundle.main.version)")
            }

            // Build age is intentionally diagnostic rather than pass/fail. An installed application can
            // legitimately be months old, and SwiftPM/Designed-for-iPad can expose different bundle-file
            // timestamps. `swift test` also runs inside SwiftPM's generated test runner rather than the app.
            let buildDate = Bundle.main.buildDate
            if buildDate == .distantPast {
                // Metadata availability varies by runner/runtime. The helper reports an explicit sentinel
                // instead of fabricating a fresh Date(), but absence alone is not a library-test failure.
                debug("Bundle build-date metadata is unavailable for this runtime.", level: .DEBUG)
            } else {
                debug("Bundle file modification date (buildDate): \(buildDate)", level: .DEBUG)
                try expect(buildDate < Date.tomorrow,
                           "Expected bundle metadata date not to be in the future but got: \(buildDate)")
                try expect(Bundle.main.buildNumber > 0, "Expected a numeric build date for: \(buildDate)")
                if buildDate < Date.yesterday {
                    // An older installed application is expected and valid. Keep this visible for diagnostic
                    // purposes without turning normal app age into a failed reusable test.
                    debug("Bundle is an older installed/test build; buildDate freshness is not a test failure.", level: .DEBUG)
                }
            }
            try expect(!String.appIconName.isEmpty, "Expected app icon name but got: \(String.appIconName)")
        }),
    ]
#endif
}

public extension String {
    static let defaultAppIconName = "AppIcon"

    /// Fetch the app icon name from the bundle.  Should work regardless of platform.  If no app icon found, will return `.defaultAppIconName`
    static var appIconName: String {
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primaryIcon = icons["CFBundlePrimaryIcon"] {
            if let primaryIcon = primaryIcon as? String {
                return primaryIcon
            } else if let primaryIcon = primaryIcon as? [String: Any],
                let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
                      let lastIcon = iconFiles.last {
                return lastIcon
            }
        }
        return .defaultAppIconName
    }
}
#endif
