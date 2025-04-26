//
//  Introspection.swift
//  Compatibility
//
//  Created by Ben Ku on 4/26/25.
//

// MARK: - Property Iteration
public protocol PropertyIterable {
    var allProperties: [String: Any] { get } // TODO: change to keypath?
    //var allKeypaths: [String: WritableKeyPath<Self, Any>] { get }
}
public extension PropertyIterable {
    var allProperties: [String: Any] {
        var result: [String: Any] = [:]
        
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
}
