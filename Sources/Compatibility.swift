//
//  Compatibility.swift
//  
//
//  Created by Ben Ku on 7/5/2024.
//  Copyright © 2025 Kudit, LLC. All rights reserved.
//

public enum Compatibility {
    /// The version of the Compatibility Library since cannot get directly from Package.swift.
    public static let version: Version = "1.10.15"
}

@_exported import Foundation

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
    macOS 10.13
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
#if !DEBUG
    @available(*, deprecated, renamed: "Application.isDebug")
    static let isDebug = _isDebugAssertConfiguration()
#endif
}
@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Compatibility { // for brief period where Application wasn't available.  Static computed properties apparently aren't supported in extensions in iOS <13?
    // MARK: - Entitlements Information
#if !DEBUG
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
    
    @available(*, deprecated, renamed: "Application.isSimulator")
    static var isSimulator: Bool {
#if targetEnvironment(simulator)
        // your simulator code
        return true
#else
        // your real device code
        return false
#endif
    }

    @available(*, deprecated, renamed: "Application.isPlayground")
    static var isPlayground: Bool {
        //print("Testing inPlayground: Bundles", Bundle.allBundles.map { $0.bundleIdentifier }.description)")
        if Bundle.allBundles.contains(where: { ($0.bundleIdentifier ?? "").contains("swift-playgrounds") }) {
            //print("in playground")
            return true
        } else {
            //print("not in playground")
            return false
        }
    }
    
    @available(*, deprecated, renamed: "Application.isPreview")
    static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    @available(*, deprecated, renamed: "Application.isMacCatalyst")
    static var isMacCatalyst: Bool {
#if targetEnvironment(macCatalyst)
        return true
#else
        return false
#endif
    }
#endif
}

#if !canImport(CoreML) // this isn't available on linux!
extension FileManager {
    var ubiquityIdentityToken: String? { nil }
}
#endif

#if canImport(SwiftUI) && compiler(>=5.9)
import SwiftUI

@available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
public struct TestCheck: View {
    var label: String
    var state: Bool
    public init(_ label: String, _ state: Bool) {
        self.label = label
        self.state = state
    }
    public var body: some View {
        Label(label, systemImage: state ? "checkmark.circle.fill" : "x.square.fill").backport.foregroundStyle(state ? .green : .gray)
    }
}

@available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
#Preview("Test Checks") {
    List {
        TestCheck("True", true)
        TestCheck("False", false)
        Label("True", systemImage: "checkmark.circle.fill").backport.foregroundStyle(.green)
        Label("False", systemImage: "x.square.fill").backport.foregroundStyle(.gray)
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 9, *)
public struct CompatibilityEnvironmentTestView: View {
#if compiler(>=5.9) && canImport(Combine)
    @CloudStorage(.compatibilityVersionsRunKey) var previouslyRunCompatibilityVersions = Compatibility.version.rawValue
#endif
    public init() {}
    public var body: some View {
        List {
//            Text("Double values: \(String(describing: CGFloat(0.2)))")
            Section("Application") {
                Backport.LabeledContent("Name:", value: "\(Application.main.name) (\(Application.main.appName).app)")
                    .backport.focusable(true) // to allow scrolling in tvOS
                Backport.LabeledContent("App Identifier:", value: Application.main.appIdentifier)
                Backport.LabeledContent("App Version:", value: Application.main.debugVersion)
                TestCheck("is first run", Application.main.isFirstRun)
                let previousVersions = Application.main.previouslyRunVersions
                if previousVersions.count > 0 {
                    Text("Previously run versions:")
                    Text("\(previousVersions.pretty)")
                }
            }
            Section("Compatibility") {
                Backport.LabeledContent("Compatibility Version:", value: Compatibility.version.description)
                TestCheck("is Debug", Application.isDebug)
#if compiler(>=5.9) && canImport(Combine)
                if previouslyRunCompatibilityVersions != "" && previouslyRunCompatibilityVersions != "\(Compatibility.version.rawValue)" {
                    Text("Previously run Compatibility versions:")
                    Text("\(previouslyRunCompatibilityVersions)")
                    Text("NOTE: This only updates if we're running the DataStore test view and is not guaranteed to be run any other time or from any other app.").font(.footnote).foregroundStyle(.gray)
                }
#endif
            }
            Section("iCloud") {
                TestCheck("Supported by app", Application.iCloudSupported)
                TestCheck("Enabled", Application.iCloudIsEnabled)
                HStack {
                    Text("iCloud status:")
                    Image(systemName: Application.iCloudStatus.symbolName)
                    Text("\(Application.iCloudStatus.description)")
                }
            }
            Section("Environment") {
                Backport.LabeledContent("Swift Version:", value: Application.swiftVersion)
                TestCheck("isSimulator", Application.isSimulator)
                    .backport.focusable(true) // to allow scrolling in tvOS
                TestCheck("isPlayground", Application.isPlayground)
                TestCheck("isPreview", Application.isPreview)
                TestCheck("isRealDevice", Application.isRealDevice)
                TestCheck("isMacCatalyst", Application.isMacCatalyst)
            }
            Section("Dates") {
                Backport.LabeledContent("Now Backport:", value: Date.nowBackport.pretty)
                Backport.LabeledContent("Now MySQL:", value: Date.nowBackport.mysqlDateTime)
                Backport.LabeledContent("Now File Format:", value: Date.nowBackport.numericDateTime)
                Backport.LabeledContent("Tomorrow:", value: Date.tomorrow.pretty)
                Backport.LabeledContent("Tomorrow Midnight:", value: Date.tomorrowMidnight.pretty)
                    .backport.focusable(true) // to allow scrolling in tvOS
            }
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
