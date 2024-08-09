//
//  Compatibility.swift
//  
//
//  Created by Ben Ku on 7/5/2024.
//  Copyright © 2024 Kudit, LLC. All rights reserved.
//

public enum Compatibility {
    /// The version of the Compatibility Library since cannot get directly from Package.swift.
    public static let version: Version = "1.2.2"
    
    /// will be true if we're in a debug configuration and false if we're building for release
    public static let isDebug = _isDebugAssertConfiguration()
    
    // MARK: - iCloud Support
    /// Use before tracking to disable iCloud checks to prevent crashes if we don't need to use iCloud for DataStore.
    //    @MainActor
    public static var iCloudSupported = true
    
    public static var iCloudIsEnabled: Bool {
        guard Self.iCloudSupported else {
            debug("iCloud is not supported by this app.", level: .DEBUG)
            return false
        }
        if isPlayground || isPreview {
            debug("iCloud works oddly in playgrounds and previews so don't actually support.")
            return false
        }
        guard let token = FileManager.default.ubiquityIdentityToken else {
            debug("iCloud not available", level: .DEBUG)
            return false
        }
        debug("iCloud logged in with token `\(token)`", level: .SILENT)
        return true
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
    
    // MARK: - Environmental info
    /// Returns `true` if running on the simulator vs actual device.
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
    
    /// Returns `true` if running in an XCode or Swift Playgrounds #Preview macro.
    static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    /// Returns `true` if NOT running in preview, playground, or simulator.
    static var isRealDevice: Bool {
        return !isPreview && !isPlayground && !isSimulator
    }
    
    /// Returns `true` if is macCatalyst app on macOS
    static var isMacCatalyst: Bool {
#if targetEnvironment(macCatalyst)
        return true
#else
        return false
#endif
    }
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
    iOS 11
    macOS 10.13
 
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

 2020
 canImport(AppleArchive)
     iOS 14+
     iPadOS 14.0+
     macOS 11+
     Mac Catalyst 14.0+
     tvOS 14+
     watchOS 7+
     visionOS 1.0+
 
 2021
 canImport(GroupActivities)
     iOS 15+ (last supported by iPhone 7)
     iPadOS 15.0+
     macOS 12+ (last supported by Touchbook)
     Mac Catalyst 15.0+
     tvOS 15+
    NOTE: NO WATCH OS SUPPORT
     visionOS 1.0+
 
 2022 Swift 5.7 (September)
 canImport(Charts) canImport(AppIntents)
     iOS 16+
     iPadOS 16.0+
     macOS 13+
     Mac Catalyst 16.0+
     tvOS 16+
     watchOS 9+
     visionOS 1.0+

 2023 Swift 5.8 (March), Swift 5.9 (September) (added #Preview syntax)
 canImport(SwiftData)
     iOS 17+
     iPadOS 17.0+
     macOS 14+
     Mac Catalyst 17.0+
     tvOS 17+
     watchOS 10+
     visionOS 1.0+

2024 Swift 5.10 (March), Swift 6 (September)
canImport(Testing)
    iOS 18+
    iPadOS 18+
    macOS 15+
    Mac Catalyst 18+
    tvOS 18+
    watchOS 11+
    visionOS 2+
 
 */

// This has been a godsend! https://davedelong.com/blog/2021/10/09/simplifying-backwards-compatibility-in-swift/

#if canImport(SwiftUI)
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
    @CloudStorage(.compatibilityVersionsRunKey) var previouslyRunVersions = Compatibility.version.rawValue
    public init() {}
    public var body: some View {
        List {
            Section("Compatibility") {
                Text("Version \(Compatibility.version)")
                TestCheck("is Debug", Compatibility.isDebug)
                Text("Previously run versions:")
                Text("\(previouslyRunVersions)")
            }
            Section("iCloud") {
                TestCheck("Supported by app", Compatibility.iCloudSupported)
                TestCheck("Enabled", Compatibility.iCloudIsEnabled)
                HStack {
                    Text("iCloud status:")
                    Image(systemName: Compatibility.iCloudStatus.symbolName)
                    Text("\(Compatibility.iCloudStatus)")
                }
            }
            Section("Environment") {
                TestCheck("isSimulator", Compatibility.isSimulator)
                TestCheck("isPlayground", Compatibility.isPlayground)
                TestCheck("isPreview", Compatibility.isPreview)
                TestCheck("isRealDevice", Compatibility.isRealDevice)
                TestCheck("isMacCatalyst", Compatibility.isMacCatalyst)
            }
        }
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 9, *)
#Preview {
    CompatibilityEnvironmentTestView()
}

#endif
