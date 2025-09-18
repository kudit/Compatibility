//
//  Application.swift
//
//
//  Created by Ben Ku on 6/30/16.
//  Copyright © 2016 Kudit. All rights reserved.
//

extension String {
    public static let legacyLastRunVersionKey = "last_run_version" // legacy (single version string) - only ever stored in UserDefaults.
    public static let localAppVersionsRunKey = "kuditVersions" // previous for compatibility (also only ever stored in UserDefaults)
    public static let appVersionsRunKey = "appVersionsRun" // modern support

    static let appTestLastRunKey = "appTestLastRun"

    public static let unknownAppIdentifier = "com.unknown.unknown"
}

@MainActor
@available(iOS 13, tvOS 13, watchOS 6, *)
public class Application: ObservableObject { // cannot automatically conform to CustomStringConvertible since it's actor-isolated...
    @MainActor
    public static var baseDomain = "com.kudit"

    @MainActor
    public static let main = Application()

    // MARK: - Compiler information
    
    /// will be true if we're in a debug configuration and false if we're building for release
    nonisolated // Not @MainActor
    static let isDebug = _isDebugAssertConfiguration()
    
    // Documentation on the following compiler directives: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/statements/#Compiler-Control-Statements
    
    /// Returns the version number of Swift being used to compile
    static var compilerVersion: String {
#if compiler(>=9.0)
        "X.x"
#elseif compiler(>=8.0)
        "8.x"
#elseif compiler(>=7.0)
        "7.x"
#elseif compiler(>=6.5)
        "6.x"
#elseif compiler(>=6.4)
        "6.4"
#elseif compiler(>=6.3)
        "6.3"
#elseif compiler(>=6.2)
        "6.2"
#elseif compiler(>=6.1)
        "6.1"
#elseif compiler(>=6.0)
        "6.0"
#elseif compiler(>=5.12)
        "5.12"
#elseif compiler(>=5.11)
        "5.11"
#elseif compiler(>=5.10)
        "5.10"
#elseif compiler(>=5.9)
        "5.9"
#elseif compiler(>=5.8)
        "5.8"
#elseif compiler(>=5.7)
        "5.7"
#elseif compiler(>=4.0)
        "4.x"
#elseif compiler(>=3.0)
        "3.x"
#elseif compiler(>=2.0)
        "2.x"
#elseif compiler(>=1.0)
        "1.x"
#else
        "Unsupported"
#endif
    }
    
    /// Returns the version number of Swift being used to run?
    static var swiftVersion: String {
#if swift(>=9.0)
        "X.x"
#elseif swift(>=8.0)
        "8.x"
#elseif swift(>=7.0)
        "7.x"
#elseif swift(>=6.5)
        "6.x"
#elseif swift(>=6.4)
        "6.4"
#elseif swift(>=6.3)
        "6.3"
#elseif swift(>=6.2)
        "6.2"
#elseif swift(>=6.1)
        "6.1"
#elseif swift(>=6.0)
        "6.0"
#elseif swift(>=5.12)
        "5.12"
#elseif swift(>=5.11)
        "5.11"
#elseif swift(>=5.10)
        "5.10"
#elseif swift(>=5.9)
        "5.9"
#elseif swift(>=5.8)
        "5.8"
#elseif swift(>=5.7)
        "5.7"
#elseif swift(>=4.0)
        "4.x"
#elseif swift(>=3.0)
        "3.x"
#elseif swift(>=2.0)
        "2.x"
#elseif swift(>=1.0)
        "1.x"
#else
        "Unsupported"
#endif
    }
    
    // MARK: - Environmental info
    /// Returns `true` if running on the simulator vs actual device.
    nonisolated // Not @MainActor
    static var isSimulator: Bool {
#if targetEnvironment(simulator)
        // your simulator code
        return true
#else
        // your real device code
        return false
#endif
    }
    
    // In macOS Playgrounds Preview: swift-playgrounds-dev-previews.swift-playgrounds-app.hdqfptjlmwifrrakcettacbhdkhn.501.KuditFramework
    // In macOS Playgrounds Running: swift-playgrounds-dev-run.swift-playgrounds-app.hdqfptjlmwifrrakcettacbhdkhn.501.KuditFrameworksApp
    // In iPad Playgrounds Preview: swift-playgrounds-dev-previews.swift-playgrounds-app.agxhnwfqkxciovauscbmuhqswxkm.501.KuditFramework
    // In iPad Playgrounds Running: swift-playgrounds-dev-run.swift-playgrounds-app.agxhnwfqkxciovauscbmuhqswxkm.501.KuditFrameworksApp
    // warning: {"message":"This code path does I/O on the main thread underneath that can lead to UI responsiveness issues. Consider ways to optimize this code path","antipattern trigger":"+[NSBundle allBundles]","message type":"suppressable","show in console":"0"}
    /// Returns `true` if running in Swift Playgrounds.
    nonisolated // Not @MainActor
    static var isPlayground: Bool {
#if SwiftPlaygrounds
        debug("New Swift Playgrounds test!", level: .WARNING)
        return true
#elseif canImport(Foundation)
        //print("Testing inPlayground: Bundles", Bundle.allBundles.map { $0.bundleIdentifier }.description)")
        if Bundle.allBundles.contains(where: { ($0.bundleIdentifier ?? "").contains("swift-playgrounds") }) {
            //print("in playground")
            return true
        } else {
            //print("not in playground")
            return false
        }
#else
        false
#endif
    }
    
    /// Returns `true` if running in an XCode or Swift Playgrounds #Preview macro.
    nonisolated // Not @MainActor
    static var isPreview: Bool {
#if canImport(Foundation)
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
#else
        false
#endif
    }
    
    /// Returns `true` if NOT running in preview, playground, or simulator.
    nonisolated // Not @MainActor
    static var isRealDevice: Bool {
        return !isPreview && !isPlayground && !isSimulator
    }
    
    /// Returns `true` if is macCatalyst app on macOS
    nonisolated // Not @MainActor
    static var isMacCatalyst: Bool {
#if targetEnvironment(macCatalyst)
        return true
#else
        return false
#endif
    }
    
    @MainActor
    @available(*, deprecated, renamed: "Application.isDebug")
    static var DEBUG: Bool {
        Application.isDebug
    }

#if canImport(Foundation)
    // MARK: - iCloud Support
    /// Use before tracking to disable iCloud checks to prevent crashes if we can't check for iCloud or for simulating behavior without iCloud support for CloudStorage.
    @MainActor
    public static var iCloudSupported = true
    
#if canImport(Combine)
    /// Returns the ubiquityIdentityToken if iCloud is available and nil otherwise.  Can be used to check for iCloud outside of MainActor.
    nonisolated // Not @MainActor
    public static var iCloudToken: (any NSCoding & NSCopying & NSObjectProtocol)? {
        return FileManager.default.ubiquityIdentityToken
    }
#endif
    
    @MainActor
    private static var iCloudPlaygroundPreviewNoticed = false
    
    @MainActor
    public static var iCloudIsEnabled: Bool {
        guard iCloudSupported else {
            debug("iCloud is not supported by this app.", level: .DEBUG)
            return false
        }
        if isPlayground || isPreview {
            debug("iCloud works oddly in playgrounds and previews so don't actually support.", level: iCloudPlaygroundPreviewNoticed ? .SILENT : .DEBUG)
            // only output once per session otherwise this is very chatty
            iCloudPlaygroundPreviewNoticed = true
            return false
        }
#if !canImport(Combine)
        return false
#elseif !os(watchOS)
        // CloudKit clients should not use this token as a way to identify whether the iCloud account is logged in. Instead, use accountStatus(completionHandler:) or fetchUserRecordID(completionHandler:).
        guard let token = iCloudToken else {
            debug("iCloud not available", level: .DEBUG)
            return false
        }
        debug("iCloud logged in with token `\(token)`", level: .SILENT)
        return true
#else
        debug("watchOS can't get the ubiquityIdentityToken but can support cloud storage.", level: .NOTICE)
        return true
#endif
    }
    
    @MainActor
    public static var iCloudStatus: CloudStatus {
        guard Self.iCloudSupported else {
            return .notSupported
        }
        if iCloudIsEnabled {
            return .available
        } else {
            return .unavailable
        }
    }
    
    /// Place `Application.track()` in `application(_:didFinishLaunchingWithOptions:)` or @main struct init() function to enable version tracking.
    @MainActor
    public static func track(file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        // Calling Application.main is what initializes the application and does the tracking.  This really should only be called once.  TODO: Should we check to make sure this isn't called twice??  Application.main singleton should only be inited once.
        debug("Application Tracking:\n\(Application.main.description)", level: .NOTICE, file: file, function: function, line: line, column: column)
    }

    // MARK: - Application information
    /// Human readable display name for the application.
    public let name = Bundle.main.name
    
    /// Name that appears on the Home Screen
    public let appName = Bundle.main.appName
    
    /// The fully qualified reverse dot notation from Bundle.main.bundleIdentifier like com.kudit.appName
    public let appIdentifier: String = {
        guard var identifier = Bundle.main.bundleIdentifier else {
            return .unknownAppIdentifier
        }
        // when running in playgrounds preview, identifier may be: swift-playgrounds-dev-previews.swift-playgrounds-app.hdqfptjlmwifrrakcettacbhdkhn.501.KuditFramework
        // swift-playgrounds-dev-previews.swift-playgrounds-app.cmofpjkqydaoovajzscjkvydowkt.501.Compatibility
        // when running from playgrounds, identifier may be: swift-playgrounds-dev-run.swift-playgrounds-app.hdqfptjlmwifrrakcettacbhdkhn.501.KuditFrameworksApp
        
        // convert to normal identifier (assumes will be com.kudit.<lastcomponent>
        // for testing, if this is KuditFrameworks, we should pull the unknown identifier FAQs
        let lastComponent = identifier.components(separatedBy: ".").last // should never really be nil
        if let lastComponent, identifier.contains("swift-playgrounds-dev") {
            let originalIdentifier = identifier // save since we're about to change the identifier and delayed code gets the new value not the original captured value
            Compatibility.main { // required or will not actually print
                debug("Swift Playgrounds Dev environment.  Replacing identifier: \(originalIdentifier)", level: .DEBUG)
            }
            identifier = "\(Application.baseDomain).\(lastComponent.replacingOccurrences(of: "-", with: ""))"
        }
        // NEXT: expose this so other frameworks can check for test frameworks as this is KUDIT specific.  TODO: create a list that this can check to return unknown app identifier?
        if lastComponent == "KuditFramework" || identifier.contains("com.kudit.KuditFrameworksTest") {
            // replace with unknown for KuditFrameworks test output.
            return .unknownAppIdentifier
        }
        return identifier
    }()
    
    /// `true`  if this is the first time the app has been run, `false` otherwise
    public private(set) var isFirstRun = true // can't be let since self._cloudVersionsRun check requires self access, but basically should only ever set once.
    
#if compiler(>=5.9) && canImport(Combine)
    @CloudStorage(.appVersionsRunKey) private var _cloudVersionsRun: String?
#endif
    private init() {
        // this actually does the tracking
        
        // check for previous versions run in user defaults (legacy)
        // if last_run_version set, add that to preserve legacy format
        let legacyLastRunVersion = UserDefaults.standard.object(forKey: .legacyLastRunVersionKey) as? String // legacy support
        let kuditPreviouslyRunVersions = UserDefaults.standard.object(forKey: .localAppVersionsRunKey) as? [String] // newer support (still local)
        
        let localFirstRun = legacyLastRunVersion == nil && kuditPreviouslyRunVersions == nil
        // if all nil, then isFirstRun is true (cache for the duration of the app running)
#if compiler(>=5.9) && canImport(Combine)
        if #available(watchOS 9, *) {
            // check for previous versions run in cloud store
            isFirstRun = localFirstRun && _cloudVersionsRun == nil
        } else {
            // for older platforms, fallback to legacy behavior
            isFirstRun = localFirstRun
        }
#else
        isFirstRun = localFirstRun
#endif
        if isFirstRun {
            debug("First Run!", level: .NOTICE)
        }
        
        // join all versions run (the beauty of this is it doesn't matter if legacyLastRunVersion is a comma-separated list or a single value - both will work)
        var allVersionsString = "\(legacyLastRunVersion ?? ""),\(kuditPreviouslyRunVersions?.joined(separator: ",") ?? ""),\(version)"
#if compiler(>=5.9) && canImport(Combine)
        if #available(watchOS 9, *) {
            allVersionsString += ",\(_cloudVersionsRun ?? "")"
        }
#endif
        // legacy last_run_version should come before new versions since the rawValue init should sort the values
        let allVersions = [Version](rawValue: allVersionsString)
        if !isFirstRun {
            debug("All versions run: \(allVersions.rawValue)", level: .NOTICE)
        }
#if compiler(>=5.9) && canImport(Combine)
        if #available(watchOS 9, *) {
            // persist back to cloud for other devices and future runs or re-installs (do with delay in case of launch issue where the crash happens at launch)
            delay(0.5) { // technically should still be on the main thread.  Would do @MainActor in but Swift 6 has issues with that
                debug("Setting versions run to: \(allVersions.rawValue)", level: .DEBUG)
                //                debug("Bundle Identifier: \(Bundle.main.identifier)")
                //                debug("Application Identifier: \(Application.main.appIdentifier)")
                // setting Application.main so don't capture mutating self.
                Compatibility.main { // but need to add this to guarantee for compiler issues.
                    Application.main._cloudVersionsRun = allVersions.rawValue
                }
            }
            return
        }
#endif
        // Since future versions will use the cloud version, modifying UserDefaults won't ever be necessary with new versions.  However, if we are building for an old platform, go ahead and use local UserDefaults to store.
        UserDefaults.standard.set(allVersions.map { $0.rawValue }, forKey: .localAppVersionsRunKey)
        UserDefaults.standard.removeObject(forKey: .legacyLastRunVersionKey)
        // UserDefaults.synchronize // don't save in case launch issue where it will crash on launch
    }
    
    /// For debugging, reset all the previously run version information including the cloud versions.  This shouldn't be run on production devices or you risk data loss.
    public func resetVersionsRun() {
        debug("Resetting Versions Run!", level: .WARNING)
        UserDefaults.standard.removeObject(forKey: .legacyLastRunVersionKey)
        UserDefaults.standard.removeObject(forKey: .localAppVersionsRunKey)
#if compiler(>=5.9) && canImport(Combine)
        Application.main._cloudVersionsRun = nil
#endif
    }
    
    // MARK: - Version information
    // NOTE: in Objective C, the key was kCFBundleVersionKey, but that returns the build number in Swift.
    /// Current app version string (not including build)
    public let version = Bundle.main.version
    
    public var debugVersion: String {
        var string = version.rawValue
        if Application.isDebug {
            string.append("b\(Bundle.main.buildNumber)")
        }
        return string
    }
    
    /// List of all versions that have been run since install.  Checks iCloud and reports versions run on other devices.
    public var versionsRun: [Version] {
#if compiler(>=5.9) && canImport(Combine)
        if #available(iOS 13, tvOS 13, watchOS 9, *) {
            return [Version](rawValue: _cloudVersionsRun ?? version.rawValue)
        }
#endif
        // for older platforms, fallback to legacy behavior
        return (UserDefaults.standard.object(forKey: .localAppVersionsRunKey) as? [String])?.map { Version(rawValue: $0) } ?? [version] // newer support (still local)
    }
    
    /// List of all versions that have been run since install.  Excludes the current version run.
    public var previouslyRunVersions: [Version] {
        var versionsRun = versionsRun
        versionsRun.remove(version)
        return versionsRun
    }
    
    public func hasRunVersion(before testVersion: Version) -> Bool {
        for versionRun in versionsRun {
            if versionRun < testVersion {
                return true
            }
        }
        return false
    }
    
    /// Vendor ID (may not be used anywhere since not very helpful)
    //    public var vendorID = UIDevice.current.identifierForVendor.UUIDString
    
    // Note that cannot do conformance to CustomStringConvertible since it requires isolation...
    public var description: String {
        var description = "\(name) (v\(debugVersion))"
        if isFirstRun {
            description += " **First Run!**"
        }
        if versionsRun.count > 1 {
            description += "\nPreviously run versions: \(previouslyRunVersions.map { "v\($0)" }.joined(separator: ", "))"
        }
        description += "\nIdentifier: \(Application.main.appIdentifier)"
        // so we can disable on simple apps and still do tracking without issues.
        description += "\niCloud Status: \(Application.iCloudStatus.description)"
        description += "\nSwift Version: \(Application.swiftVersion)"
        description += "\nCompiler Version: \(Application.compilerVersion)"
        description += "\nCompatibility Version: \(Compatibility.version)"
        return description
    }
#endif
#if compiler(>=5.9)
    @MainActor
    internal static var applicationTests: TestClosure = { @MainActor in // ensure we're running these on the Main Actor so we don't have to worry about Application main actor access.
        try expect(Application.isDebug, "App should not be running in debug mode")
        try expect(Application.isPreview == Application.isPreview, "App Preview test")
        try expect(Application.isSimulator == Application.isSimulator, "App Simulator test")
        try expect(Application.isPlayground == Application.isPlayground, "App Playground test")
        try expect(Application.isRealDevice == Application.isRealDevice, "App Real Device test")
        try expect(Application.isMacCatalyst == Application.isMacCatalyst, "App Mac Catalyst test")
#if canImport(Foundation)
        debugSuppress {
            Compatibility.main {
                Application.main.resetVersionsRun()
                // throws a warning in Swift Playgrounds that this isn't async.
                Application.track()
            }
        }
        try expect(Application.main.isFirstRun == Application.main.isFirstRun, "First Run test")
        try expect(Application.main.versionsRun.count == 1, "Versions Run test")
        try expect(Application.main.hasRunVersion(before: Application.main.version) == false, "Has Run Version test")
        try expect(Application.main.previouslyRunVersions.count == 0, "Previously Run Versions test")
        let expectedDescription = """
\(Application.main.name) (v\(Application.main.debugVersion))\(Application.main.isFirstRun ? " **First Run!**" : "")
Identifier: \(Application.main.appIdentifier)
iCloud Status: \(Application.iCloudStatus.description)
Swift Version: \(Application.swiftVersion)
Compiler Version: \(Application.compilerVersion)
Compatibility Version: \(Compatibility.version)
"""
        try expect(Application.main.description == expectedDescription, "Unexpected app description: \(Application.main.description) (expected: \(expectedDescription))")
#endif
    }

    @MainActor
    static var tests: [Test] = [
        Test("Application Tests", applicationTests),
    ]
#endif
}
