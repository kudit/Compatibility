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

// MARK: - Mixed JSON coding

public enum MixedTypeField: Codable {
    case string(String)
    case bool(Bool)
    case int(Int)
    case double(Double)
    case null
    case dictionary([String:MixedTypeField])
    case array([MixedTypeField])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if container.decodeNil() {
            self = .null
        } else if let dictionary = try? container.decode([String:MixedTypeField].self) {
            self = .dictionary(dictionary)
        } else if let array = try? container.decode([MixedTypeField].self) {
            self = .array(array)
        } else {
            throw DecodingError.typeMismatch(MixedTypeField.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Attempting to decode an unsupported base type."))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        case .dictionary(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        }
    }

    public var stringValue: String? {
        if case let .string(value) = self {
            return value
        }
        return nil
    }

    public var boolValue: Bool? {
        if case let .bool(value) = self {
            return value
        }
        return nil
    }

    public var intValue: Int? {
        if case let .int(value) = self {
            return value
        }
        return nil
    }

    public var doubleValue: Double? {
        if case let .double(value) = self {
            return value
        }
        return nil
    }
        
    public var dictionaryValue: [String: MixedTypeField]? {
        if case let .dictionary(value) = self {
            return value
        }
        return nil
    }
    
    public var arrayValue: [MixedTypeField]? {
        if case let .array(value) = self {
            return value
        }
        return nil
    }
}

// TODO: Add tests!!
//Swift Kudit Frameworks: Create tests for Json optional including test for bad data types bad Json and compatibility
#endif
