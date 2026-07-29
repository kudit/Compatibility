//
//  Compatibility.swift
//  
//
//  Created by Ben Ku on 7/5/2024.
//  Copyright © 2026 Kudit, LLC. All rights reserved.
//

public enum Compatibility: Module {
    /// The version of the Compatibility Library since cannot get directly from Package.swift.
    public static let version: Version = "1.18.3"

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
            return details
        }
        return applicationDetails + moduleInfo
#else
        return moduleInfo
#endif
    }
}
