//
//  CloudStorage.swift
//  CloudStorage
//
//  Created by Tom Lokhorst on 2020-07-05.
//

#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Combine
#endif

#if compiler(>=5.9)
// Static stored properites are not supported in generic types so we have to use a global var.
@available(iOS 13, tvOS 13, watchOS 6, *)
@MainActor
private let sync = CloudStorageSync.shared

@available(iOS 13, tvOS 13, watchOS 6, *)
@MainActor
@propertyWrapper public struct CloudStorage<Value>: DynamicProperty {
    @ObservedObject private var object: CloudStorageObject<Value>

    public var wrappedValue: Value {
        get { object.value }
        nonmutating set { object.value = newValue }
    }

    #if canImport(SwiftUI)
    public var projectedValue: Binding<Value> {
        Binding { object.value } set: { object.value = $0 }
    }
    #endif

    public init(keyName key: String, syncGet: @escaping () -> Value, syncSet: @escaping (Value) -> Void) {
        self.object = CloudStorageObject(key: key, syncGet: syncGet, syncSet: syncSet)
    }

//    @MainActor // prevent publishing on background thread
    #if canImport(Combine)
    public static subscript<OuterSelf: ObservableObject>(
        _enclosingInstance instance: OuterSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<OuterSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<OuterSelf, Self>
    ) -> Value {
        get {
            instance[keyPath: storageKeyPath].object.keyObserver.enclosingObjectWillChange = instance.objectWillChange as? ObservableObjectPublisher
            return instance[keyPath: storageKeyPath].wrappedValue
        }
        set {
            instance[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
    #endif
}

@available(iOS 13, tvOS 13, watchOS 6, *)
@MainActor // prevent publishing changes on background thread
internal class KeyObserver {
    weak var storageObjectWillChange: ObservableObjectPublisher?
    weak var enclosingObjectWillChange: ObservableObjectPublisher?

    func keyChanged() {
        // Need to do from main actor? Also can't do during view updates.
        main {
            self.storageObjectWillChange?.send()
            self.enclosingObjectWillChange?.send()
        }
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
@MainActor
internal class CloudStorageObject<Value>: ObservableObject {
    private let key: String
    private let syncGet: () -> Value
    private let syncSet: (Value) -> Void

    let keyObserver = KeyObserver()

    var value: Value {
        get { syncGet() }
        set {
            syncSet(newValue)
            sync.notifyObservers(for: key)
            sync.synchronize()
        }
    }

    init(key: String, syncGet: @escaping () -> Value, syncSet: @escaping (Value) -> Void) {
        self.key = key
        self.syncGet = syncGet
        self.syncSet = syncSet

        keyObserver.storageObjectWillChange = objectWillChange
        sync.addObserver(keyObserver, key: key)
    }

    deinit {
        // TODO: May need to keep a local copy of self.keyObserver so we don't need to access self in the main closure?
        let observer = self.keyObserver
        main { // removeObserver must be called on main and apparently deinit isn't called on main even in @MainActor isolated.
            sync.removeObserver(observer)
        }
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == Bool {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.bool(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == Int {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.int(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == Double {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.double(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == String {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.string(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == URL {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.url(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == Data {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.data(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
extension CloudStorage where Value: RawRepresentable, Value.RawValue == Int {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.int(for: key).flatMap(Value.init) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue.rawValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
extension CloudStorage where Value: RawRepresentable, Value.RawValue == Double {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.double(for: key).flatMap(Value.init) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue.rawValue, for: key) })
    }
}

// TODO: Add JSON representable for RawRepresentable when type is Codable

@available(iOS 13, tvOS 13, watchOS 6, *)
extension CloudStorage where Value: RawRepresentable, Value.RawValue == String {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.string(for: key).flatMap(Value.init) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue.rawValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == Bool? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.bool(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == Int? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.int(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == Double? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.double(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == String? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.string(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == URL? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.url(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == Data? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.data(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

// Enable CloudStorage for Date type objects (by default, stores as a mysqlDateTime string)
public protocol DefaultDateCloudStorage {
    init?(parse string: String)
    var stringValue: String { get }
}
extension Date: DefaultDateCloudStorage {
    @available(*, deprecated, renamed: "init(parse:)", message: "use failable init instead")
    public init(string: String) {
        guard let date = Self(parse: string) else {
            self = .nowBackport
            return
        }
        self = date
    }

    public var stringValue: String {
        return mysqlDateTime // change to alter the default storage format of dates.  IF you change this, will probably need to add additional parsing checks so that this format is still supported.
    }
}
extension DateStringRepresentation {
    public var stringValue: String {
        return self.rawValue
    }
    
    public init?(parse string: String) {
        self.init(string)
    }
}
extension DateString: DefaultDateCloudStorage {}
extension DateTimeString: DefaultDateCloudStorage {}
@available(iOS 13, tvOS 13, watchOS 6, *)
extension CloudStorage where Value: DefaultDateCloudStorage {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: {
                // do the conversion of a string to a date using all the strategies available in Date.
                guard let string = sync.string(for: key), let date = Value(parse: string) else {
                    return wrappedValue
                }
                return date
            },
            syncSet: { newValue in sync.set(newValue.stringValue, for: key) })
    }
}
#endif
