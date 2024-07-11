//
//  Version.swift
//
//
//  Created by Ben Ku on 7/3/24.
//

import Foundation

#if !canImport(Combine)
// Compatibility OperatingSystemVersion for Linux
public struct OperatingSystemVersion : Sendable {
    /// MAJOR version when you make incompatible API changes
    public let majorVersion: Int
    /// MINOR version when you add functionality in a backward compatible manner
    public let minorVersion: Int
    /// PATCH version when you make backward compatible bug fixes
    public let patchVersion: Int
    public init(majorVersion: Int, minorVersion: Int, patchVersion: Int) {
        self.majorVersion = majorVersion
        self.minorVersion = minorVersion
        self.patchVersion = patchVersion
    }
}
#endif

/// Version in semantic dot notation
public typealias Version = OperatingSystemVersion

extension OperatingSystemVersion: CustomStringConvertible { // @retroactive in Swift 6?
    // For CustomStringConvertible conformance
    /// SemVer string (format of "*major*.*minor*.*patch*")
    ///
    /// omits patch version number if it is zero
    ///
    /// Examples: "13.0.1", "16.1"
    public var description: String {
        var osVersion = "\(majorVersion).\(minorVersion)"
        if patchVersion != 0 {
            osVersion += ".\(patchVersion)"
        }
        return osVersion
    }
}
extension OperatingSystemVersion: ExpressibleByStringLiteral, ExpressibleByStringInterpolation { // @retroactive in Swift 6?
    // For ExpressibleByStringLiteral conformance
    public init(stringLiteral: String) {
        let components = stringLiteral.components(separatedBy: ".")
        let major = Int(components.first ?? "0") ?? 0
        let minor: Int = components.count > 1 ? Int(components[1]) ?? 0 : 0
        let patch: Int = components.count > 2 ? Int(components[2]) ?? 0 : 0
        self.init(majorVersion: major, minorVersion: minor, patchVersion: patch)
    }
}
extension OperatingSystemVersion: RawRepresentable { // @retroactive in Swift 6?
    // For RawRepresentable conformance (so we can store and make codable as a String)
    public typealias RawValue = String
    public init(rawValue: String) {
        self.init(stringLiteral: rawValue)
    }
    public var rawValue: String {
        return description
    }
}
extension OperatingSystemVersion: LosslessStringConvertible { // @retroactive in Swift 6?
    // For LosslessStringConvertible conformance
    public init(_ rawValue: String) {
        self.init(stringLiteral: rawValue)
    }
}
extension OperatingSystemVersion: Comparable { // @retroactive in Swift 6?
    // For Comparable conformance
    /// Return the components of this version as an integer array of length 3 (always length 3 even if minor and patch are 0).
    public static func < (left: Self, right: Self) -> Bool {
        let (lc, rc) = (left.components, right.components)
        for index in 0..<lc.count {
            if lc[index] < rc[index] {
                return true
            }
            if rc[index] < lc[index] {
                return false
            }
            // lc[index] == rc[index]
            // continue down the numbers
        }
        return false // likely entirely ==
    }
}

public extension OperatingSystemVersion {
    // For legacy code compatibility
    var components: [Int] {
        return [majorVersion, minorVersion, patchVersion]
    }
    
    @available(*, deprecated, message: "Versions are now typealiases of OperatingSystemVersion so no need to convert.")
    init(operatingSystemVersion osv: OperatingSystemVersion) {
        self.init(rawValue: osv.rawValue)
    }
    
    @available(*, deprecated, message: "Versions are now typealiases of OperatingSystemVersion so no need to convert.")
    var operatingSystemVersion: OperatingSystemVersion {
        return self
    }
    
    // TODO: Convert to Swift Testing
    static func test() -> Bool {
        let first = Version("2")
        let second = Version("12.1")
        let third: Version = "2.12.1"
        let fourth: Version = "12.1.0"
        return first < second && third > first && fourth == second && third < fourth
    }
}

// TODO: Remove - causes conflic with collection joined version
//// For collection convenience
//public extension [Version] {
//    var asStringArray: [String] {
//        self.map { $0.rawValue }
//    }
//    func joined(separator: String = "") -> String {
//        asStringArray.joined(separator: separator)
//    }
//}

#if canImport(SwiftUI)
// Don't know why this is necessary.  CustomStringConvertible should have covered this.
import SwiftUI
@available(watchOS 6.0, iOS 13, tvOS 13, *)
public extension LocalizedStringKey.StringInterpolation {
    mutating func appendInterpolation(_ value: Version) {
        appendInterpolation(value.description)
    }
}

@available(watchOS 6, iOS 13, tvOS 13, *)
#Preview("Tests") {
    VStack {
        Text("Version test: \(Version("13"))")
        if Version.test() {
            Text("Tests pass")
        } else {
            Text("Tests failed!")
        }
    }
}
#endif
