//
//  Compatibility.swift
//  
//
//  Created by Ben Ku on 7/5/2024.
//  Copyright © 2026 Kudit, LLC. All rights reserved.
//

public enum Compatibility: Module {
    /// The version of the Compatibility Library since cannot get directly from Package.swift.
    public static let version: Version = "1.18.0"

    /// Public source repository for Compatibility so support reports can direct developers to its source and issue history.
    ///
    /// The explicit optional type is required to witness ``Module/openSourceRepository`` rather than
    /// accidentally selecting the protocol extension's default `nil` implementation.
    public static let openSourceRepository: String? = "https://github.com/kudit/Compatibility"

    /// Immediately available Compatibility and runtime information suitable for display or human-readable reports.
    ///
    /// These portable build fields remain synchronous and nonisolated so command-line, older Apple,
    /// WASM, and other non-UI clients can always produce meaningful module output.
    public static var moduleInfo: [Field] {
        return [
            Field("Swift Version", Build.swiftVersion, symbol: "swift"),
            Field("Compiler Version", Build.compilerVersion),
        ]
    }

    /// Loads complete module information, including application details where that state is supported.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    public static func loadDetailedModuleInfo() async -> [Field] {
#if canImport(Foundation) && !(os(WASM) || os(WASI))
        // Application is main-actor isolated, so gather only its live values there instead of
        // imposing actor isolation on every Module conformer and every portable metadata field.
        let applicationDetails = await MainActor.run {
            var details = [Field]()
            details += [
                Field("App Identifier", Application.main.appIdentifier),
            ]
            if Application.iCloudSupported {
                // Pull dynamically because iCloud availability can change while the app is running.
                details += [
                    Field("iCloud status", Application.iCloudStatus),
                ]
            }
            details += moduleInfo
            return details
        }
        return applicationDetails
#else
        // Non-Foundation environments still receive every portable field without referencing Application.
        return moduleInfo
#endif
    }
}

#if canImport(Foundation)
@_exported import Foundation
// The following can be added if we want to add back in some funtions for Android or Linux (we're not currently using these personally, so if you do, please feel free to file a pull request).
//#elseif canImport(FoundationNetworking) && canImport(FoundationEssentials) && canImport(FoundationInternationalization) && canImport(FoundationXML)
///*
// Android compatibility: https://skip.tools/blog/android-native-swift-packages/#conditionally-importing-and-using-platform-specific-modules
// */
//@_exported import FoundationNetworking
//@_exported import FoundationEssentials
//@_exported import FoundationInternationalization
//@_exported import FoundationXML
#if canImport(FoundationNetworking)
// Linux separates URLSession and related HTTP types from Foundation; the implementation uses libcurl.
@_exported import FoundationNetworking
#endif
#endif

// NOTE: UNAVAILABLE to mark API as unavailabe for specific versions.
//@available(*, unavailable, message: "use native function rather than backport?")

/*
  
 For module checks to conditionally compile for versions:
 
 canImport(StoreKit)
     iOS 3.0+
     iPadOS 3.0+
     macOS 10.7+
     Mac Catalyst 13.0+
     tvOS 9.0+
     watchOS 6.2+
     visionOS 1.0+
 
 2014 (Swift announced, for OperatingSystemVersion)
 canImport(HealthKit) || canImport(Metal)
     iOS 8.0+ // Health, Metal
     iPadOS 8.0+ // Health, Metal
     macOS 10.10+
     Mac Catalyst 13.0+ // Metal
     tvOS 9.0+ // Metal
     watchOS 2.0+ // Health
     visionOS 1.0+ // Health, Metal

 2015 (initial relase of tvOS)
    iOS 9
    macOS 10.11
 
 2016
    iOS 10
    macOS 10.12
 
 2017
 canImport(CoreML)
    iOS 11
    macOS 10.13 (High Sierra)
    tvOS 11
    watchOS 4
 
 2018
    iOS 12
    macOS 10.14
    tvOS 12
    watchOS 5
 
 2019 (first year macCatalyst and SwiftUI available)
 canImport(SwiftUI) || canImport(Combine)
     iOS 13+
     iPadOS 13.0+
     macOS 10.15+
     Mac Catalyst 13.0+
     tvOS 13+
     watchOS 6+
     visionOS 1.0+
     SF Symbols 1.0

 2020
 canImport(AppleArchive)
     iOS 14+
     iPadOS 14.0+
     macOS 11+
     Mac Catalyst 14.0+
     tvOS 14+
     watchOS 7+
     visionOS 1.0+
     SF Symbols 2.0

 2021
 canImport(GroupActivities)
     iOS 15+ (last supported by iPhone 7)
     iPadOS 15.0+
     macOS 12+ (last supported by Touchbook)
     Mac Catalyst 15.0+
     tvOS 15+
    NOTE: NO WATCH OS SUPPORT (watchOS 8 is the last supported by Series 3)
     visionOS 1.0+
     SF Symbols 3.0

 2022 Swift 5.7 (September)
 canImport(Charts) canImport(AppIntents) canImport(CoreTransferable)
     iOS 16+
     iPadOS 16.0+
     macOS 13+
     Mac Catalyst 16.0+
     tvOS 16+
     watchOS 9+ (minimum for WidgetKit on watchOS - supported in iOS 14 and macOS 11)
     visionOS 1.0+
     SF Symbols 4.0

 2023 Swift 5.8 (March), Swift 5.9 (September) (added #Preview syntax and @availability syntax)
 canImport(SwiftData)
     iOS 17+
     iPadOS 17.0+
     macOS 14+
     Mac Catalyst 17.0+
     tvOS 17+
     watchOS 10+ (practical minimum for WidgetKit (due to requirement of WidgetConfigurationIntent which is only available on iOS 17, macOS 14, and watchOS 10)
     visionOS 1.0+
     SF Symbols 5.0

2024 Swift 5.10 (March), Swift 6 (September)
canImport(Testing)
    iOS 18+
    iPadOS 18+
    macOS 15+
    Mac Catalyst 18+
    tvOS 18+
    watchOS 11+
    visionOS 2+
    SF Symbols 6.0
    Xcode 16
 
 Swift Playgrounds 4.6.4 - Swift 6.0 Compiler
 
 2025 Swift 6.1 (March), Swift 6.2 (September)
    iOS 26+
    iPadOS 26+
    macOS 26+
    Mac Catalyst 26+
    tvOS 26+
    watchOS 26+
    visionOS 26+
    SF Symbols 7.0
    Xcode 26

 In Swift 6.2, Foundation is not available in WASM
 
 */
// MARK: - Configuration

public extension Compatibility {
    // https://medium.com/@aliyasirali/understanding-nonisolated-unsafe-in-swift-incremental-adoption-of-strict-concurrency-2cbb61c9adf4
    // This generates unsafe warnings anyways, so use the simpler version and hope there are no data races (theoretically, if we're only changing on the main thread first thing at init, this shouldn't be a problem)
//    private static var lock = NSLock()
//    private static var _settings = CompatibilityConfiguration()
//    static var settings: CompatibilityConfiguration {
//        get {
//            lock.lock()
//            defer { lock.unlock() }
//            return _settings
//        }
//        set {
//            lock.lock()
//            defer { lock.unlock() }
//            _settings = newValue
//        }
//    }
//
#if compiler(>=5.10)
    static nonisolated(unsafe) var settings = CompatibilityConfiguration()
#else
    static var settings = CompatibilityConfiguration()
#endif
}

// for flags in swift packages: https://stackoverflow.com/questions/38813906/swift-how-to-use-preprocessor-flags-like-if-debug-to-implement-api-keys
//swiftSettings: [
//    .define("VAPOR")
//]
// https://medium.com/@ytyubox/xcode-preprocessing-with-custom-flags-in-swift-4bfde6e7a608

// MARK: - legacy compatibility code deprecations and support
public extension Compatibility { // for brief period where Application wasn't available
    @available(*, deprecated, renamed: "Application.isDebug")
    static let isDebug = _isDebugAssertConfiguration()
}
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Compatibility { // for brief period where Application and Build wasn't available.  Static computed properties apparently aren't supported in extensions in iOS <13?
    // MARK: - Entitlements Information
#if canImport(Foundation) && !(os(WASM) || os(WASI))
    @available(*, deprecated, renamed: "Application.iCloudSupported")
    @MainActor
    static var iCloudSupported: Bool {
        get {
            Application.iCloudSupported
        }
        set {
            Application.iCloudSupported = newValue
        }
    }

    @available(*, deprecated, renamed: "Application.iCloudIsEnabled")
    @MainActor
    static var iCloudIsEnabled: Bool {
        Application.iCloudIsEnabled
    }
    
    @available(*, deprecated, renamed: "Application.iCloudStatus")
    @MainActor
    static var iCloudStatus: CloudStatus {
        Application.iCloudStatus
    }
#endif

    @available(*, deprecated, renamed: "Build.isSimulator")
    static let isSimulator = Build.isSimulator

    @available(*, deprecated, renamed: "Build.isPlayground")
    static let isPlayground = Build.isPlayground
    
    @available(*, deprecated, renamed: "Build.isPreview")
    static let isPreview = Build.isPreview
    
    @available(*, deprecated, renamed: "Build.isMacCatalyst")
    static let isMacCatalyst = Build.isMacCatalyst
}

#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation)
import SwiftUI

@available(iOS 15, macOS 12, tvOS 15, watchOS 9, *)
public struct CompatibilityEnvironmentTestView: View {
#if compiler(>=5.9) && canImport(Combine)
    @CloudStorage(.compatibilityVersionsRunKey) var previouslyRunCompatibilityVersions = Compatibility.version.rawValue
#endif
    /// Complete deferred module information; `nil` keeps the loading state distinct from the portable baseline.
    @State private var loadedModuleInfo: [Field]?

    /// Creates an environment view whose module metadata is loaded after the UI first appears.
    public init() {}

    /// Structured application fields displayed by the environment test view.
    public var applicationInfo: [Field] {
        var info = [
            Field("Name", "\(Application.main.name) (\(Application.main.appName).app)"),
            Field("App Identifier", Application.main.appIdentifier),
            Field("App Version", "v\(Application.main.debugVersion)"),
            Field("is first run", Application.main.isFirstRun),
        ]
        let previousVersions = Application.main.previouslyRunVersions
        if previousVersions.count > 0 {
            info.append(Field("Previously run versions", previousVersions.pretty))
        }
        return info
    }

    /// Structured Compatibility-version and build-mode fields displayed by the environment test view.
    public var compatibilityInfo: [Field] {
        var info = [
            Field("\(Compatibility.moduleName) Version", Compatibility.version),
            Field("is Debug", Build.isDebug),
        ]
#if compiler(>=5.9) && canImport(Combine)
        if previouslyRunCompatibilityVersions != "" && previouslyRunCompatibilityVersions != "\(Compatibility.version.rawValue)" {
            info += [
                Field("Previously run Compatibility versions", previouslyRunCompatibilityVersions),
                Field(nil, "NOTE: This only updates if we're running the DataStore test view and is not guaranteed to be run any other time or from any other app."),
            ]
        }
#endif
        return info
    }

    public var body: some View {
        List {
            FieldSections([
                "Application": applicationInfo,
                Compatibility.moduleName: compatibilityInfo,
                "iCloud": [
                    Field("Supported by app", Application.iCloudSupported),
                    Field("Enabled", Application.iCloudIsEnabled),
                    Field("iCloud status", Application.iCloudStatus),
                ],
            ])
            Section("Module Info") {
                // Show the portable baseline immediately, then replace it with the complete loaded result.
                // This is example code.  Really this only needs to include moduleInfo since the detailed info is already included in other sections.
                let displayedModuleInfo = loadedModuleInfo ?? Compatibility.moduleInfo
                ForEach(displayedModuleInfo.indices, id: \.self) { index in
                    FieldView(displayedModuleInfo[index])
                }
                if loadedModuleInfo == nil {
                    ProgressView("Loading module details…")
                }
            }
            Section("Environment") {
                FieldView(Field("Swift Version", Build.swiftVersion, symbol: "swift"))
                FieldView(Field("Compiler Version", Build.compilerVersion))
                EnvironmentsView(Build.environments())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            FieldSections([
                "Dates": [
                    Field("Now Backport", Date.nowBackport.pretty),
                    Field("Now MySQL", Date.nowBackport.mysqlDateTime),
                    Field("Now Numeric", Date.nowBackport.numericDateTime),
                    Field("Tomorrow", Date.tomorrow.pretty),
                    Field("Tomorrow Midnight", Date.tomorrowMidnight.pretty),
                    Field("Yesterday", Date.yesterday.pretty),
                ],
            ])
        }
        .task {
            // Await potentially slow details without delaying the portable module fields above.
            loadedModuleInfo = await Compatibility.loadDetailedModuleInfo()
        }
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 9, *)
#Preview {
    CompatibilityEnvironmentTestView()
        .backport.scrollContentBackground(.hidden)
        .background(.red)
}
#endif
