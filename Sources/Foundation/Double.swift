//
//  Double.swift
//
//
//  Created by Ben Ku on 7/6/24.
//

public protocol DoubleConvertible {
    var doubleValue: Double { get }
}
public extension BinaryInteger {
    var doubleValue: Double {
        return Double(self)
    }
}
extension Int: DoubleConvertible {}
public extension BinaryFloatingPoint {
    var doubleValue: Double {
        return Double(self)
    }
}
// following are implemneted automatically by conforming BinaryFloatingPoint but need to add conformances for everything that conforms to BinaryFloatingPoint since we can't make it automatically conform
extension Double: DoubleConvertible {}
extension Float: DoubleConvertible {}

public extension Double {
    /// `true` if this value is an integer (rounding does nothing to the value).
    var isInteger: Bool {
        let rounded = self.rounded()
        return rounded == self
    }
    
    /// Rounds decimals to the specified number of places.
    func precision(_ places: Int) -> Double {
#if canImport(Foundation)
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
#else
        var multiplier = 1.0
        for _ in 0..<places {
            multiplier *= 10
        }
        return (self * multiplier).rounded() / multiplier
#endif
    }
    
#if canImport(Foundation)
    /// Creates a string version of this Double value without ".0" if this contains an integer number.  Otherwise, returns the normal value description.
    var withoutZeros: String {
        if self.isInteger {
            let formatter = NumberFormatter()
            let number = NSNumber(value: self)
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0 //maximum digits in Double after dot (maximum precision)
            return String(formatter.string(from: number)!)
        } else {
            return "\(self)"
        }
    }
#else
    // backport of Double(String)
    /// Parse a decimal string to Double using only Swift stdlib (no Foundation).
    /// Accepts: [whitespace] [+|-] digits [.[digits]] [(e|E) [+|-] digits] [whitespace]
    /// Returns nil for invalid format or if result is NaN/overflow.
    init?(_ s: String) {
        let chars = Array(s)
        var i = 0
        let n = chars.count

        func skipWhitespace() {
            while i < n && (chars[i] == " " || chars[i] == "\t" || chars[i] == "\n" || chars[i] == "\r") {
                i += 1
            }
        }

        skipWhitespace()
        if i >= n { return nil }

        // sign
        var sign: Double = 1
        if chars[i] == "-" {
            sign = -1
            i += 1
        } else if chars[i] == "+" {
            i += 1
        }

        // integer part
        var intAcc: UInt64 = 0
        var intDigits = 0
        while i < n, let d = chars[i].wholeNumberValue {
            intDigits += 1
            // accumulate but cap to avoid overflow; we'll convert to Double later
            if intAcc <= (UInt64.max - UInt64(d)) / 10 {
                intAcc = intAcc * 10 + UInt64(d)
            } else {
                // overflow in integer accumulator -> keep growing digit count but stop accumulating
                // mark by setting to max
                intAcc = UInt64.max
            }
            i += 1
        }

        // fraction part
        var fracAcc: UInt64 = 0
        var fracDigits = 0
        if i < n && chars[i] == "." {
            i += 1
            while i < n, let d = chars[i].wholeNumberValue {
                fracDigits += 1
                if fracAcc <= (UInt64.max - UInt64(d)) / 10 {
                    fracAcc = fracAcc * 10 + UInt64(d)
                } else {
                    fracAcc = UInt64.max
                }
                i += 1
            }
        }

        if intDigits == 0 && fracDigits == 0 {
            // no digits found
            return nil
        }

        // exponent part
        var expSign = 1
        var expVal = 0
        if i < n && (chars[i] == "e" || chars[i] == "E") {
            i += 1
            if i < n && chars[i] == "-" {
                expSign = -1
                i += 1
            } else if i < n && chars[i] == "+" {
                i += 1
            }
            var expDigits = 0
            while i < n, let d = chars[i].wholeNumberValue {
                expDigits += 1
                if expVal <= (Int.max - d) / 10 {
                    expVal = expVal * 10 + d
                } else {
                    // cap large exponents
                    expVal = Int.max / 2
                }
                i += 1
            }
            if expDigits == 0 {
                return nil // "e" not followed by digits
            }
        }

        skipWhitespace()
        if i != n {
            // trailing invalid characters
            return nil
        }

        // integer power of 10 for non-negative exponents
        func pow10Int(_ p: Int) -> Double {
            if p <= 0 { return 1.0 }
            var result: Double = 1.0
            var base: Double = 10.0
            var exp = p
            while exp > 0 {
                if (exp & 1) != 0 { result *= base }
                base *= base
                exp >>= 1
                if !result.isFinite { break }
            }
            return result
        }

        // Convert integer and fraction accumulators to Double
        var value: Double = 0.0
        if intAcc == UInt64.max {
            // integer overflowed accumulator; build value by scanning digits again
            // fallback: construct from string parts to avoid dependence on Foundation
            // Efficient approach: use scientific scaling below; but here we fallback to a safe loop:
            // rebuild integer value using double with clamping
            var idx = 0
            // find start of digit characters in the original string
            // skip leading whitespace and optional sign
            while idx < n && (chars[idx] == " " || chars[idx] == "\t" || chars[idx] == "\n" || chars[idx] == "\r") { idx += 1 }
            if idx < n && (chars[idx] == "+" || chars[idx] == "-") { idx += 1 }
            while idx < n, let d = chars[idx].wholeNumberValue {
                value = value * 10.0 + Double(d)
                // if value is infinite, break
                if !value.isFinite { break }
                idx += 1
            }
        } else {
            value = Double(intAcc)
        }

        if fracDigits > 0 {
            // add fractional part: fracAcc / 10^fracDigits
            var fracDouble: Double
            if fracAcc == UInt64.max {
                // large fractional accumulator overflowed; build fraction incrementally
                var idx = 0
                // locate fraction start in original string
                while idx < n && chars[idx] != "." { idx += 1 }
                if idx < n && chars[idx] == "." {
                    idx += 1
                    var fracAccDouble: Double = 0.0
                    var count = 0
                    while idx < n, let d = chars[idx].wholeNumberValue {
                        fracAccDouble = fracAccDouble * 10.0 + Double(d)
                        count += 1
                        idx += 1
                    }
                    fracDouble = fracAccDouble / pow10Int(count)
                } else {
                    fracDouble = 0.0
                }
            } else {
                fracDouble = Double(fracAcc) / pow10Int(fracDigits)
            }
            value += fracDouble
        }

        // apply exponent: total decimal shift = expSign*expVal
        let totalExp = (expSign == 1 ? expVal : -expVal)
        if totalExp != 0 {
            // compute value * 10^totalExp
            if totalExp > 0 {
                // multiply by 10^totalExp
                let factor = pow10Int(totalExp)
                let scaled = value * factor
                if !scaled.isFinite { return nil }
                value = scaled
            } else {
                // divide by 10^(-totalExp)
                let factor = pow10Int(-totalExp)
                if factor == 0 { return nil }
                value = value / factor
            }
        }

        value *= sign

        if value.isNaN || value.isInfinite {
            // treat overflow/underflow as nil (change if you prefer returning inf)
            return nil
        }

        self = value
    }
#endif

#if !(os(WASM) || os(WASI))
    @MainActor
#endif
    internal static let doubleTests: TestClosure = {
        let five = 5.doubleValue.doubleValue
        try expect("\(five)" == "5.0")
#if canImport(Foundation)
        try expect(five.withoutZeros == "5")
        
        let two = Float(2).doubleValue
        try expect(two.withoutZeros == "2")
#endif

        let pi = 3.14159265358979323846
        try expect(pi.precision(2) == 3.14)
        try expect(pi.precision(3) == 3.142)
        try expect(pi.precision(4) == 3.1416)
        try expect(pi.precision(5) == 3.14159)
#if canImport(Foundation)
        try expect(pi.withoutZeros == "\(pi)")
#endif
    }
}

// Testing is only supported with Swift 5.9+
#if compiler(>=5.9)
@available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
public extension Double {
#if !(os(WASM) || os(WASI))
    @MainActor
#endif
    static let tests = [
        Test("double tests", doubleTests),
    ]
}
#endif
