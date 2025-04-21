//
//  CompatibilityTests.swift
//  CompatibilityTests
//
//  Created by Ben Ku on 4/17/25.
//
//#if canImport(Testing) && compiler(>=6.0)

// @testable // fails to include package module for testing.
// Testing is only supported with Swift 5.9+
#if compiler(>=5.9) && canImport(Compatibility) && canImport(Testing)
import Compatibility
import Testing

@Suite
struct CompatibilityTests {

    @Test
    func testEnumRotation() {
        var e = CloudStatus.notSupported
        #expect(e == .notSupported)
        e++
        #expect(e == .available)
        e++
        #expect(e == .unavailable)
        e++
        #expect(e == .notSupported)
    }
    
    @Test
    @MainActor
    @available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
    func testValidIdentifier() {
        let application = Application.main
        #expect(application.appIdentifier == "com.apple.dt.xctest.tool")
        #expect(application.version == "16.0")
    }
    
    @Test
    @MainActor
    @available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
    func testTests() {
        let namedTests = Test.namedTests
        for (name, tests) in namedTests {
            debug("Running \(name) tests...")
            for test in tests {
                test.run()
            }
        }
    }
}
#endif
