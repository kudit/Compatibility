//
//  Compatibility.swift
//  
//
//  Created by Ben Ku on 7/5/2024.
//  Copyright © 2026 Kudit, LLC. All rights reserved.
//

public enum Compatibility: Module {
    /// The version of the Compatibility Library since cannot get directly from Package.swift.
    public static let version: Version = "1.19.0"

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
#if canImport(Foundation)
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

 #if canImport(Compatibility)
 import Compatibility
 #endif

 #if canImport(Compatibility) && compiler(>=5.8)
 // Compatibility is imported and the Swift compiler is new enough for the feature being used.
 #endif

 */

#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation)
import SwiftUI

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
public struct CompatibilityEnvironmentTestView: View {
    @State private var previouslyRunCompatibilityVersions: [Version] = []
    
    public init() {}
    
    @MainActor
    private var applicationInfo: [Field] {
        var info: [Field] = [
            Field("Application", Application.main.name),
            Field("Version", Application.main.version),
            Field("Build", Bundle.main.build),
            Field("Bundle ID", Application.main.appIdentifier),
        ]
        if Application.iCloudSupported {
            info.append(Field("iCloud", Application.iCloudStatus))
        }
        return info
    }

    @MainActor
    private var compatibilityInfo: [Field] {
        var info = [
            Field("Compatibility", Compatibility.version),
        ]
        info += Compatibility.moduleInfo
        info += Build.environments().map { environment in
            Field(environment.label, environment.test, symbol: environment.symbolName)
        }
        return info
    }

    public var body: some View {
        List {
            FieldSections(applicationInfo)
            FieldSections(compatibilityInfo)
            Section("Environments") {
                EnvironmentsView()
            }
            Section("Previously Run Compatibility Versions") {
                if previouslyRunCompatibilityVersions.isEmpty {
                    Text("None")
                } else {
                    ForEach(previouslyRunCompatibilityVersions, id: \.self) { version in
                        Text(version.description)
                    }
                }
            }
        }
        .task {
            previouslyRunCompatibilityVersions = Application.main.previouslyRunVersions
        }
        .backport.navigationTitle("Compatibility")
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview("Compatibility") {
    CompatibilityEnvironmentTestView()
}
#endif
