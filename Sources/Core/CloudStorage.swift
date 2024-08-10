//
//  CloudStorage.swift
//  CloudStorage
//
//  Created by Tom Lokhorst on 2020-07-05.
//

#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Combine

@available(iOS 13, tvOS 13, watchOS 9, *) // TODO: Should this be moved into a static property so we don't pollute the global namespace?  Not applicable since private and only used in this file?
@MainActor
private let sync = CloudStorageSync.shared

@available(iOS 13, tvOS 13, watchOS 9, *)
@propertyWrapper public struct CloudStorage<Value>: DynamicProperty {
    @ObservedObject private var object: CloudStorageObject<Value>

    public var wrappedValue: Value {
        get { object.value }
        nonmutating set { object.value = newValue }
    }

    public var projectedValue: Binding<Value> {
        Binding { object.value } set: { object.value = $0 }
    }

    public init(keyName key: String, syncGet: @escaping () -> Value, syncSet: @escaping (Value) -> Void) {
        self.object = CloudStorageObject(key: key, syncGet: syncGet, syncSet: syncSet)
    }

//    @MainActor
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
}

@available(iOS 13, tvOS 13, watchOS 9, *)
// @MainActor??
internal class KeyObserver {
    weak var storageObjectWillChange: ObservableObjectPublisher?
    weak var enclosingObjectWillChange: ObservableObjectPublisher?

    func keyChanged() {
        // TODO: Need to do from main actor???
        storageObjectWillChange?.send()
        enclosingObjectWillChange?.send()
    }
}

@available(iOS 13, tvOS 13, watchOS 9, *)
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
        main { // removeObserver must be called on main and apparently deinit isn't called on main even in @MainActor isolated.
            sync.removeObserver(self.keyObserver)
        }
    }
}

@available(iOS 13, tvOS 13, watchOS 9, *)
extension CloudStorage where Value == Bool {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.bool(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 9, *)
extension CloudStorage where Value == Int {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.int(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 9, *)
extension CloudStorage where Value == Double {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.double(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 9, *)
extension CloudStorage where Value == String {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.string(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 9, *)
extension CloudStorage where Value == URL {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.url(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 9, *)
extension CloudStorage where Value == Data {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.data(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 9, *)
extension CloudStorage where Value: RawRepresentable, Value.RawValue == Int {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.int(for: key).flatMap(Value.init) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue.rawValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 9, *)
extension CloudStorage where Value: RawRepresentable, Value.RawValue == String {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.string(for: key).flatMap(Value.init) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue.rawValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 9, *)
extension CloudStorage where Value == Bool? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.bool(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 9, *)
extension CloudStorage where Value == Int? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.int(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 9, *)
extension CloudStorage where Value == Double? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.double(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 9, *)
extension CloudStorage where Value == String? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.string(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 9, *)
extension CloudStorage where Value == URL? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.url(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, tvOS 13, watchOS 9, *)
extension CloudStorage where Value == Data? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.data(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

#endif
