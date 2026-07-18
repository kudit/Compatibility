//
//  IntegrationTests.swift
//  Compatibility
//
//  Created by OpenAI on 7/17/26.
//

#if compiler(>=5.9) && !(os(WASM) || os(WASI))
/// Opt-in tests that exercise live services and user-facing system facilities.
///
/// Set `INTEGRATION_TESTING=1` in the scheme, process environment, or launched test app to enable these
/// checks. Keeping them in the shared collection makes the same integration coverage available in Xcode,
/// Swift Testing, and the in-app test interface without making normal test runs depend on external state.
@available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
@MainActor
internal let integrationTests: [Test] = {
    var tests = [
        Test("GitHub license loading") {
            guard Build.runsIntegrationTests else {
                return
            }
            let defaultLicense = await ModuleTestFixtureAccess.openSourceLicense
            try expect(defaultLicense == nil, "A private module should not expose a license")

            if let compatibilityLicense = await Compatibility.openSourceLicense {
                // Online runs receive GitHub's Apache license; unavailable requests return documented repository guidance.
                let fetchedLicense = compatibilityLicense.contains("Apache License") && compatibilityLicense.contains("Version 2.0")
                let repositoryFallback = compatibilityLicense.contains(Compatibility.openSourceRepository ?? "")
                try expect(fetchedLicense || repositoryFallback, "Expected either the Apache 2.0 license or repository guidance")
            } else {
                try expect(false, "An open-source module should fall back to repository guidance")
            }
        },
        Test("System pasteboard round trip") { @MainActor in
            guard Build.runsIntegrationTests else {
                return
            }
            let pasteboard = Pasteboard.system
            let originalItems = pasteboard.read()
            defer {
                // Restore every typed item even when the integration assertion fails.
                pasteboard.copy(originalItems)
            }
            pasteboard.copy("Compatibility system pasteboard integration test")
            try expect(pasteboard.readString() == "Compatibility system pasteboard integration test", "Expected system pasteboard text to round-trip")
        },
    ]
#if canImport(Combine) && canImport(Foundation)
    tests.append(Test("iCloud ubiquitous store round trip") {
        guard Build.runsIntegrationTests else {
            return
        }
        let store = NSUbiquitousKeyValueStore.default
        guard store.synchronize() else {
            // An unavailable account is a supported environment rather than a unit-test failure.
            return
        }
        let key = "Compatibility.IntegrationTests.\(UUID().uuidString)"
        defer {
            // A unique key avoids user collisions and is always removed after the live service check.
            store.removeObject(forKey: key)
            store.synchronize()
        }
        store.set("value", forKey: key)
        try expect(store.string(forKey: key) == "value", "Expected the ubiquitous store value to round-trip")
    })
#endif
    return tests
}()

/// A private conformer used only to verify the default nil license without exposing test API.
private enum ModuleTestFixtureAccess: Module {
    static let version: Version = "0.0.0"
}
#else
/// Integration tests are unavailable on toolchains without the custom asynchronous test runtime.
internal let integrationTests = [Test]()
#endif
