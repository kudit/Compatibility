//
//  UserDefaultsBacked.swift
//  
//
//  Created by Ben Ku on 8/7/24.
//

// TODO: Remove since @AppStorage does the same thing so this is unnecessary.
/*
#if canImport(Combine)
import Combine

// MARK: - UserDefaults Backed (requires Value to be a UserDefault-supported type
public protocol FoundationCodable: RawRepresentable where RawValue == Self {}
extension FoundationCodable {
    public init?(rawValue: Self) {
        self = rawValue
    }
    public var rawValue: RawValue {
        return self
    }
}
// RawRepresentable should automatically work as should arrays due to array conformance to RawRepresentable when elements are RawRepresentable
extension URL: FoundationCodable {}
extension Array: FoundationCodable where Element: FoundationCodable {}
// TODO: Dictionary?
extension String: FoundationCodable {}
extension Data: FoundationCodable {}
extension Bool: FoundationCodable {}
extension Int: FoundationCodable {}
extension Double: FoundationCodable {}
extension Date: FoundationCodable {}

// thanks to https://fatbobman.com/en/posts/adding-published-ability-to-custom-property-wrapper-types/ for the help!
@available(iOS 13, *)
@propertyWrapper
public struct MyPublished<Value> {
    public var wrappedValue: Value {
        willSet {  // Before modifying wrappedValue
            publisher.subject.send(newValue)
        }
    }

    public var projectedValue: Publisher {
        publisher
    }

    private var publisher: Publisher

    public struct Publisher: Combine.Publisher {
        public typealias Output = Value
        public typealias Failure = Never

        var subject: CurrentValueSubject<Value, Never> // PassthroughSubject will lack the call of initial assignment

        public func receive<S>(subscriber: S) where S: Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            subject.subscribe(subscriber)
        }

        init(_ output: Output) {
            subject = .init(output)
        }
    }

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
        publisher = Publisher(wrappedValue)
    }

    public static subscript<OuterSelf: ObservableObject>(
        _enclosingInstance observed: OuterSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<OuterSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<OuterSelf, Self>
    ) -> Value {
        get {
            observed[keyPath: storageKeyPath].wrappedValue
        }
        set {
            if let subject = observed.objectWillChange as? ObservableObjectPublisher {
                subject.send() // Before modifying wrappedValue
                observed[keyPath: storageKeyPath].wrappedValue = newValue
            }
        }
    }
}


// TODO: Figure out how to do this and published
@available(iOS 13, *)
@propertyWrapper
@MainActor
public class UserDefaultsBacked<Value: RawRepresentable>: ObservableObject {
    private let key: String
    private let defaultValue: Value
    private let storage: UserDefaults
    @Published
    private var _wrappedValue: Value

    public init(wrappedValue defaultValue: Value,
         key: String,
         storage: UserDefaults = .standard) {
        self.defaultValue = defaultValue
        self.key = key
        self.storage = storage
        _wrappedValue = defaultValue
    }
    
    private var storeValue: Value {
        guard let rawValue = storage.value(forKey: key) as? Value.RawValue, let value = Value(rawValue: rawValue) else {
            debug("Missing `\(key)` value in store.  value should already be default", level: .WARNING)
            return defaultValue
        }
        return value
    }
    
    private func saveToStore(_ newValue: Value) {
        if let optional = newValue as? AnyOptional, optional.isNil {
            storage.removeObject(forKey: key)
        } else {
            storage.setValue(newValue.rawValue, forKey: key)
        }
    }

    public var projectedValue: Published<Value>.Publisher {
        get {
            debug("Getting projected value for \(key)")
            _wrappedValue = storeValue
            return $_wrappedValue
        }
        @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
        set {
            debug("Setting projected value for \(key)")
            $_wrappedValue = newValue
            saveToStore(_wrappedValue)
        }
    }
    
    public var wrappedValue: Value {
        get {
            debug("Getting wrapped value for \(key)")
            _wrappedValue = storeValue
            return _wrappedValue
        }
        set {
            debug("Setting projected value for \(key)")
            _wrappedValue = newValue
            saveToStore(_wrappedValue)
        }
    }
}
@available(iOS 13, *)
extension UserDefaultsBacked where Value: ExpressibleByNilLiteral {
    public convenience init(key: String, storage: UserDefaults = .standard) {
        self.init(wrappedValue: nil, key: key, storage: storage)
    }
}
// Since our property wrapper's Value type isn't optional, but
// can still contain nil values, we'll have to introduce this
// protocol to enable us to cast any assigned value into a type
// that we can compare against nil:
private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}

#endif
*/
