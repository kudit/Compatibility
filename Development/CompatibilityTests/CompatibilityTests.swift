//
//  CompatibilityTests.swift
//  CompatibilityTests
//
//  Created by Ben Ku on 4/17/25.
//

// @testable // fails to include package module for testing.
// Testing is only supported with Swift 5.9+
#if compiler(>=5.9) && canImport(Compatibility) && canImport(Testing)
import Compatibility
import Testing
import SwiftUI

extension CloudStatus: @retroactive CaseNameConvertible {}

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
        debugSuppress {
            _ = Application.main
        }
        #expect(Application.main.appIdentifier == "com.apple.dt.xctest.tool")
        #expect(Application.main.version == "16.0")
    }
    
    @Test
    func testIntrospection() {
        let dictionary = ["a": 1, "b": 2]
        #expect("a" == dictionary.firstKey(for: 1))
        #expect("b" == dictionary.firstKey(for: 2))
        
        for c in CloudStatus.allCases {
            #expect(String(describing: c).contains(c.caseName))
        }
        
        let config = Compatibility.settings
        for (key, value) in config.allProperties {
            #expect(String(describing: config.allProperties[key]).contains(String(describing: value)), "property \(key) mismatch (should never happen)")
        }
    }
    
    @Test
    @MainActor
    @available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
    func testNamedTests() async throws {
        let namedTests = Test.namedTests
        var ongoingTests = Date.tests // because can't just do = [Test]() for some reason...
        ongoingTests.removeAll()
        for (name, tests) in namedTests {
            debug("Running \(name) tests...")
            for test in tests {
                test.run()
                if !test.isFinished() {
                    ongoingTests.append(test)
                } else {
                    #expect(test.succeeded())
                }
            }
        }
        while ongoingTests.count > 0 {
            await sleep(seconds: 0.01)
            for ongoingTest in ongoingTests {
                if ongoingTest.isFinished() {
                    ongoingTests.removeAll { $0 === ongoingTest }
                    #expect(ongoingTest.succeeded())
                }
            }
        }
    }
    
    @State var value: String?
    @Test
    @MainActor
    @available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
    func testUI() {
        _ = OverlappingVStack {}.body
        _ = OverlappingHStack {}.backport.presentationBackground(.thick)
        _ = ConvertTestView().body
        _ = CompatibilityEnvironmentTestView().body
        _ = ClosureTestView().body
        _ = AllTestsListView().body
        _ = BytesView(label: "label", bytes: 23, font: .body, countStyle: .file, round: true).body
        _ = Placard()
            .embossed()
            .padding(size: 22)
        _ = ClearableTextField(label: "hello", text: $value).body
     }
    
    @Test
    func additionalTests() {
        Compatibility.copyToPasteboard("Testing copying text to pasteboard via Compatibility.swiftpm")
        
        Compatibility.settings.debugLog("hello \(Compatibility.version)")
        
        for status in CloudStatus.allCases {
            debug("Cloud Status: \(status) (\(status.symbolName))")
        }
        
        #expect(CGSize(width: 4, height: 3).transposed == CGSize(width: 3, height: 4))
        
        let dict = ["a": NSString("A") as AnyObject, "b": NSString("B") as AnyObject]
        let any = NSString("B") as AnyObject
        #expect(dict.firstKey(for: any) == "b")
        
        if let files = try? FileManager.default.files(in: .desktopDirectory) {
            #expect(files.count > 0)
        }
    }
}
#endif
