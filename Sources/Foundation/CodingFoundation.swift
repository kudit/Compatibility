//
//  DictionaryCoding.swift
//
//  Created by Ben Ku on 9/28/23.
//

// https://github.com/ashleymills/SwiftDictionaryCoding/blob/master/SwiftDictionaryCoding/Classes/DictionaryDecoder.swift

// Note: Needed to support Data values since JSON doesn't support Data natively
// TODO: make more generic so works with Arrays: /// Converts a codable object to a Foundational representation for storage in UserDefaults or UbiquitousKeyValueStores.
// TODO: Remove entirely in favor of MixedFieldType encoding?  Where is this used?

#if canImport(Foundation)
public class DictionaryEncoder {
    private let encoder = JSONEncoder()
    
    public init() {}
    
    public var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy {
        set { encoder.dateEncodingStrategy = newValue }
        get { return encoder.dateEncodingStrategy }
    }
    
    public var dataEncodingStrategy: JSONEncoder.DataEncodingStrategy {
        set { encoder.dataEncodingStrategy = newValue }
        get { return encoder.dataEncodingStrategy }
    }
    
    public var nonConformingFloatEncodingStrategy: JSONEncoder.NonConformingFloatEncodingStrategy {
        set { encoder.nonConformingFloatEncodingStrategy = newValue }
        get { return encoder.nonConformingFloatEncodingStrategy }
    }
    
    public var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy {
        set { encoder.keyEncodingStrategy = newValue }
        get { return encoder.keyEncodingStrategy }
    }
    
    /// Encodes given Encodable value into an array or dictionary
    public func encode<T>(_ value: T) throws -> Any where T : Encodable {
        let data = try encoder.encode(value)
        return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
    }
}

public class DictionaryDecoder {
    private let decoder = JSONDecoder()

    public init() {}
    
    public var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy {
        set { decoder.dateDecodingStrategy = newValue }
        get { return decoder.dateDecodingStrategy }
    }
    
    public var dataDecodingStrategy: JSONDecoder.DataDecodingStrategy {
        set { decoder.dataDecodingStrategy = newValue }
        get { return decoder.dataDecodingStrategy }
    }
    
    public var nonConformingFloatDecodingStrategy: JSONDecoder.NonConformingFloatDecodingStrategy {
        set { decoder.nonConformingFloatDecodingStrategy = newValue }
        get { return decoder.nonConformingFloatDecodingStrategy }
    }
    
    public var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy {
        set { decoder.keyDecodingStrategy = newValue }
        get { return decoder.keyDecodingStrategy }
    }
    
    /// Decodes given Decodable type from given array or dictionary (converts to JSON then uses JSON decoder)
    public func decode<T>(_ type: T.Type, from jsonObject: Any) throws -> T where T : Decodable {
        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        return try decoder.decode(type, from: data)
    }
}

public extension Encodable {
//    @available(iOS 13, tvOS 13, watchOS 6, *)
    /// Returns a generic dictionary with string keys for the object.
    func asDictionary() -> Dictionary<String, Any>? {
        // really should never error since we conform to Encodable as long as the base is a dictionary or container structure.  Only issue would be an array.
        do {
            return try DictionaryEncoder().encode(self) as? Dictionary<String, Any>
        } catch {
            debug("Unable to convert codable object to dictionary.  Possibly this is an array?\n\(error)", level: .WARNING)
            return nil
        }
    }
}

public extension Decodable {
    init?(fromDictionary dictionary: Dictionary<String, Any>) {
        if let decoded = try? DictionaryDecoder().decode(Self.self, from: dictionary) {
            self = decoded
        } else {
            return nil
        }
    }
}


/**
 
 https://stackoverflow.com/questions/45209743/how-can-i-use-swift-s-codable-to-encode-into-a-dictionary
 
 
 struct Computer: Codable {
 var owner: String?
 var cpuCores: Int
 var ram: Double
 }
 
 let computer = Computer(owner: "5keeve", cpuCores: 8, ram: 4)
 let dictionary = try! DictionaryEncoder().encode(computer)
 let decodedComputer = try! DictionaryDecoder().decode(Computer.self, from: dictionary)
 
 */
#endif
