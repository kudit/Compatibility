//
//  CodingMixedTypes.swift
//  Compatibility
//
//  Created by Ben Ku on 9/17/25.
//
/// A type that can hold primitive JSON types for more easily decoding JSON and unkeyed mixed type JSON arrays.  Also a way of encoding to more generic Dictionary objects.
// MARK: - Mixed JSON coding

/// Unordered dictionary with String keys and MixedTypeField values.  If we need to encode ordered, will encode as key, value mixed array.
public typealias MixedTypeDictionary = Dictionary<String,MixedTypeField?>
public typealias MixedTypeArray = [MixedTypeField?]
public extension MixedTypeDictionary {
    /// Initializes with a Dictionary.  Returns nil if Dictionary.Key is not LosslessStringConvertible.
    init?<T>(dictionary: T) where T: DictionaryConvertible {
        var dict = MixedTypeDictionary()
        for (key, value) in dictionary.dictionaryValue {
            guard let key = key as? LosslessStringConvertible else { return nil }
            dict[key.description] = MixedTypeField(encoding: value)
        }
//        let transformedDict = Dictionary(uniqueKeysWithValues: mapDict)
        self = dict
    }
}
public enum MixedTypeField: Codable, Equatable {
    case string(String)
    case bool(Bool)
    case int(Int)
    case double(Double)
    case null
    case dictionary(MixedTypeDictionary)
    case array([MixedTypeField?])

#if canImport(Foundation)
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
        } else if let dictionary = try? container.decode(MixedTypeDictionary.self) {
            self = .dictionary(dictionary)
        } else if let array = try? container.decode(MixedTypeArray.self) {
            self = .array(array)
        } else {
            throw DecodingError.typeMismatch(MixedTypeField.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Attempting to decode an unsupported base type."))
        }
    }
#endif

    public init?(encoding value: Any?) {
        guard let value else {
            self = .null
            return
        }
        
        if let value = value as? MixedTypeField { // already encoded so no need to re-encode
            self = value
        } else if let value = value as? Bool {
            self = .bool(value)
        } else if let value = value as? any BinaryInteger {
            self = .int(Int(value))
        } else if let value = value as? DoubleConvertible {
            self = .double(value.doubleValue)
        } else if let value = value as? any DictionaryConvertible, let dict = MixedTypeDictionary(dictionary: value) {
            self = .dictionary(dict)
        } else if let value = value as? Array<Any> {
            self = .array(value.map { MixedTypeField(encoding: $0) })
        } else if let string = value as? LosslessStringConvertible { // needed to move down later because bool and numbers are convertible to string
            self = .string(string.description)
        } else if value as? MixedTypeField == Optional<MixedTypeField>.none {
            // this is how we check for null nil
            self = .null
        } else {
            debug("Encoding error creating a MixedTypeField from value (likely not Encodable): \(value)", level: .WARNING)
            return nil
        }
    }
    
    #if canImport(Foundation)
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
    #endif

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
        
    public var dictionaryValue: MixedTypeDictionary? {
        if case let .dictionary(value) = self {
            return value
        }
        return nil
    }
    
    public var arrayValue: MixedTypeArray? {
        if case let .array(value) = self {
            return value
        }
        return nil
    }
}

// MARK: - Coding Support
#if !(os(WASM) || os(WASI))
public extension Encodable {
    func asMixedTypeField() throws -> MixedTypeField {
        let encoder = MixedTypeFieldEncoder()
        return try encoder.encode(self)
    }
}
public extension Decodable {
    init(fromMixedTypeField field: MixedTypeField) throws {
        let decoder = MixedTypeFieldDecoder()
        self = try decoder.decode(Self.self, from: field)
    }
}

//
//  MixedTypeFieldCoding.swift
//
//  Pure Swift encoder/decoder for MixedTypeField.
//  Works like JSONEncoder/JSONDecoder but without Foundation.
//
/*
 Provides:
   - public struct MixedTypeFieldEncoder { func encode<T: Encodable>(_ value: T) throws -> MixedTypeField }
   - public struct MixedTypeFieldDecoder { func decode<T: Decodable>(_ type: T.Type, from field: MixedTypeField) throws -> T }

 These are pure-Swift encoder/decoder "front-ends" that convert between
 Encodable/Decodable and the MixedTypeField representation.
*/

public struct MixedTypeFieldEncoder {
    public init() {}

    /// Encode an Encodable value into a MixedTypeField
    public func encode<T: Encodable>(_ value: T) throws -> MixedTypeField {
        let encoder = _FieldEncoder()
        try value.encode(to: encoder)
        return encoder.storage
    }
}

public struct MixedTypeFieldDecoder {
    public init() {}

    /// Decode a Decodable type from a MixedTypeField
    public func decode<T: Decodable>(_ type: T.Type, from field: MixedTypeField) throws -> T {
        let decoder = _FieldDecoder(storage: field)
        return try T(from: decoder)
    }
}

// ------------------------------------------------------------
// Encoder internals
// ------------------------------------------------------------
fileprivate final class _FieldEncoder: Encoder {
    var codingPath: [CodingKey] = []
    // keep userInfo declared to match Encoder; projects that require
    // CodingUserInfoKey will provide it from elsewhere in the module.
    public var userInfo: [CodingUserInfoKey : Any] = [:]
    
    fileprivate(set) var storage: MixedTypeField = .null
    
    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(KeyedContainer<Key>(encoder: self))
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return UnkeyedContainer(encoder: self)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return SingleValueContainer(encoder: self)
    }
    
    // MARK: - Keyed container
    fileprivate struct KeyedContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
        fileprivate let encoder: _FieldEncoder
        fileprivate var dict: MixedTypeDictionary
        
        fileprivate var codingPath: [CodingKey] { encoder.codingPath }
        
        fileprivate init(encoder: _FieldEncoder) {
            self.encoder = encoder
            self.dict = MixedTypeDictionary()
        }
        
        mutating func encodeNil(forKey key: K) throws {
            // represent explicit JSON null as .null inside the optional-value dictionary
            dict[key.stringValue] = .null
            encoder.storage = .dictionary(dict)
        }
        
        mutating func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
            // Primitive values are handled by the nested encoder's SingleValueContainer
            let nested = _FieldEncoder()
            try value.encode(to: nested)
            dict[key.stringValue] = nested.storage
            encoder.storage = .dictionary(dict)
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            KeyedEncodingContainer(KeyedContainer<NestedKey>(encoder: encoder))
        }
        
        mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
            UnkeyedContainer(encoder: encoder)
        }
        
        mutating func superEncoder() -> Encoder { encoder }
        mutating func superEncoder(forKey key: K) -> Encoder { encoder }
    }
    
    // MARK: - Unkeyed container
    fileprivate struct UnkeyedContainer: UnkeyedEncodingContainer {
        fileprivate let encoder: _FieldEncoder
        fileprivate var array: [MixedTypeField?]
        fileprivate(set) var count: Int
        fileprivate var currentIndexStorage: Int = 0
        
        fileprivate var codingPath: [CodingKey] { encoder.codingPath }
        fileprivate var currentIndex: Int {
            get { currentIndexStorage }
            set { currentIndexStorage = newValue }
        }
        fileprivate init(encoder: _FieldEncoder) {
            self.encoder = encoder
            self.array = []
            self.count = 0
        }
        
        mutating func encodeNil() throws {
            array.append(.null)
            count += 1
            encoder.storage = .array(array)
        }
        
        mutating func encode<T>(_ value: T) throws where T : Encodable {
            let nested = _FieldEncoder()
            try value.encode(to: nested)
            array.append(nested.storage)
            count += 1
            encoder.storage = .array(array)
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            KeyedEncodingContainer(KeyedContainer<NestedKey>(encoder: encoder))
        }
        
        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            UnkeyedContainer(encoder: encoder)
        }
        
        mutating func superEncoder() -> Encoder { encoder }
    }
    
    // MARK: - Single value container
    fileprivate struct SingleValueContainer: SingleValueEncodingContainer {
        fileprivate let encoder: _FieldEncoder
        fileprivate var codingPath: [CodingKey] { encoder.codingPath }
        
        fileprivate init(encoder: _FieldEncoder) {
            self.encoder = encoder
        }
        
        mutating func encodeNil() throws {
            encoder.storage = .null
        }
        
        mutating func encode<T>(_ value: T) throws where T: Encodable {
            // Prefer exact primitive matches first. Use protocol existentials to handle
            // all integer/floating types generically.

            // `nil` should be accounted for before getting here using the encodeNil function.
            
            if let value = MixedTypeField(encoding: value) {
                encoder.storage = value
            } else {
                // Fallback: encode normally
                let nested = _FieldEncoder()
                try value.encode(to: nested)
                encoder.storage = nested.storage
            }
        }
    }
}

// ------------------------------------------------------------
// Decoder internals
// ------------------------------------------------------------
fileprivate final class _FieldDecoder: Decoder {
    let storage: MixedTypeField
    var codingPath: [CodingKey] = []
    public var userInfo: [CodingUserInfoKey : Any] = [:]

    init(storage: MixedTypeField) {
        self.storage = storage
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        guard case let .dictionary(dict) = storage else {
            throw DecodingError.typeMismatch([String: MixedTypeField].self,
                                             DecodingError.Context(codingPath: codingPath,
                                                                   debugDescription: "Expected dictionary"))
        }
        let container = KeyedContainer<Key>(decoder: self, dict: dict)
        return KeyedDecodingContainer(container)
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard case let .array(array) = storage else {
            throw DecodingError.typeMismatch([MixedTypeField].self,
                                             DecodingError.Context(codingPath: codingPath,
                                                                   debugDescription: "Expected array"))
        }
        return UnkeyedContainer(decoder: self, array: array)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return SingleValueContainer(decoder: self, field: storage)
    }

    // MARK: - Keyed container
    fileprivate struct KeyedContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
        fileprivate let decoder: _FieldDecoder
        fileprivate let dict: MixedTypeDictionary

        fileprivate var codingPath: [CodingKey] { decoder.codingPath }
        fileprivate var allKeys: [K] {
            dict.keys.compactMap { K(stringValue: $0) }
        }

        fileprivate init(decoder: _FieldDecoder, dict: MixedTypeDictionary) {
            self.decoder = decoder
            self.dict = dict
        }

        func contains(_ key: K) -> Bool {
            // presence of a key in the ordered dictionary
            return dict.keys.contains(key.stringValue)
        }

        func decodeNil(forKey key: K) throws -> Bool {
            // If key missing -> false. If key present and value is explicit nil -> true.
            guard let maybeInner = dict[key.stringValue] else { return false }
            // maybeInner is MixedTypeField?? (subscript returns optional because the key might be missing
            // and the stored value is itself an optional). After guard we have an Optional<MixedTypeField>.
            return maybeInner == .null
        }

        func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
            guard let maybeInner = dict[key.stringValue] else {
                throw DecodingError.keyNotFound(key,
                    DecodingError.Context(codingPath: codingPath,
                                          debugDescription: "Key not found"))
            }
            // maybeInner is Optional<MixedTypeField> (nil meaning explicit JSON null)
            let field = maybeInner ?? .null
            let nested = _FieldDecoder(storage: field)
            return try T(from: nested)
        }

        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            guard let maybeInner = dict[key.stringValue] ?? .null else {
                throw CustomError("Coding Error??", level: .WARNING)
            }
            let nestedDecoder = _FieldDecoder(storage: maybeInner)
            return try nestedDecoder.container(keyedBy: NestedKey.self)
        }

        func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
            guard let maybeInner = dict[key.stringValue] ?? .null else {
                throw CustomError("Coding Error??", level: .WARNING)
            }
            let nestedDecoder = _FieldDecoder(storage: maybeInner)
            return try nestedDecoder.unkeyedContainer()
        }

        func superDecoder() throws -> Decoder { decoder }
        func superDecoder(forKey key: K) throws -> Decoder { decoder }
    }

    // MARK: - Unkeyed container
    fileprivate struct UnkeyedContainer: UnkeyedDecodingContainer {
        fileprivate let decoder: _FieldDecoder
        fileprivate let array: [MixedTypeField?]
        fileprivate var currentIndex: Int = 0

        fileprivate var codingPath: [CodingKey] { decoder.codingPath }
        fileprivate var count: Int? { array.count }
        fileprivate var isAtEnd: Bool { currentIndex >= array.count }

        fileprivate init(decoder: _FieldDecoder, array: [MixedTypeField?]) {
            self.decoder = decoder
            self.array = array
            self.currentIndex = 0
        }

        mutating func decodeNil() throws -> Bool {
            guard !isAtEnd else {
                throw DecodingError.valueNotFound(Any?.self,
                    DecodingError.Context(codingPath: codingPath,
                                          debugDescription: "Unkeyed container is at end"))
            }
            let element = array[currentIndex] ?? .null
            if element == .null {
                currentIndex += 1
                return true
            }
            return false
        }

        mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            guard !isAtEnd else {
                throw DecodingError.valueNotFound(type,
                    DecodingError.Context(codingPath: codingPath,
                                          debugDescription: "Unkeyed container is at end"))
            }
            let element = array[currentIndex] ?? .null
            currentIndex += 1
            return try T(from: _FieldDecoder(storage: element))
        }

        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            guard !isAtEnd else {
                throw DecodingError.valueNotFound([String: MixedTypeField].self,
                    DecodingError.Context(codingPath: codingPath,
                                          debugDescription: "Unkeyed container is at end"))
            }
            let element = array[currentIndex] ?? .null
            currentIndex += 1
            return try _FieldDecoder(storage: element).container(keyedBy: NestedKey.self)
        }

        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            guard !isAtEnd else {
                throw DecodingError.valueNotFound([MixedTypeField].self,
                    DecodingError.Context(codingPath: codingPath,
                                          debugDescription: "Unkeyed container is at end"))
            }
            let element = array[currentIndex] ?? .null
            currentIndex += 1
            return try _FieldDecoder(storage: element).unkeyedContainer()
        }

        mutating func superDecoder() throws -> Decoder { decoder }
    }

    // MARK: - Single value container
    fileprivate struct SingleValueContainer: SingleValueDecodingContainer {
        fileprivate let decoder: _FieldDecoder
        fileprivate let field: MixedTypeField
        fileprivate var codingPath: [CodingKey] { decoder.codingPath }

        fileprivate init(decoder: _FieldDecoder, field: MixedTypeField) {
            self.decoder = decoder
            self.field = field
        }

        func decodeNil() -> Bool { field == .null }

        func decode(_ type: Bool.Type) throws -> Bool {
            if case let .bool(v) = field { return v }
            throw typeMismatch(type)
        }

        func decode(_ type: String.Type) throws -> String {
            if case let .string(v) = field { return v }
            throw typeMismatch(type)
        }

        func decode(_ type: Double.Type) throws -> Double {
            if case let .double(v) = field { return v }
            if case let .int(v) = field { return Double(v) }
            throw typeMismatch(type)
        }

        func decode(_ type: Float.Type) throws -> Float {
            let d = try decode(Double.self)
            return Float(d)
        }

        func decode(_ type: Int.Type) throws -> Int {
            if case let .int(v) = field { return v }
            throw typeMismatch(type)
        }

        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            return try T(from: _FieldDecoder(storage: field))
        }

        private func typeMismatch<T>(_ type: T.Type) -> DecodingError {
            DecodingError.typeMismatch(type,
                DecodingError.Context(codingPath: codingPath,
                                      debugDescription: "Type mismatch — expected \(type)"))
        }
    }
}
#endif
