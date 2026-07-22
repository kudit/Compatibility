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
    public static let localAppVersionsRunOnDeviceKey = "kuditVersionsOnDevice" // device-local version history that is intentionally never synced.
    public static let appVersionsRunKey = "appVersionsRun" // modern support

    static let appTestLastRunKey = "appTestLastRun"

    public static let unknownAppIdentifier = "com.unknown.unknown"
}

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Application
@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *) // required since CloudStorage requires this and this is a property.  This is okay since the Build settings have been pulled out and this manages App specific behavior which isn't usually necessarily for a command line tool or non-app like a service.
#if !(os(WASM) || os(WASI))
@MainActor // Application owns observable, cloud-backed, and persisted app state, so one actor boundary keeps that shared state coherent.
#endif
public class Application: ObservableObject { // The private initializer preserves singleton construction without unnecessarily forbidding future in-module subclassing.
    public static var baseDomain = "com.kudit"

    /// Forces ``main`` to report ``String/unknownAppIdentifier`` instead of the host bundle identifier.
    ///
    /// A test app may change this around a synchronous assertion even when another test has already initialized
    /// ``main``. The value is main-actor isolated so reads and writes remain serialized.
    public static var forceUnknownAppIdentifierForTesting = false

    public static let main = Application()

    // MARK: - Compiler information (moved to Build - included here to prevent breaking compatibility).
    /// will be true if we're in a debug configuration and false if we're building for release
    @available(*, deprecated, renamed: "Build.isDebug")
    nonisolated // Not @MainActor
    public static let isDebug = Build.isDebug

    /// Returns the version number of Swift being used to compile (use these checks for Swift Package Index version checks).
    @available(*, deprecated, renamed: "Build.compilerVersion")
    nonisolated // Not @MainActor
    public static let compilerVersion = Build.compilerVersion

    /// Returns the version number of Swift being used to run?
    @available(*, deprecated, renamed: "Build.swiftVersion")
    nonisolated // Not @MainActor
    public static let swiftVersion = Build.swiftVersion

    /// Returns `true` if running on the simulator vs actual device.
    @available(*, deprecated, renamed: "Build.isSimulator")
    nonisolated // Not @MainActor
    public static let isSimulator = Build.isSimulator

    /// Returns `true` if running in Swift Playgrounds.
    @available(*, deprecated, renamed: "Build.isPlayground")
    nonisolated // Not @MainActor
    public static let isPlayground = Build.isPlayground

    /// Returns `true` if running in an Xcode or Swift Playgrounds `#Preview` macro.
    @available(*, deprecated, renamed: "Build.isPreview")
    nonisolated // Not @MainActor
    public static let isPreview = Build.isPreview

    /// Returns `true` if NOT running in preview, playground, or simulator.
    @available(*, deprecated, renamed: "Build.isRealDevice")
    nonisolated // Not @MainActor
    public static let isRealDevice = Build.isRealDevice

    /// Returns `true` if is macCatalyst app on macOS
    @available(*, deprecated, renamed: "Build.isMacCatalyst")
    nonisolated // Not @MainActor
    public static let isMacCatalyst = Build.isMacCatalyst

    @available(*, deprecated, renamed: "Build.isDebug")
    nonisolated // This computed compatibility forwarding value reads only nonisolated Build state.
    public static let DEBUG = Build.isDebug

#if canImport(Foundation) && !(os(WASM) || os(WASI))
    // MARK: - iCloud Support
    /// Use before tracking to disable iCloud checks to prevent crashes if we can't check for iCloud or for simulating behavior without iCloud support for CloudStorage.
    public static var iCloudSupported = true

#if canImport(Combine)
    /// Returns the current opaque iCloud identity token, or `nil` when no token is available.
    ///
    /// This forwards `FileManager.ubiquityIdentityToken` without requiring access to the main actor. The
    /// token can detect an iCloud identity change, but CloudKit clients should use account-status APIs
    /// rather than treating the token as proof that a particular container is currently available.
    nonisolated
    public static var iCloudToken: (any NSCoding & NSCopying & NSObjectProtocol)? {
        return FileManager.default.ubiquityIdentityToken
    }

    /// Whether Foundation currently exposes an iCloud identity token.
    ///
    /// This nonisolated check is available to services that cannot hop to the main actor. When main-actor
    /// access is available, prefer ``iCloudIsEnabled`` because it also respects app support, previews,
    /// Swift Playgrounds, and platform-specific behavior.
    nonisolated
    public static var iCloudAvailable: Bool {
        iCloudToken != nil
    }
#endif

    private static var iCloudPlaygroundPreviewNoticed = false

    /// Whether this application should currently use its configured iCloud storage.
    ///
    /// Prefer this main-actor-isolated result in application code. It combines ``iCloudSupported`` with
    /// runtime environment restrictions and token availability rather than reporting token presence alone.
    public static var iCloudIsEnabled: Bool {
        guard iCloudSupported else {
            debug("iCloud is not supported by this app.", level: .DEBUG)
            return false
        }
        if Build.isPlayground || Build.isPreview {
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

    /// Enables version tracking and registers modules used by the application.
    ///
    /// Place this in `application(_:didFinishLaunchingWithOptions:)` or the `@main` type's initializer.
    /// Compatibility is always registered automatically. Pass only the highest-level modules used directly
    /// by the application; their ``Module/dependencies`` are discovered recursively.
    ///
    /// - Parameters:
    ///   - modules: Top-level modules used by the application.
    ///   - file: Source file that initiated tracking.
    ///   - function: Source function that initiated tracking.
    ///   - line: Source line that initiated tracking.
    ///   - column: Source column that initiated tracking.
    public static func track(including modules: [Module.Type] = [], file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        // Compatibility supplies Application itself, so it belongs in every tracked application's module report.
        Compatibility.include()
        Build.register(modules)
        // Prevent late mutation once asynchronous support reporting can begin reading the global registry.
        Build.finishModuleRegistration()
        // Calling Application.main is what initializes the application and does the tracking.  This really should only be called once.  TODO: Should we check to make sure this isn't called twice??  Application.main singleton should only be inited once.
        debug("Application Tracking: \(Application.main.appName)", level: .NOTICE, file: file, function: function, line: line, column: column) // Initialize persisted version state synchronously before detached reporting begins.
        // Defer the complete report so modules may calculate or fetch metadata without blocking application launch.
        Task.background {
            let description = await Application.main.loadDetailedDescription()
            Task.main {
                debug("Application Detailed Tracking:\n\(description)", level: .NOTICE, file: file, function: function, line: line, column: column)
            }
        }
    }

    // MARK: - Application information
    /// Human readable display name for the application.
    nonisolated // The bundle name is captured once as an immutable support-reporting snapshot.
    public let name = Bundle.main.name
    
    /// Name that appears on the Home Screen
    nonisolated // The executable name is captured once as an immutable support-reporting snapshot.
    public let appName = Bundle.main.appName
    
    /// The fully qualified reverse dot notation from Bundle.main.bundleIdentifier like com.kudit.appName.
    public var appIdentifier: String {
        if Application.forceUnknownAppIdentifierForTesting {
            // Resolve the override at access time so hosted tests can opt in after the singleton was initialized.
            return .unknownAppIdentifier
        }
        return detectedAppIdentifier
    }

    /// Captures the real host identifier once because bundle metadata does not change during the process.
    private let detectedAppIdentifier: String = {
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
            debug("Swift Playgrounds Dev environment.  Replacing identifier: \(originalIdentifier)", level: .DEBUG)
            identifier = "\(Application.baseDomain).\(lastComponent.replacingOccurrences(of: "-", with: ""))"
        }
        // Preserve legacy Compatibility demo identifiers while new test apps use forceUnknownAppIdentifierForTesting.
        if lastComponent == "KuditFramework" || identifier.contains("com.kudit.KuditFrameworksTest") {
            // replace with unknown for KuditFrameworks test output.
            return .unknownAppIdentifier
        }
        return identifier
    }()
    
    /// `true`  if this is the first time the app has been run, `false` otherwise
    public private(set) var isFirstRun = true // can't be let since self._cloudVersionsRun check requires self access, but basically should only ever set once.

    /// `true` if this is the first time the app has been run on this device/install, ignoring versions synced from other devices.
    nonisolated // Initialization captures this device-local result once and it never changes afterward.
    public let isFirstRunOnDevice: Bool
    
#if compiler(>=5.9) && canImport(Combine)
    @CloudStorage(.appVersionsRunKey) private var _cloudVersionsRun: String?
#endif
    private init() {
        // this actually does the tracking
        
        // check for previous versions run in user defaults (legacy)
        // if last_run_version set, add that to preserve legacy format
        let legacyLastRunVersion = UserDefaults.standard.object(forKey: .legacyLastRunVersionKey) as? String // legacy support
        let kuditPreviouslyRunVersions = UserDefaults.standard.object(forKey: .localAppVersionsRunKey) as? [String] // newer support (still local)
        let localVersionsRunOnDevice = UserDefaults.standard.object(forKey: .localAppVersionsRunOnDeviceKey) as? [String]
        
        let localFirstRun = legacyLastRunVersion == nil && kuditPreviouslyRunVersions == nil
        isFirstRunOnDevice = localFirstRun && localVersionsRunOnDevice == nil
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
        if isFirstRunOnDevice && !isFirstRun {
            debug("First Run On This Device!", level: .NOTICE)
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

        // Keep a separate local-only version list so apps can tell first launch on this device from first launch across iCloud-synced devices.
        let allLocalVersions = [Version](rawValue: "\(legacyLastRunVersion ?? ""),\(kuditPreviouslyRunVersions?.joined(separator: ",") ?? ""),\(localVersionsRunOnDevice?.joined(separator: ",") ?? ""),\(version)")
        UserDefaults.standard.set(allLocalVersions.map { $0.rawValue }, forKey: .localAppVersionsRunOnDeviceKey)
#if compiler(>=5.9) && canImport(Combine)
        if #available(watchOS 9, *) {
            // persist back to cloud for other devices and future runs or re-installs (do with delay in case of launch issue where the crash happens at launch)
            Task.delay(0.5) { // technically should still be on the main thread.  Would do @MainActor in but Swift 6 has issues with that
                debug("Setting versions run to: \(allVersions.rawValue)", level: .DEBUG)
                //                debug("Bundle Identifier: \(Bundle.main.identifier)")
                //                debug("Application Identifier: \(Application.main.appIdentifier)")
                // setting Application.main so don't capture mutating self.
                Task.main { // Explicitly return to the main actor before updating shared application state.
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
        UserDefaults.standard.removeObject(forKey: .localAppVersionsRunOnDeviceKey)
#if compiler(>=5.9) && canImport(Combine)
        Application.main._cloudVersionsRun = nil
#endif
    }
    
    // MARK: - Version information
    // NOTE: in Objective C, the key was kCFBundleVersionKey, but that returns the build number in Swift.
    /// Current app version string (not including build)
    nonisolated // Not @MainActor
    public let version = Bundle.main.version
    
    /// The immutable application version with the debug build number appended for diagnostic display.
    ///
    /// This value is nonisolated because both the release version and bundle build number are fixed for the
    /// lifetime of the process, allowing support reporting to read it without crossing onto the main actor.
    nonisolated
    public var debugVersion: String {
        var string = version.rawValue
        if Build.isDebug {
            string.append("b\(Bundle.main.buildNumber)")
        }
        return string
    }
    
    /// List of all versions that have been run since install.  Checks iCloud and reports versions run on other devices.
    public var versionsRun: [Version] {
#if compiler(>=5.9) && canImport(Combine)
        if #available(iOS 13, macOS 10.15, tvOS 13, watchOS 9, *) {
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
    
    /// Structured application information immediately available on the main actor.
    ///
    /// The fields include the current version and, when available, versions that previously ran. First-run
    /// annotations remain attached to the version so clients do not need to reproduce version-tracking rules.
    public var info: [Field] {
        var info = [Field]()
        var versionInfo = "v\(debugVersion)"
        if isFirstRun {
            versionInfo += " **First Run!**"
        } else if isFirstRunOnDevice {
            versionInfo += " **First Run On Device!**"
        }
        info.append(Field(name, versionInfo))
        if versionsRun.count > 1 {
            info.append(Field("Previously run versions", previouslyRunVersions.map { "v\($0)" }.joined(separator: ", ")))
        }
        return info
    }

    /// An immediate application and module description that does not wait for deferred module metadata.
    ///
    /// Use ``loadDetailedDescription()`` when the report should also include every deferred field returned by
    /// ``Module/loadDetailedModuleInfo()``.
    public var description: String {
        let moduleDescription = Build.allModules.description
        // Avoid a trailing newline when callers inspect Application before registering any modules.
        return moduleDescription.isEmpty ? info.description : info.description + "\n" + moduleDescription
    }

    /// Builds a complete detailed description after awaiting asynchronously generated module details.
    nonisolated
    public func loadDetailedDescription() async -> String {
#if !(os(WASM) || os(WASI))
        // Capture actor-owned application state briefly, then allow module loading and formatting to proceed off actor.
        let appInfo = await MainActor.run { self.info.description }
        let moduleInfo = await Build.allModules.loadDetailedDescription()
        // Preserve clean app-only output when no modules were registered before detailed reporting.
        return moduleInfo.isEmpty ? appInfo : appInfo + "\n" + moduleInfo
#else
        return description
#endif
    }
#endif

#if compiler(>=5.9)
#if canImport(Foundation) && !(os(WASM) || os(WASI))
    internal static var applicationTests: TestClosure = { @MainActor in // ensure we're running these on the Main Actor so we don't have to worry about Application main actor access.
        try expect(Build.isDebug, "App should not be running in debug mode")
        for environment in Build.Environment.allCases {
            try expect(environment.test == environment.test, "App \(environment) test")
        }
        debugSuppress {
            // This test closure already runs on the main actor, so perform setup synchronously before assertions.
            Application.main.resetVersionsRun()
            Application.track()
        }
        try expect(Application.main.isFirstRun == Application.main.isFirstRun, "First Run test")
        try expect(Application.main.isFirstRunOnDevice == Application.main.isFirstRunOnDevice, "First Run On Device test")
        try expect(Application.main.versionsRun.count == 1, "Versions Run test")
        try expect(Application.main.hasRunVersion(before: Application.main.version) == false, "Has Run Version test")
        try expect(Application.main.previouslyRunVersions.count == 0, "Previously Run Versions test")
        let expectedDescription = Application.main.info.description + "\n" + Build.allModules.description
        // Use the active registry so these shared tests also pass in apps that register additional top-level modules.
        try expect(Application.main.description == expectedDescription, "Unexpected app description: \(Application.main.description) (expected: \(expectedDescription))")
        try expect(Build.allModules.contains { $0.moduleIdentifier == Compatibility.moduleIdentifier }, "Application.track() should register Compatibility")
        let detailedDescription = await Application.main.loadDetailedDescription()
        try expect(detailedDescription.contains("Swift Version: \(Build.swiftVersion)"), "The asynchronous detailed description should include module metadata")
        try expect(detailedDescription.contains("\(Compatibility.moduleName) Framework Version: \(Compatibility.version)"), "The asynchronous detailed description should include registered module versions")
        try expect(detailedDescription.contains("App Identifier: \(Application.main.appIdentifier)"), "The asynchronous detailed description should include the app's identifier, which the immediate description omits")
    }
#else
    internal static var applicationTests: TestClosure = {
        try expect(Build.isDebug, "App should not be running in debug mode")
        for environment in Build.Environment.allCases {
            try expect(environment.test == environment.test, "App \(environment) test")
        }
    }
#endif

    public static var tests: [TestCase] = [
        TestCase("Application Tests", applicationTests),
    ]
#endif
}
