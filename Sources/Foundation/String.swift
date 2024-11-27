//
//  String.swift
//  KuditFrameworks
//
//  Created by Ben Ku on 1/8/16.
//  Copyright © 2016 Kudit. All rights reserved.
//

/// TODO: Make note of how to convert a string to markdown?

// for NSDocumentTypeDocumentAttribute
//#if canImport(UIKit)
//import UIKit
//#elseif canImport(AppKit)
//import AppKit
//#endif

public extension LosslessStringConvertible {
    /// Initialize from a possibly empty string and a default value if the string is nil or if the conversion fails
    init(string: String?, defaultValue: Self) {
        guard let string else {
            self = defaultValue
            return
        }
        guard let converted = Self(string) else {
            self = defaultValue
            return
        }
        self = converted
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
extension CharacterSet {
    @MainActor public static let tests = [
        Test("character strings", testCharacterStrings),
    ]
}
public extension CharacterSet {
    /// Returns the character set as an array of strings. (ONLY ASCII Characters!)
    var characterStrings: [String] {
        let unichars = Array(0..<128).map { UnicodeScalar($0)! }
        let filtered = unichars.filter(contains)
        return filtered.map { String($0) }
    }
    @MainActor
    internal static let testCharacterStrings: TestClosure = {
        let array = "hello".characterStrings
        try expect(array == ["h","e","l","l","o"], String(describing:array))
    }

    /// Returns a character set containing all numeric digits.
    // NOTE: Can't use static let because CharacterSet is not Sendable :(
    static var numerics: CharacterSet { CharacterSet(charactersIn: "0123456789")
    }

    /// Returns a character set containing the characters allowed in an URL's parameter subcomponent.
    static var urlParameterAllowed: CharacterSet {
        var validCharacterString = CharacterSet.alphanumerics.characterStrings.joined()
        validCharacterString += "-_.!~*()" // alphanumeric plus some additional valid characters
        return CharacterSet(charactersIn: validCharacterString)
    }
}

// MARK: - HTML
#if canImport(NSAttributedString)
import NSAttributedString
#endif

// need it to be a typealias rather than a struct so that when coded it stores as a string instead of a keyed object.
// Needs to be in a container or the compiler has issues in Swift Playgrounds.
public extension Compatibility {
    typealias HTML = String
}
public typealias HTML = Compatibility.HTML
public extension HTML {
    /// Cleans the HTML content to ensure this isn't just a snippet of HTML and includes the proper headers, etc.
    var cleaned: HTML {
        var cleaned = self
        if !cleaned.contains("<body>") {
            cleaned = """
<body>
\(cleaned)
</body>
"""
        }
        if !cleaned.contains("<html>") {
            cleaned = """
<html>
\(cleaned)
</html>
"""
        }
        return cleaned
    }

#if canImport(Combine) || canImport(NSAttributedString)
    /// Generate an NSAttributedString from the HTML content enclosed
    var attributedString: NSAttributedString {
        let cleaned = self.cleaned
        let data = Data(cleaned.utf8)
        if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
            return attributedString
        }
        return NSAttributedString(string: cleaned)
    }
#endif
    
    /// Encode a string using the typical HTML entities syntax according to https://www.w3.org/wiki/Common_HTML_entities_used_for_typography
    // TODO: Do we want to convert this to a map and for loop?
    var htmlEncoded: String {
        let entities = [
            "&": "&amp;",
            "¢": "&cent;",
            "£": "&pound;",
            "§": "&sect;",
            "©": "&copy;",
            "«": "&laquo;",
            "»": "&raquo;",
            "®": "&reg;",
            "°": "&deg;",
            "±": "&plusmn;",
            "¶": "&para;",
            "·": "&middot;",
            "µ": "&micro;",
            "½": "&frac12;",
            "¼": "&frac14;",
            "¾": "&frac34;",
            "–": "&ndash;",
            "—": "&mdash;",
            "¹": "&sup1;",
            "²": "&sup2;",
            "³": "&sup3;",
            "⁴": "&sup4;",
            "⁵": "&sup5;",
            "⁶": "&sup6;",
            "⁷": "&sup7;",
            "⁸": "&sup8;",
            "⁹": "&sup9;",
            "<": "&lt;",
            ">": "&gt;",
            "‘": "&lsquo;",
            "’": "&rsquo;",
            "‚": "&sbquo;",
            "“": "&ldquo;",
            "”": "&rdquo;",
            "„": "&bdquo;",
            "†": "&dagger;",
            "‡": "&Dagger;",
            "•": "&bull;",
            "…": "&hellip;",
            "′": "&prime;",
            "″": "&Prime;",
            "‹": "&lsaquo;",
            "›": "&rsaquo;",
            "€": "&euro;",
            "™": "&trade;",
            "≈": "&asymp;",
            "≠": "&ne;",
            "≤": "&le;",
            "≥": "&ge;",
            "÷": "&divide;",
            "√": "&radic;",
            "∞": "&infin;",
            "∫": "&int;",
            "×": "&times;",
            //            .replacingOccurrences(of: "/", with: "&sol;")
            //            .replacingOccurrences(of: "\\", with: "&bsol;")
            //            .replacingOccurrences(of: "'", with: "&apos;")
            //            .replacingOccurrences(of: "\"", with: "&quot;")
            //            .replacingOccurrences(of: "#", with: "&hash;")
            //            .replacingOccurrences(of: "@", with: "&at;")
            //            .replacingOccurrences(of: "$", with: "&dollar;")
            //            .replacingOccurrences(of: "%", with: "&percent;")
            //            .replacingOccurrences(of: "*", with: "&ast;")
            //            .replacingOccurrences(of: "+", with: "&plus;")
            //            .replacingOccurrences(of: "-", with: "&minus;")
            //            .replacingOccurrences(of: ".", with: "&period;")
            //            .replacingOccurrences(of: ",", with: "&comma;")
            //            .replacingOccurrences(of: ":", with: "&colon;")
            //            .replacingOccurrences(of: ";", with: "&semicolon;")
            //            .replacingOccurrences(of: "=", with: "&equal;")
            //            .replacingOccurrences(of: "?", with: "&question;")
            //            .replacingOccurrences(of: "!", with: "&exclam;")
            //            .replacingOccurrences(of: "/", with: "&slash;")
            //            .replacingOccurrences(of: "(", with: "&lparen;")
            //            .replacingOccurrences(of: ")", with: "&rparen;")
            //            .replacingOccurrences(of: "{", with: "&lbrace;")
            // accented characters we're going to not replace.
        ]
        var encodedString = self
        for (symbol, entity) in entities {
            encodedString = encodedString.replacingOccurrences(of: symbol, with: entity)
        }
        return encodedString
    }

    internal static let testHTML = """
    <html>
    <head>
    <title>Title</title>
    <style>
    body {
        text-decoration: underline;
        font-size: x-large;
        font-family: sans-serif;
        border: 5px solid blue; /* Not supported */
        padding: 20px; /* Not supported */
    }
    </style>
    </head>
    <body>
    <h1>Header</h1>
    <p>The quick <strong style="color: brown;">bold</strong> <span style="color: orange;">fox</span> <span style="color: green;">jumped</span> over the <em>italic</em> dog.</p>
    </body>
    </html>
    """
}

#if canImport(SwiftUI) && (canImport(Combine) || canImport(NSAttributedString)) && swift(>=5.9)
@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview("HTML") {
    ScrollView {
        Text(AttributedString(HTML.testHTML.attributedString))
    }
}
#endif

public extension String {
    static let INVALID_ENCODING = "INVALID_ENCODING"
    
    // MARK: - UUID Generation
    static func uuid() -> String {
        return UUID().uuidString
    }
    
    // MARK: - Introspection
    /*
     /// number of characters in the `String`
     @available(*, deprecated, message: "use String.count instead") // TODO: see where used and adapt.
     var length: Int {
     return self.count
     }
     */
    /// Return whether this value should evalute to true whether it's a positive integer, "true", "t", "yes", "y", or "on" regardless of capitalization.
    var asBool: Bool {
        let lower = self.lowercased()
        let int = Int(self) ?? 0
        if int > 0 || lower == "true" || lower == "yes" || lower == "y" || lower == "t" || lower == "on" {
            return true
        }
        return false
    }
    /// `true` iff `self` contains characters.
    ///
    /// Equivalent to `!self.isEmpty`
    var hasContent: Bool {
        return !self.isEmpty
    }
    /// Returns `true` iff the `String` contains one of the `strings` by case-sensitive, non-literal search.
    func containsAny(_ strings: [String]) -> Bool {
        for string in strings {
            if self.contains(string) {
                return true
            }
        }
        return false
    }
    /// Returns the number of times a string is included in the `String`.  Does not count overlaps.
    func occurrences(of substring: String) -> Int {
        let components = self.components(separatedBy: substring)
        return components.count - 1
    }
    /// `true` if there is only an integer number or double in the `String` and there isn't other letters or spaces.
    var isNumeric: Bool {
        if let _ = Double(self) {
            return true
            //            if let intVersion = Int(foo) {
            //                print("Int: \(intVersion)")
            //            } else {
            //                print("Double: \(doubleVersion)")
            //            }
        }
        // print("NaN")
        return false
    }
    
    // NOTE: NSDataDetector is not available on Linux!
#if canImport(Combine)
    /// Helper for various data detector matches.
    /// Returns `true` iff the `String` matches the data detector type for the complete string.
    func matchesDataDetector(type: NSTextCheckingResult.CheckingType, scheme: String? = nil) -> Bool {
        let dataDetector = try? NSDataDetector(types: type.rawValue)
        guard let firstMatch = dataDetector?.firstMatch(in: self, options: NSRegularExpression.MatchingOptions.reportCompletion, range: NSRange(location: 0, length: count)) else {
            return false
        }
        return firstMatch.range.location != NSNotFound
        // make sure the entire string is an email, not just contains an email
        && firstMatch.range.location == 0
        && firstMatch.range.length == count
        // make sure the link type matches if link scheme
        && (type != .link || scheme == nil || firstMatch.url?.scheme == scheme)
    }
    /// `true` iff the `String` is an email address in the proper form.
    var isEmail: Bool {
        return matchesDataDetector(type: .link, scheme: "mailto")
    }
    /// `true` iff the `String` is a phone number in the proper form.
    var isPhoneNumber: Bool {
        return matchesDataDetector(type: .phoneNumber)
    }
    /// `true` iff the `String` is a phone number in the proper form.
    var isURL: Bool {
        return matchesDataDetector(type: .link)
    }
    /// `true` iff the `String` is an address in the proper form.
    var isAddress: Bool {
        return matchesDataDetector(type: .address)
    }
    
    /// Returns a URL if the String can be converted to URL.  `nil` otherwise.
    var asURL: URL? {
        // make sure data matches detector so "world.json" isn't seen as a valid URL.  must be fully qualified.
        guard isURL else {
            return nil
        }
        return URL(string: self)
    }
#endif

    /// Get last "path" component of a string (basically everything from the last `/` to the end)
    var lastPathComponent: String {
        let parts = self.components(separatedBy: "/")
        let last = parts.last ?? self
        return last
    }
    
    /// `true` if the byte length of the `String` is larger than 100k (the exact threashold may change)
    var isLarge: Bool {
        let bytes = self.lengthOfBytes(using: String.Encoding.utf8)
        return bytes / 1024 > 100 // larger than 100k worth of text (that's still a LOT of lines)
    }
    /// `true` if the `String` appears to be a year after 1760 and before 3000 (use for reasonablly assuming text could be a year value)
    var isPostIndustrialYear: Bool {
        guard let year = Int(self) else {
            return false
        }
        guard self.isNumeric else {
            return false
        }
        return year > 1760 && year < 3000
    }
    
    /// an array of the characters of the `String` as strings
    // Objective-C was [string characters] which returned character strings.
    // Swift strings have a .characters method which returns an array of characters.
    // Matches the syntax for CharacterSet added above.
    var characterStrings: [String] {
        var characters = [String]()
        for character in self {
            characters += [String(character)]
        }
        return characters
        //return Array(self.characters).map { String($0) }
    }
    
    // MARK: - Trimming
    /// Returns a new string made by removing whitespace from both ends of the `String`.
    var trimmed: String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    /// Removes whitespace from both ends of the `String`.
    mutating func trim() {
        self = self.trimmed
    }
    /// Returns a new string made by removing from both ends of the `String` instances of the given string.
    /// Returns a new string made by removing from both ends of the `String` instances of the given string.
    // Fixed to use Substrings so we don't have to do length or indexing.
    func trimming(_ trimString: String) -> String {
        guard trimString.count > 0 else { // if we try to trim an empty string, infinite loop will happen below so just return.
            return self
        }
        var returnString = Substring(self)
        while returnString.hasPrefix(trimString) {
            //returnString = returnString.substring(from: returnString.characters.index(returnString.startIndex, offsetBy: trimString.length))
            let index = returnString.index(returnString.startIndex, offsetBy: trimString.count)
            returnString = returnString.suffix(from: index)
        }
        while returnString.hasSuffix(trimString) {
            let index = returnString.index(returnString.endIndex, offsetBy: -(trimString.count + 1)) // NOTE: Needs the +1 since the endIndex is one AFTER the position and we're using the "through:" syntax which includes the last index.
            //            print("Trimming suffix \(trimString) from \(returnString) offset: \(-trimString.count)")
            returnString = returnString.prefix(through: index) // since through, need to be -1 to not be inclusive
            //returnString = returnString.substring(to: returnString.characters.index(returnString.endIndex, offsetBy: -trimString.length))
        }
        return String(returnString)
    }
    /// Removes the given string from both ends of the `String`.
    mutating func trim(_ trimString: String) {
        self = self.trimming(trimString)
    }
    /// Returns a new string made by removing from both ends of the `String` instances of any of the given strings.
    func trimming(_ trimStrings: [String]) -> String {
        var returnString = self
        for string in trimStrings {
            returnString = returnString.trimming(string)
        }
        return returnString
    }
    /// Removes the given strings from both ends of the `String`.
    mutating func trim(_ trimStrings: [String]) {
        self = self.trimming(trimStrings)
    }
    /// Returns a new string made by removing from both ends of the `String` characters contained in a given string.
    func trimmingCharacters(in string: String) -> String {
        let badSet = CharacterSet(charactersIn: string)
        return self.trimmingCharacters(in: badSet)
    }
    
    @MainActor
    internal static let testTriming: TestClosure = {
        let long = "ExampleWorld/world.json"
        let trim = "world.json"
        let trimmed = long.trimming(trim)
        // assert
        try expect(trimmed == "ExampleWorld/", "Trimmed: \(trimmed)")
    }
    @MainActor
    internal static let testTrimingEmpty: TestClosure = {
        let long = "ExampleWorld/world.json"
        let trim = ""
        let trimmed = long.trimming(trim)
        // assert
        try expect(trimmed == long, "Trimmed should match long: \(trimmed)")
    }
    
    
    // MARK: - Replacements
    func replacingCharacters(in range: NSRange, with string: String) -> String {
        return (self as NSString).replacingCharacters(in: range, with: string)
    }
    
    /// Returns a new string in which all occurrences of any target
    /// strings in a specified range of the `String` are replaced by
    /// another given string.
    func replacingOccurrences(
        of targets: [String],
        with replacement: String,
        options: CompareOptions = [],
        range searchRange: Range<Index>? = nil
    ) -> String {
        var returnString = self // copy
        for search in targets {
            returnString = returnString.replacingOccurrences(of: search, with: replacement, options: options, range: searchRange)
        }
        return returnString
    }
    /// Returns a new string in which all characters in a target
    /// string in a specified range of the `String` are replaced by
    /// another given string.
    func replacingCharacters(
        in findCharacters: String,
        with replacement: String,
        options: CompareOptions = [],
        range searchRange: Range<Index>? = nil
    ) -> String {
        let characters = findCharacters.characterStrings
        return self.replacingOccurrences(of: characters, with: replacement, options: options, range: searchRange)
    }
    /// Returns a new string in which all characters in a target
    /// string in a specified range of the `String` are replaced by
    /// another given string.
    func replacingCharacters(
        in characterSet: CharacterSet,
        with replacement: String,
        options: CompareOptions = [],
        range searchRange: Range<Index>? = nil
    ) -> String {
        return self.components(separatedBy: characterSet).joined(separator: replacement)
    }
    
    // MARK: - Condensing
    /// Returns a trimmed string with all double spaces collapsed to single spaces and multiple line breaks collapsed to a single line break.  Removes non-breaking spaces.  Designed for making text compact.  (Note: for compatibility with KuditFrameworks.php, not used currently in any swift code).
    var whitespaceCollapsed: String {
        // replace non-breaking space with normal space (seems to not be included in whitespaces)
        var returnString = self.replacingOccurrences(of: " ", with: " ");
        // replace whitespace characters with spaces
        returnString = returnString.replacingOccurrences(of: CharacterSet.whitespaces.characterStrings, with: " ")
        // replace newline characters with new lines
        returnString = returnString.replacingOccurrences(of: CharacterSet.newlines.characterStrings, with: "\n")
        // collapse runs of spaces
        while returnString.contains("  ") {
            returnString = returnString.replacingOccurrences(of: "  ", with: " ")
        }
        // collapse runs of line breaks with a single line break
        while returnString.contains("\n\n") {
            returnString = returnString.replacingOccurrences(of: "\n\n", with: "\n")
        }
        return returnString.trimmed
    }
    // - (NSString *)
    //     stringByRemovingCharactersInString:(NSString *)target
    /// Returns a string with characters in the `characters` string removed.
    // used in CSSColors
    func removing(
        characters: String,
        options: CompareOptions = [],
        range searchRange: Range<Index>? = nil
    ) -> String {
        return self.replacingOccurrences(of: characters.characterStrings, with: "", options: options, range: searchRange)
    }
    // - (NSString *)
    //     stringByRemovingCharactersNotInString:(NSString *)target
    /// Returns a string containing only the characters found in the `characters` string.
    func preserving(
        characters: String,
        options: CompareOptions = [],
        range searchRange: Range<Index>? = nil
    ) -> String {
        let whitelistCharacterSet = CharacterSet(charactersIn: characters)
        let badCharacterSet = whitelistCharacterSet.inverted
        return self.components(separatedBy: badCharacterSet).joined(separator: "")
    }
    /// string with all duplicate characters removed
    var duplicateCharactersRemoved: String {
        return self.characterStrings.unique.joined(separator: "")
    }
    
    // MARK: - Transformed
    /// version of string with first letter of each sentence capitalized
    var sentenceCapitalized: String {
        let sentences = self.components(separatedBy: ".")
        var fixed = [String]()
        for sentence in sentences {
            var words = sentence.components(separatedBy: " ")
            for index in words.indices {
                // check for spaces or blank words
                if words[index].trimmed != "" {
                    words[index] = words[index].capitalized
                    break // only do first word
                }
            }
            fixed.append(words.joined(separator: " "))
        }
        return fixed.joined(separator: ".")
    }
    @MainActor
    internal static let testSentenceCapitalized: TestClosure = {
        let capitalized = "hello world. goodbye world.".sentenceCapitalized
        try expect(capitalized == "Hello world. Goodbye world.", String(describing:capitalized))
    }
    
    /// normalized version of string for comparisons and database lookups.  If normalization fails or results in an empty string, original string is returned.
    var normalized: String? {
        // expand ligatures and other joined characters and flatten to simple ascii (æ => ae, etc.) by converting to ascii data and back
        guard let data = self.data(using: String.Encoding.ascii, allowLossyConversion: true) else {
            print("WARNING: Unable to convert string to ASCII Data: \(self)")
            return self
        }
        guard let processed = String(data: data, encoding: String.Encoding.ascii) else {
            print("WARNING: Unable to decode ASCII Data normalizing stirng: \(self)")
            return self
        }
        var normalized = processed
        
        //    // remove non alpha-numeric characters
        normalized = normalized.replacingOccurrences(of: "?", with: "") // educated quotes and the like will be destroyed by above data conversion
        // replace diatrics and accented characters with normal equivalents
        // (probably unnecessary due to the ascii encoding above)
        normalized = normalized.decomposedStringWithCanonicalMapping
        // strip appostrophes
        normalized = normalized.replacingCharacters(in: "'", with: "")
        // replace non-alpha-numeric characters with spaces
        normalized = normalized.replacingCharacters(in: CharacterSet.alphanumerics.inverted, with: " ")
        // lowercase string
        normalized = normalized.lowercased()
        
        // remove multiple spaces and line breaks and tabs and trim
        normalized = normalized.whitespaceCollapsed
        
        // may return an empty string if no alphanumeric characters!  In this case, use the raw string as the "normalized" form (for Deckmaster card "____"
        if normalized == "" {
            return self
        } else {
            return normalized
        }
    }
    /// Returns the `String` reversed.
    var reversed: String {
        return self.characterStrings.reversed().joined(separator: "")
    }
    /// Returns the `String` repeated the specified number of times.
    func repeated(_ times: Int) -> String {
        return String(repeating: self, count: times)
    }
    
    /// An array of string of all the vowels in the english language (not counting Y).
    static let vowels = ["a", "e", "i", "o", "u"]
    
    /// An array of all the consonants in the english language (not counting Y).
    static let consonants = ["b", "c", "d", "f", "g", "h", "j", "k", "l", "m", "n", "p", "q", "r", "s", "t", "v", "w", "x", "z"]
    
    /// The name game string
    var banana : String {
        guard self.count > 1 else {
            return "\"\(self)\" is too short to play the name game :("
        }
        let secondIndex = self.index(startIndex, offsetBy: 1)
        let first = self[..<secondIndex].uppercased()
        //let first = substring(to:secondIndex).uppercased()
        var shortName = self
        if String.consonants.contains(first.lowercased()) {
            shortName = String(self[secondIndex...])
            //shortName = substring(from: secondIndex)
        }
        var string = "\(self), \(self), bo-"
        if "B" != first {
            string += "b"
        }
        string += "\(shortName)\nBanana-fana fo-"
        if "F" != first {
            string += "f"
        }
        string += "\(shortName)\nFee-fy-mo-"
        if "M" != first {
            string += "m"
        }
        string += "\(shortName)\n\(self)!"
        return string
    }
    
    // MARK: - Encoded
    /// URL encoded (% encoded) string or the `String` "`COULD_NOT_ENCODE`" if the `String` is not valid Unicode.
    var urlEncoded: String {
        // http://stackoverflow.com/a/33558934/897883
        guard let encoded = self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlParameterAllowed) else {
            return String.INVALID_ENCODING
        }
        return encoded
    }
    /// String with non-file-safe characters replaced with an underscore (`_`).
    var fileSafe: String {
        return self.replacingCharacters(in: "/=\\?%*|'\"<>:", with:"_")
    }
    /// get the basename of the file without the extension (returns entire string if no extension)
    @available(*, deprecated, message: "use fileBasename method on NSURL") // TODO: see where used and adapt.
    var fileBasename: String {
        var parts = self.components(separatedBy: ".")
        guard parts.count > 1 else {
            return self
        }
        _ = parts.popLast() // strip off extension
        return parts.joined(separator: ".")
    }
    /// get the extension of the file
    @available(*, deprecated, message: "use pathExtension method on NSString") // TODO: see where used and adapt.
    var fileExtension: String {
        return self.replacingOccurrences(of: "\(self.fileBasename).", with: "")
    }
    
    // MARK: - HTML Tools
    /// String with XML style tags removed.
    var tagsStripped: String {
        var cleaned = self
        while let range = cleaned.range(of: "<[^>]+>", options: .regularExpression) {
            cleaned = cleaned.replacingCharacters(in: range, with: "")
        }
        return cleaned
    }
    
    // MARK: - Parsing
    /// Fix to avoid casting String to NSString
    func substring(with range: NSRange) -> String { // TODO: figure out how to replace this...
        return (self as NSString).substring(with: range)
    }
    @MainActor
    internal static let testSubstring: TestClosure = {
        let extraction = TEST_STRING.substring(with: NSRange(7...12))
        try expect(extraction == "string" , String(describing:extraction))
    }
    
    /// Parses out a substring from the first occurrence of `start` to the next occurrence of `end`.
    /// If `start` or `end` are `nil`, will parse from the beginning of the `String` or to the end of the `String`.
    /// If the `String` doesn't contain the start or end (whichever is provided), this will return nil.
    /// - Parameter from: start the extraction after the first occurrence of this string or from the beginning of the `String` if this is `nil`
    /// - Parameter to: end the extraction at the first occurrence of this string after `from` or at the end of the `String` if this is `nil`
    ///  - Return: the extracted string or nil if either start or end are not found
    // TODO: rename extracting?
    func extract(from start: String?, to end: String?) -> String? {
        // copy this string for use
        var substr = self
        if let start = start {
            guard self.contains(start) else {
                return nil
            }
            // get everything after the start tag
            var parts = substr.components(separatedBy: start)
            parts.removeFirst()
            substr = parts.joined(separator: start) // probably only 1 item, but just in case...
        }
        if let end = end {
            guard self.contains(end) else {
                return nil
            }
            // get everything before the end tag
            let parts = substr.components(separatedBy: end)
            substr = parts[0]
        }
        return substr
    }
    internal static let TEST_STRING = "A long string with some <em>intérressant</em> properties!"
    @MainActor
    internal static let testExtractTags: TestClosure = {
        let extraction = TEST_STRING.extract(from: "<em>", to: "</em>") // should never fail
        try expect(extraction == "intérressant" , String(describing:extraction))
    }
    @MainActor
    internal static let testExtractNilStart: TestClosure = {
        let extraction = TEST_STRING.extract(from: nil, to: "string")
        try expect(extraction == "A long " , String(describing:extraction))
    }
    @MainActor
    internal static let testExtractNilEnd: TestClosure = {
        let extraction = TEST_STRING.extract(from: "</em>", to: nil)
        try expect(extraction == " properties!" , String(describing:extraction))
    }
    @MainActor
    internal static let testExtractMissingStart: TestClosure = {
        let extraction = TEST_STRING.extract(from: "<strong>", to: "</em>")
        try expect(extraction == nil , String(describing:extraction))
    }
    @MainActor
    internal static let testExtractMissingEnd: TestClosure = {
        let extraction = TEST_STRING.extract(from: "<em>", to: "</strong>")
        try expect(extraction == nil , String(describing:extraction))
    }
    
    
    
    // NOTE: Removed since deprecated for a while and throws errors in Linux as it's unable to bridge NSString to String.
    //    /// Deletes a section of text from the first occurrence of `start` to the next occurrence of `end` (inclusive).
    //    /// - Warning: string must contain `start` and `end` in order to work as expected.
    //    @available(*, deprecated, message: "There may be better ways to do this not in the standard library") // TODO: see where used and adapt.  If keep, change to deleting(from: to:) no throws (just don't do anything)
    //    func stringByDeleting(from start: String, to end: String) throws -> String {
    //        let scanner = Scanner(string: self)
    //        scanner.charactersToBeSkipped = nil // don't skip any whitespace!
    //        var beginning: NSString? = ""
    //        scanner.scanUpTo(start, into: &beginning)
    //        guard beginning != nil else {
    //            return self
    //        }
    //        scanner.scanUpTo(end, into: nil)
    //        scanner.scanString(end, into: nil)
    //        let tail = scanner.string.substring(from: self.index(self.startIndex, offsetBy: scanner.scanLocation))
    //        return "\(beginning!)" + tail
    //    }
    
    // MARK: - JSON Tools
    /**
     Returns a string with backslashes added before characters that need to be escaped. These characters are:

//     single quote (')
     double quote (")
     backslash (\)
//     NUL (the NUL byte)
     */
    func addSlashes() -> String {
        return self
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
    
    /// Returns `self` as the `errorMessage` parameter of a JSON object with a `success` parameter equal to `false`.  Pass a debug `level` to also print a debug statement as the provided `level`.
    func asErrorJSON(level: DebugLevel = .NOTICE) -> String {
        debug(self, level: level)
        return """
{
    "success" : false,
    "errorMessage": "\(self.addSlashes())"
}
"""
    }
    
    /// Return an object extracted from the JSON data in this string or nil if this is not a valid JSON string.
    @available(*, deprecated, message: "Is this used by anyone/anything?  If not, remove.  Deprecated in version 1.0.13")
    var JSONObject: Any? {
        let data = Data(self.utf8)
        do {
            return try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            // don't warn because this could be expected behavior print("WARNING: Unable to create JSON object: \(self)")
            return nil
        }
    }
    
    @available(iOS 13, tvOS 13, watchOS 6, *)
    @MainActor
    static let tests = [
        Test("sentence capitalized", testSentenceCapitalized),
        Test("substring", testSubstring),
        Test("trimming", testTriming),
        Test("trimming empty", testTrimingEmpty),
        Test("extract tags", testExtractTags),
        Test("extract nil start", testExtractNilStart),
        Test("extract nil end", testExtractNilEnd),
        Test("extract missing start", testExtractMissingStart),
        Test("extract missing end", testExtractMissingEnd),
        Test("Line Reversal", testTextReversal)
    ]
}

// TODO: See where we can use @autoclosure in Kudit Frameworks to delay execution (particularly in test frameworks!)
public extension Optional where Wrapped == any Numeric {
    /// Support displaying string as an alternative in nil coalescing for inline \(optionalNum ?? "String description of nil")
    static func ?? (optional: Wrapped?, defaultValue: @autoclosure () -> String) -> String {
        if let optional {
            return String(describing: optional)
        } else {
            return defaultValue()
        }
    }
}

@MainActor
let testTextReversal: TestClosure = {
    let text = """
v1.0.8 8/10/2022 Manually created initializers for SwiftUI views to prevent internal protection errors.
v1.0.9 8/10/2022 Fixed tests to run in Xcode.  Added watchOS and tvOS support.
v1.0.10 8/11/2022 Removed a bunch of KuditConnect and non-critical code since those should be completely re-thought and added in a modern way and there is too much legacy code.
v1.0.11 8/11/2022 Removed unnecessary KuditFrameworks import from Image.swift.
v1.0.12 8/12/2022 changed String.contains() to String.containsAny() to be more clear.  Modified KuError to include public initializer and automatic Debug print.
v1.0.13 8/12/2022 Added File and Date and URL comparable code.  Need to migrate NSDate to Date.
v1.0.14 8/24/2022 Added RingedText, ShareSheet, and Graphics code from old Swift Frameworks.
v1.0.15 8/25/2022 Checked added frameworks to make sure everything is marked public so usable by ouside code.
v1.0.16 8/25/2022 Made let properties on ShareSheet struct public vars hopefully to silence private init warning.
v1.0.17 8/26/2022 Added public init to ShareSheet.  Added Coding framework.
v1.0.18 8/26/2022 Added String.sentenceCapitalization.
v1.0.19 8/29/2022 Re-worked testing framework to be more robust and to allow code coverage tests in Xcode.
v1.0.20 8/30/2022 Removed shuffle and random since built-in as part of native Array functions.
v1.0.21 8/31/2022 Moved folders for KuditFrameworks into Sources folder since we already know this is for KuditFrameworks and removes unnecessary nesting.
v1.0.22 8/31/2022 Rearranged test order and shorted sleep test.
v1.0.23 9/8/2022 Added KuditLogo to framework from Tracker (not perfected yet).  Added preview to KuditFrameworksApp.  Fixed UIActivity missing from Mac (non-catalyst) build.
v1.0.24 9/8/2022 Removed conditions from ShareSheet as it prevents access on iOS for some reason.
v1.0.25 9/8/2022 Tweaked KuditLogo with some previews that have examples of how it might be used.
v1.0.26 9/14/2022 Added additional documentation to KuditFrameworks Threading.  Renamed KuError to CustomError.  Added ++ operator.  Added Date.pretty formatter. Added Image(data:Data) import extensions.  Added padding(size:) extension.  Added Color: Codable extensions.  Added Int.ordinal function.  Included deprecated message for KuError.  Added PlusPlus test.  Fixed Playgrounds test with #if canImport(PreviewProvider) to #if canImport(SwiftUI).  Fixed/Added App Icon.
v1.0.27 9/14/2022 Fixed permissions on methods.  Fixed package versioning and synced package.txt files.
v1.0.28 9/14/2022 Added signing capabilities for macOS network connections and added note about future dependency on DeviceKit project (replace any usage in KuditHardware since DeviceKit will be more likely updated regularly.)
v1.0.29 9/14/2022 Fixed problem with Readme comments continually reverting.  Added @available modifiers to code.  Restored mistakenly uploaded Package file.  Moved some TODOs around.
v1.0.30 9/14/2022 Fixed issue where last two updates were the wrong major version number!
v1.0.31 9/14/2022 Updated KuColor protocol to apply to SwiftUI Color.  Removed old UIImage code that could cause crashes.  Added .frame(size:) method.  Fixed issue with RGBA parsing and HSV calculations.  Re-worked SwiftUI color conformance to KuColor protocols to simplify.  Added some test methods.  Reversed order of versioning to make easier to find changes.
"""
    var lines = text.components(separatedBy: "\n")
    lines.reverse()
    let reversed = lines.joined(separator: "\n")
//    print(reversed)
    let expected = """
v1.0.31 9/14/2022 Updated KuColor protocol to apply to SwiftUI Color.  Removed old UIImage code that could cause crashes.  Added .frame(size:) method.  Fixed issue with RGBA parsing and HSV calculations.  Re-worked SwiftUI color conformance to KuColor protocols to simplify.  Added some test methods.  Reversed order of versioning to make easier to find changes.
v1.0.30 9/14/2022 Fixed issue where last two updates were the wrong major version number!
v1.0.29 9/14/2022 Fixed problem with Readme comments continually reverting.  Added @available modifiers to code.  Restored mistakenly uploaded Package file.  Moved some TODOs around.
v1.0.28 9/14/2022 Added signing capabilities for macOS network connections and added note about future dependency on DeviceKit project (replace any usage in KuditHardware since DeviceKit will be more likely updated regularly.)
v1.0.27 9/14/2022 Fixed permissions on methods.  Fixed package versioning and synced package.txt files.
v1.0.26 9/14/2022 Added additional documentation to KuditFrameworks Threading.  Renamed KuError to CustomError.  Added ++ operator.  Added Date.pretty formatter. Added Image(data:Data) import extensions.  Added padding(size:) extension.  Added Color: Codable extensions.  Added Int.ordinal function.  Included deprecated message for KuError.  Added PlusPlus test.  Fixed Playgrounds test with #if canImport(PreviewProvider) to #if canImport(SwiftUI).  Fixed/Added App Icon.
v1.0.25 9/8/2022 Tweaked KuditLogo with some previews that have examples of how it might be used.
v1.0.24 9/8/2022 Removed conditions from ShareSheet as it prevents access on iOS for some reason.
v1.0.23 9/8/2022 Added KuditLogo to framework from Tracker (not perfected yet).  Added preview to KuditFrameworksApp.  Fixed UIActivity missing from Mac (non-catalyst) build.
v1.0.22 8/31/2022 Rearranged test order and shorted sleep test.
v1.0.21 8/31/2022 Moved folders for KuditFrameworks into Sources folder since we already know this is for KuditFrameworks and removes unnecessary nesting.
v1.0.20 8/30/2022 Removed shuffle and random since built-in as part of native Array functions.
v1.0.19 8/29/2022 Re-worked testing framework to be more robust and to allow code coverage tests in Xcode.
v1.0.18 8/26/2022 Added String.sentenceCapitalization.
v1.0.17 8/26/2022 Added public init to ShareSheet.  Added Coding framework.
v1.0.16 8/25/2022 Made let properties on ShareSheet struct public vars hopefully to silence private init warning.
v1.0.15 8/25/2022 Checked added frameworks to make sure everything is marked public so usable by ouside code.
v1.0.14 8/24/2022 Added RingedText, ShareSheet, and Graphics code from old Swift Frameworks.
v1.0.13 8/12/2022 Added File and Date and URL comparable code.  Need to migrate NSDate to Date.
v1.0.12 8/12/2022 changed String.contains() to String.containsAny() to be more clear.  Modified KuError to include public initializer and automatic Debug print.
v1.0.11 8/11/2022 Removed unnecessary KuditFrameworks import from Image.swift.
v1.0.10 8/11/2022 Removed a bunch of KuditConnect and non-critical code since those should be completely re-thought and added in a modern way and there is too much legacy code.
v1.0.9 8/10/2022 Fixed tests to run in Xcode.  Added watchOS and tvOS support.
v1.0.8 8/10/2022 Manually created initializers for SwiftUI views to prevent internal protection errors.
"""
    try expect(expected == reversed, reversed)
}

extension Character {
    /// A simple emoji is one scalar and presented to the user as an Emoji
    var isSimpleEmoji: Bool {
        guard let firstScalar = unicodeScalars.first else { return false }
        return firstScalar.properties.isEmoji && firstScalar.value > 0x238C
    }
    
    /// Checks if the scalars will be merged into an emoji
    var isCombinedIntoEmoji: Bool { unicodeScalars.count > 1 && unicodeScalars.first?.properties.isEmoji ?? false }
    
    var isEmoji: Bool { isSimpleEmoji || isCombinedIntoEmoji }
}

extension String {
    var containsEmoji: Bool { contains { $0.isEmoji } }
}

#if canImport(SwiftUI) && swift(>=5.9)
import SwiftUI
@available(iOS 13, tvOS 13, watchOS 6, *)
#Preview("Tests") {
    TestsListView(tests: String.tests + CharacterSet.tests)
}
#endif
