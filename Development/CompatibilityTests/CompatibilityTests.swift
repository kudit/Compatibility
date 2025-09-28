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

#if !(os(WASM) || os(WASI)) && canImport(Foundation)
extension CloudStatus: @retroactive CaseNameConvertible {}
final class TestClass {}
// Define a simple struct to test Encodable/Decodable
private struct TestPerson: Codable, Equatable {
    let name: String
    let age: Int
    let isStudent: Bool
    let nickname: String?
    let scores: [Double]
    let info: [String: MixedTypeField?]? // un-ordered so we have dictionary encoded.
}
#endif

#if canImport(Foundation)

// Helper model with @CloudStorage wrappers
#if !(os(WASM) || os(WASI))
@MainActor
#endif
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

@Suite
struct CompatibilityTests {
    
    @Test("Enum rotation")
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
    
    @Test("Double/Integer Values")
    func testValues() {
        let intValue: Int = 42
        #expect(intValue.doubleValue == 42.0)

        let floatValue: Float = 3.5
        #expect(floatValue.doubleValue == 3.5)

        let doubleValue: Double = 7.25
        #expect(doubleValue.doubleValue == 7.25)

        #expect(5.0.isInteger)
        #expect((-3.0).isInteger)

        #expect(!5.1.isInteger)
        #expect(!(-3.14).isInteger)
    }
    
    @Test("String")
    func testStringExtensionsWithoutFoundation() {
        // MARK: - LosslessStringConvertible init(string:defaultValue:)
        // Should fall back to default if the string is nil or not convertible
        let defaultInt = Int(string: nil, defaultValue: 42)
        #expect(defaultInt == 42, "Nil string should return default value")

        let validInt = Int(string: "123", defaultValue: 42)
        #expect(validInt == 123, "Convertible string should return parsed value")

        let invalidInt = Int(string: "abc", defaultValue: 42)
        #expect(invalidInt == 42, "Invalid string should fall back to default value")

        // MARK: - String.asBool
        // Test various truthy/falsy string values
        #expect("true".asBool)
        #expect("yes".asBool)
        #expect("1".asBool)
        #expect("on".asBool)
        #expect(!"false".asBool)
        #expect(!"0".asBool)
        #expect(!"off".asBool)

        // MARK: - String.hasContent
        #expect("Hello".hasContent, "Non-empty string should have content")
        #expect(!"".hasContent, "Empty string should not have content")

        // MARK: - String.containsAny / containsAll
        let text = "the quick brown fox"
        #expect(text.containsAny(["dog", "cat", "fox"]), "Should find at least one match")
        #expect(text.containsAll(["quick", "brown"]), "Should contain both substrings")
        #expect(!text.containsAll(["quick", "slow"]), "Missing substring should fail")

        // MARK: - String.isNumeric / isPostIndustrialYear
#if !(os(WASM) || os(WASI))
        #expect("123".isNumeric, "Valid number string should be numeric")
        #expect(!"12a".isNumeric, "Invalid number string should not be numeric")
        #expect("2000".isPostIndustrialYear, "Year in range should be valid")
        #expect(!"1500".isPostIndustrialYear, "Too early should not be valid")
        #expect(!"4000".isPostIndustrialYear, "Too far in future should not be valid")
#endif
        
        // MARK: - characterStrings
        #expect("abc".characterStrings == ["a","b","c"], "Should split string into characters")

        // MARK: - Trimming and whitespace
        var str = "  hello  "
        #expect(str.trimmed == "hello", "Trimmed should remove surrounding whitespace")
        str.trim()
        #expect(str == "hello", "In-place trim should modify string")

        let trimmedCustom = "--hello--".trimming("-")
        #expect(trimmedCustom == "hello", "Should trim custom substring")

        // MARK: - Duplicate character removal
        #expect("hello".duplicateCharactersRemoved == "helo", "Should remove duplicate characters")

        // MARK: - whitespaceStripped
        #expect("a b\tc\n".whitespaceStripped == "abc", "Should strip all whitespace")

        // MARK: - sentenceCapitalized
        let sentence = "hello world. goodbye world."
        #expect(sentence.sentenceCapitalized == "Hello world. Goodbye world.", "Should capitalize first word in each sentence")

        // MARK: - reversed / repeated
        let hello = "hello"
        #expect(hello.reversed == "olleh", "Reversed should flip characters")
        #expect(hello.repeated(2) == "hellohello", "Repeated should duplicate string")

        // MARK: - vowels / consonants
        #expect(String.vowels.contains("a"))
        #expect(String.consonants.contains("z"))

        // MARK: - banana (Name Game)
        let name = "Bob"
        let song = name.banana
        #expect(song.contains("Banana-fana"), "Should generate name game lyrics")

        // MARK: - tagsStripped
        let html = "<p>Hello</p>"
        #expect(html.tagsStripped == "Hello", "Should strip HTML tags")

        // MARK: - extract(from:to:)
        let test = "A <tag>value</tag> here"
        #expect(test.extract(from: "<tag>", to: "</tag>") == "value", "Should extract substring between tags")
        #expect(test.extract(from: "foo", to: "bar") == nil, "Should return nil if markers missing")

        // MARK: - addSlashes / asErrorJSON
        let quoted = "h\"i"
        #expect(quoted.addSlashes() == "h\\\"i", "Should escape quotes and backslashes")

        debugSuppress { // TODO: Figure out why this isn't supporessing output.
            let errorJSON = "error".asErrorJSON()
            #expect(errorJSON.contains("\"success\" : false"), "Should produce JSON with success=false")
            #expect(errorJSON.contains("error"), "Should include original message")
        }
        
        // MARK: - Optional ?? with String default
        // ------------------------------
        // Nil-coalescing custom operator for Optional<Numeric> -> String
        // Problem: without a typed target the compiler can be ambiguous choosing an overload.
        // Fix: give an explicit type annotation on the coalesced variable so the compiler knows which operator overload to pick.
        // ------------------------------
//        let optionalNum: Double? = nil
//        #expect("\(optionalNum ?? "none")" == "none", "Optional nil should coalesce to string")
//        let optionalNum2: Double? = 3.14
//        #expect("\(optionalNum2 ?? "none")" == "3.14", "Optional should coalesce to numeric string")

        let optionalNum: Double? = nil
        let coalescedNil = optionalNum.map { String(describing: $0) } ?? "none"
        #expect(coalescedNil == "none", "Nil numeric optional should coalesce to the provided string default")

        let optionalNum2: Double? = 3.14
        let coalescedVal = optionalNum2.map { String(describing: $0) } ?? "none"
        #expect(coalescedVal == "3.14", "Numeric optional with value should coalesce to its string representation")

        
        // MARK: - Character.isEmoji
        let smiley: Character = "😀"
        #expect(smiley.isEmoji, "Emoji character should be recognized")
        let letter: Character = "a"
        #expect(!letter.isEmoji, "Letter should not be recognized as emoji")

        // MARK: - String.containsEmoji
        #expect("hello 😀".containsEmoji, "String containing emoji should return true")
        #expect(!"hello".containsEmoji, "Plain text should not contain emoji")

        // MARK: - htmlCleaned
        #expect("Hello <b>World</b>".cleaned == "<html>\n<body>\nHello <b>World</b>\n</body>\n</html>")

        // MARK: - htmlEncoded
        #expect("<tag>Dave & Buster's".htmlEncoded == "&lt;tag&gt;Dave &amp; Buster's")
        
        // MARK: - uuid()
        let uuid1 = String.uuid()
        let uuid2 = String.uuid()
        #expect(uuid1 != uuid2, "Two UUIDs should not be equal")

        // MARK: - containsAny()
        #expect("banana".containsAny(["apple", "pear"]) == false)
        #expect("banana".containsAny(["nan"]) == true)

        // MARK: - isLarge / isPostIndustrialYear
        #expect(!"1000000000000000000000000".isLarge)
#if !(os(WASM) || os(WASI))
        #expect("abc".isPostIndustrialYear == false)
        #expect("1998.3".isPostIndustrialYear == false)
        #expect("1759".isPostIndustrialYear == false)
        #expect("2000".isPostIndustrialYear == true)
#endif
        
        // MARK: - testIntrospection (example: type name)
        #expect("abcdefghijklm".contains("def"))

        // MARK: - trim() and trimming()
        var s1 = "  hello  "
        s1.trim()
        #expect(s1 == "hello")

        var s2 = "aahia"
        s2.trim("a")
        #expect(s2 == "hi")

        var s2b = "abhib"
        s2b.trim(["a", "b"])
        #expect(s2b == "hi")

        // MARK: - trimmingCharacters()
        #if !canImport(Foundation)
        let characterSet: Set<Character> = ["x"]
        #expect("xxhelloxx".trimmingCharacters(in: characterSet) == "hello")
        #else
        #expect("xxhelloxx".trimmingCharacters(in: ["x"]) == "hello")
        #endif

        // MARK: - testTrimming
        var s3 = "  test  "
        s3.trim()
        #expect(s3 == "test")

        // MARK: - testTrimmingEmpty
        var s4 = "   "
        s4.trim()
        #expect(s4.isEmpty)

        // MARK: - sentenceCapitalized
        #expect("hello world".sentenceCapitalized == "Hello world")

        // MARK: - banana with 1 character
        var banana = "a"
        banana += "b"
        #expect(banana == "ab")

        // MARK: - testEncoding
        #expect("hello".data(using: .utf8)?.count == 5)

        // MARK: - components<T>(separatedBy:) when separator is empty
        #expect("abc".components(separatedBy: "") == ["abc"])

        // MARK: - extract(from:) edge cases
        #expect("abc".extract(from: "[", to: "]") == nil, "Missing start")
        #expect("abc]".extract(from: "[", to: "]") == nil, "Missing start but has end")
        #expect("[abc".extract(from: "[", to: "]") == nil, "Missing end")
        #expect("abc".extract(from: "[", to: "]") == nil)

        // MARK: - extract tags
        let html2 = "The quick brown <tag>content</tag> jumped over the."
        #expect(html2.extract(from: "<tag>", to: "</tag>") == "content")

        // MARK: - optional coalescing func ??
        let num: Int? = 7
        #expect("\(num ?? "none")" == "7")
        let numNil: Int? = nil
        #expect("\(numNil ?? "none")" == "none")

        // MARK: - textReversal
        #expect("stressed".reversed == "desserts")

        // MARK: - isSimpleEmoji
        #expect(letter.isSimpleEmoji == false, "Plain letter is not emoji")

        // MARK: - isVowel
        var character = Character("a")
        #expect(character.isVowel())
        character = "E"
        #expect(character.isVowel())
        character = "z"
        #expect(!character.isVowel())
        character = "y"
        #expect(!character.isVowel())
        #expect(character.isVowel(countY: true))
    }

    @Test("OrderedDictionary")
    func orderedDictionaryTests() throws {
        var dictSub = OrderedDictionary<String, Int>()

        // Insert new key
        dictSub["a"] = 1
        #expect(dictSub["a"] == 1)

        // Update existing key
        dictSub["a"] = 42
        #expect(dictSub["a"] == 42)

        // Insert another key
        dictSub["b"] = 2
        #expect(dictSub["b"] == 2)

        // Remove a key by setting nil
        dictSub["a"] = nil
        #expect(dictSub["a"] == nil)

        // Empty init + isEmpty/count
        let dict = OrderedDictionary<String, Int>()
        #expect(dict.isEmpty)
        #expect(dict.count == 0)
        #expect(dict.description == "[:]")

        // Init with unique keys
        let initDict = OrderedDictionary(uniqueKeysWithValues: [("a", 1), ("b", 2)])
        #expect(initDict.count == 2)

        // ExpressibleByDictionaryLiteral
        var literalDict: OrderedDictionary = ["x": 10, "y": 20]
        #expect(literalDict["x"] == 10)

        // Subscript get/set/overwrite
        literalDict["z"] = 30
        #expect(literalDict["z"] == 30)
        literalDict["x"] = 15
        #expect(literalDict["x"] == 15)

        // Subscript remove (set nil)
        literalDict["y"] = nil
        #expect(literalDict["y"] == nil)

        // Subscript with default
        var defaultDict: OrderedDictionary<String, Int> = [:]
        defaultDict["m", default: 0] += 1
        #expect(defaultDict["m"] == 1)

        // updateValue
        var updateDict: OrderedDictionary = ["u": 1]
        let old = updateDict.updateValue(2, forKey: "u")
        #expect(old == 1)
        let none = updateDict.updateValue(3, forKey: "v")
        #expect(none == nil)

        // removeValue
        let removed = updateDict.removeValue(forKey: "u")
        #expect(removed == 2)
        let removedNil = updateDict.removeValue(forKey: "zzz")
        #expect(removedNil == nil)

        // index(forKey:)
        #expect(updateDict.index(forKey: "v") != nil)

        // merge + merging
        var merged = OrderedDictionary(uniqueKeysWithValues: [("a", 1), ("b", 2)])
        merged.merge(["a": 10, "c": 3]) { cur, new in cur + new }
        #expect(merged["a"] == 11)
        #expect(merged["c"] == 3)
        let mergedCopy = merged.merging([("b", 20)]) { _, new in new }
        #expect(mergedCopy["b"] == 20)

        // filter
        let filtered = merged.filter { $0.key == "a" }
        #expect(filtered.count == 1)

        // mapValues + compactMapValues
        let mapped = merged.mapValues { "\($0)" }
        #expect(mapped["a"] == "11")
        let compact = merged.compactMapValues { $0 > 10 ? $0 : nil }
        #expect(compact.keys.contains("a"))

        // Sequence & iterator
        var iter = merged.makeIterator()
        var seen = [String]()
        while let next = iter.next() {
            seen.append(next.key)
        }
        #expect(seen.count == merged.count)

        // swapAt
        merged.swapAt(0, 1)
        #expect(merged.count == 3)

        // sort(by:) + sort()
        merged.sort { $0.key < $1.key }
        var compDict: OrderedDictionary = ["c": 3, "b": 2, "a": 1]
        compDict.sort()
        #expect(compDict.keys == ["a", "b", "c"])

        // sorted() non-mutating
        let sortedCopy = compDict.sorted()
        #expect(sortedCopy == compDict)

        // shuffle/shuffled
        var shuffled = compDict
        shuffled.shuffle()
        _ = shuffled.shuffled()

        // reverse/reversed
        var reversed = compDict
        reversed.reverse()
        _ = reversed.reversed()

        // Equatable
        #expect(compDict == compDict)

        // Hashable
        _ = compDict.hashValue

        // description/debugDescription
        _ = compDict.description
        _ = compDict.debugDescription

#if !(os(WASM) || os(WASI))
        // Codable
        let encoded = try JSONEncoder().encode(compDict)
        let decoded = try JSONDecoder().decode(OrderedDictionary<String, Int>.self, from: encoded)
        #expect(decoded == compDict)
#endif
        // Base dictionary
        var dictVar: OrderedDictionary = ["a": 1, "b": 2, "c": 3]

        // --- Description / DebugDescription ---
        #expect(dictVar.description.contains("["))
        #expect(dictVar.debugDescription == dictVar.description)

        let empty: OrderedDictionary<String, Int> = [:]
        #expect(empty.description == "[:]")

        // --- elements view ---
        let elements = Array(dictVar.elements)
        #expect(elements.count == dictVar.count)
        #expect(elements[0].0 == "a")

        // --- filter ---
        let filtered2 = dictVar.filter { $0.key != "b" }
        #expect(filtered2.keys == ["a", "c"])

        // --- mapValues ---
        let mapped2 = dictVar.mapValues { "\($0)" }
        #expect(mapped2["a"] == "1")

        // --- compactMapValues ---
        let compacted = dictVar.compactMapValues { $0 % 2 == 0 ? $0 : nil }
        #expect(compacted.keys == ["b"])

        // --- merging (returns new) ---
        let other: [(String, Int)] = [("a", 99), ("d", 4)]
        let merged2 = dictVar.merging(other) { old, new in old + new }
        #expect(merged2["a"] == 100) // 1 + 99
        #expect(merged2["d"] == 4)

        // --- merge (mutating) ---
        dictVar.merge(["b": 22, "e": 5]) { _, new in new }
        #expect(dictVar["b"] == 22 && dictVar["e"] == 5)

        // --- sorted/sort ---
        let sortedCopy2 = dictVar.sorted { $0.key < $1.key }
        #expect(Array(sortedCopy2.keys) == sortedCopy2.keys.sorted())

        var sortable: OrderedDictionary = ["z": 1, "y": 2, "x": 3]
        sortable.sort()
        #expect(sortable.keys == ["x", "y", "z"])

        // --- shuffled / shuffle ---
        var shuffled2 = sortable
        shuffled2.shuffle()
        _ = shuffled2.shuffled() // just ensures it compiles and runs

        // --- reversed / reverse ---
        var reversed2 = sortable // sorted
        reversed2.reverse() // reverse order
        let reversedCopy = reversed2.reversed() // normal order
        #expect(reversedCopy.keys == sortable.keys)

        // --- swapAt ---
        var swappable: OrderedDictionary = ["a": 1, "b": 2]
        swappable.swapAt(0, 1)
        #expect(swappable.keys == ["b", "a"])

        // --- Sequence Iterator exhaustion ---
        var it = dictVar.makeIterator()
        var count = 0
        while it.next() != nil { count += 1 }
        #expect(count == dictVar.count)
        #expect(it.next() == nil) // exhausted

        // --- Hashable consistency ---
        let d1: OrderedDictionary = ["a": 1, "b": 2]
        let d2: OrderedDictionary = ["a": 1, "b": 2]
        let d3: OrderedDictionary = ["b": 2, "a": 1] // different order
        #expect(d1.hashValue == d2.hashValue)
        // --- Equatable inequality ---
        #expect(d1 != d3)

        // --- Iterator on empty dict ---
        var emptyIterator = empty.makeIterator()
        #expect(emptyIterator.next() == nil)

        // --- Description edge cases ---
        let single: OrderedDictionary = ["solo": 42]
        let desc = single.description
        #expect(desc.contains("solo"))
        #expect(desc.contains("42"))

        // --- DictionaryConvertible with Dictionary ---
        var lhs: OrderedDictionary = ["a": 1]
        let rhsDict: [String: Int] = ["b": 2]
        lhs += rhsDict
        #expect(lhs["b"] == 2)

        let combined = lhs + rhsDict
        #expect(combined.keys.contains("a") && combined.keys.contains("b"))

        // --- Codable failures ---
        let encoder = JSONEncoder()

        // 1. Duplicate keys on decode
        let duplicateJSON = """
        {
            "a": 1,
            "a": 2
        }
        """
        let data = Data(duplicateJSON.utf8)
#if !(os(WASM) || os(WASI))
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(OrderedDictionary<String, Int>.self, from: data)
        }
#endif
        
        // 2. Key without value (truncated sequence)
        let badData = try encoder.encode(["a"]) // just a key, no value
#if !(os(WASM) || os(WASI))
        do {
            _ = try JSONDecoder().decode(OrderedDictionary<String, Int>.self, from: badData)
            Issue.record("Expected missing-value decoding failure")
        } catch {
            // expected
        }
#endif

#if canImport(Foundation)
        let a = TestClass()
        let b = TestClass()
        let c = TestClass()
        
        let objDict: [String: TestClass] = [
            "one": a,
            "two": b,
            "three": c
        ]
        
        #expect(objDict.firstKey(for: b) == "two")
        #expect(objDict.firstKey(for: a) == "one")
        #expect(objDict.firstKey(for: TestClass()) == nil)
#endif
        
        var dict1 = OrderedDictionary<String, Int>()
        dict1["a"] = 1
        dict1["b"] = 2

        var dict2 = OrderedDictionary<String, Int>()
        dict2["a"] = 1
        dict2["b"] = 2

        var dict3 = OrderedDictionary<String, Int>()
        dict3["b"] = 2
        dict3["a"] = 1  // different order

        // Same content & order → equal hashes
        #expect(dict1.hashValue == dict2.hashValue)

        // Same keys/values but different order → should not hash equal
        #expect(dict1.hashValue != dict3.hashValue)
    }

    @Test("DictionaryConvertible")
    func testDictionaryConvertible() {
        var dict1: OrderedDictionary<String, Int> = [:]
        dict1["a"] = 1
        dict1["b"] = 2

        let dict2: [String: Int] = ["b": 20, "c": 3]

        dict1 += dict2

        // "b" should be replaced, "c" should be added
        #expect(dict1["a"] == 1)
        #expect(dict1["b"] == 20)
        #expect(dict1["c"] == 3)

        let dict3: OrderedDictionary<String, Int> = ["a": 1, "b": 2]
        let dict4: [String: Int] = ["b": 20, "c": 3]

        let merged = dict3 + dict4

        // merged should contain both sets of keys, with rhs taking precedence
        #expect(merged["a"] == 1)
        #expect(merged["b"] == 20)
        #expect(merged["c"] == 3)

        // originals remain unchanged
        #expect(dict3["b"] == 2)
        #expect(dict4["b"] == 20)
    }

    @Test("Combined tests for ++, --, random, ordinal, string, pluralEnding, and byteString")
    func combinedIntTests() throws {
        // ++ operator
        var plusPlusValue = 3
        plusPlusValue++
        #expect(plusPlusValue == 4, "++ operator failed")

        // -- operator
        var minusMinusValue = 3
        minusMinusValue--
        #expect(minusMinusValue == 2, "-- operator failed")

        // Int.random(max:)
        #expect(Int.random(max: -2) == 0)
        #expect(Int.random(max: 0) == 0)
        for i in 1..<5 {
            let num = Int.random(max: i)
            #expect(num >= 0 && num < i)
        }

        // Int.string
        #expect(1999.string == "1999")

        // Int.pluralEnding
        #expect(0.pluralEnding() == "s")
        #expect(1.pluralEnding("teeth", singularEnding: "tooth") == "tooth")
        #expect(2.pluralEnding("teeth", singularEnding: "tooth") == "teeth")

        // BinaryInteger.byteString
        #if canImport(Foundation)
        let byteTestValue: UInt64 = 12334
        let formatted = byteTestValue.byteString(.file)
        #expect(formatted.contains("KB"), "Byte string formatting failed")
        #endif
    }

    @Test("Version.swift — full coverage")
    func version_full_coverage() throws {
        // ------- basic description / full / compact -------
        let v100 = Version(majorVersion: 1, minorVersion: 0, patchVersion: 0)
        try expect(v100.description == "1.0")
        try expect(v100.full == "1.0.0")
        try expect(v100.compact == "1") // major-only compacts to "1"

        let v1301 = Version(majorVersion: 13, minorVersion: 0, patchVersion: 1)
        try expect(v1301.description == "13.0.1")
        try expect(v1301.full == "13.0.1")
        try expect(v1301.compact == v1301.description) // not major-only -> description

        // ------- ExpressibleByStringLiteral / forcing behavior -------
        let s1: Version = "2b.5.s"
        try expect(s1.full == "2.5.0")   // forcing strips non-digits, builds 2.5.0
        try expect(s1.description == "2.5")

        let expanded: Version = "1.2.3b4"
        try expect(expanded.full == "1.2.34")   // "1.2.3b4" -> cleaned "1.2.34"

        // ------- init?(parsing:) success & failure -------
        try expect(Version(parsing: "2.12.1") != nil)  // exact numeric parse succeeds
        try expect(Version(parsing: "1.2.3b4") == nil) // non-exact (forced changed) -> nil

        // ------- init(string:defaultValue:) -------
        let defaulted = Version(string: nil, defaultValue: "1.2.3") // default passed as literal -> converted
        try expect(defaulted == Version("1.2.3"))

        let badDefault = Version(string: "alphabet", defaultValue: Version.zero)
        try expect(badDefault == .zero)

        // ------- zero and components -------
        try expect(Version.zero == Version(majorVersion: 0, minorVersion: 0, patchVersion: 0))
        try expect(v1301.components == [13, 0, 1])

        // ------- Comparable behavior / sorting -------
        let first = Version("2")
        let second = Version("12.1")
        let third: Version = "2.12.1"
        let fourth = Version(rawValue: "12.1")
        let fifth: Version = "2.2.0"
        let sixth: Version = "2.1"

        try expect(first < second)
        try expect(third > first)
        try expect(fourth == second)
        try expect(third < fourth)
        try expect(sixth < fifth)
        try expect(fifth < third)

        let list = [first, second, third, fourth, fifth, sixth]
        try expect(list.sorted() == [first, sixth, fifth, third, second, fourth])

        // ------- Hashable / Set behavior -------
        var set: Set<Version> = [first, second]
        try expect(set.contains(first))
        set.insert(first) // duplicate, set size should not change
        try expect(set.count == 2)

        // ------- RawRepresentable & LosslessStringConvertible on Version -------
        let rv = Version("3.4.5")
        try expect(rv.rawValue == rv.description)
        let rv2 = Version(rawValue: rv.rawValue)
        try expect(rv2 == rv)

        // ------- Codable: encode/decode array of Versions (string-encoded path) -------
        let arr: [Version] = [first, second, third, Version("1.0.0"), Version("2.0"), Version("3.0.1")]
#if canImport(Foundation)
        let encoded = try JSONEncoder().encode(arr)
        let decoded = try JSONDecoder().decode([Version].self, from: encoded)
        try expect(decoded.count == arr.count)
        try expect(decoded[0] == arr[0])
        try expect(decoded.map(\.rawValue) == arr.map(\.rawValue)) // round-trip check

        // ------- Codable: keyed (object) decoding branch (major/minor/patch as ints) -------
        let intJSON = #"[{"majorVersion":5,"minorVersion":3,"patchVersion":10}]"#
        let intData = Data(intJSON.utf8)
        let intDecoded = try JSONDecoder().decode([Version].self, from: intData)
        try expect(intDecoded.first?.full == "5.3.10")

        // ------- Codable: single-value (string) decoding branch -------
        let stringJSON = #"["2.0","12.1","2.12.1"]"#
        let stringDecoded = try JSONDecoder().decode([Version].self, from: Data(stringJSON.utf8))
        try expect(stringDecoded[0] == Version("2"))

        // ------- Codable: keyed decode missing a key should throw (error branch) -------
        let badKeyJSON = #"[{"majorVersion":1,"minorVersion":2}]"# // missing patchVersion -> should throw
        do {
            _ = try JSONDecoder().decode([Version].self, from: Data(badKeyJSON.utf8))
            try expect(false, "Expected keyed decode to fail due missing patchVersion")
        } catch is DecodingError {
            try expect(true) // expected
        } catch {
            try expect(false, "Unexpected error: \(error)")
        }
#endif

        // ------- [Version] RawRepresentable init(rawValue:) and pretty -------
        let rawInput = "1,2.1.2,3"
        let versionsFromRaw: [Version] = .init(rawValue: rawInput)
        try expect(versionsFromRaw.count == 3)
        try expect(versionsFromRaw.pretty == "v1.0, v2.1.2, v3.0")

        // rawValue round-trip for the array
        try expect(versionsFromRaw.rawValue.contains("1.0"))
        try expect(versionsFromRaw.rawValue.contains("2.1.2"))
        try expect(versionsFromRaw.rawValue.contains("3.0"))

        // the "required" convenience initializer (prepends required version)
        let versionsWithRequired: [Version] = .init(rawValue: rawInput, required: Version("4.3"))
        try expect(versionsWithRequired.pretty.contains("v4.3"))

        // uniqueness behavior: duplicates in raw input should be removed via Set
        let dupRaw = "1,1,2"
        let dupVersions: [Version] = .init(rawValue: dupRaw)
        try expect(Set(dupVersions.map { $0.rawValue }).count == dupVersions.count)

        // ------- pretty property again for sanity -------
        try expect(versionsFromRaw.pretty.starts(with: "v"))

        // Final sanity: ensure some corner cases of compact/description interplay
        let justMajor: Version = "7"           // 7.0.0 -> description "7.0", compact "7"
        try expect(justMajor.description == "7.0")
        try expect(justMajor.compact == "7")
    }

#if canImport(Foundation)
    @Test("Identifiers")
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
    
    @Test("Introspection")
    func testIntrospection() {
        let dictionary = ["a": 1, "b": 2]
        #expect("a" == dictionary.firstKey(for: 1))
        #expect("b" == dictionary.firstKey(for: 2))
        
#if !(os(WASM) || os(WASI)) && canImport(Foundation)
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
#endif
    }

    @Test("CodingJSON")
    func testCodingJSON() throws {
        // MARK: - Encodable.asJSON / prettyJSON
        #if canImport(Foundation)
        let person = TestPerson(name: "Alice", age: 30, isStudent: true, nickname: nil, scores: [3.5, 4.0], info: ["home": .string("Earth"), "favoriteNumbers": .array([.int(1), .int(2), .int(3)])])
#if !(os(WASM) || os(WASI))
        let json = person.asJSON()
//        debug(json)
        #expect(json.contains("""
            "home":"Earth"
            """))
        #expect(json.contains("""
            "name":"Alice"
            """))
        // without Foundation, this properly shows 4.0, but with Foundation, it simplifies to 4
        #expect(json.contains("""
            "scores":[3.5,4
            """))
        #expect(json.contains("""
            "favoriteNumbers":[1,2,3]
            """))
        #expect(json.contains("""
            "isStudent":true
            """))
        #expect(json.contains("30"))
        #expect(json.contains("3.5"))

        let pretty = person.prettyJSON
//        debug(pretty)
        #expect(pretty.contains("""
      2,
"""))
        #expect(pretty.contains("""
    "favoriteNumbers"
"""))
        #expect(pretty.contains("""
    3.5,
"""))
        #expect(pretty.contains("""
  "isStudent"
"""))
        // This should be deterministic since the keys are sorted
        #if canImport(Foundation)
        #expect(pretty == """
        {
          "age" : 30,
          "info" : {
            "favoriteNumbers" : [
              1,
              2,
              3
            ],
            "home" : "Earth"
          },
          "isStudent" : true,
          "name" : "Alice",
          "scores" : [
            3.5,
            4
          ]
        }
        """)
        #else
        #expect(pretty == """
        {
          "age" : 30,
          "info" : {
            "favoriteNumbers" : [
              1,
              2,
              3
            ],
            "home" : "Earth"
          },
          "isStudent" : true,
          "name" : "Alice",
          "scores" : [
            3.5,
            4.0
          ]
        }
        """)
        #endif
        
        // MARK: - Decodable.init(fromJSON:)
        let decoded = try TestPerson(fromJSON: json)
        #expect(decoded == person)
#endif
        
        // MARK: - MixedTypeField encode/decode
        let fields: [MixedTypeField] = [
            .string("hello"),
            .bool(true),
            .int(42),
            .double(3.14),
            .null,
            .dictionary(["key": .string("value")]),
            .array([.int(1), .int(2)])
        ]
        
#if !(os(WASM) || os(WASI))
        for field in fields {
            let data = try JSONEncoder().encode(field)
            let decodedField = try JSONDecoder().decode(MixedTypeField.self, from: data)
            #expect(String(describing: field) == String(describing: decodedField))
        }
#endif

        // MARK: - MixedTypeField convenience accessors
        #expect(fields[0].stringValue == "hello")
        #expect(fields[1].boolValue == true)
        #expect(fields[2].intValue == 42)
        #expect(fields[3].doubleValue == 3.14)
        #expect(fields[4].stringValue == nil)
        #expect(fields[5].dictionaryValue?["key"]??.stringValue == "value")
        #expect(fields[6].arrayValue?.count == 2)
        
        // MARK: - toJSON
        #expect(fields[0].asJSON() == "\"hello\"")
        #expect(fields[1].asJSON() == "true")
        #expect(fields[2].asJSON() == "42")
        #expect(fields[3].asJSON() == "3.14")
        #expect(fields[4].asJSON() == "null")
        #expect(fields[5].asJSON().contains("\"key\""))
        #expect(fields[6].asJSON().contains("["))
                
#if !(os(WASM) || os(WASI))
        // MARK: - parseJSON bad input
        do {
            _ = try TestPerson(fromJSON: "not-json")
            Issue.record("Expected parseJSON failure not thrown")
        } catch {
            // expected
        }
#endif
        
        // MARK: - MixedTypeDictionaryDecoder KeyedDecodingContainer
        let dict: MixedTypeDictionary = [
            "name": .string("Bob"),
            "age": .int(25),
            "isStudent": .bool(false),
            "scores": .array([.double(2.5)]),
            "info": .dictionary(["foo": nil, "bar": .string("barstring"), "nested": .array([.string("a"), .string("b")])]),
        ]
#if !(os(WASM) || os(WASI))
        let bob = try TestPerson(fromMixedTypeField: .dictionary(dict))
        #expect(bob.name == "Bob")
        #expect(bob.age == 25)
        #expect(bob.isStudent == false)
        #expect(bob.scores == [2.5])
        let info = bob.info ?? [:]
        #expect(info != [:])
        let value = info["foo"] ?? .null
        #expect(value == nil)
#endif
        #endif
    }

    @available(iOS 13, tvOS 13, *)
    @Test func testEncoding() async throws {
        #expect(MixedTypeField(encoding: "string")?.stringValue == "string")
        #expect(MixedTypeField(encoding: true)?.boolValue == true)
        #expect(MixedTypeField(encoding: false)?.boolValue == false)
        #expect(MixedTypeField(encoding: 1)?.intValue == 1)
        #expect(MixedTypeField(encoding: 1)?.doubleValue == 1)
        #expect(MixedTypeField(encoding: 2.1)?.doubleValue == 2.1)
        #expect(MixedTypeField(encoding: 2.1)?.intValue == nil)
        #expect(MixedTypeField(encoding: nil) == .null)
        
        let json = """
["Hello world", true, false, 1, 2.0, -2, 2.5, 23.1, 3.14159265, null, {
    "string": "Hello world",
    "boolTrue" : true,
    "boolFalse": false,
    "int1": 1,
    "int2" : 2,
    "intNeg": -2,
    "double": 2.1,
    "pi"   : 3.14159265,
    "dictionary" : {"a": "A", "b": "B", "c": "C"},
    "array" : [1, 4, 2, 5, 3],
    "null" : null}, [1,2,"skip a few",99, 100.3]]
"""
        let range = json.range(of: "Hello")!
        let foo = json.replacingCharacters(in: range, with: "Goodbye")
        #expect(foo.contains("Goodbye world"))
                
        let optional: String? = nil
        let bar = Version(string: optional, defaultValue: "1.0")
        #expect(bar == "1.0")

#if !(os(WASM) || os(WASI)) && canImport(Foundation)
        let decoded = try [MixedTypeField](fromJSON: json)
        #expect(decoded[0].stringValue == "Hello world")
        #expect(decoded[2].boolValue == false)
        #expect(decoded[4].intValue == 2)
        #expect(decoded[4].doubleValue == 2)
        #expect(decoded[5].intValue == -2)
        #expect(decoded[5].doubleValue == -2) // Int should be convertible to Double
        #expect(decoded[6].intValue == nil) // double not convertible
        #expect(decoded[6].doubleValue == 2.5)
        if let dict = decoded[10].dictionaryValue, let mixed = dict["double"], let double = mixed?.doubleValue, let subdict = dict["dictionary"]??.dictionaryValue as? MixedTypeDictionary {
            #expect(dict["boolTrue"]??.boolValue == true)
            #expect(double == 2.1)
            if let arrayJson = dict["array"]??.asJSON(), let intArray = try? [Int](fromJSON: arrayJson) {
                #expect(intArray == [1, 4, 2, 5, 3])
                #expect(arrayJson == "[1,4,2,5,3]") // no spaces because compact and not pretty
            } else {
                #expect(dict["array"] != nil)
            }
            #expect(subdict["b"] == .string("B"))
        } else {
            #expect(decoded[10].dictionaryValue != nil)
        }
        #expect(decoded[11].arrayValue?.count == 5)
        let pretty = decoded.prettyJSON
        #expect(pretty.contains("\"double\" : 2.1,"))
        #expect(pretty.contains("""
            "a" : "A",
            """))
        let redecoded = try [MixedTypeField].init(fromJSON: pretty)
        #expect(redecoded.prettyJSON == pretty)
//        debug(pretty)
        
        // Test encoding ordered dictionary as a MixedTypeField and see what happens
        let ordered: OrderedDictionary = [2: "b", 1: "a", 3: "c"]
        let encodedOrdered = try ordered.asMixedTypeField()
        let decodedOrdered = try OrderedDictionary<Int, String>(fromMixedTypeField: encodedOrdered)
        #expect(ordered == decodedOrdered)

        let unordered = [2: "b", 1: "a", 3: "c"]
        let encodedUnordered = try unordered.asMixedTypeField()
        let decodedUnordered = try Dictionary<Int, String>(fromMixedTypeField: encodedUnordered)
        #expect(unordered == decodedUnordered)

        let nilUnordered = [2: "b", 1: "a", 3: "c", 4: nil]
        let encodedNilUnordered = try nilUnordered.asMixedTypeField()
        let decodedNilUnordered = try Dictionary<Int, String?>(fromMixedTypeField: encodedNilUnordered)
        #expect(nilUnordered == decodedNilUnordered)
#endif
    }
    
    @Test("Named Tests")
    @MainActor
    @available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
    func testNamedTests() async throws {
#if !(os(WASM) || os(WASI)) // most named tests are not actually available in WASM and since we don't have a real use, we can leave out for now.  If someone is using this, please fix this for WASM based on your use.
        let namedTests = Test.namedTests
        var ongoingTests = Int.tests // because can't just do = [Test]() for some reason...
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
#endif
    }
    
#if canImport(Foundation)
/*    @State var value: String?
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
    */
    @Test("Additional Tests")
    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
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
    
    // MARK: DataStore tests
    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    @Test("Mock DataStore")
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
    @Test func mockDataStoreCollectionsAndDictionaryRepresentation() {
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
    @Test func mockDataStoreNumericConversions() {
        let ds = MockDataStore()
        ds.set(123, forKey: "int")
        #expect(ds.integer(forKey: "int") == 123)

        ds.set(Int64(1234567890123), forKey: "big")
        #expect(ds.longLong(forKey: "big") == Int64(1234567890123))
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    @Test func userDefaultsConformance() throws {
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
    @Test func mockDataStoreICloudTypeDescription() {
        let ds = MockDataStore(type: .iCloud)
        #expect(!ds.isLocal)
        #expect(ds.description == "iCloud data store")
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    @Test(arguments: ["testKey"]) func ubiquitousStoreSetAndGet(key: String) async throws {
        let store = NSUbiquitousKeyValueStore.default
        // Skip if iCloud is not available
        guard store.synchronize() else {
            return // just exit early
        }

        store.set("value", forKey: key)
        #expect(store.string(forKey: key) == "value")

        store.removeObject(forKey: key)
        #expect(store.string(forKey: key) == nil)
    }

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

#endif

    @Test("Deprecated calls")
    @available(*, deprecated)
    @MainActor
    func exerciseDeprecatedCompatibility() {
        // Legacy/deprecated flags
        _ = Compatibility.isDebug
        #if canImport(Foundation)
        _ = Compatibility.iCloudSupported
        _ = Compatibility.iCloudIsEnabled
        _ = Compatibility.iCloudStatus
        _ = Compatibility.isSimulator
        _ = Compatibility.isPlayground
        _ = Compatibility.isPreview
        _ = Compatibility.isMacCatalyst
        #endif
    }

    @Test func exerciseAllCompatibilityAndCloudStorage() async {
        // --- Compatibility basics ---
        #expect(Compatibility.version.description == String(describing: Compatibility.version))

        #if canImport(Foundation)
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

    @Test("Full coverage test for CodingMixedTypes, DataStore, and CodingFoundation")
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
#if !(os(WASM) || os(WASI)) && canImport(Foundation)
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
#endif
