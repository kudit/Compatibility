//
//  Version.swift
//
//
//  Created by Ben Ku on 7/3/24.
//

#if !canImport(Foundation) || arch(wasm32)
// Compatibility OperatingSystemVersion for Linux
public struct OperatingSystemVersion : Sendable {
    /// MAJOR version when you make incompatible API changes
    public let majorVersion: Int
    /// MINOR version when you add functionality in a backward compatible manner
    public let minorVersion: Int
    /// PATCH version when you make backward compatible bug fixes
    public let patchVersion: Int
    /// Creates a version from explicit semantic-version components without parsing or validation.
    ///
    /// - Parameters:
    ///   - majorVersion: The major component.
    ///   - minorVersion: The minor component.
    ///   - patchVersion: The patch component.
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
    /// omits patch version number if it is zero but always shows the minor version.
    ///
    /// Examples: "13.0.1", "16.1", "12.0"
    public var description: String {
        var osVersion = "\(majorVersion).\(minorVersion)"
        if patchVersion != 0 {
            osVersion += ".\(patchVersion)"
        }
        return osVersion
    }
    
    /// Fully qualified major.minor.patch string, not the default pretty version.
    /// Example: "1.0.0", "12.1.3", "15.5.0"
    public var full: String {
        return "\(majorVersion).\(minorVersion).\(patchVersion)"
    }
    
    /// For the most compact version of the version (will never have .0)
    /// Example: If the version is 1.0.0, it will show as just "1"
   public var compact: String {
        if minorVersion == 0 && patchVersion == 0 {
            return "\(majorVersion)"
        }
        return description // already the pretty version for 1.2.0 -> 1.2
    }
}

// MARK: - Codable conformance so stored as string rather than as a structure of values.
#if !os(Linux)
// Full-runtime WebAssembly supplies Swift's real coding protocols. Because its
// OperatingSystemVersion fallback is owned here, it can use the same stable string representation
// and legacy keyed decoder as Apple and Android instead of a synthesized keyed representation.
extension Version: Swift.Decodable {
    enum CodingKeys: String, CodingKey {
        case majorVersion, minorVersion, patchVersion
    }
    /// Decodes either the legacy keyed component representation or the current string representation.
    ///
    /// Keyed values must contain `majorVersion`, `minorVersion`, and `patchVersion`. String values
    /// use the same forgiving conversion as a ``Version`` string literal.
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
#else
// swift-corelibs-foundation already supplies these conformances for its OperatingSystemVersion;
// even an empty extension would redeclare the conformance and produce a compiler warning.
#endif

#if canImport(Foundation) && compiler(>=6.0) && !canImport(Android) && !arch(wasm32)
// Foundation owns OperatingSystemVersion while Swift owns the literal protocols, so Swift 6
// requires these intentionally retroactive conformances to be stated explicitly.
extension OperatingSystemVersion: @retroactive ExpressibleByExtendedGraphemeClusterLiteral {}
extension OperatingSystemVersion: @retroactive ExpressibleByUnicodeScalarLiteral {}
#endif
extension Version: Swift.ExpressibleByStringLiteral, Swift.ExpressibleByStringInterpolation { // @retroactive in Swift 6?
    // For ExpressibleByStringLiteral conformance
    /// Creates a forgiving version from a string literal.
    ///
    /// Runs of non-numeric characters become component separators, missing components become zero,
    /// and components after the patch component are ignored. For example, `"23b123"` becomes
    /// `23.123.0` and `"1.2-beta"` becomes `1.2.0`. Use ``init(parsing:)`` when invalid text should
    /// return `nil`.
    public init(stringLiteral: String) {
        self.init(forcing: stringLiteral)
    }
}
extension Version: Swift.RawRepresentable { // @retroactive in Swift 6?
    // For RawRepresentable conformance (so we can store and make codable as a String)
    public typealias RawValue = String
    /// Creates a forgiving version from its stored string representation.
    ///
    /// This behaves like ``init(stringLiteral:)`` and therefore never fails. Use
    /// ``init(parsing:)`` when accepting only an exact numeric version.
    public init(rawValue: String) {
        self.init(stringLiteral: rawValue)
    }
    public var rawValue: String {
        return description
    }
}
extension Version: Swift.LosslessStringConvertible { // @retroactive in Swift 6?
    // For LosslessStringConvertible conformance and failable init option.
    /// Creates a forgiving version from text.
    ///
    /// This initializer exists for `LosslessStringConvertible` source compatibility but intentionally
    /// never fails: nonnumeric runs separate numeric components and missing components become zero.
    /// For validation, use ``init(parsing:)`` instead.
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
    /// Creates a version by treating each run of non-numeric characters as a component separator.
    ///
    /// Leading and trailing separators are discarded, repeated separators collapse, missing components
    /// become zero, and only the first three numeric components are used. Thus `"23b123"` becomes
    /// `23.123.0`, `"...1--2__3..."` becomes `1.2.3`, and `"1.0.0.2"` remains `1.0.0`.
    /// This initializer is useful for display-oriented or legacy input. Use ``init(parsing:)`` for
    /// strict validation.
    public init(forcing: String) {
        // Parse directly so Foundation, Linux, WASM, and WASI all apply identical forgiving rules.
        var parsedComponents = [Int]()
        var currentComponent = 0
        var hasCurrentDigits = false
        for character in forcing {
            if let digit = character.wholeNumberValue {
                currentComponent = currentComponent * 10 + digit
                hasCurrentDigits = true
            } else if hasCurrentDigits {
                // A whole run of punctuation or text creates one separator because later characters
                // encounter no pending digits until the next numeric component starts.
                parsedComponents.append(currentComponent)
                if parsedComponents.count == 3 {
                    break
                }
                currentComponent = 0
                hasCurrentDigits = false
            }
        }
        if hasCurrentDigits && parsedComponents.count < 3 {
            parsedComponents.append(currentComponent)
        }
        parsedComponents += Array(repeating: 0, count: 3 - parsedComponents.count)
        self.init(majorVersion: parsedComponents[0], minorVersion: parsedComponents[1], patchVersion: parsedComponents[2])
    }
    /// Creates a version only when the input is an exact numeric version with one to three components.
    ///
    /// Unlike the forgiving initializers, this returns `nil` for labels, suffixes, missing numeric
    /// components, or extra components. For example, `"2.12.1"` succeeds while `"1.2.3b4"` and
    /// `"alphabet"` fail.
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
#if canImport(Foundation) && compiler(>=6.0) && !canImport(Android) && !os(Linux) && !arch(wasm32)
// This is an ownership annotation for Foundation's foreign type, not an availability workaround:
// FoundationEssentials already supplies Equatable on Linux and Android, while the package-owned
// WebAssembly fallback gains it from the local Comparable conformance.
extension Version: @retroactive Equatable {}
#endif
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

#if !os(Linux) || compiler(<6.0)
extension Version: Swift.Hashable {}
#endif

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
        // Keep formatting and component coverage in the framework-owned collection so it runs in the demo too.
        let v100 = Version(majorVersion: 1, minorVersion: 0, patchVersion: 0)
        try expect(v100.description == "1.0")
        try expect(v100.full == "1.0.0")
        try expect(v100.compact == "1")
        let v1301 = Version(majorVersion: 13, minorVersion: 0, patchVersion: 1)
        try expect(v1301.description == "13.0.1")
        try expect(v1301.full == "13.0.1")
        try expect(v1301.compact == v1301.description)
        try expect(v1301.components == [13, 0, 1])
        try expect(Version.zero == Version(majorVersion: 0, minorVersion: 0, patchVersion: 0))

        let defaulted = Version(string: nil, defaultValue: "1.2.3")
        try expect(defaulted == Version("1.2.3"))
        try expect(Version(string: "alphabet", defaultValue: .zero) == .zero)
        let zero = Version("0.0.0")
        try expect(zero == Version("a.b.c"))
        let okay: Version = "2b.5.s"
        try expect(okay == "2.5.0")
        let forced: Version = "2b.5.s"
        try expect(forced == "2.5.0")
        let expanded: Version = "1.2.3b4"
        try expect(expanded == "1.2.3")
        try expectEqual(Version(forcing: "23b123"), "23.123.0")
        try expectEqual(Version(forcing: "...1--2__3..."), "1.2.3")
        try expectEqual(Version(forcing: "1..2...3.4"), "1.2.3")
        let bad: Version = "alphabet soup"
        try expect(bad == .zero)
        try expect(Version(parsing: "alphabet") == nil)
        try expect(Version(parsing: "2.12.1") != nil)
        try expect(Version(parsing: "1.2.3b4") == nil)
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
        var set: Set<Version> = [first, second]
        set.insert(first)
        try expect(set.count == 2)
        let rawVersion = Version("3.4.5")
        try expect(Version(rawValue: rawVersion.rawValue) == rawVersion)

        let rawInput = "1,2.1.2,3"
        let rawVersions: [Version] = .init(rawValue: rawInput)
        try expect(rawVersions.count == 3)
        try expect(rawVersions.pretty == "v1.0, v2.1.2, v3.0")
        try expect(rawVersions.rawValue.contains("2.1.2"))
        let duplicateVersions: [Version] = .init(rawValue: "1,1,2")
        try expect(Set(duplicateVersions.map(\.rawValue)).count == duplicateVersions.count)
        let req: [Version] = .init(rawValue: rawInput, required: "4.3")
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

        // A keyed legacy value missing a semantic-version component must remain a decoding failure.
        let badKeyJSON = #"[{"majorVersion":1,"minorVersion":2}]"#
        do {
            _ = try JSONDecoder().decode([Version].self, from: Data(badKeyJSON.utf8))
            try expect(false, "Expected keyed decode to fail due to a missing patchVersion")
        } catch is DecodingError {
            // The expected failure confirms corrupt legacy storage is not silently accepted.
        }
    }

#if compiler(>=5.9)
    @MainActor
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    static var tests: [TestCase] = [
        TestCase("Version Comparison Tests", testVersions),
        TestCase("Version Codable Tests", versionCodableTest),
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
    /// Creates a sorted, duplicate-free list from comma-separated forgiving version strings.
    ///
    /// Each item uses `Version`'s forgiving conversion, so invalid items become ``Version/zero``.
    public init(rawValue: String) {
        // Remove duplicates and convert invalid values to 0.0.0.
        let versions = Set(rawValue.split(separator: ",").map { Version(string: String($0), defaultValue: .zero) })
        // order
        self = versions.sorted()
    }
    
    public var rawValue: String {
        self.map { $0.rawValue }.joined(separator: ",")
    }
    
    /// Creates a comma-separated version list and ensures that `required` is present.
    ///
    /// The resulting collection is sorted and duplicate-free.
    public init(rawValue: String, required: Version) {
        self.init(rawValue: "\(required),\(rawValue)")
    }
}



#if canImport(SwiftUI) && compiler(>=5.9) && canImport(Foundation)
// Don't know why this is necessary.  CustomStringConvertible should have covered this.
import SwiftUI
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension LocalizedStringKey.StringInterpolation {
    mutating func appendInterpolation(_ value: Version) {
        appendInterpolation(value.description)
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("Tests") {
    TestsListView(tests: Version.tests)
}
#endif
