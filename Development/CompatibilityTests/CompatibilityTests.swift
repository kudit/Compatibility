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
    
#if canImport(Foundation)
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
#endif
    
    @Test
    func testIntrospection() {
        let dictionary = ["a": 1, "b": 2]
        #expect("a" == dictionary.firstKey(for: 1))
        #expect("b" == dictionary.firstKey(for: 2))
        
        for c in CloudStatus.allCases {
            #expect(String(describing: c).contains(c.caseName))
        }
        
        let config = Compatibility.settings
        let propertyKeys = config.allProperties.keys
        for (key, value) in config.allProperties {
            #expect(String(describing: config.allProperties[key]).contains(String(describing: value)), "property \(key) mismatch (should never happen)")
        }
        
        let pathKeys = config.allKeyPaths.keys
        #expect(propertyKeys == pathKeys)
        for (key, path) in config.allKeyPaths {
            guard let propertyValue = config.allProperties[key] else {
                #expect(key == "BAD")
                continue
            }
            let pathValue = config[keyPath: path]
//            debug("Key: \(key)\n\tProperty: \(String(describing: propertyValue))\n\tPath: \(String(describing: pathValue))")
            // testing strings since function values might be problematic or not exactly equal.
            #expect(areEqual(String(describing: propertyValue), String(describing: pathValue)))
        }
    }
        
#if canImport(Foundation)
    @Test func testEncoding() async throws {
        let json = """
["Hello world", true, false, 1, 2, -2, 2.1, 23.1, 3.14159265, null, {
    "string": "Hello world",
    "boolTrue" : true,
    "boolFalse": false,
    "int1": 1,
    "int2" : 2,
    "intNeg": -2,
    "double": 2.1,
    "pi"   : 3.14159265,
    "null" : null}, [1,2,"skip a few",99, 100.3]]
"""
        let range = json.range(of: "Hello")!
        let foo = json.replacingCharacters(in: range, with: "Goodbye")
        #expect(foo.contains("Goodbye world"))
        
        let optional: String? = nil
        let bar = Version(string: optional, defaultValue: "1.0")
        #expect(bar == "1.0")

        let decoded = try [MixedTypeField].init(fromJSON: json)
        #expect(decoded[0].stringValue == "Hello world")
        #expect(decoded[2].boolValue == false)
        #expect(decoded[5].intValue == -2)
        #expect(decoded[10].dictionaryValue?["double"]?.doubleValue == 2.1)
        #expect(decoded[11].arrayValue?.count == 5)
        let pretty = decoded.prettyJSON
        let redecoded = try [MixedTypeField].init(fromJSON: pretty)
        #expect(redecoded.prettyJSON == pretty)
//        debug(pretty)
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
        
        let html = "This is <b>bold</b> and this is <i>italic</i>."
        let markdownString = "This is **bold** and this is *italic*."
        let attributedString = try? AttributedString(markdown: markdownString)
        #expect(AttributedString(html.attributedString) != attributedString) // not exact
        
        // Check vowels.
        #expect("foo".first?.isVowel() == false)
        #expect("yes".first?.isVowel() == false)
        #expect("yes".first?.isVowel(countY: true) == true)
        #expect("elephant".first?.isVowel() == true)

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
#endif
}
#endif
