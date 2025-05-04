//
//  Bundle.swift
//  Compatibility
//
//  Created by Ben Ku on 6/30/16.
//  Copyright © 2016 Kudit. All rights reserved.
//

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
    var version: Version { Version(getInfo("CFBundleShortVersionString") ?? "⚠️.⚠️") }
    //public var appVersionShort: String { getInfo("CFBundleShortVersion") }
    
    /// Returns the time that this was built
    var buildDate: Date {
        if let infoPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let infoAttr = try? FileManager.default.attributesOfItem(atPath: infoPath),
           let infoDate = infoAttr[.modificationDate] as? Date {
            return infoDate
        }
        return Date()
    }
    
    /// Returns a number representing the time that this bundle was built.
    var buildNumber: Int {
        Int(string: buildDate.numericDateTime, defaultValue: -1)
    }
    
    fileprivate func getInfo(_ str: String) -> String? { infoDictionary?[str] as? String }
    
#if compiler(>=5.9)
    @MainActor
    internal static var bundleTests: TestClosure = {
        try expect(!Bundle.main.name.isEmpty, "Expected bundle name but got: \(Bundle.main.name)")
        try expect(!Bundle.main.displayName.isEmpty, "Expected bundle display name but got: \(Bundle.main.displayName)")
        try expect(!Bundle.main.appName.isEmpty, "Expected bundle app name but got: \(Bundle.main.appName)")
        try expect(!Bundle.main.language.isEmpty, "Expected bundle language but got: \(Bundle.main.language)")
        try expect(!Bundle.main.identifier.isEmpty, "Expected bundle identifier but got: \(Bundle.main.identifier)")
        try expect(!Bundle.main.copyright.isEmpty, "Expected bundle copyright but got: \(Bundle.main.copyright)")
        try expect(!Bundle.main.build.isEmpty, "Expected bundle build but got: \(Bundle.main.build)")
        try expect(Bundle.main.version > "0.1", "Expected bundle version but got: \(Bundle.main.version)")
        try expect(Bundle.main.buildDate > Date.yesterday && Bundle.main.buildDate < Date.tomorrow)
        try expect(Bundle.main.buildNumber > 0)
        try expect(!String.appIconName.isEmpty, "Expected app icon name but got: \(String.appIconName)")
    }

    @available(iOS 13, tvOS 13, watchOS 6, *)
    @MainActor
    static var tests: [Test] = [
        Test("Bundle Tests", bundleTests),
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
