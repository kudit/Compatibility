//
//  Array.swift
//  KuditFrameworks
//
//  Created by Ben Ku on 1/9/16.
//  Copyright © 2016 Kudit. All rights reserved.
//

// we want this usable by Array and Set
public extension Collection {
    /// shuffle is native now

    /// Returns a shuffled array.
    /// - Returns: a shuffled copy of self
    var shuffled: [Iterator.Element] {
        get {
            var array = Array(self) // copy
            array.shuffle()
            return array
        }
    }
#if !DEBUG
    /// Returns a randomly selected item from the collection.
    @available(*, deprecated, message: "Use native randomElement() method")
    var randomItem: Iterator.Element {
        get {
            return self.randomElement()!
        }
    }
#endif
}


public extension Array {
    mutating func pad(to count: Int, with element: Element) {
        while self.count < count {
            self.append(element)
        }
    }
    /// returns an array with the elements of the base array repeated `count` times.  If count is less than 1, will return an empty array of the same type
    func repeated(_ count: Int) -> Self {
        var returnArray = self // so we get a copy of the same type of array
        
        guard count > 0 else {
            returnArray.removeAll()
            return returnArray
        }
        
        for _ in 1..<count { // 1 since first will be included above in self copy
            returnArray.append(contentsOf: self)
        }
        return returnArray
    }
    
    /// chunks the array into `size` sized chunks.  Last array may have fewer than `size` elements if it does not divide evenly.
    ///  https://www.hackingwithswift.com/example-code/language/how-to-split-an-array-into-chunks
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 && count > 0 else {
            return []
        }
//        return stride(from: 0, to: count, by: size).map {
//            Array(self[$0 ..< Swift.min($0 + size, count)])
//        }
        // `stride` has issues with RawRepresentable so do manually
        var results = [[Element]]()
        var progress = [Element]()
        for item in self {
            progress.append(item)
            if progress.count == size {
                results.append(progress)
                progress = []
            }
        }
        if !progress.isEmpty {
            results.append(progress)
        }
        return results
    }
}

// MARK: - RawRepresentable conformance when array contents are RawRepresentable.  Must conform an array to this so we don't force this version of the raw representation on all sequences.
public protocol RawRepresentableSequence: Sequence, ExpressibleByArrayLiteral, RawRepresentable where Element: RawRepresentable, RawValue == [Element.RawValue] {
    init<S>(_ s: S) where Element == S.Element, S : Sequence
}
public extension RawRepresentableSequence {
    init(rawValue: [Element.RawValue]) {
        self.init(rawValue.compactMap { Element(rawValue: $0) })
    }
    
    var rawValue: RawValue {
        self.map { $0.rawValue }
    }
}

public extension Array where Element: Hashable {
    /// Returns the collection with duplicate values in `self` removed.
    /// Similar to Array(Set(self)) but with order preserved.
    var unique: [Element] {
        get {
            var seen: [Element:Bool] = [:]
            return self.filter { (element) -> Bool in
                return seen.updateValue(true, forKey: element) == nil
            }
        }
    }
    /// Remove all duplicates from the array
    mutating func removeDuplicates() { // better name than "formUnique"
        self = self.unique
    }
}

public extension Array where Element: Equatable {
    /// Append the value only if it doesn't already exist.
    mutating func appendUnique(_ newItem: Element) {
        if !self.contains(newItem) {
            self.append(newItem)
        }
    }
}
public extension Collection where Element: Equatable {
    /// Returns `true` iff the array contains one of the values.
    func containsAny(_ needles: [Element]) -> Bool {
        for needle in needles {
            if self.contains(needle) {
                return true
            }
        }
        return false
    }
    
    /// Returns `true` iff the array contains all of the values.
    func containsAll(_ needles: [Element]) -> Bool {
        for needle in needles {
            if !self.contains(needle) {
                return false
            }
        }
        return true
    }
}

public extension Array where Element: Equatable {
#if !DEBUG
    /// like indexOf but with just the element instead of having to construct a predicate.
    @available(*, deprecated, message: "Use new native firstIndex(of:) method")
    func indexOf(item: Element) -> Int? {
        return self.firstIndex(of: item)
    }
#endif
    
    /// remove the object from the array if it exists
    mutating func remove(_ item: Element) {
        while let index = firstIndex(of: item) {
            self.remove(at: index)
        }
    }
}

public extension Collection {
    /// Return the Element at `index` iff the index is in bounds of the array.  Otherwise returns `nil`. Different from normal subscript as normal subscript will just crash with an out of bounds value and will never return nil.  Usage: array[safe:5]
    subscript (safe index: Index) -> Element? {
        guard self.indices.contains(index) else { return nil }
        return self[index]
    }
    @Sendable
    static func safeTests() throws {
        let array = [1,2,3]
        try expect(array[safe: 0] == 1, "Basic functionality fails")
        try expect(array[safe: 5] == nil, "Should be a safe nil return")
    }
    /// return the `nth` element.  If `nth` is more than the array size, loop around to the beginning (for use in getting an item in an array that should loop).  Will crash if array is empty.
    subscript (nth offset: Int) -> Element {
        let index = self.index(self.startIndex, offsetBy: offset % self.count)
        return self[index]
    }
    @Sendable
    static func modificationTests() throws {
        var array = ["apple", "pear", "orange"]
        let original = array
        array.appendUnique("apple")
        try expect(original == array)
        array.appendUnique("zoo")
        try expect(original != array)
        try expect(array.count == 4)
        
        try expect(!array.containsAny(["foo", "bar"]))
        try expect(array.containsAny(["foo", "zoo"]))
        try expect(!array.containsAll(["zoo", "bar"]))
        try expect(array.containsAll(["zoo", "pear"]))
        array.append("zoo")
        try expect(array.count == 5)
        let unique = array.unique
        array.removeDuplicates()
        try expect(array.count == 4)
        try expect(unique == array)
        
        let repeated = array.repeated(3)
        let chunked = repeated.chunked(into: 2)
        var chunk = chunked[5]
        try expect(chunk == ["orange", "zoo"])
        chunk.pad(to: 5, with: "x")
        try expect(chunk == ["orange", "zoo", "x", "x", "x"])
        let copy = chunk.shuffled
        try expect(copy != chunk, "should be randomized but there is a chance this could fail due to random chance")
    }
    @Sendable
    static func nthTests() throws {
        let array = [1,2,3]
        try expect(array[nth: 0] == 1, "Basic functionality fails")
        try expect(array[nth: 7] == 2, "Should be looped value")
    }
}
// Testing is only supported with Swift 5.9+
#if compiler(>=5.9)
@available(iOS 13, tvOS 13, watchOS 6, *)
#if !(os(WASM) || os(WASI))
@MainActor
#endif
let collectionTests: [Test] = [
    Test("identity", {
        let testSequence = [5, 4, 2, 1, 3]
        try expect(testSequence.repeated(0) == [])
        try expect(testSequence.chunked(into: 2) == [[5, 4], [2, 1], [3]])
        try expect(testSequence.sorted(by: \.self, isAscending: true) == [1, 2, 3, 4, 5])
        try expect(testSequence.average() == 3)
        try expect(testSequence.sum() == 15)
    }),
    Test("modification", [String].modificationTests),
    Test("safety", [Int].safeTests),
    Test("nth", [Int].nthTests),
    Test("OrderedSet", orderedSetTests),
]

// Array Identifiable
@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Array where Element: Identifiable {
    subscript(id: Element.ID) -> Element? {
        get {
            first { $0.id == id }
        }
        set {
            guard let index = firstIndex(where: { $0.id == id }) else {
                debug("Attempting to set a value in an array keyed by id subscript but index could not be found")
                return
            }
            guard let newValue else {
                debug("Attempting to set an id subscript value to nil")
                return
            }
            self[index] = newValue
        }
    }
}
#endif

// let arrayOfIdentifiables = []
// let itemWithId = arrayOfIdentifiables[id]

public extension Array {
    /// Sort array by KeyPath
    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>, isAscending: Bool = true) -> [Element] {
        return sorted {
            let lhs = $0[keyPath: keyPath]
            let rhs = $1[keyPath: keyPath]
            return isAscending ? lhs < rhs : lhs > rhs
        }
    }
}

// MARK: - Numeric collection functions

public extension Sequence where Element: AdditiveArithmetic {
    /// calculates the sum of the sequence
    func sum() -> Element {
        return self.reduce(.zero, +)
    }
}

public extension Collection where Element: DoubleConvertible & AdditiveArithmetic {
    /// calculates the average value of the collection
    func average() -> Double {
        return self.sum().doubleValue / self.count.doubleValue
    }
}

#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation)
import SwiftUI
@available(iOS 13, tvOS 13, watchOS 6, *)
#Preview("Tests") {
    TestsListView(tests: collectionTests)
}
#endif
