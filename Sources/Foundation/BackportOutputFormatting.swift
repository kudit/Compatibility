#if !hasFeature(Embedded)
/// JSON output options usable without Foundation and on older deployment targets.
///
/// `asJSON` delegates to Foundation when it supports the requested options. Otherwise
/// the portable formatter sorts every object's keys and formats the encoded text,
/// preserving numeric precision. Keys use lexicographic UTF-8 ordering, as in modern
/// Foundation; older Foundation releases may use different collation rules.
///
/// Follow the Foundation-present call path in this order:
/// 1. `Encodable.asJSON(outputFormatting:)` calls `encode(_:nativeSupport:)` below.
/// 2. `nativeSupport` checks the running OS, not just whether Foundation imports.
/// 3. `nativeOptions(restrictingTo:)` compares ALL requested flags with that support.
/// 4. `encode` returns native JSON if that comparison succeeds; otherwise it calls
///    `format(_:)` with ALL original flags after Foundation encodes the value.
///
/// `format(_:)` itself never chooses a native implementation. It is the explicitly
/// portable text-formatting entry point, also used to test the fallback on a new OS.
public struct BackportOutputFormatting: OptionSet, Sendable {
    public let rawValue: Int
    /// Adds newlines and two-space indentation.
    public static let prettyPrinted = Self(rawValue: 1 << 0)
    /// Sorts keys recursively, including objects contained in arrays.
    public static let sortedKeys = Self(rawValue: 1 << 1)
    /// Leaves `/` unescaped while preserving literal backslashes.
    public static let withoutEscapingSlashes = Self(rawValue: 1 << 3)

    /// Creates options with the same bit positions as Foundation's output options.
    public init(rawValue: Int) { self.rawValue = rawValue }

    /// Formats existing JSON without decoding numbers into fixed-width numeric types.
    ///
    /// This always uses the portable implementation, making it useful for validating
    /// legacy behavior on a newer OS. Throws if the input is malformed or nested more
    /// than 64 levels. Object ordering is retained unless `sortedKeys` is requested.
    public func format(_ json: String) throws -> String {
        // Raw option bits outside the documented set cannot be faithfully applied.
        guard subtracting([.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]).isEmpty else {
            throw PortableJSONError.unsupportedOptions
        }
        var formatter = PortableJSONFormatter(json: json, options: self)
        let result = try formatter.value(depth: 0)
        formatter.whitespace()
        guard formatter.atEnd else { throw PortableJSONError.invalidJSON }
        return result
    }

    #if canImport(Foundation)
    /// A nil result means that at least one requested option needs the text backport.
    internal var nativeOptions: JSONEncoder.OutputFormatting? {
        return nativeOptions(restrictingTo: Self.nativeSupport)
    }

    /// Report actual OS capabilities independently of the options requested by a caller.
    internal static var nativeSupport: Self {
        // These are capabilities, not the caller's requested output. Foundation can
        // be present on iOS 8–10 while its JSONEncoder still lacks sortedKeys.
        var supported: Self = [.prettyPrinted]
        if #available(iOS 11, macOS 10.13, tvOS 11, watchOS 4, *) { supported.insert(.sortedKeys) }
        if #available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *) { supported.insert(.withoutEscapingSlashes) }
        return supported
    }

    /// Tests can restrict capabilities to an older OS while retaining real Foundation
    /// encoding. Never return a partially supported option set: nil selects the entire
    /// portable formatting pass. Unknown bits are rejected instead of silently dropped.
    internal func nativeOptions(restrictingTo supported: Self) -> JSONEncoder.OutputFormatting? {
        // `self` contains the requested flags. Intersection prevents a test override
        // from claiming capabilities the real OS lacks. Subtraction then asks:
        // "Are ANY requested flags left that native Foundation cannot apply?"
        // If yes, return nil for the WHOLE request; do not strip just those flags.
        // nil means fallback, whereas a non-nil empty set means native defaults.
        guard subtracting(supported.intersection(Self.nativeSupport)).isEmpty else { return nil }
        return JSONEncoder.OutputFormatting(rawValue: UInt(bitPattern: rawValue))
    }

    /// Shared Foundation-present encoding path, including the legacy fallback decision.
    /// The capability parameter is internal and only narrows the actual OS capabilities.
    internal func encode<T: Encodable>(_ value: T, nativeSupport: Self = Self.nativeSupport) throws -> String {
        // Step 1: distinguish invalid raw bits from valid flags unavailable on this
        // OS. Invalid bits are an error; unavailable known flags have a backport.
        let known: Self = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard subtracting(known).isEmpty else { throw PortableJSONError.unsupportedOptions }
        // Step 2: make the all-or-nothing native formatting decision. Production
        // callers use the default OS support; tests can simulate old Foundation.
        let native = nativeOptions(restrictingTo: nativeSupport)
        let encoder = JSONEncoder()
        // Step 3: Foundation ALWAYS encodes the Encodable value in this path.
        // When native is nil, [] only disables formatting during this FIRST pass.
        // It does not replace or discard `self`, which still holds every request.
        encoder.outputFormatting = native ?? []
        let data = try encoder.encode(value)
        guard let json = String(data: data, encoding: .utf8) else { throw PortableJSONError.invalidJSON }
        // Foundation still encodes the value on old systems; only text formatting is
        // replaced. No requested option disappears when one is unavailable natively.
        // Step 4: this is the actual dispatch to portable formatting. For example,
        // iOS 10 + [.prettyPrinted, .sortedKeys] reaches format(json) with BOTH flags;
        // iOS 10 + [.prettyPrinted] returns the already-pretty native JSON directly.
        return try native == nil ? format(json) : json
    }
    #endif
}

/// Retains the former Foundation-free option name for source compatibility.
public typealias JSONFormattingOptions = BackportOutputFormatting

private enum PortableJSONError: Error { case invalidJSON, unsupportedOptions }

/// A lossless text formatter: only keys need decoding; values keep their number and
/// string spelling. An ordered array of members avoids relying on Dictionary's or
/// an Encodable OrderedDictionary's serialization order.
private struct PortableJSONFormatter {
    let input: [Unicode.Scalar]
    let options: BackportOutputFormatting
    var index = 0
    init(json: String, options: BackportOutputFormatting) {
        input = Array(json.unicodeScalars)
        self.options = options
    }
    var atEnd: Bool { index == input.count }
    var current: Unicode.Scalar? { atEnd ? nil : input[index] }
    mutating func whitespace() {
        while let c = current, c == " " || c == "\n" || c == "\r" || c == "\t" { index += 1 }
    }
    mutating func take(_ scalar: Unicode.Scalar) throws {
        guard current == scalar else { throw PortableJSONError.invalidJSON }
        index += 1
    }
    func text(_ start: Int) -> String { String(String.UnicodeScalarView(input[start..<index])) }

    /// Recurse over containers only; scalar number tokens are never converted to Double.
    mutating func value(depth: Int) throws -> String {
        // Bound recursion conservatively for the smaller stacks used by test/executor threads.
        guard depth <= 64 else { throw PortableJSONError.invalidJSON }
        whitespace()
        guard let c = current else { throw PortableJSONError.invalidJSON }
        if c == "\"" { return try string().encoded }
        if c == "{" || c == "[" {
            let object = c == "{"
            let close: Unicode.Scalar = object ? "}" : "]"
            index += 1
            whitespace()
            var members: [(key: String, text: String)] = []
            if current != close {
                while true {
                    whitespace()
                    var key = ""
                    var prefix = ""
                    if object {
                        let parsed = try string()
                        key = parsed.decoded
                        prefix = parsed.encoded + (options.contains(.prettyPrinted) ? " : " : ":")
                        whitespace()
                        try take(":")
                    }
                    members.append((key, prefix + (try value(depth: depth + 1))))
                    whitespace()
                    if current != "," { break }
                    index += 1
                }
            }
            try take(close)
            if object && options.contains(.sortedKeys) {
                members.sort { $0.key.utf8.lexicographicallyPrecedes($1.key.utf8) }
            }
            let opening = object ? "{" : "["
            let closing = object ? "}" : "]"
            guard !members.isEmpty else { return opening + closing }
            if options.contains(.prettyPrinted) {
                let indent = String(repeating: "  ", count: depth + 1)
                return opening + "\n" + members.map { indent + $0.text }.joined(separator: ",\n")
                    + "\n" + String(repeating: "  ", count: depth) + closing
            }
            return opening + members.map { $0.text }.joined(separator: ",") + closing
        }
        let start = index
        if c == "t" || c == "f" || c == "n" {
            let literal = c == "t" ? "true" : c == "f" ? "false" : "null"
            for scalar in literal.unicodeScalars { try take(scalar) }
        } else {
            // Validate JSON's ASCII number grammar without changing its spelling.
            if current == "-" { index += 1 }
            if current == "0" { index += 1 }
            else {
                guard let digit = current, digit >= "1", digit <= "9" else { throw PortableJSONError.invalidJSON }
                digits()
            }
            if current == "." { index += 1; try requiredDigits() }
            if current == "e" || current == "E" {
                index += 1
                if current == "+" || current == "-" { index += 1 }
                try requiredDigits()
            }
        }
        return text(start)
    }
    mutating func digits() {
        while let c = current, c >= "0", c <= "9" { index += 1 }
    }
    mutating func requiredDigits() throws {
        let start = index
        digits()
        guard index > start else { throw PortableJSONError.invalidJSON }
    }

    /// Decode keys for sorting while retaining escapes in the output. Slash handling
    /// occurs per escape token, so a literal backslash followed by `/` stays intact.
    mutating func string() throws -> (encoded: String, decoded: String) {
        try take("\"")
        var encoded = "\""
        var decoded = ""
        while let c = current {
            index += 1
            if c == "\"" { return (encoded + "\"", decoded) }
            guard c.value >= 0x20 else { throw PortableJSONError.invalidJSON }
            if c != "\\" {
                decoded.unicodeScalars.append(c)
                encoded += c == "/" && !options.contains(.withoutEscapingSlashes) ? "\\/" : String(c)
                continue
            }
            let start = index - 1
            guard let escape = current else { throw PortableJSONError.invalidJSON }
            index += 1
            switch escape {
            case "\"", "\\", "/": decoded.unicodeScalars.append(escape)
            case "b": decoded.append("\u{8}")
            case "f": decoded.append("\u{c}")
            case "n": decoded.append("\n")
            case "r": decoded.append("\r")
            case "t": decoded.append("\t")
            case "u":
                var code = try hexQuad()
                if (0xD800...0xDBFF).contains(code) {
                    try take("\\"); try take("u")
                    let low = try hexQuad()
                    guard (0xDC00...0xDFFF).contains(low) else { throw PortableJSONError.invalidJSON }
                    code = 0x10000 + (code - 0xD800) * 0x400 + low - 0xDC00
                }
                guard let scalar = Unicode.Scalar(code) else { throw PortableJSONError.invalidJSON }
                decoded.unicodeScalars.append(scalar)
            default: throw PortableJSONError.invalidJSON
            }
            encoded += escape == "/" && options.contains(.withoutEscapingSlashes) ? "/" : text(start)
        }
        throw PortableJSONError.invalidJSON
    }
    mutating func hexQuad() throws -> UInt32 {
        var hex = ""
        for _ in 0..<4 {
            guard let c = current, (c >= "0" && c <= "9") || (c >= "a" && c <= "f") || (c >= "A" && c <= "F") else {
                throw PortableJSONError.invalidJSON
            }
            hex.unicodeScalars.append(c)
            index += 1
        }
        guard let value = UInt32(hex, radix: 16) else { throw PortableJSONError.invalidJSON }
        return value
    }
}

/// Synchronous checks shared by the module test catalog and the legacy CLI runner.
/// These deliberately avoid TestCase, actors, and Swift Testing so the same checks
/// can execute on macOS 10.10/iOS 8 with an appropriately packaged Swift runtime.
internal func testBackportOutputFormatting() throws {
    struct Failure: Error { let message: String }
    func check(_ condition: Bool, _ message: String) throws {
        guard condition else { throw Failure(message: message) }
    }
    let sorted: BackportOutputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    // Nested objects, arrays, escaped keys, large integers, and exact decimal tokens
    // catch lossy decode/re-encode implementations and sorting only the root object.
    let input = #"{"z":[{"b":18446744073709551615,"a":1.2345678901234567890123456789}],"\u0061":"https:\/\/example.com","empty":{}}"#
    let expected = #"{"\u0061":"https://example.com","empty":{},"z":[{"a":1.2345678901234567890123456789,"b":18446744073709551615}]}"#
    try check(try sorted.format(input) == expected, "Recursive sorting must preserve numeric precision")
    let pretty: BackportOutputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    let formatted = try pretty.format(input)
    try check(formatted.contains("\n  \"z\" : [\n    {\n      \"a\""), "Nested pretty indentation")
    try check(try sorted.format(formatted) == expected, "Pretty output round trip")
    // A backslash followed by a slash must not be mistaken for one escaped slash.
    let slash = #"{"path":"a\\\/b","emoji":"\uD83D\uDE00","controls":"\b\f\n\r\t"}"#
    let unescaped = try sorted.format(slash)
    try check(unescaped.contains(#"a\\/b"#), "Literal backslashes survive slash unescaping")
    try check(try BackportOutputFormatting.sortedKeys.format(unescaped) == BackportOutputFormatting.sortedKeys.format(slash), "Slash escaping is reversible")
    try check(try sorted.format(#"{"z":0,"😀":1,"a":2}"#) == #"{"a":2,"z":0,"😀":1}"#, "Unicode keys sort lexicographically")
    for malformed in ["", "[1,]", "{\"a\":1,}", "01", "1.", "1e", "true false", #""\uD800""#, #""\uDC00""#, "\"\n\"", "[" + String(repeating: "[", count: 513)] {
        do {
            _ = try sorted.format(malformed)
        } catch { continue }
        throw Failure(message: "Accepted malformed JSON: \(malformed)")
    }
    // Public convenience calls exercise native delegation on new OSs and automatic
    // fallback on old ones. No Foundation option availability annotations are needed.
    let model = ["z": "https://example.com/😀", "a": "back\\/slash"]
    let json = model.asJSON(outputFormatting: sorted)
    try check(try [String: String](fromJSON: json) == model, "Public encoding round trip")
    try check(try sorted.format(json) == json, "Public compact output is sorted and slash-unescaped")
    try check(try sorted.format(model.prettyJSON) == json, "prettyJSON sorts on every deployment target")
    #if canImport(Foundation)
    // Simulate iOS 8–10 capabilities with Foundation PRESENT. Exercise exactly the
    // encoder/route used by asJSON, rather than just calling the text formatter.
    let legacySupport: BackportOutputFormatting = [.prettyPrinted]
    let sortOnly: BackportOutputFormatting = [.sortedKeys]
    try check(sortOnly.nativeOptions(restrictingTo: legacySupport) == nil, "Unsupported sortedKeys must select full fallback")
    try check(BackportOutputFormatting.prettyPrinted.nativeOptions(restrictingTo: legacySupport) == .prettyPrinted, "Pretty-only output stays native on old Foundation")
    try check(BackportOutputFormatting().nativeOptions(restrictingTo: legacySupport) == [], "Default formatting stays native")
    let nested = ["z": [["b": "two/2", "a": "one/1"]], "a": [["d": "four", "c": "three"]]]
    for options: BackportOutputFormatting in [[.sortedKeys], [.sortedKeys, .prettyPrinted], [.sortedKeys, .withoutEscapingSlashes]] {
        let fallback = try options.encode(nested, nativeSupport: legacySupport)
        try check(try options.format(fallback) == fallback, "Foundation-present fallback must apply every requested option")
        try check(try [String: [[String: String]]](fromJSON: fallback) == nested, "Fallback preserves nested keys and values")
        if let native = options.nativeOptions {
            let encoder = JSONEncoder()
            encoder.outputFormatting = native
            let nativeJSON = String(decoding: try encoder.encode(nested), as: UTF8.self)
            try check(nativeJSON == fallback, "Native and fallback agree for sorted nested fixtures")
            try check(try options.encode(nested) == nativeJSON, "Supported options delegate to native encoder")
        }
    }
    let unsupported = BackportOutputFormatting(rawValue: 1 << 20)
    try check(unsupported.nativeOptions == nil, "Unknown option bits must not disappear")
    do {
        _ = try unsupported.encode(nested)
        throw Failure(message: "Unknown option was ignored")
    } catch is PortableJSONError { /* Expected rejection, not partial formatting. */ }
    // Keep explicitly typed legacy options source-compatible, including nil.
    let native: JSONEncoder.OutputFormatting? = .prettyPrinted
    try check(model.asJSON(outputFormatting: native).contains("\n"), "Typed Foundation options")
    try check(try [String: String](fromJSON: model.asJSON(outputFormatting: nil)) == model, "Nil options remain unambiguous")
    let integers = ["z": UInt64.max, "a": 0]
    try check(try sorted.format(integers.asJSON()) == #"{"a":0,"z":18446744073709551615}"#, "Encoded UInt64 precision")
    #endif
}
#endif
