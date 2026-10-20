//
//  CloudStorage.swift
//  CloudStorage
//
//  Created by Tom Lokhorst on 2020-07-05.
//

#if canImport(SwiftUI) && canImport(Combine) && compiler(>=5.9) && canImport(Foundation)
import SwiftUI
import Combine

// Static stored properites are not supported in generic types so we have to use a global var.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
private let sync = CloudStorageSync.shared

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
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

//    @MainActor // prevent publishing on background thread
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

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor // prevent publishing changes on background thread
internal class KeyObserver {
    weak var storageObjectWillChange: ObservableObjectPublisher?
    weak var enclosingObjectWillChange: ObservableObjectPublisher?

    func keyChanged() {
        // Need to do from main actor? Also can't do during view updates.
        Task.main {
            self.storageObjectWillChange?.send()
            self.enclosingObjectWillChange?.send()
        }
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
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
        Task.main { // removeObserver must be called on main and apparently deinit isn't called on main even in @MainActor isolated.
            sync.removeObserver(observer)
        }
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == Bool {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.bool(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == Int {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.int(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == Double {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.double(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == String {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.string(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == URL {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.url(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == Data {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.data(for: key) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension CloudStorage where Value: RawRepresentable, Value.RawValue == Int {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.int(for: key).flatMap(Value.init) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue.rawValue, for: key) })
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension CloudStorage where Value: RawRepresentable, Value.RawValue == Double {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.double(for: key).flatMap(Value.init) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue.rawValue, for: key) })
    }
}

// TODO: Add JSON representable for RawRepresentable when type is Codable

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension CloudStorage where Value: RawRepresentable, Value.RawValue == String {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.string(for: key).flatMap(Value.init) ?? wrappedValue },
            syncSet: { newValue in sync.set(newValue.rawValue, for: key) })
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == Bool? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.bool(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == Int? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.int(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == Double? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.double(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == String? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.string(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension CloudStorage where Value == URL? {
    public init(_ key: String) {
        self.init(
            keyName: key,
            syncGet: { sync.url(for: key) },
            syncSet: { newValue in sync.set(newValue, for: key) })
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
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
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
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

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
enum CloudStorageTests {
    /// Covers the public date-string conversion contract without requiring a SwiftUI host view.
    @MainActor
    internal static let tests: [TestCase] = [
        TestCase("CloudStorage value and binding behavior") { @MainActor in
            var storedValue = 7
            let storage = CloudStorage<Int>(
                keyName: "Compatibility.CloudStorageTests.injected",
                syncGet: { storedValue },
                syncSet: { storedValue = $0 }
            )

            try expect(storage.wrappedValue == 7)
            storage.wrappedValue = 8
            try expect(storedValue == 8)
            try expect(storage.projectedValue.wrappedValue == 8)
            storage.projectedValue.wrappedValue = 9
            try expect(storage.wrappedValue == 9)
        },
        TestCase("CloudStorage primitive and optional initializers") { @MainActor in
            let sync = CloudStorageSync.shared
            let keys = (0..<14).map { "Compatibility.CloudStorageTests.primitive.\($0)" }
            defer { keys.forEach(sync.remove(for:)) }

            // Start from clean keys so each nonoptional initializer must use its supplied default.
            keys.forEach(sync.remove(for:))
            let boolean = CloudStorage<Bool>(wrappedValue: true, keys[0])
            try expect(boolean.wrappedValue)
            boolean.wrappedValue = false
            if sync.bool(for: keys[0]) == false { try expect(!boolean.wrappedValue) }

            let integer = CloudStorage<Int>(wrappedValue: 12, keys[1])
            try expect(integer.wrappedValue == 12)
            integer.wrappedValue = 13
            if sync.int(for: keys[1]) == 13 { try expect(integer.wrappedValue == 13) }

            let double = CloudStorage<Double>(wrappedValue: 1.5, keys[2])
            try expect(double.wrappedValue == 1.5)
            double.wrappedValue = 2.5
            if sync.double(for: keys[2]) == 2.5 { try expect(double.wrappedValue == 2.5) }

            let string = CloudStorage<String>(wrappedValue: "default", keys[3])
            try expect(string.wrappedValue == "default")
            string.wrappedValue = "stored"
            if sync.string(for: keys[3]) == "stored" { try expect(string.wrappedValue == "stored") }

            let url = URL(string: "https://example.com/default")!
            let storedURL = URL(string: "https://example.com/stored")!
            let urlStorage = CloudStorage<URL>(wrappedValue: url, keys[4])
            try expect(urlStorage.wrappedValue == url)
            urlStorage.wrappedValue = storedURL
            if sync.url(for: keys[4]) == storedURL { try expect(urlStorage.wrappedValue == storedURL) }

            let data = Data([1, 2])
            let storedData = Data([3, 4])
            let dataStorage = CloudStorage<Data>(wrappedValue: data, keys[5])
            try expect(dataStorage.wrappedValue == data)
            dataStorage.wrappedValue = storedData
            if sync.data(for: keys[5]) == storedData { try expect(dataStorage.wrappedValue == storedData) }

            let optionalBool = CloudStorage<Bool?>(keys[6])
            try expect(optionalBool.wrappedValue == nil)
            optionalBool.wrappedValue = true
            if sync.bool(for: keys[6]) == true { try expect(optionalBool.wrappedValue == true) }

            let optionalInt = CloudStorage<Int?>(keys[7])
            try expect(optionalInt.wrappedValue == nil)
            optionalInt.wrappedValue = 14
            if sync.int(for: keys[7]) == 14 { try expect(optionalInt.wrappedValue == 14) }

            let optionalDouble = CloudStorage<Double?>(keys[8])
            try expect(optionalDouble.wrappedValue == nil)
            optionalDouble.wrappedValue = 3.5
            if sync.double(for: keys[8]) == 3.5 { try expect(optionalDouble.wrappedValue == 3.5) }

            let optionalString = CloudStorage<String?>(keys[9])
            try expect(optionalString.wrappedValue == nil)
            optionalString.wrappedValue = "optional"
            if sync.string(for: keys[9]) == "optional" { try expect(optionalString.wrappedValue == "optional") }

            let optionalURL = CloudStorage<URL?>(keys[10])
            try expect(optionalURL.wrappedValue == nil)
            optionalURL.wrappedValue = storedURL
            if sync.url(for: keys[10]) == storedURL { try expect(optionalURL.wrappedValue == storedURL) }

            let optionalData = CloudStorage<Data?>(keys[11])
            try expect(optionalData.wrappedValue == nil)
            optionalData.wrappedValue = storedData
            if sync.data(for: keys[11]) == storedData { try expect(optionalData.wrappedValue == storedData) }

            // Also cover the generic object access and removal routes used by the wrapper's backing store.
            sync.set("object", for: keys[12])
            if let object = sync.object(forKey: keys[12]) as? String { try expect(object == "object") }
            sync.remove(for: keys[12])
            sync.set(6.25, for: keys[13])
            if sync.double(for: keys[13]) == 6.25 { try expect(sync.double(for: keys[13]) == 6.25) }
        },
        TestCase("CloudStorage raw values and dates", test: { @MainActor in
            enum IntegerOption: Int, Equatable { case first = 1, second = 2 }
            enum DoubleOption: Double, Equatable { case first = 1.25, second = 2.5 }
            enum StringOption: String, Equatable { case first = "first", second = "second" }

            let sync = CloudStorageSync.shared
            let keys = (0..<4).map { "Compatibility.CloudStorageTests.raw.\($0)" }
            defer { keys.forEach(sync.remove(for:)) }
            keys.forEach(sync.remove(for:))

            let integer = CloudStorage<IntegerOption>(wrappedValue: .first, keys[0])
            try expect(integer.wrappedValue == .first)
            integer.wrappedValue = .second
            if sync.int(for: keys[0]) == IntegerOption.second.rawValue { try expect(integer.wrappedValue == .second) }

            let double = CloudStorage<DoubleOption>(wrappedValue: .first, keys[1])
            try expect(double.wrappedValue == .first)
            double.wrappedValue = .second
            if sync.double(for: keys[1]) == DoubleOption.second.rawValue { try expect(double.wrappedValue == .second) }

            let string = CloudStorage<StringOption>(wrappedValue: .first, keys[2])
            try expect(string.wrappedValue == .first)
            string.wrappedValue = .second
            if sync.string(for: keys[2]) == StringOption.second.rawValue { try expect(string.wrappedValue == .second) }

            let date = Date(parse: "2024-01-02 03:04:05")!
            let dateStorage = CloudStorage<Date>(wrappedValue: date, keys[3])
            try expect(dateStorage.wrappedValue == date)
            let nextDate = Date(parse: "2025-06-07 08:09:10")!
            dateStorage.wrappedValue = nextDate
            if sync.string(for: keys[3]) == nextDate.stringValue { try expect(dateStorage.wrappedValue == nextDate) }

        }),
        TestCase("CloudStorage date representations") {
            let date = Date(parse: "2024-01-02 03:04:05")
            try expect(date != nil)
            try expect(date?.stringValue == "2024-01-02 03:04:05")
            try expect(DateString("custom").stringValue == "custom")
            try expect(DateTimeString("custom").stringValue == "custom")
        },
    ]
}
#endif
