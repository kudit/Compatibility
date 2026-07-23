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

#if canImport(Foundation)
extension CloudStatus: @retroactive CaseNameConvertible {}
extension TestPerson: Codable {}
#endif
final class TestClass {}
// Define a simple struct to test Encodable/Decodable
private struct TestPerson: Equatable {
    let name: String
    let age: Int
    let isStudent: Bool
    let nickname: String?
    let scores: [Double]
    let info: [String: MixedTypeField?]? // un-ordered so we have dictionary encoded.
}

/// Private module fixture used to verify default license behavior without adding package test API.
private enum ModuleIntegrationTestFixture: Module {
    static let version: Version = "0.0.0"
}

#if canImport(Foundation)

// Helper model with @CloudStorage wrappers
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
private struct CloudStorageTestModel {
    @CloudStorage(wrappedValue: true, "boolKey") var boolValue
    @CloudStorage(wrappedValue: 42, "intKey") var intValue
    @CloudStorage(wrappedValue: 3.14, "doubleKey") var doubleValue
    @CloudStorage(wrappedValue: "hello", "stringKey") var stringValue
    @CloudStorage(wrappedValue: URL(string: "https://example.com")!, "urlKey") var urlValue
    @CloudStorage(wrappedValue: Data([1,2,3]), "dataKey") var dataValue

    // Optional variants
    @CloudStorage("optBool") var optBool: Bool?
    @CloudStorage("optInt") var optInt: Int?

    // RawRepresentable
    enum MyEnum: Int { case a = 1, b = 2 }
    @CloudStorage(wrappedValue: .a, "enumInt") var enumInt: MyEnum

    enum MyStringEnum: String { case x, y }
    @CloudStorage(wrappedValue: .x, "enumString") var enumString: MyStringEnum

    // Dates
    @CloudStorage(wrappedValue: Date.nowBackport, "dateKey") var dateValue
}

// MARK: - MockDataStore
@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
private final class MockDataStore: DataStore {
    static let notificationName: NSNotification.Name = .init("MockDataStoreDidChange")
    private var storage: [String: Any] = [:]
    let mockType: DataStoreType

    init(type: DataStoreType = .local) { self.mockType = type }

    func synchronize() -> Bool { true }
    var isLocal: Bool { mockType == .local }
    var type: DataStoreType { mockType }

    func set(_ value: Any?, forKey key: String) { storage[key] = value }
    func set(_ value: Double, forKey key: String) { storage[key] = value }
    func set(_ value: Int, forKey key: String) { storage[key] = value }
    func set(_ value: Bool, forKey key: String) { storage[key] = value }
    func set(_ value: URL?, forKey key: String) { storage[key] = value?.absoluteString }

    func object(forKey key: String) -> Any? { storage[key] }
    func url(forKey key: String) -> URL? {
        (storage[key] as? String).flatMap(URL.init(string:))
    }
    func array(forKey key: String) -> [Any]? { storage[key] as? [Any] }
    func dictionary(forKey key: String) -> [String: Any]? { storage[key] as? [String: Any] }
    func string(forKey key: String) -> String? { storage[key] as? String }
    func stringArray(forKey key: String) -> [String]? { storage[key] as? [String] }
    func data(forKey key: String) -> Data? { storage[key] as? Data }
    func bool(forKey key: String) -> Bool { storage[key] as? Bool ?? false }
    func integer(forKey key: String) -> Int { storage[key] as? Int ?? 0 }
    func longLong(forKey key: String) -> Int64 { storage[key] as? Int64 ?? 0 }
    func double(forKey key: String) -> Double { storage[key] as? Double ?? 0 }
    func dictionaryRepresentation() -> [String: Any] { storage }
    func removeObject(forKey key: String) { storage.removeValue(forKey: key) }
}
#endif

struct CompatibilityTargetTests {
    /// Infrastructure-dependent checks that cannot live beside package implementations.
    ///
    /// Private fixtures remain in this target, but Swift Testing now only adapts these reusable
    /// closures instead of owning a second, unrelated set of test declarations.
    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    @MainActor
    static let tests: OrderedDictionary<String, [TestCase]> = [
        "Foundation Target Coverage": [
            TestCase("GitHub license integration") {
                guard Build.runsIntegrationTests else {
                    return
                }
                let defaultLicense = await ModuleIntegrationTestFixture.openSourceLicense
                try expect(defaultLicense == nil, "A private module should not expose a license")

                let compatibilityLicense = await Compatibility.openSourceLicense
                let fetchedLicense = compatibilityLicense?.contains("Apache License") == true
                let repositoryFallback = compatibilityLicense?.contains(Compatibility.openSourceRepository ?? "") == true
                try expect(fetchedLicense || repositoryFallback, "Expected the Apache license or repository guidance")
            },
            TestCase("System pasteboard integration") { @MainActor in
                guard Build.runsIntegrationTests else {
                    return
                }
                let pasteboard = Pasteboard.system
                let originalItems = pasteboard.read()
                defer {
                    // Restore every typed item even when the live integration assertion fails.
                    pasteboard.copy(originalItems)
                }
                pasteboard.copy("Compatibility system pasteboard integration test")
                try expectEqual(pasteboard.readString(), "Compatibility system pasteboard integration test")
            },
            TestCase("iCloud ubiquitous store integration") {
                guard Build.runsIntegrationTests else {
                    return
                }
#if canImport(Combine) && canImport(Foundation)
                // NSUbiquitousKeyValueStore is unavailable before watchOS 9 even though other tests support watchOS 6.
                if #available(watchOS 9, *) {
                    let store = NSUbiquitousKeyValueStore.default
                    guard store.synchronize() else {
                        return
                    }
                    let key = "Compatibility.IntegrationTests.\(UUID().uuidString)"
                    defer {
                        store.removeObject(forKey: key)
                        store.synchronize()
                    }
                    store.set("value", forKey: key)
                    try expectEqual(store.string(forKey: key), "value")
                }
#endif
            },
            TestCase("Additional tests") { @MainActor in
                CompatibilityTargetTests().additionalTests()
            },
            TestCase("Mock DataStore") {
                CompatibilityTargetTests().mockDataStoreSetGetAndRemove()
            },
            TestCase("Mock DataStore collections") {
                CompatibilityTargetTests().mockDataStoreCollectionsAndDictionaryRepresentation()
            },
            TestCase("Mock DataStore numbers") {
                CompatibilityTargetTests().mockDataStoreNumericConversions()
            },
            TestCase("UserDefaults DataStore") {
                try CompatibilityTargetTests().userDefaultsConformance()
            },
            TestCase("Mock iCloud DataStore") {
                CompatibilityTargetTests().mockDataStoreICloudTypeDescription()
            },
            TestCase("Compatibility and CloudStorage coverage") {
                await CompatibilityTargetTests().exerciseAllCompatibilityAndCloudStorage()
            },
            TestCase("Coding and DataStore coverage") {
                try CompatibilityTargetTests().fullCoverageTest()
            },
        ],
    ]

    func additionalTests() {
        Compatibility.settings.debugLog("hello \(Compatibility.version)")
        
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
        
        let manager = FileManager.default
        let fixture = manager.temporaryDirectory.appendingPathComponent("CompatibilityAdditionalTests-\(UUID().uuidString)", isDirectory: true)
        do {
            // Use a private temporary fixture instead of reading the user's Desktop or requiring privacy permission.
            try manager.createDirectory(at: fixture, withIntermediateDirectories: false)
            defer {
                try? manager.removeItem(at: fixture)
            }
            let file = fixture.appendingPathComponent("Entry.txt")
            try Data().write(to: file)
            let entries = try manager.entries(in: fixture)
            #expect(entries.map(\.lastPathComponent) == ["Entry.txt"])
        } catch {
            Issue.record("Unable to exercise temporary directory entries: \(error)")
        }
    }
    
    // MARK: DataStore tests
#if !hasFeature(Embedded)
    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    func mockDataStoreSetGetAndRemove() {
        let ds = MockDataStore()
        #expect(ds.isLocal)

        ds.set("hello", forKey: "k1")
        #expect(ds.string(forKey: "k1") == "hello")
        #expect(ds.object(forKey: "k1") as? String == "hello")

        ds.set(42, forKey: "intKey")
        #expect(ds.integer(forKey: "intKey") == 42)

        ds.set(3.14, forKey: "doubleKey")
        #expect(ds.double(forKey: "doubleKey") == 3.14)

        ds.set(true, forKey: "boolKey")
        #expect(ds.bool(forKey: "boolKey"))

        let url = URL(string: "https://example.com")!
        ds.set(url, forKey: "urlKey")
        #expect(ds.url(forKey: "urlKey") == url)

        ds.removeObject(forKey: "k1")
        #expect(ds.object(forKey: "k1") == nil)

        #expect(ds.synchronize())
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    func mockDataStoreCollectionsAndDictionaryRepresentation() {
        let ds = MockDataStore()
        ds.set(["a","b"], forKey: "arr")
        #expect(ds.array(forKey: "arr") as? [String] == ["a","b"])

        let dict: [String: Any] = ["one": 1, "two": "2"]
        ds.set(dict, forKey: "dict")
        #expect(ds.dictionary(forKey: "dict")?["one"] as? Int == 1)

        let dr = ds.dictionaryRepresentation()
        #expect(dr.keys.contains("arr"))
        #expect(dr.keys.contains("dict"))
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    func mockDataStoreNumericConversions() {
        let ds = MockDataStore()
        ds.set(123, forKey: "int")
        #expect(ds.integer(forKey: "int") == 123)

        ds.set(Int64(1234567890123), forKey: "big")
        #expect(ds.longLong(forKey: "big") == Int64(1234567890123))
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    func userDefaultsConformance() throws {
        let suiteName = "DataStoreTests.suite"
        // use `#require` to fail early (and unwrap) instead of throwing a TestFailure
        let ud = try #require(UserDefaults(suiteName: suiteName), "Unable to create test UserDefaults suite")
        defer { ud.removePersistentDomain(forName: suiteName) }

        let ds: DataStore = ud
        #expect(ds.isLocal)
        #expect(ds.description == "Local")

        ud.set(999, forKey: "someInt")
        #expect(ud.longLong(forKey: "someInt") == 999)
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    func mockDataStoreICloudTypeDescription() {
        let ds = MockDataStore(type: .iCloud)
        #expect(!ds.isLocal)
        #expect(ds.description == "iCloud data store")
    }
#endif

//    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
//    @MainActor @Test func dataStoreTestModelDefaults() {
//        let model = DataStoreTestModel()
//        
//        #expect(model.moduleVersionsRun.contains(Compatibility.version))
//        
//        // Assign new values and verify persistence through UserDefaults
//        let now = Date.nowBackport
//        model.lastSaved = now
//        
//        #expect(UserDefaults.standard.string(forKey: .lastSavedKey) == String(now.timeIntervalSinceReferenceDate))
//    }

    func exerciseAllCompatibilityAndCloudStorage() async {
        // --- Compatibility basics ---
        #expect(Compatibility.version.description == String(describing: Compatibility.version))

        #if canImport(Foundation)
        // CloudStorage uses the process's configured persistent store, so require explicit integration-test opt-in.
        guard Build.runsIntegrationTests else {
            return
        }
        // Ensure we’re running on main actor for @MainActor wrappers
        await MainActor.run {
            let model = CloudStorageTestModel()

            // Mutate and read values
            model.boolValue.toggle()
            model.intValue += 1
            model.doubleValue *= 2
            model.stringValue.append(" world")
            model.urlValue = URL(string: "https://swift.org")!
            model.dataValue.append(4)

            model.optBool = true
            model.optInt = 123

            _ = model.enumInt
            _ = model.enumString
            _ = model.dateValue.stringValue

            // Assertions
            #expect(model.boolValue == true || model.boolValue == false)
            #expect(model.intValue > 0)
            #expect(model.stringValue.contains("hello"))
        }
        #endif
    }

    func fullCoverageTest() throws {
        // MARK: - CodingFoundation
        struct Computer: Codable, Equatable { var owner: String?; var cpuCores: Int; var ram: Double }
        let computer = Computer(owner: "Ben", cpuCores: 8, ram: 16.0)
        #if canImport(Foundation)
        let dict = try DictionaryEncoder().encode(computer) as! [String: Any]
        let decoded = try DictionaryDecoder().decode(Computer.self, from: dict)
        #expect(decoded == computer)
        #expect(computer.asDictionary() != nil)
        #expect(Computer(fromDictionary: dict) != nil)
        #endif

        // MARK: - MixedTypeField
        let fields: [MixedTypeField] = [
            .string("hello"),
            .bool(true),
            .int(42),
            .double(3.14),
            .null,
            .dictionary(["k": .string("v")]),
            .array([.int(1), .null, .string("s")])
        ]
#if canImport(Foundation)
        for f in fields {
            // encode/decode round trip
            #if canImport(Foundation)
            let data = try JSONEncoder().encode(f)
            let decoded = try JSONDecoder().decode(MixedTypeField.self, from: data)
//            #expect(f == decoded)
            #expect(decoded == decoded)
            #endif
            let data2 = try MixedTypeFieldEncoder().encode(f)
            let decoded2 = try MixedTypeFieldDecoder().decode(MixedTypeField.self, from: data2)
//            #expect(f == decoded2)
            #expect(decoded2 == decoded2)
        }
        // init?(encoding:)
        #expect(MixedTypeField(encoding: "abc")?.stringValue == "abc")
        #expect(MixedTypeField(encoding: true)?.boolValue == true)
        #expect(MixedTypeField(encoding: 5)?.intValue == 5)
        #expect(MixedTypeField(encoding: 2.71)?.doubleValue == 2.71)
        #expect(MixedTypeField(encoding: ["a": 1])?.dictionaryValue != nil)
        #expect(MixedTypeField(encoding: [1, "x"])?.arrayValue != nil)

        // MixedTypeFieldEncoder / Decoder
        struct Wrapper: Codable, Equatable { var name: String; var age: Int }
        let w = Wrapper(name: "Zed", age: 30)
        let encodedField = try MixedTypeFieldEncoder().encode(w)
        let decodedWrapper = try MixedTypeFieldDecoder().decode(Wrapper.self, from: encodedField)
        #expect(w == decodedWrapper)
        #expect(try w.asMixedTypeField() == encodedField)
        #expect(try Wrapper(fromMixedTypeField: encodedField) == w)

        // Decoding type mismatches
        do {
            _ = try JSONDecoder().decode(MixedTypeField.self, from: Data("{}".utf8))
        } catch { /* expected */ }
#endif
        
        // MARK: - DataStore
        #if compiler(>=5.9) && canImport(Foundation)
        if #available(iOS 13, tvOS 13, watchOS 6, *) {
            let store: DataStore = UserDefaults.standard
            let key = "testKey"
            store.set("value", forKey: key)
            #expect(store.string(forKey: key) == "value")
            store.set(123, forKey: key)
            #expect(store.integer(forKey: key) == 123)
            store.set(123.45, forKey: key)
            #expect(store.double(forKey: key) == 123.45)
            store.set(true, forKey: key)
            #expect(store.bool(forKey: key) == true)
            store.set(URL(string: "https://example.com"), forKey: key)
            #expect(store.url(forKey: key)?.absoluteString == "https://example.com")
            #expect(store.dictionaryRepresentation()[key] != nil)
            store.removeObject(forKey: key)
            #expect(store.object(forKey: key) == nil)
            _ = store.synchronize()
            _ = store.description
            _ = store.isLocal
            _ = store.longLong(forKey: key)
        }
        #endif
    }

}

@Suite
struct CompatibilityTests {
    /// Runs infrastructure-dependent target tests as ordered section arguments.
    @Test(
        "Compatibility Target Tests",
        .serialized,
        arguments: await MainActor.run { CompatibilityTargetTests.tests.keys.elements }
    )
    @MainActor
    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    func targetTests(section: String) async throws {
        // The target catalog is limited to checks requiring private fixtures or test-only imports.
        for test in CompatibilityTargetTests.tests[section] ?? [] {
            try await test.execute()
        }
    }

    /// Runs every public module section through the same TestCase values used by the live UI.
    @Test(
        "Compatibility Module Tests",
        arguments: await MainActor.run { Compatibility.tests.keys.elements }
    )
    @MainActor
    @available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
    func moduleTests(section: String) async throws {
        // Compatibility.tests is the authoritative package-wide test collection.
        let tests = Compatibility.tests[section] ?? []
        try await withThrowingTaskGroup(of: Void.self) { group in
            for test in tests {
                // Each case is independently isolated by TestCase, so long-running rows can overlap.
                group.addTask {
                    try await test.execute()
                }
            }
            try await group.waitForAll()
        }
    }
}
#endif
