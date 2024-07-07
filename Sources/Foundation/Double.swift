//
//  Double.swift
//
//
//  Created by Ben Ku on 7/6/24.
//

import Foundation

public protocol DoubleConvertible {
    var doubleValue: Double { get }
}
extension Int: DoubleConvertible {
    public var doubleValue: Double {
        return Double(self)
    }
}
extension Float: DoubleConvertible {
    public var doubleValue: Double {
        return Double(self)
    }
}
extension Double: DoubleConvertible {
    public var doubleValue: Double {
        return Double(self)
    }
}
