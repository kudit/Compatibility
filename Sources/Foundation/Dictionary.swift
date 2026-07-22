//
//  Dictionary.swift
//  KuditFrameworks
//
//  Created by Ben Ku on 9/19/16.
//  Copyright © 2016 Kudit. All rights reserved.
//

// MARK: - DictionaryConvertible
public protocol DictionaryConvertible: Sequence {
    associatedtype Key: Hashable
    associatedtype Value
    associatedtype Element = (key: Key, value: Value)
    var dictionaryValue: Dictionary<Key, Value> { get }
    subscript(_ key: Key) -> Value? { get set }
}
extension Dictionary: DictionaryConvertible {
    public var dictionaryValue: Dictionary<Key, Value> {
        self
    }
}
extension OrderedDictionary: DictionaryConvertible {
    public var dictionaryValue: Dictionary<Key, Value> {
        var dictionaryValue = Dictionary<Key, Value>()
        for (key, value) in self {
            dictionaryValue[key] = value
        }
        return dictionaryValue
    }
}

// MARK: - Dictionary addition
extension DictionaryConvertible {
    /// Adds the right hand dictionary to the left hand dictionary.  If there are matching keys, the right hand side will replace the values in the left hand side.
    public static func += <Other: DictionaryConvertible>(
        lhs: inout Self, rhs: Other
    ) where Self.Key == Other.Key, Self.Value == Other.Value, Other.Element == (key: Key, value: Value) {
        for (key, value) in rhs {
            lhs[key] = value
        }
    }

    /// Adds the right hand dictionary to the left hand dictionary and returns the result.  If there are matching keys, the right hand side will replace the values in the left hand side.
    public static func + <Other: DictionaryConvertible>(
        lhs: Self, rhs: Other
    ) -> Self where Self.Key == Other.Key, Self.Value == Other.Value, Other.Element == (key: Key, value: Value) {
        var union = lhs
        union += rhs
        return union
    }
}


// MARK: - Dictionary key lookup extensions
public extension DictionaryConvertible where Value: AnyObject, Element == (key: Key, value: Value) {
#if !DEBUG
    @available(*, deprecated, renamed: "firstKey(for:)")
    func key(for value: AnyObject) -> Key? {
        return firstKey(for: value)
    }
#endif
    /// return the first encountered key for the given class object.
    func firstKey(for value: AnyObject) -> Key? {
        for (key, val) in self {
            if val === value {
                return key
            }
        }
        return nil
    }
}
public extension DictionaryConvertible where Value: Equatable, Element == (key: Key, value: Value) {
#if !DEBUG
    @available(*, deprecated, renamed: "firstKey(for:)")
    func key(for value: Value) -> Key? {
        return firstKey(for: value)
    }
#endif
    /// return the first encountered key for the given equatable value.
    func firstKey(for value: Value) -> Key? {
        for (key, val) in self {
            if val == value {
                return key
            }
        }
        return nil
    }
}

#if compiler(>=5.9)
/// Portable coverage for the shared operators and reverse-lookup helpers.
///
/// Keeping this beside `DictionaryConvertible` ensures the app test UI exercises the same
/// implementation that package clients compile, including Foundation-free and WASM builds.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#if !(os(WASM) || os(WASI))
@MainActor
#endif
internal let dictionaryConvertibleTests: [TestCase] = [
    TestCase("DictionaryConvertible merging and lookup") {
        var dictionary = ["a": 1, "b": 2]
        let ordered: OrderedDictionary = ["b": 20, "c": 3]
        dictionary += ordered
        try expectEqual(dictionary, ["a": 1, "b": 20, "c": 3])

        let merged = ["a": 1, "b": 2] + ordered
        try expectEqual(merged, ["a": 1, "b": 20, "c": 3])
        try expectEqual(merged.firstKey(for: 20), "b")

        final class Reference {}
        let first = Reference()
        let second = Reference()
        let references = ["first": first, "second": second]
        try expectEqual(references.firstKey(for: second), "second")
        try expect(references.firstKey(for: Reference()) == nil)
    },
]
#endif
