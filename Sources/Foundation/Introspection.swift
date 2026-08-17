//
//  Introspection.swift
//  Compatibility
//
//  Created by Ben Ku on 4/26/25.
//

// MARK: - Property Iteration
public protocol PropertyIterable {
    var allProperties: OrderedDictionary<String, Any> { get }
    var allKeyPaths: OrderedDictionary<String, PartialKeyPath<Self>> { get }
}
#if !hasFeature(Embedded)
public extension PropertyIterable {
    var allProperties: OrderedDictionary<String, Any> {
        var result = OrderedDictionary<String, Any>()
        
        let mirror = Mirror(reflecting: self)
        
        guard let style = mirror.displayStyle, style == .struct || style == .class else {
            debug("Unable to get properties for non-struct or non-class.", level: .ERROR)
            return result
        }
        
        for (labelMaybe, valueMaybe) in mirror.children {
            guard let label = labelMaybe else {
                continue
            }
            
            result[label] = valueMaybe
        }
        
        return result
    }
    private subscript(checkedMirrorDescendant key: String) -> Any {
        return Mirror(reflecting: self).descendant(key)!
    }
    var allKeyPaths: OrderedDictionary<String, PartialKeyPath<Self>> {
        var membersTokeyPaths = OrderedDictionary<String, PartialKeyPath<Self>>()
        let mirror = Mirror(reflecting: self)
        for case (let key?, _) in mirror.children {
            membersTokeyPaths[key] = \Self.[checkedMirrorDescendant: key] as PartialKeyPath
        }
        return membersTokeyPaths
    }
}
#else
public extension PropertyIterable {
    var allProperties: OrderedDictionary<String, Any> {
        debug("Property reflection is unavailable in Embedded Swift.", level: .ERROR)
        return [:]
    }
    var allKeyPaths: OrderedDictionary<String, PartialKeyPath<Self>> {
        debug("Property reflection is unavailable in Embedded Swift.", level: .ERROR)
        return [:]
    }
}
#endif

// Equatable conformance for this use and testing pathed values equality
public extension Equatable {
    func isEqual(_ other: any Equatable) -> Bool {
        guard let otherValue = other as? Self else {
            return false
        }
        return self == otherValue
    }
}

#if hasFeature(Embedded)
@available(*, deprecated, message: "This always returns false in Embedded Swift because dynamic casting is unavailable.")
#endif
public func areEqual(_ left: Any?, _ right: Any?) -> Bool {
#if !hasFeature(Embedded)
    guard let first = left as? any Equatable, let second = right as? any Equatable else { return false }
    return first.isEqual(second)
#else
    return false
#endif
}

#if compiler(>=5.9)
private struct IntrospectionStructFixture: PropertyIterable {
    let name: String
    let count: Int
}

private final class IntrospectionClassFixture: PropertyIterable {
    let enabled: Bool
    let value: Double

    init(enabled: Bool, value: Double) {
        self.enabled = enabled
        self.value = value
    }
}

private enum IntrospectionEnumFixture: PropertyIterable {
    case value(Int)
}

private struct IntrospectionNonEquatableFixture {
    let value: Int
}

/// Reusable tests for reflection/key-path helpers and type-erased equality.
///
/// The app's All Tests screen and the Swift Testing adapter both consume this same list so the
/// introspection implementation remains testable without maintaining a target-specific duplicate.
@MainActor
public let introspectionTests: [TestCase] = [
    TestCase("Struct properties and key paths") {
#if !hasFeature(Embedded)
        let fixture = IntrospectionStructFixture(name: "Compatibility", count: 2)
        let properties = fixture.allProperties
        try expectEqual(properties.count, 2)
        try expectEqual(properties["name"] as? String, "Compatibility")
        try expectEqual(properties["count"] as? Int, 2)

        let keyPaths = fixture.allKeyPaths
        try expectEqual(keyPaths.count, 2)
        if let namePath = keyPaths["name"], let countPath = keyPaths["count"] {
            try expectEqual(fixture[keyPath: namePath] as? String, "Compatibility")
            try expectEqual(fixture[keyPath: countPath] as? Int, 2)
        } else {
            try expect(false, "Expected reflected key paths for both stored properties.")
        }
#else
        let fixture = IntrospectionStructFixture(name: "Compatibility", count: 2)
        try expect(fixture.allProperties.isEmpty)
        try expect(fixture.allKeyPaths.isEmpty)
#endif
    },
    TestCase("Class properties and unsupported reflection") {
#if !hasFeature(Embedded)
        let fixture = IntrospectionClassFixture(enabled: true, value: 4.5)
        try expectEqual(fixture.allProperties["enabled"] as? Bool, true)
        try expectEqual(fixture.allProperties["value"] as? Double, 4.5)

        // Enums deliberately take the unsupported reflection path; suppress the expected diagnostic
        // so a successful negative test does not add an error-looking line to normal test output.
        try debugSuppress {
            try expect(IntrospectionEnumFixture.value(1).allProperties.isEmpty)
        }
#else
        let fixture = IntrospectionClassFixture(enabled: true, value: 4.5)
        try expect(fixture.allProperties.isEmpty)
#endif
    },
    TestCase("Type-erased equality") {
#if !hasFeature(Embedded)
        try expect(1.isEqual(1))
        try expect(!1.isEqual("1"))
        try expect(areEqual(42, 42))
        try expect(!areEqual(42, "42"))
        try expect(!areEqual(nil, nil))
        try expect(!areEqual(IntrospectionNonEquatableFixture(value: 1), IntrospectionNonEquatableFixture(value: 1)))
#else
        try expect(!areEqual(42, 42))
#endif
    },
]
#endif
