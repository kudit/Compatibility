/// For flagging properties that should not be included in Codable conformance.  Can provide a default value if the property is not an Optional

/*
/// Note: T needs to conform to Codable so that the parent struct can also automatically conform to Codable, however, we won't actually be coding this value.
@propertyWrapper
public struct CodableIgnored<T: Codable>: Codable {
    private let defaultValue: T
    public var _wrappedValue: T?
    
    public init(wrappedValue defaultValue: T) {
        self.defaultValue = defaultValue
    }

    public var wrappedValue: T {
        get {
            return _wrappedValue ?? defaultValue
        }
        set {
            _wrappedValue = newValue
        }
    }

    #warning("need a way to access the default value when decoding!")
//    public init(from decoder: Decoder) throws {
//        _wrappedValue = nil
//    }
    
    public func encode(to encoder: Encoder) throws {
        // Do nothing
    }
}
 

//extension KeyedDecodingContainer {
//    public func decode<T>(
//        _ type: CodableIgnored<T>.Type,
//        forKey key: Self.Key) throws -> CodableIgnored<T>
//    {
//        // Need to ensure we can create from default!
//        return CodableIgnored(wrappedValue: T(from: self))
//    }
//}

extension KeyedEncodingContainer {
    public mutating func encode<T>(
        _ value: CodableIgnored<T>,
        forKey key: KeyedEncodingContainer<K>.Key) throws
    {
        // Do nothing
    }
}
*/
