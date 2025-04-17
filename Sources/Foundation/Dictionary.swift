//
//  Dictionary.swift
//  KuditFrameworks
//
//  Created by Ben Ku on 9/19/16.
//  Copyright © 2016 Kudit. All rights reserved.
//

public extension Dictionary where Value: AnyObject {
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
public extension Dictionary where Value: Equatable {
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
