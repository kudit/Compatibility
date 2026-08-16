//
//  CoverageGapTests.swift
//  CompatibilityTests
//
//  Focused tests for public code paths that are expensive to reach through the demo UI.
//

#if compiler(>=5.9) && canImport(Compatibility) && canImport(Testing)
import Compatibility
import Testing
#if canImport(Foundation)
import Foundation
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif

#if !hasFeature(Embedded)
private struct IntrospectionFixture: PropertyIterable {
    let name: String
    let count: Int
}

private enum IntrospectionNonObjectFixture: PropertyIterable {
    case value
}

private enum RawValueFixture: String {
    case alpha
    case beta
}

private struct RawSequenceFixture: RawRepresentableSequence {
    typealias Element = RawValueFixture
    typealias RawValue = [String]

    private var storage: [Element]

    init<S>(_ s: S) where S: Sequence, Element == S.Element {
        storage = Array(s)
    }

    init(arrayLiteral elements: Element...) {
        storage = elements
    }

    func makeIterator() -> Array<Element>.Iterator {
        storage.makeIterator()
    }
}

private struct IdentifiableFixture: Identifiable, Equatable {
    let id: Int
    var value: String
}
#endif

#if canImport(Foundation)
private struct FoundationCodingFixture: Codable, Equatable {
    let eventDate: Date
    let payload: Data
    let score: Double
    let camelCaseValue: String
}

private enum ExpectedEncodingError: Error {
    case expected
}

private struct ThrowingEncodableFixture: Encodable {
    func encode(to encoder: Encoder) throws {
        throw ExpectedEncodingError.expected
    }
}
#endif

@Suite("Coverage Gap Tests")
struct CoverageGapTests {
#if !hasFeature(Embedded)
    @Test("Property introspection and dynamic equality")
    func propertyIntrospectionAndEquality() throws {
        let fixture = IntrospectionFixture(name: "Compatibility", count: 19)
        let properties = fixture.allProperties

        #expect(properties.count == 2)
        #expect(properties["name"] as? String == "Compatibility")
        #expect(properties["count"] as? Int == 19)

        let keyPaths = fixture.allKeyPaths
        #expect(keyPaths.count == 2)
        let nameKeyPath = try #require(keyPaths["name"])
        #expect(fixture[keyPath: nameKeyPath] as? String == "Compatibility")

        // Exercise the non-struct/class guard as well as matching, mismatched, and non-Equatable values.
        #expect(IntrospectionNonObjectFixture.value.allProperties.isEmpty)
        #expect(42.isEqual(42))
        #expect(!42.isEqual("42"))
        #expect(areEqual(42, 42))
        #expect(!areEqual(42, "42"))
        #expect(!areEqual(nil, nil))
    }

    @Test("RawRepresentable sequence conversion and identifiable array mutation")
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    func collectionGapCoverage() {
        let raw = RawSequenceFixture(rawValue: ["alpha", "invalid", "beta"])
        #expect(Array(raw) == [.alpha, .beta])
        #expect(raw.rawValue == ["alpha", "beta"])

        var values = [
            IdentifiableFixture(id: 1, value: "one"),
            IdentifiableFixture(id: 2, value: "two"),
        ]
        #expect(values[id: 2]?.value == "two")
        values[id: 2] = IdentifiableFixture(id: 2, value: "updated")
        #expect(values[id: 2]?.value == "updated")

        // These intentionally leave the array unchanged while exercising the guarded setter paths.
        values[id: 99] = IdentifiableFixture(id: 99, value: "missing")
        values[id: 1] = nil
        #expect(values.count == 2)
        #expect(values[id: 1]?.value == "one")
    }
#endif

#if canImport(Foundation)
    @Test("Foundation dictionary coder strategies and failure path")
    func foundationDictionaryCoderStrategies() throws {
        let encoder = DictionaryEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.dataEncodingStrategy = .base64
        encoder.nonConformingFloatEncodingStrategy = .convertToString(
            positiveInfinity: "INF",
            negativeInfinity: "-INF",
            nan: "NaN"
        )
        encoder.keyEncodingStrategy = .convertToSnakeCase

        // Read each public strategy back as well as setting it; these accessors are part of the wrapper API.
        _ = encoder.dateEncodingStrategy
        _ = encoder.dataEncodingStrategy
        _ = encoder.nonConformingFloatEncodingStrategy
        _ = encoder.keyEncodingStrategy

        let fixture = FoundationCodingFixture(
            eventDate: Date(timeIntervalSince1970: 12_345),
            payload: Data([0, 1, 2, 3]),
            score: .infinity,
            camelCaseValue: "value"
        )
        let encoded = try #require(try encoder.encode(fixture) as? [String: Any])
        #expect(encoded["event_date"] != nil)
        #expect(encoded["camel_case_value"] as? String == "value")
        #expect(encoded["score"] as? String == "INF")

        let decoder = DictionaryDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.dataDecodingStrategy = .base64
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "INF",
            negativeInfinity: "-INF",
            nan: "NaN"
        )
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        _ = decoder.dateDecodingStrategy
        _ = decoder.dataDecodingStrategy
        _ = decoder.nonConformingFloatDecodingStrategy
        _ = decoder.keyDecodingStrategy

        let decoded = try decoder.decode(FoundationCodingFixture.self, from: encoded)
        #expect(decoded == fixture)

        // Verify the convenience API's documented failure behavior for an Encodable that throws.
        #expect(ThrowingEncodableFixture().asDictionary() == nil)
    }

    @Test("OrderedSet Codable, hashing, filtering, and reflection")
    func orderedSetGapCoverage() throws {
        let original: OrderedSet<Int> = [3, 1, 3, 2]
        #expect(Array(original) == [3, 1, 2])

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(OrderedSet<Int>.self, from: data)
        #expect(decoded == original)

        var hasher = Hasher()
        original.hash(into: &hasher)
        _ = hasher.finalize()

        #expect(Array(original.filter { $0 > 1 }) == [3, 2])
        _ = original.customMirror
    }
#endif

#if canImport(SwiftUI) && canImport(Foundation)
    @Test("Shape path generation")
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    func shapePathGeneration() {
        let rect = CGRect(x: 10, y: 20, width: 200, height: 120)

        for edge in Edge.allCases {
            let bounds = Triangle(flatEdge: edge).path(in: rect).boundingRect
            #expect(bounds.width > 0)
            #expect(bounds.height > 0)
        }

        let placardBounds = Placard().path(in: rect).boundingRect
        #expect(placardBounds.width > 0)
        #expect(placardBounds.height > 0)
    }
#endif
}
#endif
