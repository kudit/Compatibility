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


/// An ordered collection of unique elements.
///
/// Similar to the standard `Set`, ordered sets ensure that each element appears
/// only once in the collection, and they provide efficient tests for
/// membership. However, like `Array` (and unlike `Set`), ordered sets maintain
/// their elements in a particular user-specified order, and they support
/// efficient random-access traversal of their members.
///
/// `OrderedSet` is a useful alternative to `Set` when the order of elements is
/// important, or when you need to be able to efficiently access elements at
/// various positions within the collection. It can also be used instead of an
/// `Array` when each element needs to be unique, or when you need to be able to
/// quickly determine if a value is a member of the collection.
///
/// You can create an ordered set with any element type that conforms to the
/// `Hashable` protocol.
///
///     let buildingMaterials: OrderedSet = ["straw", "sticks", "bricks"]
///
///
/// # Equality of Ordered Sets
///
/// Two ordered sets are considered equal if they contain the same elements, and
/// *in the same order*. This matches the concept of equality of an `Array`, and
/// it is different from the unordered `Set`.
///
///     let a: OrderedSet = [1, 2, 3, 4]
///     let b: OrderedSet = [4, 3, 2, 1]
///     a == b // false
///     b.sort() // `b` now has value [1, 2, 3, 4]
///     a == b // true
///
/// # Set Operations
///
/// `OrderedSet` implements most, but not all, `SetAlgebra` requirements. In
/// particular, it supports the membership test ``contains(_:)`` as well as all
/// high-level set operations such as ``union(_:)-67y2h``,
/// ``intersection(_:)-4o09a`` or ``isSubset(of:)-ptij``.
///
///     buildingMaterials.contains("glass") // false
///     buildingMaterials.intersection(["bricks", "straw"]) // ["straw", "bricks"]
///
/// Operations that return an ordered set usually preserve the ordering of
/// elements in their input. For example, in the case of the `intersection` call
/// above, the ordering of elements in the result is guaranteed to match their
/// order in the first input set, `buildingMaterials`.
///
/// On the other hand, predicates such as ``isSubset(of:)-ptij`` tend to ignore
/// element ordering:
///
///     let moreMaterials: OrderedSet = ["bricks", "glass", "sticks", "straw"]
///     buildingMaterials.isSubset(of: moreMaterials) // true
///
/// `OrderedSet` does not implement `insert(_:)` nor `update(with:)` from
/// `SetAlgebra` -- it provides its own variants for insertion that are more
/// explicit about where in the collection new elements gets inserted:
///
///     func append(_ item: Element) -> (inserted: Bool, index: Int)
///     func insert(_ item: Element, at index: Int) -> (inserted: Bool, index: Int)
///     func updateOrAppend(_ item: Element) -> Element?
///     func updateOrInsert(_ item: Element, at index: Int) -> (originalMember: Element?, index: Int)
///     func update(_ item: Element, at index: Int) -> Element
///
/// Additionally,`OrderedSet` has an order-sensitive definition of equality (see
/// above) that is incompatible with `SetAlgebra`'s documented semantic
/// requirements. Accordingly, `OrderedSet` does not (cannot) itself conform to
/// `SetAlgebra`.
///
/// # Unordered Set View
///
/// For cases where `SetAlgebra` conformance is desired (such as when passing an
/// ordered set to a function that is generic over that protocol), `OrderedSet`
/// provides an efficient *unordered view* of its elements that conforms to
/// `SetAlgebra`. This view is accessed through the ``unordered`` property, and
/// it implements the same concept of equality as the standard `Set`, ignoring
/// element ordering.
///
///     var a: OrderedSet = [0, 1, 2, 3]
///     let b: OrderedSet = [3, 2, 1, 0]
///     a == b // false
///     a.unordered == b.unordered // true
///
///     func frobnicate<S: SetAlgebra>(_ set: S) { ... }
///     frobnicate(a) // error: `OrderedSet<String>` does not conform to `SetAlgebra`
///     frobnicate(a.unordered) // OK
///
/// The unordered view is mutable. Insertions into it implicitly append new
/// elements to the end of the collection.
///
///     buildingMaterials.unordered.insert("glass") // => inserted: true
///     // buildingMaterials is now ["straw", "sticks", "bricks", "glass"]
///
/// Accessing the unordered view is an efficient operation, with constant
/// (minimal) overhead. Direct mutations of the unordered view (such as the
/// insertion above) are executed in place when possible. However, as usual with
/// copy-on-write collections, if you make a copy of the view (such as by
/// extracting its value into a named variable), the resulting values will share
/// the same underlying storage, so mutations of either will incur a copy of the
/// whole set.
///
/// # Sequence and Collection Operations
///
/// Ordered sets are random-access collections. Members are assigned integer
/// indices, with the first element always being at index `0`:
///
///     let buildingMaterials: OrderedSet = ["straw", "sticks", "bricks"]
///     buildingMaterials[1] // "sticks"
///     buildingMaterials.firstIndex(of: "bricks") // 2
///
///     for i in 0 ..< buildingMaterials.count {
///       print("Little piggie #\(i) built a house of \(buildingMaterials[i])")
///     }
///     // Little piggie #0 built a house of straw
///     // Little piggie #1 built a house of sticks
///     // Little piggie #2 built a house of bricks
///
/// Because `OrderedSet` needs to keep its members unique, it cannot conform to
/// the full `MutableCollection` or `RangeReplaceableCollection` protocols.
/// Operations such as `MutableCollection`'s subscript setter or
/// `RangeReplaceableCollection`'s `replaceSubrange` method assume the ability
/// to insert/replace arbitrary elements in the collection, but allowing that
/// could lead to duplicate values.
///
/// However, `OrderedSet` is able to partially implement these two protocols;
/// namely, it supports mutation operations that merely change the
/// order of elements (such as ``sort()`` or ``swapAt(_:_:)``, or just remove
/// some subset of existing members (such as ``remove(at:)`` or
/// ``removeAll(where:)``).
///
/// Accordingly, `OrderedSet` provides permutation operations from `MutableCollection`:
/// - ``swapAt(_:_:)``
/// - ``partition(by:)``
/// - ``sort()``, ``sort(by:)``
/// - ``shuffle()``, ``shuffle(using:)``
/// - ``reverse()``
///
///
/// # Accessing The Contents of an Ordered Set as an Array
///
/// In cases where you need to pass the contents of an ordered set to a function
/// that only takes an array value or (or something that's generic over
/// `RangeReplaceableCollection` or `MutableCollection`), then the best option
/// is usually to directly extract the members of the `OrderedSet` as an `Array`
/// value using its ``elements`` property. `OrderedSet` uses a standard array
/// value for element storage, so extracting the array value has minimal
/// overhead.
///
///     func pickyFunction(_ items: Array<Int>)
///
///     var set: OrderedSet = [0, 1, 2, 3]
///     pickyFunction(set) // error
///     pickyFunction(set.elements) // OK
///
/// It is also possible to mutate the set by updating the value of the
/// ``elements`` property. This guarantees that direct mutations happen in place
/// when possible (i.e., without spurious copy-on-write copies).
///
/// However, the set needs to ensure the uniqueness of its members, so every
/// update to ``elements`` includes a postprocessing step to detect and remove
/// duplicates over the entire array. This can be slower than doing the
/// equivalent updates with direct `OrderedSet` operations, so updating
/// ``elements`` is best used in cases where direct implementations aren't
/// available -- for example, when you need to call a `MutableCollection`
/// algorithm that isn't directly implemented by `OrderedSet` itself.
///
/// # Performance
///
/// An `OrderedSet` stores its members in a standard `Array` value (exposed by
/// the ``elements`` property). It also maintains a separate hash table
/// containing array indices into this array; this hash table is used to ensure
/// member uniqueness and to implement fast membership tests.
///
/// ## Element Lookups
///
/// Like the standard `Set`, looking up a member is expected to execute
/// a constant number of hashing and equality check operations. To look up
/// an element, `OrderedSet` generates a hash value from it, and then finds a
/// set of array indices within the hash table that could potentially contain
/// the element we're looking for. By looking through these indices in the
/// storage array, `OrderedSet` is able to determine if the element is a member.
/// As long as `Element` properly implements hashing, the size of this set of
/// candidate indices is expected to have a constant upper bound, so looking up
/// an item will be a constant operation.
///
/// ## Appending New Items
///
/// Similarly, appending a new element to the end of an `OrderedSet` is expected
/// to require amortized O(1) hashing/comparison/copy operations on the
/// element type, just like inserting an item into a standard `Set`.
/// (If the ordered set value has multiple copies, then appending an item will
/// need to copy all its items into unique storage (again just like the standard
/// `Set`) -- but once the set has been uniqued, additional appends will only
/// perform a constant number of operations, so when averaged over many appends,
/// the overall complexity comes out as O(1).)
///
/// ## Removing Items and Inserting in Places Other Than the End
///
/// Unfortunately, `OrderedSet` does not emulate `Set`'s performance for all
/// operations. In particular, operations that insert or remove elements at the
/// front or in the middle of an ordered set are generally expected to be
/// significantly slower than with `Set`. To perform these operations, an
/// `OrderedSet` needs to perform the corresponding operation in the storage
/// array, and then it needs to renumber all subsequent members in the hash
/// table. Both of these phases take a number of steps that grows linearly with
/// the size of the ordered set, while the standard `Set` can do the
/// corresponding operations with O(1) expected complexity.
///
/// This generally makes `OrderedSet` a poor replacement to `Set` in use cases
/// that do not specifically require a particular element ordering.
///
/// ## Memory Utilization
///
/// The hash table in an ordered set never needs to store larger indices than
/// the current size of the storage array, and `OrderedSet` makes use of this
/// observation to reduce the number of bits it uses to encode these integer
/// values. Additionally, the actual hashed elements are stored in a flat array
/// value rather than the hash table itself, so they aren't subject to the hash
/// table's strict maximum load factor. These two observations combine to
/// optimize the memory utilization of `OrderedSet`, sometimes making it even
/// more efficient than the standard `Set` -- despite the additional
/// functionality of preserving element ordering.
///
/// ## Proper Hashing is Crucial
///
/// Similar to the standard `Set` type, the performance of hashing operations in
/// `OrderedSet` is highly sensitive to the quality of hashing implemented by
/// the `Element` type. Failing to correctly implement hashing can easily lead
/// to unacceptable performance, with the severity of the effect increasing with
/// the size of the hash table.
///
/// In particular, if a certain set of elements all produce the same hash value,
/// then hash table lookups regress to searching an element in an unsorted
/// array, i.e., a linear operation. To ensure hashed collection types exhibit
/// their target performance, it is important to ensure that such collisions
/// cannot be induced merely by adding a particular list of members to the set.
///
/// The easiest way to achieve this is to make sure `Element` implements hashing
/// following `Hashable`'s documented best practices. The `Element` type must
/// implement the `hash(into:)` requirement (not `hashValue`) in such a way that
/// every bit of information that is compared in `==` is fed into the supplied
/// `Hasher` value. When used correctly, `Hasher` produces high-quality,
/// randomly seeded hash values that prevent repeatable hash collisions and
/// therefore avoid (intentional or accidental) denial of service attacks.
///
/// Like with all hashed collection types, all complexity guarantees are null
/// and void if `Element` implements `Hashable` incorrectly. In the worst case,
/// the hash table can regress into a particularly slow implementation of an
/// unsorted array, with even basic lookup operations taking complexity
/// proportional to the size of the set.
@frozen
public struct OrderedSet<Element> where Element: Hashable {
    /// A view of the members of this set, as a regular array value.
    ///
    /// It is possible to mutate the set by updating the value of this property.
    /// This guarantees that direct mutations happen in place when possible (i.e.,
    /// without spurious copy-on-write copies).
    ///
    /// However, the set needs to ensure the uniqueness of its members, so every
    /// update to `elements` includes a postprocessing step to detect and remove
    /// duplicates over the entire array. This can be slower than doing the
    /// equivalent updates with direct `OrderedSet` operations, so updating
    /// `elements` is best used in cases where direct implementations aren't
    /// available -- for example, when you need to call a `MutableCollection`
    /// algorithm that isn't directly implemented by `OrderedSet` itself.
    public var elements: [Element]
}

extension OrderedSet {
    /// Returns the index of the given element in the set, or `nil` if the element
    /// is not a member of the set.
    ///
    /// `OrderedSet` members are always unique, so the first index of an element
    /// is always the same as its last index.
    @inlinable
    @inline(__always)
    public func firstIndex(of element: Element) -> Int? {
        elements.firstIndex(of: element)
    }
    
    /// Returns the index of the given element in the set, or `nil` if the element
    /// is not a member of the set.
    ///
    /// `OrderedSet` members are always unique, so the first index of an element
    /// is always the same as its last index.
    @inlinable
    @inline(__always)
    public func lastIndex(of element: Element) -> Int? {
        elements.lastIndex(of: element)
    }
}

extension OrderedSet {
    /// Returns a new ordered set containing all the members of this ordered set
    /// that satisfy the given predicate.
    ///
    /// - Parameter isIncluded: A closure that takes a value as its
    ///   argument and returns a Boolean value indicating whether the value
    ///   should be included in the returned dictionary.
    ///
    /// - Returns: An ordered set of the values that `isIncluded` allows.
    @inlinable
    public func filter(
        _ isIncluded: (Element) throws -> Bool
    ) rethrows -> Self {
        .init(try elements.filter(isIncluded))
    }
}

// MARK: - Codable
extension OrderedSet: Encodable where Element: Encodable {
    /// Encodes the elements of this ordered set into the given encoder.
    ///
    /// - Parameter encoder: The encoder to write data to.
    @inlinable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(elements)
    }
}

extension OrderedSet: Decodable where Element: Decodable {
    /// Creates a new ordered set by decoding from the given decoder.
    ///
    /// This initializer throws an error if reading from the decoder fails, or
    /// if the decoded contents contain duplicate values.
    ///
    /// - Parameter decoder: The decoder to read data from.
    @inlinable
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let elements = try container.decode(ContiguousArray<Element>.self)
        self.init(elements)
    }
}

// MARK: - Mirror
extension OrderedSet: CustomReflectable {
    /// The custom mirror for this instance.
    public var customMirror: Mirror {
        Mirror(self, unlabeledChildren: elements, displayStyle: .set)
    }
}


// MARK: - String Convertible
extension OrderedSet: CustomStringConvertible {
    /// A textual representation of this instance.
    public var description: String {
        elements.description
    }
}

extension OrderedSet: CustomDebugStringConvertible {
    /// A textual representation of this instance, suitable for debugging.
    public var debugDescription: String {
        elements.debugDescription
    }
}

// MARK: - Equatable

extension OrderedSet: Equatable {
    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Two ordered sets are considered equal if they contain the same
    /// elements in the same order.
    ///
    /// - Note: This operator implements different behavior than the
    ///    `isEqualSet(to:)` method -- the latter implements an unordered
    ///    comparison, to match the behavior of members like `isSubset(of:)`,
    ///    `isStrictSuperset(of:)` etc.
    @inlinable
    public static func ==(left: Self, right: Self) -> Bool {
        left.elements == right.elements
    }
}


// MARK: - ExpressibleByArrayLiteral

extension OrderedSet: ExpressibleByArrayLiteral {
    /// Creates a new ordered set from the contents of an array literal.
    ///
    /// Duplicate elements in the literal are allowed, but the resulting ordered
    /// set will only contain the first occurrence of each.
    ///
    /// Do not call this initializer directly. It is used by the compiler when
    /// you use an array literal. Instead, create a new ordered set using an array
    /// literal as its value by enclosing a comma-separated list of values in
    /// square brackets. You can use an array literal anywhere an ordered set is
    /// expected by the type context.
    ///
    /// - Parameter elements: A variadic list of elements of the new ordered set.
    @inlinable
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}

// MARK: - Hashable
extension OrderedSet: Hashable {
    /// Hashes the essential components of this value by feeding them into the
    /// given hasher.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(count) // Discriminator
        for item in elements {
            hasher.combine(item)
        }
    }
}

// MARK: - Initialization
extension OrderedSet {
    /// Creates an empty set.
    ///
    /// This initializer is equivalent to initializing with an empty array
    /// literal.
    @inlinable
    public init() {
        elements = []
    }

    /// Creates a new set from a finite sequence of items.
    ///
    /// - Parameter elements: The elements to use as members of the new set.
    ///    The sequence is allowed to contain duplicate elements, but only
    ///    the first duplicate instance is preserved in the result.
    @inlinable
    public init(_ elements: some Sequence<Element>) {
        self.elements = []
        append(contentsOf: elements)
    }
    
    // Specializations
    
    /// Creates a new set from a an existing set. This is functionally the same as
    /// copying the value of `elements` into a new variable.
    ///
    /// - Parameter elements: The elements to use as members of the new set.
    @inlinable
    public init(_ elements: Self) {
        self = elements
    }
}


// MARK: - Appending
extension OrderedSet {
    /// Append a new member to the end of the set, if the set doesn't
    /// already contain it.
    ///
    /// - Parameter item: The element to add to the set.
    ///
    /// - Returns: A pair `(inserted, index)`, where `inserted` is a Boolean value
    ///    indicating whether the operation added a new element, and `index` is
    ///    the index of `item` in the resulting set.
    @inlinable
    @inline(__always)
    @discardableResult
    public mutating func append(_ item: Element) -> (inserted: Bool, index: Int) {
        if let index = elements.firstIndex(of: item) {
            return (false, index)
        }
        let index = elements.count
        elements.append(item) // appends to end so will have previous count
        return (true, index)
    }
    
    /// Append the contents of a sequence to the end of the set, excluding
    /// elements that are already members.
    ///
    /// This is functionally equivalent to `self.formUnion(elements)`, but it's
    /// more explicit about how the new members are ordered in the new set.
    ///
    /// - Parameter elements: A finite sequence of elements to append.
    @inlinable
    public mutating func append(
        contentsOf elements: some Sequence<Element>
    ) {
        for item in elements {
            append(item)
        }
    }
}

// MARK: - Insertion
extension OrderedSet {
    /// Insert a new member to this set at the specified index, if the set doesn't
    /// already contain it.
    ///
    /// - Parameter item: The element to insert.
    ///
    /// - Returns: A pair `(inserted, index)`, where `inserted` is a Boolean value
    ///    indicating whether the operation added a new element, and `index` is
    ///    the index of `item` in the resulting set. If `inserted` is false, then
    ///    the returned `index` may be different from the index requested.
    @inlinable
    @discardableResult
    public mutating func insert(
        _ item: Element,
        at index: Int
    ) -> (inserted: Bool, index: Int) {
        if let index = firstIndex(of: item) {
            return (false, index)
        }
        elements.insert(item, at: index)
        return (true, index)
    }
}

// MARK: - Removal
extension OrderedSet {
    /// Removes and returns the element at the specified position.
    ///
    /// All the elements following the specified position are moved to close the
    /// resulting gap.
    ///
    /// - Parameter index: The position of the element to remove. `index` must be
    ///    a valid index of the collection that is not equal to the collection's
    ///    end index.
    ///
    /// - Returns: The removed element.
    @inlinable
    @discardableResult
    public mutating func remove(at index: Int) -> Element {
        return elements.remove(at: index)
    }
}

// MARK: - Swapping
extension OrderedSet {
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
        elements.swapAt(i, j)
    }
}

// MARK: - Comparable
extension OrderedSet where Element: Comparable {
    /// Sorts the set in place.
    ///
    /// You can sort an ordered set of elements that conform to the
    /// `Comparable` protocol by calling this method. Elements are sorted in
    /// ascending order.
    ///
    /// Here's an example of sorting a list of students' names. Strings in Swift
    /// conform to the `Comparable` protocol, so the names are sorted in
    /// ascending order according to the less-than operator (`<`).
    ///
    ///     var students: OrderedSet = ["Kofi", "Abena", "Peter", "Kweku", "Akosua"]
    ///     students.sort()
    ///     print(students)
    ///     // Prints "["Abena", "Akosua", "Kofi", "Kweku", "Peter"]"
    ///
    /// To sort the elements of your collection in descending order, pass the
    /// greater-than operator (`>`) to the `sort(by:)` method.
    ///
    ///     students.sort(by: >)
    ///     print(students)
    ///     // Prints "["Peter", "Kweku", "Kofi", "Akosua", "Abena"]"
    ///
    /// The sorting algorithm is guaranteed to be stable. A stable sort
    /// preserves the relative order of elements that compare as equal.
    @inlinable
    public mutating func sort() {
        elements.sort()
    }
}

// MARK: - Shuffling
extension OrderedSet {
    /// Shuffles the collection in place.
    ///
    /// Use the `shuffle()` method to randomly reorder the elements of an ordered
    /// set.
    ///
    ///     var names: OrderedSet
    ///       = ["Alejandro", "Camila", "Diego", "Luciana", "Luis", "Sofía"]
    ///     names.shuffle()
    ///     // names == ["Luis", "Camila", "Luciana", "Sofía", "Alejandro", "Diego"]
    ///
    /// This method is equivalent to calling `shuffle(using:)`, passing in the
    /// system's default random generator.
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
    ///     var names: OrderedSet
    ///       = ["Alejandro", "Camila", "Diego", "Luciana", "Luis", "Sofía"]
    ///     names.shuffle(using: &myGenerator)
    ///     // names == ["Sofía", "Alejandro", "Camila", "Luis", "Diego", "Luciana"]
    ///
    /// - Parameter generator: The random number generator to use when shuffling
    ///   the collection.
    ///
    /// - Note: The algorithm used to shuffle a collection may change in a future
    ///   version of Swift. If you're passing a generator that results in the
    ///   same shuffled order each time you run your program, that sequence may
    ///   change when your program is compiled using a different version of
    ///   Swift.
    @inlinable
    public mutating func shuffle(
        using generator: inout some RandomNumberGenerator
    ) {
        elements.shuffle(using: &generator)
    }
}

// MARK: - Reversing
extension OrderedSet {
    /// Reverses the elements of the ordered set in place.
    @inlinable
    public mutating func reverse() {
        elements.reverse()
    }
}

// MARK: - Equality
extension OrderedSet {
    /// Returns a Boolean value indicating whether two set values contain the
    /// same elements, but not necessarily in the same order.
    ///
    /// - Note: This member implements different behavior than the `==(_:_:)`
    ///    operator -- the latter implements an ordered comparison, matching
    ///    the stricter concept of equality expected of an ordered collection
    ///    type.
    public func isEqualSet(to other: some Sequence<Element>) -> Bool {
        let left = Set(elements)
        let right = Set(other)
        return left == right
    }
}

// MARK: - Subtraction

// `OrderedSet` does not directly conform to `SetAlgebra` because its definition
// of equality conflicts with `SetAlgebra` requirements. However, it still
// implements most `SetAlgebra` requirements (except `insert`, which is replaced
// by `append`).
//
// `OrderedSet` also provides an `unordered` view that explicitly conforms to
// `SetAlgebra`. That view implements `Equatable` by ignoring element order,
// so it can satisfy `SetAlgebra` requirements.

extension OrderedSet {
    /// Removes the elements of the given sequence from this set.
    ///
    ///     var set: OrderedSet = [1, 2, 3, 4]
    ///     set.subtract([6, 4, 2, 0] as Array)
    ///     // set is now [1, 3]
    ///
    /// - Parameter other: A finite sequence of elements.
    @inlinable
    @inline(__always)
    public mutating func subtract(_ other: some Sequence<Element>) {
        self = subtracting(other)
    }
}

extension OrderedSet {
    /// Returns a new set containing the elements of this set that do not occur
    /// in the given sequence.
    ///
    /// The result contains elements in the same order they appear in `self`.
    ///
    ///     let set: OrderedSet = [1, 2, 3, 4]
    ///     set.subtracting([6, 4, 2, 0] as Array) // [1, 3]
    ///
    /// - Parameter other: A finite sequence of elements.
    ///
    /// - Returns: A new set.
    @inlinable
    @inline(__always)
    public __consuming func subtracting(_ other: some Sequence<Element>) -> Self {
        var difference = Self()
        for element in self.elements {
            if !other.contains(element) {
                difference.append(element)
            }
        }
        return difference
    }
}


// MARK: - Sequence Conformance
extension OrderedSet: Sequence {
    // wrap elements subscript so can access as a keyed dictionary or as an array
    public subscript(_ index: Int) -> Element {
        get {
            elements[index]
        }
        set {
            elements[index] = newValue
        }
    }
    // Use underlying array iterator instead of re-inventing
    public func makeIterator() -> IndexingIterator<[Element]> {
        return elements.makeIterator()
    }
}


// MARK: - Contents introspection
extension OrderedSet {
    /// A Boolean value indicating whether the collection is empty.
    @inlinable
    @inline(__always)
    public var isEmpty: Bool { elements.isEmpty }
    
    /// The number of elements in the set.
    @inlinable
    @inline(__always)
    public var count: Int { elements.count }
    
}

// MARK: - Sendable Conformance
extension OrderedSet: @unchecked Sendable where Element: Sendable {}

// MARK: - Set Addition
public extension OrderedSet {
    /// Adds the right hand collection to the left hand OrderedSet.  Duplicates will be ignored and the ordering will not change.
    @inlinable
    static func += <Other>(lhs: inout Self, rhs: Other) where Other : Sequence, Self.Element == Other.Element {
        lhs.append(contentsOf: rhs)
    }

    /// Adds the right hand collection to the left hand OrderedSet and returns the result.  Duplicates will be ignored and the ordering will not change.
    @inlinable
    static func + <Other>(lhs: Self, rhs: Other) -> Self where Other : Sequence, Self.Element == Other.Element {
        var union = lhs
        union += rhs
        return union
    }
}

