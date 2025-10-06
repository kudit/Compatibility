//
//  CharacterSet.swift
//  Compatibility
//
//  Created by Ben Ku on 10/6/25.
//

// Backport for CharacterSet without Foundation

#if !canImport(Foundation)
public typealias CharacterSet = Set<Character>

public extension CharacterSet {
    /// Initialize with the characters in the given string.
    ///
    /// - parameter string: The string content to inspect for characters.
    init(charactersIn string: String) {
        var set = CharacterSet()
        for character in string {
            set.insert(character)
        }
        self = set
    }

    /// Returns a character set containing the characters in Unicode General Category Cc and Cf.
//    static let controlCharacters: CharacterSet = []

    /// Returns a character set containing the characters in Unicode General Category Zs and `CHARACTER TABULATION (U+0009)`.
    static let whitespaces: CharacterSet = [
        "\u{0009}", // CHARACTER TABULATION (HT)
        "\u{000A}", // LINE FEED (LF)
        "\u{000B}", // LINE TABULATION (VT)
        "\u{000C}", // FORM FEED (FF)
        "\u{000D}", // CARRIAGE RETURN (CR)
        "\u{0020}", // SPACE
        "\u{0085}", // NEXT LINE (NEL)
        "\u{00A0}", // NO-BREAK SPACE
        "\u{1680}", // OGHAM SPACE MARK
        "\u{180E}", // MONGOLIAN VOWEL SEPARATOR (deprecated)
        "\u{2000}", // EN QUAD
        "\u{2001}", // EM QUAD
        "\u{2002}", // EN SPACE
        "\u{2003}", // EM SPACE
        "\u{2004}", // THREE-PER-EM SPACE
        "\u{2005}", // FOUR-PER-EM SPACE
        "\u{2006}", // SIX-PER-EM SPACE
        "\u{2007}", // FIGURE SPACE
        "\u{2008}", // PUNCTUATION SPACE
        "\u{2009}", // THIN SPACE
        "\u{200A}", // HAIR SPACE
        "\u{2028}", // LINE SEPARATOR
        "\u{2029}", // PARAGRAPH SEPARATOR
        "\u{202F}", // NARROW NO-BREAK SPACE
        "\u{205F}", // MEDIUM MATHEMATICAL SPACE
        "\u{3000}"  // IDEOGRAPHIC SPACE
    ]
    
    /// Returns a character set containing the newline characters (`U+000A ~ U+000D`, `U+0085`, `U+2028`, and `U+2029`).
    static let newlines: CharacterSet = [
        "\u{000A}", // LINE FEED (LF)          — \n
        "\u{000D}", // CARRIAGE RETURN (CR)    — \r
        "\u{000B}", // LINE TABULATION (VT)
        "\u{000C}", // FORM FEED (FF)
        "\u{0085}", // NEXT LINE (NEL)
        "\u{2028}", // LINE SEPARATOR
        "\u{2029}"  // PARAGRAPH SEPARATOR
    ]

    /// Returns a character set containing characters in Unicode General Category Z*, `U+000A ~ U+000D`, and `U+0085`.
    static let whitespacesAndNewlines = CharacterSet.whitespaces.union(CharacterSet.newlines)

    /// Returns a character set containing the characters in the category of Decimal Numbers.
    static let decimalDigits: CharacterSet = .init(charactersIn: "0123456789")

    /// Returns a character set containing the characters in Unicode General Category L* & M*.
//    public static var letters: CharacterSet { get }

    /// Returns a character set containing the characters in Unicode General Category Ll.
//    public static var lowercaseLetters: CharacterSet { get }

    /// Returns a character set containing the characters in Unicode General Category Lu and Lt.
//    public static var uppercaseLetters: CharacterSet { get }

    /// Returns a character set containing the characters in Unicode General Categories L*, M*, and N*.
//    public static var alphanumerics: CharacterSet { get }
    static let alphanumerics = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
}

#endif

// Testing is only supported with Swift 5.9+
#if compiler(>=5.9)
@available(iOS 13, tvOS 13, watchOS 6, *)
extension CharacterSet {
    @MainActor public static let tests = [
        Test("character strings", testCharacterStrings),
    ]
}
#endif
public extension CharacterSet {
    /// Returns the character set as an array of strings. (ONLY ASCII Characters!)
    var characterStrings: [String] {
        #if canImport(Foundation)
        let unichars = Array(0..<128).map { UnicodeScalar($0)! }
        let filtered = unichars.filter(contains)
        #else
        let unichars = Array(0..<128).map { Character(UnicodeScalar($0)!) }
        let filtered = unichars.filter(contains)
        #endif
        return filtered.map { String($0) }
    }
    @MainActor
    internal static let testCharacterStrings: TestClosure = {
        let array = "hello".characterStrings
        try expect(array == ["h","e","l","l","o"], String(describing:array))

        // emoji tests
        let emoji = "😀👨🏻‍💻"
        
        let simple = emoji.first!
        try expect(simple.isSimpleEmoji)
        try expect(!simple.isCombinedIntoEmoji)
        try expect(simple.isEmoji)
        
        let complex = emoji.last!
        try expect(complex.isCombinedIntoEmoji)
        try expect(complex.isEmoji)
        
        let letter = Character("a")
        try expect(letter.isEmoji == false)
        
        for i in 0..<10 {
            try expect(Self.numerics.allCharacters.contains(Character(string: "\(i)", defaultValue: "x")))
        }
    }

    /// Returns a character set containing all numeric digits.
    // NOTE: Can't use static let because CharacterSet is not Sendable :(
    static var numerics: CharacterSet { CharacterSet(charactersIn: "0123456789")
    }
    
    /// Returns a character set containing the characters allowed in an URL's parameter subcomponent.
    static var urlParameterAllowed: CharacterSet {
        var validCharacterString = CharacterSet.alphanumerics.characterStrings.joined()
        validCharacterString += "-_.!~*()" // alphanumeric plus some additional valid characters (not including + or ,
        return CharacterSet(charactersIn: validCharacterString)
    }
    
    #if canImport(Foundation)
    /// Returns a character set containing the characters allowed in a URL
    static var urlAllowed: CharacterSet {
        // https://stackoverflow.com/questions/7109143/what-characters-are-valid-in-a-url
        return urlHostAllowed.union(urlUserAllowed.union(urlPasswordAllowed.union(urlFragmentAllowed.union(urlPathAllowed.union(urlQueryAllowed.union(urlFragmentAllowed))))))
//        urlParameterAllowed.union(.init(charactersIn: "/?&:;=#%[]@!$'"))
    }
    #endif
}
public extension CharacterSet {
    /// Returns the set as an array of Characters.
    var allCharacters: [Character] {
        var result: [Character] = []
        #if canImport(Foundation)
        for plane: UInt8 in 0...16 where self.hasMember(inPlane: plane) {
            for unicode in UInt32(plane) << 16 ..< UInt32(plane + 1) << 16 {
                if let uniChar = UnicodeScalar(unicode), self.contains(uniChar) {
                    result.append(Character(uniChar))
                }
            }
        }
        #else
        result = [Character](self)
        #endif
        return result
    }
    /// Returns the CharacterSet as a string containing all the characters.
    var asString: String {
        return String(self.allCharacters)
    }
}
