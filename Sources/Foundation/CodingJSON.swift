// MARK: - JSON management (simplified)

#if canImport(Foundation)
public extension Encodable {
    /**
     Use to output the encodable object as a JSON representation.
     ex:
     ```swift
     return self.asJSON(outputFormatting: [.prettyPrinted, .sortedKeys])
     ```
     */
    func asJSON(outputFormatting: JSONEncoder.OutputFormatting? = nil) -> String {
        // really should never error since we conform to Encodable
        // Don't need to do this check since we should conform to Encodable
        //        guard JSONSerialization.isValidJSONObject(self) else {
        //            return "WARNING: Invalid JSON object: \(self)".asErrorJSON(level: .ERROR)
        //        }
        let encoder = JSONEncoder()
        if let outputFormatting {
            encoder.outputFormatting = outputFormatting
        }
        do {
            let data = try encoder.encode(self)
            /* LEGACY:
             let jsonData = try JSONSerialization.data(withJSONObject: self, options: (compact ? [] : JSONSerialization.WritingOptions.prettyPrinted))
             return String(data: jsonData, encoding: String.Encoding.utf8)
             */
            guard let json = String(data: data, encoding: .utf8) else {
                return "Unable to encode \(self) as JSON.".asErrorJSON(level: .ERROR)
            }
            return json
        } catch {
            return "JSON Encoding error: \(error)".asErrorJSON(level: .ERROR)
        }
    }
    
    /// Outputs a nicely formatted JSON string with keys sorted.
    var prettyJSON: String {
        return self.asJSON(outputFormatting: [.prettyPrinted, .sortedKeys])
    }
}

public extension Decodable {
    init(fromJSON jsonString: String) throws {
        let jsonData = Data(jsonString.utf8)
        self = try JSONDecoder().decode(Self.self, from: jsonData)
    }
}
#else
// MARK: Legacy support for WASM or where Foundation isn't available
public struct JSONFormattingOptions: OptionSet {
    public let rawValue: Int

    public static let prettyPrinted = JSONFormattingOptions(rawValue: 1 << 0)
    public static let sortedKeys = JSONFormattingOptions(rawValue: 1 << 1)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public extension Encodable {
    /**
     Use to output the encodable object as a JSON representation.
     ex:
     ```swift
     return self.asJSON(outputFormatting: [.prettyPrinted, .sortedKeys])
     ```
     */
    func asJSON(outputFormatting: JSONFormattingOptions? = nil) -> String {
        let encoder = MixedTypeFieldEncoder()
        do {
            let mixedTypeField = try encoder.encode(self)
            
            return mixedTypeField.asJSON(outputFormatting: outputFormatting)
        } catch {
            return "JSON Encoding error: \(error)".asErrorJSON(level: .ERROR)
        }
    }
    
    /// Outputs a nicely formatted JSON string with keys sorted.
    var prettyJSON: String {
        return self.asJSON(outputFormatting: [.prettyPrinted, .sortedKeys])
    }
}

public extension Decodable {
    init(fromJSON jsonString: String) throws {
        let field = try MixedTypeField(fromJSON: jsonString)
        self = try Self(fromMixedTypeField: field)
    }
}
//
//  MixedTypeField+JSON.swift
//
//  Pure Swift JSON → MixedTypeField parser
//

public extension MixedTypeField {
    init(fromJSON jsonString: String) throws {
        var parser = _JSONParser(input: jsonString)
        self = try parser.parseValue()
        parser.skipWhitespace()
        if !parser.isAtEnd {
            throw _JSONError.extraData
        }
    }
}

// MARK: - Internal JSON parser

fileprivate enum _JSONError: Error {
    case unexpectedCharacter(Character)
    case unexpectedEnd
    case invalidNumber
    case invalidString
    case extraData
}

fileprivate struct _JSONParser {
    private let scalars: [Character]
    private(set) var index: Int = 0
    
    init(input: String) {
        self.scalars = Array(input)
    }
    
    var isAtEnd: Bool { index >= scalars.count }
    private var current: Character? { isAtEnd ? nil : scalars[index] }
    
    mutating func advance() { index += 1 }
    
    mutating func skipWhitespace() {
        while let c = current, c.isWhitespace { advance() }
    }
    
    mutating func parseValue() throws -> MixedTypeField {
        skipWhitespace()
        guard let c = current else { throw _JSONError.unexpectedEnd }
        switch c {
        case "\"": return .string(try parseString())
        case "{":  return .dictionary(try parseObject())
        case "[":  return .array(try parseArray())
        case "t":  return try parseTrue()
        case "f":  return try parseFalse()
        case "n":  return try parseNull()
        case "-", "0"..."9": return try parseNumber()
        default: throw _JSONError.unexpectedCharacter(c)
        }
    }
    
    // MARK: - Literals
    
    private mutating func parseTrue() throws -> MixedTypeField {
        try expect("true")
        return .bool(true)
    }
    
    private mutating func parseFalse() throws -> MixedTypeField {
        try expect("false")
        return .bool(false)
    }
    
    private mutating func parseNull() throws -> MixedTypeField {
        try expect("null")
        return .null
    }
    
    private mutating func expect(_ word: String) throws {
        for expected in word {
            guard current == expected else { throw _JSONError.unexpectedCharacter(current ?? "?") }
            advance()
        }
    }
    
    // MARK: - String
    
    private mutating func parseString() throws -> String {
        guard current == "\"" else { throw _JSONError.unexpectedCharacter(current ?? "?") }
        advance() // skip opening "
        var result = ""
        while let c = current {
            advance()
            if c == "\"" { return result }
            if c == "\\" {
                guard let esc = current else { throw _JSONError.unexpectedEnd }
                advance()
                switch esc {
                case "\"": result.append("\"")
                case "\\": result.append("\\")
                case "/": result.append("/")
                case "b": result.append("\u{0008}")
                case "f": result.append("\u{000C}")
                case "n": result.append("\n")
                case "r": result.append("\r")
                case "t": result.append("\t")
                case "u":
                    var hex = ""
                    for _ in 0..<4 {
                        guard let h = current else { throw _JSONError.unexpectedEnd }
                        guard h.isHexDigit else { throw _JSONError.invalidString }
                        hex.append(h)
                        advance()
                    }
                    if let scalar = UInt32(hex, radix: 16),
                       let uni = UnicodeScalar(scalar) {
                        result.append(Character(uni))
                    } else {
                        throw _JSONError.invalidString
                    }
                default:
                    throw _JSONError.invalidString
                }
            } else {
                result.append(c)
            }
        }
        throw _JSONError.unexpectedEnd
    }
    
    // MARK: - Number
    
    private mutating func parseNumber() throws -> MixedTypeField {
        var numberStr = ""
        if current == "-" { numberStr.append("-"); advance() }
        
        func consumeDigits() {
            while let c = current, c.isNumber {
                numberStr.append(c)
                advance()
            }
        }
        
        guard let c = current else { throw _JSONError.unexpectedEnd }
        if c == "0" {
            numberStr.append("0")
            advance()
        } else if ("1"..."9").contains(c) {
            consumeDigits()
        } else {
            throw _JSONError.invalidNumber
        }
        
        if current == "." {
            numberStr.append("."); advance()
            guard let c2 = current, c2.isNumber else { throw _JSONError.invalidNumber }
            consumeDigits()
        }
        
        if current == "e" || current == "E" {
            numberStr.append("e"); advance()
            if current == "+" || current == "-" {
                numberStr.append(current!); advance()
            }
            guard let c3 = current, c3.isNumber else { throw _JSONError.invalidNumber }
            consumeDigits()
        }
        
        if numberStr.contains(".") || numberStr.contains("e") || numberStr.contains("E") {
            if let d = Double(numberStr) {
                return .double(d)
            }
        } else {
            if let i = Int(numberStr) {
                return .int(i)
            }
        }
        throw _JSONError.invalidNumber
    }
    
    // MARK: - Array
    
    private mutating func parseArray() throws -> MixedTypeArray {
        guard current == "[" else { throw _JSONError.unexpectedCharacter(current ?? "?") }
        advance()
        skipWhitespace()
        var result: MixedTypeArray = []
        if current == "]" {
            advance()
            return result
        }
        while true {
            let value = try parseValue()
            result.append(value)
            skipWhitespace()
            if current == "," {
                advance(); skipWhitespace()
                continue
            }
            if current == "]" {
                advance()
                break
            }
            throw _JSONError.unexpectedCharacter(current ?? "?")
        }
        return result
    }
    
    // MARK: - Object
    
    private mutating func parseObject() throws -> MixedTypeDictionary {
        guard current == "{" else { throw _JSONError.unexpectedCharacter(current ?? "?") }
        advance()
        skipWhitespace()
        var dict = MixedTypeDictionary()
        if current == "}" {
            advance()
            return dict
        }
        while true {
            let key = try parseString()
            skipWhitespace()
            guard current == ":" else { throw _JSONError.unexpectedCharacter(current ?? "?") }
            advance()
            let value = try parseValue()
            dict[key] = value
            skipWhitespace()
            if current == "," {
                advance(); skipWhitespace()
                continue
            }
            if current == "}" {
                advance()
                break
            }
            throw _JSONError.unexpectedCharacter(current ?? "?")
        }
        return dict
    }
}

// MARK: - MixedTypeField → JSON
extension MixedTypeField {
    public func asJSON(outputFormatting: JSONFormattingOptions? = nil) -> String {
        let opts = outputFormatting ?? []
        var writer = _JSONWriter(options: opts)
        writer.writeField(self, indentLevel: 0)
        return writer.output
    }
}

// MARK: - Internal writer
fileprivate struct _JSONWriter {
    let options: JSONFormattingOptions
    var output: String = ""

    private var indentString: String { "  " } // 2 spaces per indent

    mutating func writeField(_ field: MixedTypeField, indentLevel: Int) {
        switch field {
        case .null:
            output.append("null")
        case .bool(let v):
            output.append(v ? "true" : "false")
        case .int(let v):
            output.append(String(v))
        case .double(let v):
            // Use standard JSON number formatting
            output.append(String(v))
        case .string(let v):
            writeString(v)
        case .array(let arr):
            writeArray(arr, indentLevel: indentLevel)
        case .dictionary(let dict):
            writeObject(dict, indentLevel: indentLevel)
        }
    }

    private mutating func writeString(_ s: String) {
        output.append("\"")
        for c in s {
            switch c {
            case "\"": output.append("\\\"")
            case "\\": output.append("\\\\")
            case "\n": output.append("\\n")
            case "\r": output.append("\\r")
            case "\t": output.append("\\t")
            default:
                if c.unicodeScalars.allSatisfy({ $0.isASCII && $0.value >= 0x20 }) {
                    output.append(c)
                } else {
                    for scalar in c.unicodeScalars {
                        let hex = String(scalar.value, radix: 16, uppercase: true)
                        output.append("\\u")
                        output.append(String(repeating: "0", count: 4 - hex.count))
                        output.append(hex)
                    }
                }
            }
        }
        output.append("\"")
    }

    private mutating func writeArray(_ arr: [MixedTypeField?], indentLevel: Int) {
        if arr.isEmpty {
            output.append("[]")
            return
        }
        output.append("[")
        let pretty = options.contains(.prettyPrinted)
        if pretty { output.append("\n") }
        for (i, elem) in arr.enumerated() {
            if pretty { output.append(String(repeating: indentString, count: indentLevel + 1)) }
            writeField(elem ?? .null, indentLevel: indentLevel + 1)
            if i < arr.count - 1 { output.append(pretty ? ",\n" : ",") }
        }
        if pretty {
            output.append("\n")
            output.append(String(repeating: indentString, count: indentLevel))
        }
        output.append("]")
    }

    private mutating func writeObject(_ dict: MixedTypeDictionary, indentLevel: Int) {
        let keys: [String]
        if options.contains(.sortedKeys) {
            keys = dict.keys.sorted()
        } else {
            keys = Array(dict.keys)
        }

        if keys.isEmpty {
            output.append("{}")
            return
        }

        output.append("{")
        let pretty = options.contains(.prettyPrinted)
        if pretty { output.append("\n") }

        for (i, key) in keys.enumerated() {
            if pretty { output.append(String(repeating: indentString, count: indentLevel + 1)) }
            writeString(key)
            output.append(pretty ? " : " : ":")
            writeField((dict[key] ?? .null) ?? .null, indentLevel: indentLevel + 1)
            if i < keys.count - 1 { output.append(pretty ? ",\n" : ",") }
        }

        if pretty {
            output.append("\n")
            output.append(String(repeating: indentString, count: indentLevel))
        }
        output.append("}")
    }
}
#endif
