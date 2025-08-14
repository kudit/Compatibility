//
//  Version.swift
//
//
//  Created by Ben Ku on 7/3/24.
//

#if !canImport(Combine) || !canImport(Foundation)
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

// Needs to be in a container or the compiler has issues in Swift Playgrounds.
public extension Compatibility {
    typealias Version = OperatingSystemVersion
}
/// Version in semantic dot notation
public typealias Version = Compatibility.Version

extension Version: Swift.CustomStringConvertible { // @retroactive in Swift 6?
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
    
    /// Fully qualified major.minor.patch string, not the default pretty version
    public var full: String {
        return "\(majorVersion).\(minorVersion).\(patchVersion)"
    }
}

// MARK: - Codable conformance so stored as string rather than as a structure of values.
extension Version: Swift.Decodable {
    enum CodingKeys: String, CodingKey {
        case majorVersion, minorVersion, patchVersion
    }
    public init(from decoder: Decoder) throws {
        do {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let majorVersion = try values.decode(Int.self, forKey: .majorVersion)
            let minorVersion = try values.decode(Int.self, forKey: .minorVersion)
            let patchVersion = try values.decode(Int.self, forKey: .patchVersion)
            self.init(majorVersion: majorVersion, minorVersion: minorVersion, patchVersion: patchVersion)
        } catch {
            // probably stored as string.  Decode using singleValueContainer
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            self.init(stringLiteral: string)
        }
    }
}
extension Version: Swift.Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}


extension Version: Swift.ExpressibleByStringLiteral, Swift.ExpressibleByStringInterpolation { // @retroactive in Swift 6?
    // For ExpressibleByStringLiteral conformance
    /// Any non-numeric text will be ignored, so if you have something like `23b123` it will be converted to `23123`.
    public init(stringLiteral: String) {
        self.init(forcing: stringLiteral)
    }
}
extension Version: Swift.RawRepresentable { // @retroactive in Swift 6?
    // For RawRepresentable conformance (so we can store and make codable as a String)
    public typealias RawValue = String
    public init(rawValue: String) {
        self.init(stringLiteral: rawValue)
    }
    public var rawValue: String {
        return description
    }
}
extension Version: Swift.LosslessStringConvertible { // @retroactive in Swift 6?
    // For LosslessStringConvertible conformance and failable init option.
    public init(_ rawValue: String) {
        self.init(stringLiteral: rawValue)
    }
}

extension Version {
    init(string: String?, defaultValue: Self) {
        guard let string else {
            self = defaultValue
            return
        }
        guard let converted = Self(parsing: string) else {
            self = defaultValue
            return
        }
        self = converted
    }
    #if canImport(Foundation)
    public static let validCharacters = CharacterSet(charactersIn: "0123456789.")
    #endif
    /// Create a version ignoring any text.  If a component contains non-numerics, it will force it to 0 and additional pieces (like 1.0.0.2) will be ignored.
    public init(forcing: String) {
        // TODO: See if there is a better/faster way of stripping characters
        #if canImport(Foundation)
        let cleaned = forcing.replacingCharacters(in: Self.validCharacters.inverted, with: "")
        #else
        let cleaned = forcing
        #endif
        let components = cleaned.components(separatedBy: ".")
        let major = Int(components.first ?? "0") ?? 0
        let minor: Int = components.count > 1 ? Int(components[1]) ?? 0 : 0
        let patch: Int = components.count > 2 ? Int(components[2]) ?? 0 : 0
        self.init(majorVersion: major, minorVersion: minor, patchVersion: patch)
    }
    /// A failable initializer in case the parsing doesn't match exactly.
    public init?(parsing: String) {
        // 1.0.1b5 should actually give us a valid version of 1.0.15 (will only fail if completely fails to give any numbers)
        let trimmed = parsing.trimmed // possibly 0, 0.0, or 0.0.0
        let forced = Version(forcing: trimmed)
        if !forced.full.contains(trimmed) {
            // there were other characters or something in the version that had to be assumed or stripped.  Mark this as not perfectly convertible.
            return nil
        }
        self = forced
    }
}
extension Version: Swift.Comparable { // @retroactive in Swift 6?
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

extension Version: Swift.Hashable {}

public extension Version {
    /// equivalent to Version("0.0.0")
    static let zero = Version(majorVersion: 0, minorVersion: 0, patchVersion: 0)

    // For legacy code compatibility
    var components: [Int] {
        return [majorVersion, minorVersion, patchVersion]
    }
    
#if !DEBUG
    @available(*, deprecated, message: "Versions are now typealiases of OperatingSystemVersion so no need to convert.")
    init(operatingSystemVersion osv: OperatingSystemVersion) {
        self.init(rawValue: osv.rawValue)
    }
    
    @available(*, deprecated, message: "Versions are now typealiases of OperatingSystemVersion so no need to convert.")
    var operatingSystemVersion: OperatingSystemVersion {
        return self
    }
#endif
    
    // TODO: Convert to Swift Testing
    @MainActor
    internal static var testVersions: TestClosure = {
        let defaulted = Version(string: nil, defaultValue: "1.2.3")
        try expect(defaulted == Version("1.2.3"))
        let zero = Version("0.0.0")
        try expect(zero == Version("a.b.c"))
        let okay: Version = "2b.5.s"
        try expect(okay == "2.5.0")
        let forced: Version = "2b.5.s"
        try expect(forced == "2.5.0")
        let expanded: Version = "1.2.3b4"
        try expect(expanded == "1.2.34")
        let bad: Version = "alphabet soup"
        try expect(bad == .zero)
        try expect(Version(parsing: "alphabet") == nil)
        let forcedBad: Version = "alphabet soup"
        try expect(forcedBad == .zero)
        let first = Version("2")
        let second = Version("12.1")
        let third: Version = "2.12.1"
        let fourth: Version = "12.1.0"
        let fifth: Version = "2.2.0"
        let sixth: Version = "2.1"
        try expect(first < second)
        try expect(third > first)
        try expect(fourth == second)
        try expect(third < fourth)
        try expect(sixth < fifth)
        try expect(fifth < third)
        let list = [first, second, third, fourth, fifth, sixth]
        try expect(list.sorted() == [first, sixth, fifth, third, second, fourth])
        let req: [Version] = .init(rawValue: "1,2.1.2,3", required: "4.3")
        try expect(req.pretty == "v1.0, v2.1.2, v3.0, v4.3")
    }

    @MainActor
    internal static var versionCodableTest: TestClosure = {
        
//        - [ ] Determine when Version should print 1.0.0 vs 1.0 vs 1 (do 1.0 at least, but if .0.0, just print the major and minor and not the patch) - see if there are best practices.

        let one = Version("2")
        let two = Version("12.1")
        let three: Version = "2.12.1"
        let four = Version(rawValue: "4")
        let a: Version = "1.0.0"
        let b: Version = "2.0"
        let c: Version = "3.0.1"
        let array = [one, two, three, a, b, c]
#if canImport(Foundation)
        let json = array.asJSON()
        let expected = """
["2.0","12.1","2.12.1","1.0","2.0","3.0.1"]
"""
        try expect(json == expected, "unexpected json coding conversion: \(json)")
        let decoded = try [Version].init(fromJSON: json)
        try expect(decoded.asJSON() == expected, "json decoding failed.")
        let intVersion = """
            [{"majorVersion": 5, "minorVersion":3, "patchVersion": 10}]
            """
        let intDecoded = try [Version].init(fromJSON: intVersion)
        try expect(intDecoded.first == "5.3.10", "int json decoding failed.")
#endif
    }

#if compiler(>=5.9) && canImport(Foundation)
    @available(iOS 13, tvOS 13, watchOS 6, *)
    @MainActor
    static var tests: [Test] = [
        Test("Version Comparison Tests", testVersions),
        Test("Version Codable Tests", versionCodableTest),
    ]
#endif
}

#if !DEBUG
//// For collection convenience
public extension [Version] {
    @available(*, deprecated, renamed: "rawValue") // unnecessary now that Version has a RawRepresentable conversion to String automatically.
    var asStringArray: [String] {
        self.map { $0.rawValue }
    }
//    // TODO: Remove - causes conflict with collection joined version
//    func joined(separator: String = "") -> String {
//        asStringArray.joined(separator: separator)
//    }
}
#endif

public extension [Version] {
    /// Pretty output like "v0.0, v1.0.2, v2.3, v1.0, v3.4.2"
    var pretty: String {
        return self.map { "v\($0.description)" }.joined(separator: ", ")
    }
}

// The rawValue for an array of versions should be a comma-separated String, not an array of strings since this is easier to store
extension [Version]: Swift.RawRepresentable {
    public init(rawValue: String) {
        // remove duplicates and convert invalid values to 0.0.0
        let versions = Set(rawValue.split(separator: ",").map { Version(string: String($0), defaultValue: .zero) })
        // order
        self = versions.sorted()
    }
    
    public var rawValue: String {
        self.map { $0.rawValue }.joined(separator: ",")
    }
    
    public init(rawValue: String, required: Version) {
        self.init(rawValue: "\(required),\(rawValue)")
    }
}



#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation)
// Don't know why this is necessary.  CustomStringConvertible should have covered this.
import SwiftUI
@available(iOS 13, tvOS 13, watchOS 6, *)
public extension LocalizedStringKey.StringInterpolation {
    mutating func appendInterpolation(_ value: Version) {
        appendInterpolation(value.description)
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
#Preview("Tests") {
    TestsListView(tests: Version.tests)
}
#endif
