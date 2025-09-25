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
#if !os(WASM)
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
        debug("Not implemented for non-WASM platforms.", level: .ERROR)
        return [:]
    }
    var allKeyPaths: OrderedDictionary<String, PartialKeyPath<Self>> {
        debug("Not implemented for non-WASM platforms.", level: .ERROR)
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
public func areEqual(_ left: Any?, _ right: Any?) -> Bool {
    guard let first = left as? any Equatable, let second = right as? any Equatable else { return false }
    return first.isEqual(second)
}

