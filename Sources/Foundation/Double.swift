//
//  Double.swift
//
//
//  Created by Ben Ku on 7/6/24.
//

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

public extension Double {
    /// Creates a string version of this Double value without ".0" if this contains an integer number.
    var withoutZeros: String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 16 //maximum digits in Double after dot (maximum precision)
        return String(formatter.string(from: number) ?? "")
    }
}
