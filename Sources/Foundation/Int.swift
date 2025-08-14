//
//  Int.swift
//  KuditFrameworks
//
//  Created by Ben Ku on 1/9/16.
//  Copyright © 2016 Kudit. All rights reserved.
//

//#if canImport(Darwin)
//import Darwin.C
//#elseif os(Linux)
//import Glibc
//#endif

// MARK: ++ operator for compatibility functions
public postfix func ++(x: inout Int) {
    x += 1
}
@MainActor
internal let testPlusPlus: TestClosure = {
    var value = 3
    value++
    let expected = 4
    try expect(value == expected, "\(value)++ does not equal \(expected)")
}

// MARK: -- operator for compatibility functions
public postfix func --(x: inout Int) {
    x -= 1
}
@MainActor
internal let testMinusMinus: TestClosure = {
    var value = 3
    value--
    let expected = 2
    try expect(value == expected, "\(value)-- does not equal \(expected)")
}


// MARK: - Random
public extension Int {
    /// Generates a uniformly random integer between 0 and `max` - 1 (including 0 but not including `max`).  Convenience for built-in `.random(in: 0..<max)`
    static func random(max: Int) -> Int {
        guard max > 0 else {
            return 0
        }
        return .random(in: 0..<max)
    }
}
@MainActor
internal let randomTests: TestClosure = {
    try expect(Int.random(max: -2) == 0)
    try expect(Int.random(max: 0) == 0)
    for i in 1..<5 {
        let num = Int.random(max: i)
        try expect(num >= 0 && num < i)
    }
}

// MARK: - Ordinal display
public extension Int {
    var ordinal: String {
        #if canImport(Foundation)
        let ordinalFormatter = NumberFormatter()
        ordinalFormatter.numberStyle = .ordinal
        return ordinalFormatter.string(from: NSNumber(value: self)) ?? "\(self)th"
        #else
        var suffix = "th"
        switch self % 10 {
        case 1:
            suffix = "st"
        case 2:
            suffix = "nd"
        case 3:
            suffix = "rd"
        default: ()
        }
        if 10 < (self % 100) && (self % 100) < 20 {
            suffix = "th"
        }
        return String(self) + suffix
        #endif
    }
    internal static let ordinalTestMap = [
        0: "th",
        1: "st",
        2: "nd",
        3: "rd",
        4: "th",
        5: "th",
        6: "th",
        7: "th",
        8: "th",
        9: "th",
        11: "th",
        12: "th",
        13: "th",
        21: "st",
        22: "nd",
    ]
}
@MainActor
internal let ordinalTests: TestClosure = {
    var failedMessages = [String]()
    for (num, suffix) in Int.ordinalTestMap {
        let expected = "\(num)\(suffix)"
        try expect(expected == num.ordinal, "\(num.ordinal) does not equal \(expected)")
    }
}

// MARK: - String output support
public extension Int {
    /// convenience for String(self) so that can be included in string interpolation without commas. (Instead of 1,999 it will display 1999).
    var string: String {
        return String(self)
    }
}

// MARK: - Pluralization utility
public extension Int {
    /// Adds an "s" (or specified ending) if the value is anything other than 1.
    /// If you need a completely different term, you can specify the versions like this:
    /// ```swift
    /// number.pluralEnding("teeth", singularEnding: "tooth")
    /// ```
    func pluralEnding(_ pluralEnding: String = "s", singularEnding: String = "") -> String {
        if self == 1 {
            return singularEnding
        } else {
            return pluralEnding
        }
    }
}
@MainActor
internal let pluralTests: TestClosure = {
    try expect(0.pluralEnding() == "s")
    try expect(1.pluralEnding("teeth", singularEnding: "tooth") == "tooth")
    try expect(2.pluralEnding("teeth", singularEnding: "tooth") == "teeth")
    
//    try expect("\(1999)" == "1,999") only seems to happen in SwiftUI.Text("\(1999)")
    try expect(1999.string == "1999")
}


// MARK: - Byte strings
/// Add byte functions to all integer types. (Int64, Int, and UInt64 all automatically conform)
public extension BinaryInteger {
    /// Formats this value as a number of bytes (or kB/MB/GB/etc) using the ByteCountFormatter() to get a nice clean string.
    var bytes: Int64 {
        Int64(self)
    }
#if !DEBUG
    @available(*, deprecated, renamed: "byteString(countStyle:)", message: "use byteString(countStyle) instead so we know whether to convert with 1000 or 1024 division")
    var byteString: String {
        return byteString(.file)
    }
#endif
    #if canImport(Foundation)
    func byteString(_ countStyle: ByteCountFormatter.CountStyle) -> String {
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: countStyle)
    }
    /// Formats this value as a number of bytes (or kB/MB/GB/etc) using the ByteCountFormatter() to get a nice clean string.  Returns a named tuple (count: String, units: String)
    func byteParts(_ countStyle: ByteCountFormatter.CountStyle) -> (count: String, units: String) {
        var parts = byteString(countStyle).components(separatedBy: " ")
        if parts.count == 1 {
            // should not happen!
            return (count: parts[0], units: "ERROR")
        } else if parts.count > 2 {
            let count = parts.removeFirst()
            return (count: count, parts.joined(separator: " "))
        } else {
            return (parts[0], parts[1])
        }
    }
    func byteCount(_ countStyle: ByteCountFormatter.CountStyle) -> Double {
        return Double(byteParts(countStyle).count) ?? 0
    }
    #endif
}
@MainActor
internal let byteTests: TestClosure = {
    let fileTests: [UInt64: String] = [
        12334: "12 KB",
        2131231: "2.1 MB",
        3342131231: "3.34 GB",
        4231232323234: "4.23 TB",
    ]
    let memoryTests: [UInt64: String] = [
        12334: "12 KB",
        2131231: "2 MB",
        3342131231: "3.11 GB",
        4231232323234: "3.85 TB",
    ]

    var failedMessages = [String]()
    var allPass = true
    
    #if canImport(Foundation)
    let runTestsClosure: (ByteCountFormatter.CountStyle, [UInt64: String]) throws -> Void = { style, tests in
        for (count, expected) in tests {
            let parts = count.byteParts(style)
            try expect(Double(parts.count) == count.byteCount(style))
            let craftedString = "\(parts.count) \(parts.units)"
            try expect(expected == craftedString, "`\(craftedString)` does not equal `\(expected)` (\(style == .file ? "file" : "memory"))")
        }
    }
    try runTestsClosure(.memory, memoryTests)
    try runTestsClosure(.file, fileTests)
    #endif
}

// MARK: - Tests

// Testing is only supported with Swift 5.9+ and FoundationX
#if compiler(>=5.9) && canImport(Foundation)
@available(iOS 13, tvOS 13, watchOS 6, *)
extension Int {
    @MainActor
    public static let tests: [Test] = [
        Test("plusplus", testPlusPlus),
        Test("minusminus", testMinusMinus),
        Test("ordinals", ordinalTests),
        Test("random", randomTests),
        Test("strings", pluralTests),
        Test("bytes", byteTests)
    ]
}

#if canImport(SwiftUI)
import SwiftUI
@available(iOS 13, tvOS 13, watchOS 6, *)
#Preview("Ordinals") {
    List {
        ForEach(1..<25 + .random(max: 5), id: \.self) { i in
            Text("\(i) -> \(i.ordinal)")
        }
    }
}
@available(iOS 13, tvOS 13, watchOS 6, *)
#Preview("Tests") {
    TestsListView(tests: Int.tests)
}
#endif
#endif
