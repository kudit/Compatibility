//
//  ModuleTestEntryTests.swift
//  CompatibilityTests
//
//  Exercises the reusable CompatibilityTesting adapter through Swift Testing.
//

#if compiler(>=5.9) && canImport(Compatibility) && canImport(CompatibilityTesting) && canImport(Testing)
import Compatibility
import CompatibilityTesting
import Testing

@Suite("Compatibility Module Test Entries")
struct ModuleTestEntryTests {
    /// Presents every reusable Compatibility `TestCase` as its own named Swift Testing argument.
    @Test(
        "Compatibility Module Test",
        arguments: await MainActor.run {
            ModuleTestEntry.entries(
                for: Compatibility.self,
                tests: Compatibility.tests
            )
        }
    )
    @MainActor
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    func moduleTest(entry: ModuleTestEntry) async throws {
        try await entry.execute()
    }

    /// Simple static control used to verify that Xcode discovers and expands parameterized cases.
    @Test("Parameter display test", arguments: [1, 2, 3])
    func parameterDisplayTest(value: Int) {
        #expect((1...3).contains(value))
    }
}
#endif
