//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// An ordered collection of key-value pairs.
///
/// `OrderedDictionary` is a useful alternative to `Dictionary` when the order
/// of elements is important, or when you need to be able to efficiently access
/// elements at various positions within the collection.
///
/// You can create an ordered dictionary with any key type that conforms to the
/// `Hashable` protocol.
///
///     let responses: OrderedDictionary = [
///       200: "OK",
///       403: "Access forbidden",
///       404: "File not found",
///       500: "Internal server error",
///     ]
///
/// ### Equality of Ordered Dictionaries
///
/// Two ordered dictionaries are considered equal if they contain the same
/// elements, and *in the same order*. This matches the concept of equality of
/// an `Array`, and it is different from the unordered `Dictionary`.
///
///     let a: OrderedDictionary = [1: "one", 2: "two"]
///     let b: OrderedDictionary = [2: "two", 1: "one"]
///     a == b // false
///     b.swapAt(0, 1) // `b` now has value [1: "one", 2: "two"]
///     a == b // true
///
/// (`OrderedDictionary` only conforms to `Equatable` when its `Value` is
/// equatable.)
///
/// ### Dictionary Operations
///
/// `OrderedDictionary` provides many of the same operations as `Dictionary`.
///
/// For example, you can look up and add/remove values using the familiar
/// key-based subscript, returning an optional value:
///
///     var dictionary: OrderedDictionary<String, Int> = [:]
///     dictionary["one"] = 1
///     dictionary["two"] = 2
///     dictionary["three"] // nil
///     // dictionary is now ["one": 1, "two": 2]
///
/// If a new entry is added using the subscript setter, it gets appended to the
/// end of the dictionary. (So that by default, the dictionary contains its
/// elements in the order they were originally inserted.)
///
/// `OrderedDictionary` also implements the variant of this subscript that takes
/// a default value. Like with `Dictionary`, this is useful when you want to
/// perform in-place mutations on values:
///
///     let text = "short string"
///     var counts: OrderedDictionary<Character, Int> = [:]
///     for character in text {
///       counts[character, default: 0] += 1
///     }
///     // counts is ["s": 2, "h": 1, "o": 1,
///     //            "r": 2, "t": 2, " ": 1,
///     //            "i": 1, "n": 1, "g": 1]
///
/// If the `Value` type implements reference semantics, or when you need to
/// perform a series of individual mutations on the values, the closure-based
/// ``updateValue(forKey:default:with:)`` method provides an easier-to-use
/// alternative to the defaulted key-based subscript.
///
///     let text = "short string"
///     var counts: OrderedDictionary<Character, Int> = [:]
///     for character in text {
///       counts.updateValue(forKey: character, default: 0) { value in
///         value += 1
///       }
///     }
///     // Same result as before
///
/// (This isn't currently available on the regular `Dictionary`.)
///
/// The `Dictionary` type's original ``updateValue(_:forKey:)`` method is also
/// available, and so is ``index(forKey:)``, grouping/uniquing initializers
/// (``init(uniqueKeysWithValues:)-5ux9r``, ``init(_:uniquingKeysWith:)-2y39b``,
/// ``init(grouping:by:)-6mahw``), methods for merging one dictionary with
/// another (``merge(_:uniquingKeysWith:)-6ka2i``,
/// ``merging(_:uniquingKeysWith:)-4z49c``), filtering dictionary entries
/// (``filter(_:)``), transforming values (``mapValues(_:)``), and a combination
/// of these two (``compactMapValues(_:)``).
///
/// ### Sequence and Collection Operations
///
/// Ordered dictionaries use integer indices representing offsets from the
/// beginning of the collection. However, to avoid ambiguity between key-based
/// and indexing subscripts, `OrderedDictionary` doesn't directly conform to
/// `Collection`. Instead, it only conforms to `Sequence`, and provides a
/// random-access collection view over its key-value pairs, called
/// ``elements-swift.property``:
///
///     responses[0] // `nil` (key-based subscript)
///     responses.elements[0] // `(200, "OK")` (index-based subscript)
///
/// Because ordered dictionaries need to maintain unique keys, neither
/// `OrderedDictionary` nor its `elements` view can conform to the full
/// `MutableCollection` or `RangeReplaceableCollection` protocols.
/// However, `OrderedDictioanr` is still able to implement some of the
/// requirements of these protocols. In particular, it supports permutation
/// operations from `MutableCollection`:
///
/// - ``swapAt(_:_:)``
/// - ``partition(by:)``
/// - ``sort()``, ``sort(by:)``
/// - ``shuffle()``, ``shuffle(using:)``
/// - ``reverse()``
///
/// It also supports removal operations from `RangeReplaceableCollection`:
///
/// - ``removeAll(keepingCapacity:)``
/// - ``remove(at:)``
/// - ``removeSubrange(_:)-512n3``, ``removeSubrange(_:)-8rmzx``
/// - ``removeLast()``, ``removeLast(_:)``
/// - ``removeFirst()``, ``removeFirst(_:)``
/// - ``removeAll(where:)``
///
/// `OrderedDictionary` also implements ``reserveCapacity(_:)`` from
/// `RangeReplaceableCollection`, to allow for efficient insertion of a known
/// number of elements. (However, unlike `Array` and `Dictionary`,
/// `OrderedDictionary` does not provide a `capacity` property.)
///
/// ### Keys and Values Views
///
/// Like the standard `Dictionary`, `OrderedDictionary` provides ``keys`` and
/// ``values-swift.property`` properties that provide lightweight views into
/// the corresponding parts of the dictionary.
///
/// The ``keys`` collection is of type ``OrderedSet``, containing all the keys
/// in the original dictionary.
///
///     let d: OrderedDictionary = [2: "two", 1: "one", 0: "zero"]
///     d.keys // [2, 1, 0] as OrderedSet<Int>
///
/// The ``keys`` property is read-only, so you cannot mutate the dictionary
/// through it. However, it returns an ordinary ordered set value, which can be
/// copied out and then mutated if desired. (Such mutations won't affect the
/// original dictionary value.)
///
/// The ``values-swift.property`` collection is a mutable random-access
/// ordered collection of the values in the dictionary:
///
///     d.values // "two", "one", "zero"
///     d.values[2] = "nada"
///     // `d` is now [2: "two", 1: "one", 0: "nada"]
///     d.values.sort()
///     // `d` is now [2: "nada", 1: "one", 0: "two"]
///
/// Both views store their contents in regular `Array` values, accessible
/// through their ``elements-swift.property`` property.
///
/// ## Performance
///
/// An ordered dictionary consists of an ``OrderedSet`` of keys, alongside a
/// regular `Array` value that contains their associated values.
/// The performance characteristics of `OrderedDictionary` are mostly dictated
/// by this setup.
///
/// - Looking up a member in an ordered dictionary is expected to execute
///    a constant number of hashing and equality check operations, just like
///    the standard `Dictionary`.
/// - `OrderedDictionary` is also able to append new items at the end of the
///    dictionary with an expected amortized complexity of O(1), similar to
///    inserting new items into `Dictionary`.
/// - Unfortunately, removing or inserting items at the start or middle of an
///    `OrderedDictionary` has linear complexity, making these significantly
///    slower than `Dictionary`.
/// - Storing keys and values outside of the hash table makes
///    `OrderedDictionary` more memory efficient than most alternative
///    ordered dictionary representations. It can sometimes also be more memory
///    efficient than the standard `Dictionary`, despote the additional
///    functionality of preserving element ordering.
///
/// Like all hashed data structures, ordered dictionaries are extremely
/// sensitive to the quality of the `Key` type's `Hashable` conformance.
/// All complexity guarantees are null and void if `Key` implements `Hashable`
/// incorrectly.
///
/// See ``OrderedSet`` for a more detailed discussion of these performance
/// characteristics.
@frozen
public struct OrderedDictionary<Key: Hashable, Value> {
    @usableFromInline
    internal var _keys: OrderedSet<Key>
    
    @usableFromInline
    internal var _values: [Value]
}

// MARK: - Initialization
extension OrderedDictionary {
    /// Creates a new empty ordered dictionary.
    public init() {
        _keys = []
        _values = []
    }
    
    /// Creates a new dictionary from the key-value pairs in the given sequence.
    ///
    /// You use this initializer to create a dictionary when you have a sequence
    /// of key-value tuples with unique keys. Passing a sequence with duplicate
    /// keys to this initializer results in a runtime error. If your
    /// sequence might have duplicate keys, use the
    /// `Dictionary(_:uniquingKeysWith:)` initializer instead.
    ///
    /// - Parameter keysAndValues: A sequence of key-value pairs to use for
    ///   the new dictionary. Every key in `keysAndValues` must be unique.
    ///
    /// - Returns: A new dictionary initialized with the elements of
    ///   `keysAndValues`.
    ///
    /// - Precondition: The sequence must not have duplicate keys.
    ///
    /// - Complexity: Expected O(*n*) on average, where *n* is the count if
    ///    key-value pairs, if `Key` implements high-quality hashing.
    @inlinable
    public init(
        uniqueKeysWithValues keysAndValues: some Sequence<(Key, Value)>
    ) {
        self.init()
        for (key, value) in keysAndValues {
            self[key] = value
        }
    }
}

// MARK: - Introspection
extension OrderedDictionary {
    /// A read-only ordered collection view for the keys contained in this dictionary, as
    /// an `OrderedSet`.
    @inlinable
    @inline(__always)
    public var keys: OrderedSet<Key> { _keys }
    
    /// A mutable collection view containing the ordered values in this dictionary. // TODO: Is this actually mutable??
    @inlinable
    @inline(__always)
    public var values: [Value] { _values }
}

extension OrderedDictionary {
    /// A Boolean value indicating whether the dictionary is empty.
    @inlinable
    @inline(__always)
    public var isEmpty: Bool { _values.isEmpty }
    
    /// The number of elements in the dictionary.
    @inlinable
    @inline(__always)
    public var count: Int { _values.count }
    
    /// Returns the index for the given key.
    ///
    /// If the given key is found in the dictionary, this method returns an index
    /// into the dictionary that corresponds with the key-value pair.
    ///
    ///     let countryCodes: OrderedDictionary = ["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]
    ///     let index = countryCodes.index(forKey: "JP")
    ///
    ///     let (key, value) = countryCodes.elements[index!]
    ///     print("Country code for \(value): '\(key)'.")
    ///     // Prints "Country code for Japan: 'JP'."
    ///
    /// - Parameter key: The key to find in the dictionary.
    ///
    /// - Returns: The index for `key` and its associated value if `key` is in
    ///    the dictionary; otherwise, `nil`.
    @inlinable
    @inline(__always)
    public func index(forKey key: Key) -> Int? {
        _keys.firstIndex(of: key)
    }
}

extension OrderedDictionary {
    /// Accesses the value associated with the given key for reading and writing.
    ///
    /// This *key-based* subscript returns the value for the given key if the key
    /// is found in the dictionary, or `nil` if the key is not found.
    ///
    /// The following example creates a new dictionary and prints the value of a
    /// key found in the dictionary (`"Coral"`) and a key not found in the
    /// dictionary (`"Cerise"`).
    ///
    ///     var hues: OrderedDictionary = ["Heliotrope": 296, "Coral": 16, "Aquamarine": 156]
    ///     print(hues["Coral"])
    ///     // Prints "Optional(16)"
    ///     print(hues["Cerise"])
    ///     // Prints "nil"
    ///
    /// When you assign a value for a key and that key already exists, the
    /// dictionary overwrites the existing value. If the dictionary doesn't
    /// contain the key, the key and value are added as a new key-value pair.
    ///
    /// Here, the value for the key `"Coral"` is updated from `16` to `18` and a
    /// new key-value pair is added for the key `"Cerise"`.
    ///
    ///     hues["Coral"] = 18
    ///     print(hues["Coral"])
    ///     // Prints "Optional(18)"
    ///
    ///     hues["Cerise"] = 330
    ///     print(hues["Cerise"])
    ///     // Prints "Optional(330)"
    ///
    /// If you assign `nil` as the value for the given key, the dictionary
    /// removes that key and its associated value.
    ///
    /// In the following example, the key-value pair for the key `"Aquamarine"`
    /// is removed from the dictionary by assigning `nil` to the key-based
    /// subscript.
    ///
    ///     hues["Aquamarine"] = nil
    ///     print(hues)
    ///     // Prints "["Coral": 18, "Heliotrope": 296, "Cerise": 330]"
    ///
    /// - Parameter key: The key to find in the dictionary.
    ///
    /// - Returns: The value associated with `key` if `key` is in the dictionary;
    ///   otherwise, `nil`.
    ///
    /// - Complexity: Looking up values in the dictionary through this subscript
    ///    has an expected complexity of O(1) hashing/comparison operations on
    ///    average, if `Key` implements high-quality hashing. Updating the
    ///    dictionary also has an amortized expected complexity of O(1) --
    ///    although individual updates may need to copy or resize the dictionary's
    ///    underlying storage.
    @inlinable
    public subscript(key: Key) -> Value? {
        get {
            guard let index = _keys.firstIndex(of: key) else { return nil }
            return _values[index]
        }
        set {
            let index = _keys.firstIndex(of: key) // optional
            guard let newValue else {
                if let index {
                    // remove existing
                    _keys.remove(at: index)
                    _values.remove(at: index)
                } else {
                    // Noop
                }
                return
            }
            if let index {
                // modify existing
                _values[index] = newValue
            } else {
                // add missing (already checked that index doesn't exist so never should fail)
                _keys.append(key)
                _values.append(newValue)
                // indicies should match
            }
        }
    }
    
    /// Accesses the value with the given key. If the dictionary doesn't contain
    /// the given key, accesses the provided default value as if the key and
    /// default value existed in the dictionary.
    ///
    /// Use this subscript when you want either the value for a particular key
    /// or, when that key is not present in the dictionary, a default value. This
    /// example uses the subscript with a message to use in case an HTTP response
    /// code isn't recognized:
    ///
    ///     var responseMessages: OrderedDictionary = [
    ///         200: "OK",
    ///         403: "Access forbidden",
    ///         404: "File not found",
    ///         500: "Internal server error"]
    ///
    ///     let httpResponseCodes = [200, 403, 301]
    ///     for code in httpResponseCodes {
    ///         let message = responseMessages[code, default: "Unknown response"]
    ///         print("Response \(code): \(message)")
    ///     }
    ///     // Prints "Response 200: OK"
    ///     // Prints "Response 403: Access forbidden"
    ///     // Prints "Response 301: Unknown response"
    ///
    /// When a dictionary's `Value` type has value semantics, you can use this
    /// subscript to perform in-place operations on values in the dictionary.
    /// The following example uses this subscript while counting the occurrences
    /// of each letter in a string:
    ///
    ///     let message = "Hello, Elle!"
    ///     var letterCounts: OrderedDictionary<Character, Int> = [:]
    ///     for letter in message {
    ///         letterCounts[letter, default: 0] += 1
    ///     }
    ///     // letterCounts == ["H": 1, "e": 2, "l": 4, "o": 1, ...]
    ///
    /// When `letterCounts[letter, defaultValue: 0] += 1` is executed with a
    /// value of `letter` that isn't already a key in `letterCounts`, the
    /// specified default value (`0`) is returned from the subscript,
    /// incremented, and then added to the dictionary under that key.
    ///
    /// - Note: Do not use this subscript to modify dictionary values if the
    ///   dictionary's `Value` type is a class. In that case, the default value
    ///   and key are not written back to the dictionary after an operation. (For
    ///   a variant of this operation that supports this usecase, see
    ///   `updateValue(forKey:default:_:)`.)
    ///
    /// - Parameters:
    ///   - key: The key the look up in the dictionary.
    ///   - defaultValue: The default value to use if `key` doesn't exist in the
    ///     dictionary.
    ///
    /// - Returns: The value associated with `key` in the dictionary; otherwise,
    ///   `defaultValue`.
    ///
    /// - Complexity: Looking up values in the dictionary through this subscript
    ///    has an expected complexity of O(1) hashing/comparison operations on
    ///    average, if `Key` implements high-quality hashing. Updating the
    ///    dictionary also has an amortized expected complexity of O(1) --
    ///    although individual updates may need to copy or resize the dictionary's
    ///    underlying storage.
    @inlinable
    public subscript(
        _ key: Key,
        default defaultValue: @autoclosure () -> Value
    ) -> Value {
        get {
            guard let offset = _keys.firstIndex(of: key) else { return defaultValue() }
            return _values[offset]
        }
        set {
            self[key] = newValue // a += should automatically query the default value as the base during the get {}
        }
    }
}

extension OrderedDictionary {
    /// Updates the value stored in the dictionary for the given key, or appends a
    /// new key-value pair if the key does not exist.
    ///
    /// Use this method instead of key-based subscripting when you need to know
    /// whether the new value supplants the value of an existing key. If the
    /// value of an existing key is updated, `updateValue(_:forKey:)` returns
    /// the original value.
    ///
    ///     var hues: OrderedDictionary = [
    ///         "Heliotrope": 296,
    ///         "Coral": 16,
    ///         "Aquamarine": 156]
    ///
    ///     if let oldValue = hues.updateValue(18, forKey: "Coral") {
    ///         print("The old value of \(oldValue) was replaced with a new one.")
    ///     }
    ///     // Prints "The old value of 16 was replaced with a new one."
    ///
    /// If the given key is not present in the dictionary, this method appends the
    /// key-value pair and returns `nil`.
    ///
    ///     if let oldValue = hues.updateValue(330, forKey: "Cerise") {
    ///         print("The old value of \(oldValue) was replaced with a new one.")
    ///     } else {
    ///         print("No value was found in the dictionary for that key.")
    ///     }
    ///     // Prints "No value was found in the dictionary for that key."
    ///
    /// - Parameters:
    ///   - value: The new value to add to the dictionary.
    ///   - key: The key to associate with `value`. If `key` already exists in
    ///     the dictionary, `value` replaces the existing associated value. If
    ///     `key` isn't already a key of the dictionary, the `(key, value)` pair
    ///     is added.
    ///
    /// - Returns: The value that was replaced, or `nil` if a new key-value pair
    ///   was added.
    @inlinable
    @discardableResult
    public mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
        let existing = self[key]
        self[key] = value
        return existing
    }
}

extension OrderedDictionary {
    /// Removes the given key and its associated value from the dictionary.
    ///
    /// If the key is found in the dictionary, this method returns the key's
    /// associated value.
    ///
    ///     var hues: OrderedDictionary = [
    ///        "Heliotrope": 296,
    ///        "Coral": 16,
    ///        "Aquamarine": 156]
    ///     if let value = hues.removeValue(forKey: "Coral") {
    ///         print("The value \(value) was removed.")
    ///     }
    ///     // Prints "The value 16 was removed."
    ///
    /// If the key isn't found in the dictionary, `removeValue(forKey:)` returns
    /// `nil`.
    ///
    ///     if let value = hues.removeValue(forKey: "Cerise") {
    ///         print("The value \(value) was removed.")
    ///     } else {
    ///         print("No value found for that key.")
    ///     }
    ///     // Prints "No value found for that key.""
    ///
    /// - Parameter key: The key to remove along with its associated value.
    /// - Returns: The value that was removed, or `nil` if the key was not
    ///   present in the dictionary.
    @inlinable
    @discardableResult
    public mutating func removeValue(forKey key: Key) -> Value? {
        let existing = self[key]
        self[key] = nil
        return existing
    }
}

// MARK: - Merging
extension OrderedDictionary {
    /// Merges the key-value pairs in the given sequence into the dictionary,
    /// using a combining closure to determine the value for any duplicate keys.
    ///
    /// Use the `combine` closure to select a value to use in the updated
    /// dictionary, or to combine existing and new values. As the key-value
    /// pairs are merged with the dictionary, the `combine` closure is called
    /// with the current and new values for any duplicate keys that are
    /// encountered.
    ///
    /// This example shows how to choose the current or new values for any
    /// duplicate keys:
    ///
    ///     var dictionary: OrderedDictionary = ["a": 1, "b": 2]
    ///
    ///     // Keeping existing value for key "a":
    ///     dictionary.merge(zip(["a", "c"], [3, 4])) { (current, _) in current }
    ///     // ["a": 1, "b": 2, "c": 4]
    ///
    ///     // Taking the new value for key "a":
    ///     dictionary.merge(zip(["a", "d"], [5, 6])) { (_, new) in new }
    ///     // ["a": 5, "b": 2, "c": 4, "d": 6]
    ///
    /// This operation preserves the order of keys in the original dictionary.
    /// New key-value pairs are appended to the end in the order they appear in
    /// the given sequence.
    ///
    /// - Parameters:
    ///   - keysAndValues: A sequence of key-value pairs.
    ///   - combine: A closure that takes the current and new values for any
    ///     duplicate keys. The closure returns the desired value for the final
    ///     dictionary.
    @inlinable
    public mutating func merge(
        _ keysAndValues: __owned some Sequence<(key: Key, value: Value)>,
        uniquingKeysWith combine: (Value, Value) throws -> Value
    ) rethrows {
        for (key, value) in keysAndValues {
            if let index = _keys.firstIndex(of: key) {
                // update existing value using combine function
                try { $0 = try combine($0, value) }(&_values[index])
            } else {
                self[key] = value
            }
        }
    }
    
    /// Creates a dictionary by merging key-value pairs in a sequence into this
    /// dictionary, using a combining closure to determine the value for
    /// duplicate keys.
    ///
    /// Use the `combine` closure to select a value to use in the returned
    /// dictionary, or to combine existing and new values. As the key-value
    /// pairs are merged with the dictionary, the `combine` closure is called
    /// with the current and new values for any duplicate keys that are
    /// encountered.
    ///
    /// This example shows how to choose the current or new values for any
    /// duplicate keys:
    ///
    ///     let dictionary: OrderedDictionary = ["a": 1, "b": 2]
    ///     let newKeyValues = zip(["a", "b"], [3, 4])
    ///
    ///     let keepingCurrent = dictionary.merging(newKeyValues) { (current, _) in current }
    ///     // ["a": 1, "b": 2]
    ///     let replacingCurrent = dictionary.merging(newKeyValues) { (_, new) in new }
    ///     // ["a": 3, "b": 4]
    ///
    /// - Parameters:
    ///   - other: A sequence of key-value pairs.
    ///   - combine: A closure that takes the current and new values for any
    ///     duplicate keys. The closure returns the desired value for the final
    ///     dictionary.
    ///
    /// - Returns: A new dictionary with the combined keys and values of this
    ///    dictionary and `other`. The order of keys in the result dictionary
    ///    matches that of `self`, with additional key-value pairs (if any)
    ///    appended at the end in the order they appear in `other`.
    @inlinable
    public __consuming func merging(
        _ other: __owned some Sequence<(key: Key, value: Value)>,
        uniquingKeysWith combine: (Value, Value) throws -> Value
    ) rethrows -> Self {
        var copy = self
        try copy.merge(other, uniquingKeysWith: combine)
        return copy
    }
}

// MARK: - Transforms
extension OrderedDictionary {
    /// Returns a new dictionary containing the key-value pairs of the dictionary
    /// that satisfy the given predicate.
    ///
    /// - Parameter isIncluded: A closure that takes a key-value pair as its
    ///   argument and returns a Boolean value indicating whether the pair
    ///   should be included in the returned dictionary.
    ///
    /// - Returns: A dictionary of the key-value pairs that `isIncluded` allows,
    ///    in the same order that they appear in `self`.
    ///
    /// - Complexity: O(`count`)
    @inlinable
    public func filter(
        _ isIncluded: (Element) throws -> Bool
    ) rethrows -> Self {
        var result: OrderedDictionary = [:]
        for element in self where try isIncluded(element) {
            result[element.key] = element.value
        }
        return result
    }
}

extension OrderedDictionary {
    /// Returns a new dictionary containing the keys of this dictionary with the
    /// values transformed by the given closure.
    ///
    /// - Parameter transform: A closure that transforms a value. `transform`
    ///   accepts each value of the dictionary as its parameter and returns a
    ///   transformed value of the same or of a different type.
    /// - Returns: A dictionary containing the keys and transformed values of
    ///   this dictionary, in the same order.
    ///
    /// - Complexity: O(`count`)
    public func mapValues<T>(
        _ transform: (Value) throws -> T
    ) rethrows -> OrderedDictionary<Key, T> {
        OrderedDictionary<Key, T>(
            _keys: _keys,
            _values: try _values.map(transform))
    }
    
    /// Returns a new dictionary containing only the key-value pairs that have
    /// non-`nil` values as the result of transformation by the given closure.
    ///
    /// Use this method to receive a dictionary with non-optional values when
    /// your transformation produces optional values.
    ///
    /// In this example, note the difference in the result of using `mapValues`
    /// and `compactMapValues` with a transformation that returns an optional
    /// `Int` value.
    ///
    ///     let data: OrderedDictionary = ["a": "1", "b": "three", "c": "///4///"]
    ///
    ///     let m: [String: Int?] = data.mapValues { str in Int(str) }
    ///     // ["a": Optional(1), "b": nil, "c": nil]
    ///
    ///     let c: [String: Int] = data.compactMapValues { str in Int(str) }
    ///     // ["a": 1]
    ///
    /// - Parameter transform: A closure that transforms a value. `transform`
    ///   accepts each value of the dictionary as its parameter and returns an
    ///   optional transformed value of the same or of a different type.
    ///
    /// - Returns: A dictionary containing the keys and non-`nil` transformed
    ///   values of this dictionary, in the same order.
    ///
    /// - Complexity: O(`count`)
    @inlinable
    public func compactMapValues<T>(
        _ transform: (Value) throws -> T?
    ) rethrows -> OrderedDictionary<Key, T> {
        var result: OrderedDictionary<Key, T> = [:]
        for (key, value) in self {
            if let value = try transform(value) {
                result[key] = value
            }
        }
        return result
    }
}


// MARK: - CustomStringConvertible
extension OrderedDictionary: CustomStringConvertible {
    // A textual representation of this instance.
    public var description: String {
        guard !_values.isEmpty else { return "[:]" }
        var result = "["
        var first = true
        for (key, value) in elements {
            if first {
                first = false
            } else {
                result += ", "
            }
            debugPrint(key, terminator: "", to: &result)
            result += ": "
            debugPrint(value, terminator: "", to: &result)
        }
        result += "]"
        return result
    }
}

extension OrderedDictionary: CustomDebugStringConvertible {
    /// A textual representation of this instance, suitable for debugging.
    public var debugDescription: String {
        description
    }
}


// MARK: - Sequence and Iterators
extension OrderedDictionary: Sequence {
    /// The element type of a dictionary: a tuple containing an individual
    /// key-value pair.
    public typealias Element = (key: Key, value: Value)
    
    /// The type that allows iteration over an ordered dictionary's elements.
    @frozen
    public struct Iterator: IteratorProtocol {
        @usableFromInline
        internal let _base: OrderedDictionary
        
        @usableFromInline
        internal var _position: Int
        
        @inlinable
        @inline(__always)
        internal init(_base: OrderedDictionary) {
            self._base = _base
            self._position = 0
        }
        
        /// Advances to the next element and returns it, or nil if no next
        /// element exists.
        ///
        /// - Complexity: O(1)
        @inlinable
        public mutating func next() -> Element? {
            guard _position < _base._values.count else { return nil }
            let result = (_base._keys[_position], _base._values[_position])
            _position += 1
            return result
        }
    }
    
    /// Returns an iterator over the elements of this collection.
    ///
    /// - Complexity: O(1)
    @inlinable
    @inline(__always)
    public func makeIterator() -> Iterator {
        Iterator(_base: self)
    }
}

// MARK: - Sendable conformances
extension OrderedDictionary: Sendable
where Key: Sendable, Value: Sendable {}

extension OrderedDictionary.Iterator: Sendable
where Key: Sendable, Value: Sendable {}


// MARK: - Swapping
extension OrderedDictionary {
    /// Exchanges the key-value pairs at the specified indices of the dictionary.
    ///
    /// Both parameters must be valid indices below `endIndex`. Passing the same
    /// index as both `i` and `j` has no effect.
    ///
    /// - Parameters:
    ///   - i: The index of the first value to swap.
    ///   - j: The index of the second value to swap.
    ///
    /// - Complexity: O(1) when the dictionary's storage isn't shared with another
    ///    value; O(`count`) otherwise.
    @inlinable
    public mutating func swapAt(_ i: Int, _ j: Int) {
        _keys.swapAt(i, j)
        _values.swapAt(i, j)
    }
}

// MARK: - Sorting
extension OrderedDictionary {
    /// Returns the collection sorted using the given predicate as the
    /// comparison between elements.
    ///
    /// When you want to sort a collection of elements that don't conform to
    /// the `Comparable` protocol, pass a closure to this method that returns
    /// `true` when the first element should be ordered before the second.
    ///
    /// Alternatively, use this method to sort a collection of elements that do
    /// conform to `Comparable` when you want the sort to be descending instead
    /// of ascending. Pass the greater-than operator (`>`) operator as the
    /// predicate.
    ///
    /// `areInIncreasingOrder` must be a *strict weak ordering* over the
    /// elements. That is, for any elements `a`, `b`, and `c`, the following
    /// conditions must hold:
    ///
    /// - `areInIncreasingOrder(a, a)` is always `false`. (Irreflexivity)
    /// - If `areInIncreasingOrder(a, b)` and `areInIncreasingOrder(b, c)` are
    ///   both `true`, then `areInIncreasingOrder(a, c)` is also `true`.
    ///   (Transitive comparability)
    /// - Two elements are *incomparable* if neither is ordered before the other
    ///   according to the predicate. If `a` and `b` are incomparable, and `b`
    ///   and `c` are incomparable, then `a` and `c` are also incomparable.
    ///   (Transitive incomparability)
    ///
    /// The sorting algorithm is guaranteed to be stable. A stable sort
    /// preserves the relative order of elements for which
    /// `areInIncreasingOrder` does not establish an order.
    ///
    /// - Parameter areInIncreasingOrder: A predicate that returns `true` if its
    ///   first argument should be ordered before its second argument;
    ///   otherwise, `false`. If `areInIncreasingOrder` throws an error during
    ///   the sort, the elements may be in a different order, but none will be
    ///   lost.
    @inlinable
    public func sorted(
        by areInIncreasingOrder: (Element, Element) throws -> Bool
    ) rethrows -> Self {
        let newKeyOrder = try _keys.sorted { leftKey, rightKey in
            guard let leftValue = self[leftKey], let rightValue = self[rightKey] else {
                throw CustomError("Found invalid key during sort: \(leftKey) or \(rightKey)", level: .ERROR) // this should theoretically never happen as this should be only ever using existing keys unless we somehow modify during this iteration
            }
            let leftElement: Element = (key: leftKey, value: leftValue)
            let rightElement: Element = (key: rightKey, value: rightValue)
            return try areInIncreasingOrder(leftElement, rightElement)
        }
        var sorted = Self()
        for key in newKeyOrder {
            guard let value = self[key] else {
                debug("Found invalid key during sort: \(key)", level: .ERROR) // this should theoretically never happen as this should be only ever using existing keys unless we somehow modify during this iteration
                continue
            }
            sorted[key] = value
        }
        return sorted
    }


    /// Sorts the collection in place, using the given predicate as the
    /// comparison between elements.
    ///
    /// When you want to sort a collection of elements that don't conform to
    /// the `Comparable` protocol, pass a closure to this method that returns
    /// `true` when the first element should be ordered before the second.
    ///
    /// Alternatively, use this method to sort a collection of elements that do
    /// conform to `Comparable` when you want the sort to be descending instead
    /// of ascending. Pass the greater-than operator (`>`) operator as the
    /// predicate.
    ///
    /// `areInIncreasingOrder` must be a *strict weak ordering* over the
    /// elements. That is, for any elements `a`, `b`, and `c`, the following
    /// conditions must hold:
    ///
    /// - `areInIncreasingOrder(a, a)` is always `false`. (Irreflexivity)
    /// - If `areInIncreasingOrder(a, b)` and `areInIncreasingOrder(b, c)` are
    ///   both `true`, then `areInIncreasingOrder(a, c)` is also `true`.
    ///   (Transitive comparability)
    /// - Two elements are *incomparable* if neither is ordered before the other
    ///   according to the predicate. If `a` and `b` are incomparable, and `b`
    ///   and `c` are incomparable, then `a` and `c` are also incomparable.
    ///   (Transitive incomparability)
    ///
    /// The sorting algorithm is guaranteed to be stable. A stable sort
    /// preserves the relative order of elements for which
    /// `areInIncreasingOrder` does not establish an order.
    ///
    /// - Parameter areInIncreasingOrder: A predicate that returns `true` if its
    ///   first argument should be ordered before its second argument;
    ///   otherwise, `false`. If `areInIncreasingOrder` throws an error during
    ///   the sort, the elements may be in a different order, but none will be
    ///   lost.
    @inlinable
    public mutating func sort(
        by areInIncreasingOrder: (Element, Element) throws -> Bool
    ) rethrows {
        self = try sorted(by: areInIncreasingOrder)
    }
}

extension OrderedDictionary where Key: Comparable {
    /// Sorts the dictionary in place.
    ///
    /// You can sort an ordered dictionary of keys that conform to the
    /// `Comparable` protocol by calling this method. The key-value pairs are
    /// sorted in ascending order. (`Value` doesn't need to conform to
    /// `Comparable` because the keys are guaranteed to be unique.)
    ///
    /// The sorting algorithm is guaranteed to be stable. A stable sort
    /// preserves the relative order of elements that compare as equal.
    ///
    /// - Complexity: O(*n* log *n*), where *n* is the length of the collection.
    @inlinable
    public mutating func sort() {
        sort { $0.key < $1.key }
    }
    
    public func sorted() -> Self {
        sorted { $0.key < $1.key }
    }
}

// MARK: - Shuffling
extension OrderedDictionary {
    /// Returns a shuffled version of the collection.
    ///
    /// This method is equivalent to calling ``shuffle(using:)``, passing in the
    /// system's default random generator.
    @inlinable
    public func shuffled() -> Self {
        var copy = self
        copy.shuffle()
        return copy
    }

    /// Shuffles the collection in place.
    ///
    /// Use the `shuffle()` method to randomly reorder the elements of an ordered
    /// dictionary.
    ///
    /// This method is equivalent to calling ``shuffle(using:)``, passing in the
    /// system's default random generator.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @inlinable
    public mutating func shuffle() {
        var generator = SystemRandomNumberGenerator()
        shuffle(using: &generator)
    }
    
    /// Shuffles the collection in place, using the given generator as a source
    /// for randomness.
    ///
    /// You use this method to randomize the elements of a collection when you
    /// are using a custom random number generator. For example, you can use the
    /// `shuffle(using:)` method to randomly reorder the elements of an array.
    ///
    /// - Parameter generator: The random number generator to use when shuffling
    ///   the collection.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    ///
    /// - Note: The algorithm used to shuffle a collection may change in a future
    ///   version of Swift. If you're passing a generator that results in the
    ///   same shuffled order each time you run your program, that sequence may
    ///   change when your program is compiled using a different version of
    ///   Swift.
    public mutating func shuffle(
        using generator: inout some RandomNumberGenerator
    ) {
        guard count > 1 else { return }
        var keys = self._keys
        var values = self._values
        var amount = keys.count
        var current = 0
        while amount > 1 {
            let random = Int.random(in: 0 ..< amount, using: &generator)
            amount -= 1
            keys.swapAt(current, current + random)
            values.swapAt(current, current + random)
            current += 1
        }
        self = Self(_keys: keys, _values: values)
    }
}

// MARK: - Reversing
extension OrderedDictionary {
    /// Reverses the elements of the ordered dictionary in place.
    ///
    /// - Complexity: O(`count`)
    @inlinable
    public mutating func reverse() {
        _keys.reverse()
        _values.reverse()
    }
    
    public func reversed() -> OrderedDictionary {
        var reversedSelf = self
        reversedSelf.reverse()
        return reversedSelf
    }
}

// MARK: - Hashable
extension OrderedDictionary: Hashable where Value: Hashable {
    /// Hashes the essential components of this value by feeding them into the
    /// given hasher.
    ///
    /// Complexity: O(`count`)
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(count) // Discriminator
        for (key, value) in self {
            hasher.combine(key)
            hasher.combine(value)
        }
    }
}

// MARK: - ExpressibleByDictionaryLiteral
extension OrderedDictionary: ExpressibleByDictionaryLiteral {
    /// Creates a new ordered dictionary from the contents of a dictionary
    /// literal.
    ///
    /// Do not call this initializer directly. It is used by the compiler when you
    /// use a dictionary literal. Instead, create a new ordered dictionary using a
    /// dictionary literal as its value by enclosing a comma-separated list of
    /// key-value pairs in square brackets. You can use a dictionary literal
    /// anywhere an ordered dictionary is expected by the type context.
    ///
    /// - Parameter elements: A variadic list of key-value pairs for the new
    ///    ordered dictionary.
    @inlinable
    public init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(uniqueKeysWithValues: elements)
    }
}

// MARK: - Equatable
extension OrderedDictionary: Equatable where Value: Equatable {
    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Two ordered dictionaries are considered equal if they contain the same
    /// key-value pairs, in the same order.
    ///
    /// - Complexity: O(`min(left.count, right.count)`)
    @inlinable
    public static func ==(left: Self, right: Self) -> Bool {
        left._keys == right._keys && left._values == right._values
    }
}

// MARK: - Elements array
extension OrderedDictionary {
    /// A view of the contents of this dictionary as a random-access collection.
    @inlinable
    @inline(__always)
    public var elements: Zip2Sequence<OrderedSet<Key>, [Value]> {
        zip(_keys, _values)
    }
}

// MARK: - Codable
#if !os(WASM)
extension OrderedDictionary: Encodable where Key: Encodable, Value: Encodable {
    /// Encodes the contents of this dictionary into the given encoder.
    ///
    /// The dictionary's contents are encoded as alternating key-value pairs in
    /// an unkeyed container.
    ///
    /// This function throws an error if any values are invalid for the given
    /// encoder's format.
    ///
    /// - Note: Unlike the standard `Dictionary` type, ordered dictionaries
    ///    always encode themselves into an unkeyed container, because
    ///    `Codable`'s keyed containers do not guarantee that they preserve the
    ///    ordering of the items they contain. (And in popular encoding formats,
    ///    keyed containers tend to map to unordered data structures -- e.g.,
    ///    JSON's "object" construct is explicitly unordered.)
    ///
    /// - Parameter encoder: The encoder to write data to.
    @inlinable
    public func encode(to encoder: Encoder) throws {
        // Encode contents as an array of alternating key-value pairs.
        var container = encoder.unkeyedContainer()
        for (key, value) in self {
            try container.encode(key)
            try container.encode(value)
        }
    }
}

extension OrderedDictionary: Decodable where Key: Decodable, Value: Decodable {
    /// Creates a new dictionary by decoding from the given decoder.
    ///
    /// `OrderedDictionary` expects its contents to be encoded as alternating
    /// key-value pairs in an unkeyed container.
    ///
    /// This initializer throws an error if reading from the decoder fails, or
    /// if the decoded contents are not in the expected format.
    ///
    /// - Note: Unlike the standard `Dictionary` type, ordered dictionaries
    ///    always encode themselves into an unkeyed container, because
    ///    `Codable`'s keyed containers do not guarantee that they preserve the
    ///    ordering of the items they contain. (And in popular encoding formats,
    ///    keyed containers tend to map to unordered data structures -- e.g.,
    ///    JSON's "object" construct is explicitly unordered.)
    ///
    /// - Parameter decoder: The decoder to read data from.
    @inlinable
    public init(from decoder: Decoder) throws {
        // We expect to be encoded as an array of alternating key-value pairs.
        var container = try decoder.unkeyedContainer()
        
        self.init()
        while !container.isAtEnd {
            let key = try container.decode(Key.self)
            let index = self._keys.firstIndex(of: key)
            guard index == nil else {
                let context = DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Duplicate key at offset \(container.currentIndex - 1)")
                throw DecodingError.dataCorrupted(context)
            }
            
            guard !container.isAtEnd else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "Unkeyed container reached end before value in key-value pair"
                    )
                )
            }
            let value = try container.decode(Value.self)
            self[key] = value
        }
    }
}
#endif

#if compiler(>=5.9)
#if !os(WASM)
@MainActor
#endif
internal var orderedDictionaryTests: TestClosure = {
    var ordered: OrderedDictionary = ["b": 2, "a": 1]
    let manipulated = ordered.sorted().reversed()
    try expect(ordered["c", default: 4] == 4)
    try expect(manipulated == ordered)
    let unordered = ordered.shuffled().dictionaryValue.dictionaryValue
    try expect(unordered.firstKey(for: 1) == "a")
    try expect(ordered.dictionaryValue == unordered)
// TODO: Figure out why this doesn't work.  It should given the extensions above!
//    ordered += unordered
//    let merged = ordered + unordered
    
#if !os(WASM)
    let encoded = ordered.asJSON()
    let decoded = try? OrderedDictionary<String, Int>(fromJSON: encoded)
    try expect(decoded == ordered)
#endif

    ordered.sort()
    ordered.updateValue(10, forKey: "b")
    ordered["d"] = 5
    ordered.removeValue(forKey: "a")
    
    try expect(ordered.keys == ["b", "d"])
    ordered.swapAt(0, 1)
    try expect(ordered.values == [5, 10])
    try expect(!ordered.isEmpty)
    try expect(ordered.count == 2)
    try expect(ordered.index(forKey: "b") == 1)
    for (key, value) in ordered {
        try expect(ordered[key] == value)
    }
    let d = ordered.description
    let dd = ordered.debugDescription
    
    let merged = ordered.merging(unordered) { (_, new) in new }
    let filtered = merged.filter { (key, value) in
        key == "b"
    }
    let mapped = ordered.mapValues { $0 * 10 }
    let cm = ordered.compactMapValues { Int.random(in: 0...1) == 0 ? nil : $0 }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
#if !os(WASM)
@MainActor
#endif
internal var dictionaryTests: [Test] = [
    Test("Ordered Dictionary Tests", orderedDictionaryTests),
]
#endif
