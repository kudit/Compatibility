//
//  Application.swift
//
//
//  Created by Ben Ku on 6/30/16.
//  Copyright © 2016 Kudit. All rights reserved.
//

extension String {
    static let legacyLastRunVersionKey = "last_run_version" // legacy (single version string) - only ever stored in UserDefaults.
    static let localAppVersionsRunKey = "kuditVersions" // previous for compatibility (also only ever stored in UserDefaults)
    static let appVersionsRunKey = "appVersionsRun" // modern support

    public static let unknownAppIdentifier = "com.unknown.unknown"
}


@available(iOS 13, tvOS 13, watchOS 6, *)
@MainActor
public class Application: ObservableObject { // cannot automatically conform to CustomStringConvertible since it's actor-isolated...
    @MainActor
    public static var baseDomain = "com.kudit"
    
    /// will be true if we're in a debug configuration and false if we're building for release
    nonisolated // Not @MainActor
    public static let isDebug = _isDebugAssertConfiguration()

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
    public static var iCloudIsEnabled: Bool {
        guard iCloudSupported else {
            debug("iCloud is not supported by this app.", level: .DEBUG)
            return false
        }
        if isPlayground || isPreview {
            debug("iCloud works oddly in playgrounds and previews so don't actually support.", level: .DEBUG)
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
#else
        debug("watchOS can't get the ubiquityIdentityToken but can support cloud storage.")
#endif
        return true
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
    
    // MARK: - Environmental info
    /// Returns `true` if running on the simulator vs actual device.
    nonisolated // Not @MainActor
    public static var isSimulator: Bool {
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
    public static var isPlayground: Bool {
        //print("Testing inPlayground: Bundles", Bundle.allBundles.map { $0.bundleIdentifier }.description)")
        if Bundle.allBundles.contains(where: { ($0.bundleIdentifier ?? "").contains("swift-playgrounds") }) {
            //print("in playground")
            return true
        } else {
            //print("not in playground")
            return false
        }
    }
    
    /// Returns `true` if running in an XCode or Swift Playgrounds #Preview macro.
    nonisolated // Not @MainActor
    public static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    /// Returns `true` if NOT running in preview, playground, or simulator.
    nonisolated // Not @MainActor
    public static var isRealDevice: Bool {
        return !isPreview && !isPlayground && !isSimulator
    }
    
    /// Returns `true` if is macCatalyst app on macOS
    nonisolated // Not @MainActor
    public static var isMacCatalyst: Bool {
#if targetEnvironment(macCatalyst)
        return true
#else
        return false
#endif
    }

    
    @MainActor
    @available(*, deprecated, renamed: "Compatibility.isDebug")
    public static var DEBUG: Bool {
        return DebugLevel.currentLevel == .DEBUG
    }
    
    /// Place `Application.track()` in `application(_:didFinishLaunchingWithOptions:)` or @main struct init() function to enable version tracking.
    @MainActor
    public static func track(file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        // Calling Application.main is what initializes the application and does the tracking.  This really should only be called once.  TODO: Should we check to make sure this isn't called twice??  Application.main singleton should only be inited once.
        debug("Application Tracking:\n\(Application.main.description)", level: .NOTICE, file: file, function: function, line: line, column: column)
    }
    
    // MARK: - Application information
    @MainActor
    public static let main = Application()

    /// Human readable display name for the application.
    public let name = Bundle.main.name

    /// Name that appears on the Home Screen
    public let appName = Bundle.main.appName

    /// The fully qualified reverse dot notation from Bundle.main.bundleIdentifier like com.kudit.appName
    public let appIdentifier: String = {
        guard var identifier = Bundle.main.bundleIdentifier else {
            return .unknownAppIdentifier
        }
        // when running in preview, identifier may be: swift-playgrounds-dev-previews.swift-playgrounds-app.hdqfptjlmwifrrakcettacbhdkhn.501.KuditFramework
        // when running from playgrounds, identifier may be: swift-playgrounds-dev-run.swift-playgrounds-app.hdqfptjlmwifrrakcettacbhdkhn.501.KuditFrameworksApp
        // convert to normal identifier (assumes will be com.kudit.<lastcomponent>
        // for testing, if this is KuditFrameworks, we should pull the unknown identifier FAQs
        let lastComponent = identifier.components(separatedBy: ".").last // should never really be nil
        if let lastComponent, identifier.contains("swift-playgrounds-dev") {
            identifier = "\(Application.baseDomain).\(lastComponent)"
        }
        // NEXT: expose this so other frameworks can check for test frameworks as this is KUDIT specific.  TODO: create a list that this can check to return unknown app identifier?
        if lastComponent == "KuditFramework" || identifier.contains("com.kudit.KuditFrameworksTest") {
            return .unknownAppIdentifier
        }
        return identifier
    }()

    /// `true`  if this is the first time the app has been run, `false` otherwise
    public private(set) var isFirstRun = true // can't be let since self._cloudVersionsRun check requires self access, but basically should only ever set once.
    
    @CloudStorage(.appVersionsRunKey) private var _cloudVersionsRun: String?
    private init() {
        // this actually does the tracking

        // check for previous versions run in user defaults (legacy)
        // if last_run_version set, add that to preserve legacy format
        let legacyLastRunVersion = UserDefaults.standard.object(forKey: .legacyLastRunVersionKey) as? String // legacy support
        let kuditPreviouslyRunVersions = UserDefaults.standard.object(forKey: .localAppVersionsRunKey) as? [String] // newer support (still local)
        
        let localFirstRun = legacyLastRunVersion == nil && kuditPreviouslyRunVersions == nil
        // if all nil, then isFirstRun is true (cache for the duration of the app running)
        if #available(watchOS 9, *) {
            // check for previous versions run in cloud store
            isFirstRun = localFirstRun && _cloudVersionsRun == nil
        } else {
            // for older platforms, fallback to legacy behavior
            isFirstRun = localFirstRun
        }
        if isFirstRun {
            debug("First Run!", level: .NOTICE)
        }
        
        // join all versions run (the beauty of this is it doesn't matter if legacyLastRunVersion is a comma-separated list or a single value - both will work)
        var allVersionsString = "\(legacyLastRunVersion ?? ""),\(kuditPreviouslyRunVersions?.joined(separator: ",") ?? ""),\(version)"
        if #available(watchOS 9, *) {
            allVersionsString += ",\(_cloudVersionsRun ?? "")"
        }
        // legacy last_run_version should come before new versions since the rawValue init should sort the values
        let allVersions = [Version](rawValue: allVersionsString)
        if !isFirstRun {
            debug("All versions run: \(allVersions.rawValue)", level: .NOTICE)
        }
        if #available(watchOS 9, *) {
            // persist back to cloud for other devices and future runs or re-installs (do with delay in case of launch issue where the crash happens at launch)
            delay(0.5) { // technically should still be on the main thread.  Would do @MainActor in but Swift 6 has issues with that
                debug("Setting versions run to: \(allVersions.rawValue)", level: .DEBUG)
                // setting Application.main so don't capture mutating self.
                Compatibility.main { // but need to add this to guarantee for compiler issues.
                    Application.main._cloudVersionsRun = allVersions.rawValue
                }
            }
        } else {
            // Since future versions will use the cloud version, modifying UserDefaults won't ever be necessary with new versions.  However, if we are building for an old platform, go ahead and use local UserDefaults to store.
            UserDefaults.standard.set(allVersions.map { $0.rawValue }, forKey: .localAppVersionsRunKey)
            UserDefaults.standard.removeObject(forKey: .legacyLastRunVersionKey)
            // UserDefaults.synchronize // don't save in case launch issue where it will crash on launch
        }
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
        if #available(iOS 13, tvOS 13, watchOS 9, *) {
            return [Version](rawValue: _cloudVersionsRun ?? version.rawValue)
        } else {
            // for older platforms, fallback to legacy behavior
            return (UserDefaults.standard.object(forKey: .localAppVersionsRunKey) as? [String])?.map { Version(rawValue: $0) } ?? [version] // newer support (still local)
        }
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
        description += "\nCompatibility Version: \(Compatibility.version)"
        return description
    }
}
