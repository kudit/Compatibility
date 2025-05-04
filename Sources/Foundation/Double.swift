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
    
    /// Rounds decimals to the specified number of places.
    func precision(_ places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    
    @MainActor
    internal static let doubleTests: TestClosure = {
        let five = 5.doubleValue.doubleValue
        try expect("\(five)" == "5.0")
        try expect(five.withoutZeros == "5")
        
        let two = Float(2).doubleValue
        try expect(two.withoutZeros == "2")

        let pi = 3.141592653589793
        try expect(pi.precision(2) == 3.14)
        try expect(pi.precision(3) == 3.142)
        try expect(pi.precision(4) == 3.1416)
        try expect(pi.precision(5) == 3.14159)
    }
}

// Testing is only supported with Swift 5.9+
#if compiler(>=5.9)
@available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
public extension Double {
    @MainActor
    static let tests = [
        Test("double tests", doubleTests),
    ]
}
#endif
