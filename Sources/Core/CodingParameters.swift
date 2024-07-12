//
//  CodingParameters.swift
//
//
//  Created by Ben Ku on 10/5/23.
//

public class ParameterEncoder {
    public init() {}
    /// Encode an encodable item as a set of keyed parameters designed for a URL.  All values need to be custom string convertable to their value which will be URL encoded.  Returns a String with all the parameters ready to attach to a URL (not including the "?")
    public func encode<T: Encodable>(_ item: T) throws -> String {
        // do and re-throw any encoding errors
        let encoded = try DictionaryEncoder().encode(item)
        // use a separate guard for the conversion to not be nil
        guard let encoded = encoded as? [String : Any] else {
            throw EncodingError.invalidValue(item, EncodingError.Context(codingPath: [], debugDescription: "Can't encode item to parameter.  Possible non-leaf value."))
        }
        return encodeDictionary(encoded)
    }
    
    /// helper function for encoding a dictionary as parameters
    // TODO: TEST: hopefully nil values are automatically left out of dictonary encoding
    public func encodeDictionary(_ dictionary: [String: Any]) -> String {
        return dictionary
            .compactMap { (key, value) -> String? in
                if value is [String: Any] {
                    if let dictionary = value as? [String: Any] {
                        return encodeDictionary(dictionary)
                    }
                }
                else {
                    let valueString = "\(value)".urlEncoded
                    return "\(key)=\(valueString)"
                }
                
                return nil
            }
            .joined(separator: "&")
    }
}
public class ParameterDecoder {
    public init() {}
    /// Decodes given Decodable type from given array or dictionary (converts to JSON then uses JSON decoder)
    public func decode<T>(_ type: T.Type, from string: String) throws -> T where T: Decodable {
        let dictionary = decodeDictionary(string)
        return try DictionaryDecoder().decode(type, from: dictionary)
    }

    /// helper function for decoding a parameter string as a dictionary.  Values will always be Strings but should be able to be initied with a codable object
    public func decodeDictionary(_ string: String) -> [String: String] {
        var dictionary = [String:String]()
        for pairString in string.components(separatedBy: "&") {
            let pairs = pairString.components(separatedBy: "=")
            guard pairs.count == 2 else {
                debug("Unable to get Key=Value pair from: \(pairString)")
                continue
            }
            let key = pairs[0]
            var value = pairs[1]
            value = value.replacingOccurrences(of: "+", with: " ")
            value = value.removingPercentEncoding ?? value
            dictionary[key] = value // values will always be Strings
        }
        return dictionary
    }
}

public extension URL {
    /// Return the query parameters as a keyed dictionary
    var queryDictionary: [String: String] {
        // parse parameters from URL
        guard let query = self.query else { return [:] }
        return ParameterDecoder().decodeDictionary(query)
    }
}
