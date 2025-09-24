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
    @available(*, deprecated, renamed: "firstKey")
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
    @available(*, deprecated, renamed: "firstKey")
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
