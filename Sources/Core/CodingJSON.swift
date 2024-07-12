// MARK: - JSON management (simplified)

public extension Encodable {
    func asJSON(outputFormatting: JSONEncoder.OutputFormatting? = nil) -> String {
        // really should never error since we conform to Encodable
        guard JSONSerialization.isValidJSONObject(self) else {
            return "WARNING: Invalid JSON object: \(self)".asErrorJSON(level: .ERROR)
        }
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
}

public extension Decodable {
    init(fromJSON jsonString: String) throws {
        let jsonData = Data(jsonString.utf8)
        self = try JSONDecoder().decode(Self.self, from: jsonData)
    }
}

// TODO: Add tests!!
