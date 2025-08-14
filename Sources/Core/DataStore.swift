// TODO: Do we want to restrict DataStore to the main thread?

#if compiler(>=5.9) && canImport(Foundation)
@available(iOS 13, tvOS 13, watchOS 6, *)
public enum DataStoreType: Sendable {
    case local
    case iCloud // shared will return local if watchOS < 9
    
    @MainActor
    public var shared: DataStore {
#if canImport(CoreML) // not available in Linux so skip
        if #available(watchOS 9, *) {
            // xcode previews indicate icloud is not available and thus will default to UserDefaults.  Playgrounds will indicate iCloud availability but values don't seem to persist.
            if self == .iCloud && !Application.isPlayground && !Application.isPreview && Application.iCloudIsEnabled {
                debug("Using ubiquitous store")
                return NSUbiquitousKeyValueStore.default
            } // if not, just use local.  Technically this case shouldn't even be available on unsupported devices
        }
#endif
        if self != .local {
            debug("Using local store because watchOS <9, isPlayground, isPreview, Linux, or iCloud not enabled.")
        }
        return UserDefaults.standard
    }
}
//@available(watchOS 9, *)
public protocol DataStore {
    static var notificationName: NSNotification.Name { get }
    @discardableResult func synchronize() -> Bool
        
    var isLocal: Bool { get }
    
    /// Sets the value of the specified default key.
    func set(
        _ value: Any?,
        forKey defaultName: String
    )
    /// Sets the value of the specified default key to the double value.
    func set(
        _ value: Double,
        forKey defaultName: String
    )
    /// Sets the value of the specified default key to the specified integer value.
    func set(
        _ value: Int,
        forKey defaultName: String
    )
    /// Sets the value of the specified default key to the specified Boolean value.
    func set(
        _ value: Bool,
        forKey defaultName: String
    )
    /// Sets the value of the specified default key to the specified URL.
    func set(
        _ value: URL?,
        forKey defaultName: String
    )
    
    ///Returns the object associated with the specified key.
    func object(forKey: String) -> Any?
    ///Returns the URL associated with the specified key.
    func url(forKey: String) -> URL?
    ///Returns the array associated with the specified key.
    func array(forKey: String) -> [Any]?
    ///Returns the dictionary object associated with the specified key.
    func dictionary(forKey: String) -> [String : Any]?
    ///Returns the string associated with the specified key.
    func string(forKey: String) -> String?
    ///Returns the array of strings associated with the specified key.
    func stringArray(forKey: String) -> [String]?
    ///Returns the data object associated with the specified key.
    func data(forKey: String) -> Data?
    ///Returns the Boolean value associated with the specified key.  If the key does not exist, returns `false`.
    func bool(forKey: String) -> Bool
    ///Returns the integer value associated with the specified key.
    func integer(forKey: String) -> Int
    ///Returns the longlong value associated with the specified key.  Note that this is here just for compatibility with @CloudStorage and may result in truncation...
    func longLong(forKey: String) -> Int64
    ///Returns the double value associated with the specified key.
    func double(forKey: String) -> Double
    ///Returns a dictionary that contains a union of all key-value pairs in the domains in the search list.
    func dictionaryRepresentation() -> [String : Any]
    
    /// Remove a key and it's value from the store.
    func removeObject(forKey: String)
    
    @available(iOS 13, tvOS 13, watchOS 6, *)
    var type: DataStoreType { get }
}

// CustomStringConvertible default conformance
extension DataStore {
    public var description: String {
        return isLocal ? "Local" : "iCloud" + " data store"
    }
    @available(iOS 13, tvOS 13, watchOS 6, *)
    @MainActor
    public static func shared(for type: DataStoreType) -> DataStore {
        return type.shared
    }
    @available(iOS 13, tvOS 13, watchOS 6, *)
    public var isLocal: Bool {
        self.type == .local
    }
}

// MARK: - Local (UserDefaults)
@available(iOS 13, tvOS 13, watchOS 6, *)
extension UserDefaults: DataStore {
    public static let notificationName = UserDefaults.didChangeNotification
    public var type: DataStoreType { .local }
    
    public func longLong(forKey: String) -> Int64 {
        return Int64(integer(forKey: forKey))
    }
}

// MARK: - iCloud (NSUbiquitousKeyValueStore)
#if canImport(CoreML) // not available in Linux
@available(iOS 13, tvOS 13, watchOS 9, *)
extension NSUbiquitousKeyValueStore: DataStore {
    public func set(_ value: Int, forKey defaultName: String) {
        self.set(Int64(value), forKey: defaultName)
    }

    public func set(_ value: URL?, forKey defaultName: String) {
        set(value?.absoluteString, forKey: defaultName)
    }
    public var type: DataStoreType { .iCloud }
}
@available(watchOS 9, *)
public extension NSUbiquitousKeyValueStore {
    static let notificationName = NSUbiquitousKeyValueStore.didChangeExternallyNotification
    ///Returns the integer value associated with the specified key.
    func integer(forKey key: String) -> Int {
        return Int(self.longLong(forKey: key))
    }
    func url(forKey key: String) -> URL? {
        guard let string = self.string(forKey: key) else {
            return nil
        }
        return URL(string: string)
    }
    func stringArray(forKey key: String) -> [String]? {
        guard let array = self.array(forKey: key) else {
            return nil
        }
        return try? array.map {
            guard let value = $0 as? String else {
                throw CustomError("Type Mismatch") // will this ever actually propagate?  Map should return a nil for this value if it throws I think.
            }
            return value
        }
    }
    
    func dictionaryRepresentation() -> [String : Any] {
        return self.dictionaryRepresentation
    }
}
#endif

// TODO: Since we have the @CloudStorage wrapper, we really don't need this at all anymore.
/*

// MARK: - Observation
@available(watchOS 9, *)
public class DataStoreObserver {
    static var observers: [DataStoreObserver] = []
    let store: DataStore
    let migrateLocal: (DataStore) -> Void
    let onUpdate: (DataStore, Bool) -> Void
    /// Called when there is some sync issue along with the issue Int.  For example, `NSUbiquitousKeyValueStoreQuotaViolationChange` or `NSUbiquitousKeyValueStoreAccountChange`
    let syncIssue: (DataStore, Int) -> Void
        
    /// Return an observer that has a `DataStore` that is configured to provide callbacks to run on update notifications.  `migrateLocal` is called when a store needs to be reset, for example, when migrating local data to iCloud, the local store should be reset after the migration since this will be called every time the observer is `.setup()`.  When first loaded, the `onUpdate` will be called with the `initialLoad` boolean to indicate this is the first fetching of the cloud data.  Subsequent changes will call `onUpdate` with `initialLoad` equal to `false`.  This observer will not run any of these or start observation until the `.setup()` method is called allowing this to be done in initializers and shared singletons without worrying about infinite loops accessing self properties before being intialized.  You will typically configure the `DataStoreObserver`, save just the `store` property for future save calls, and then you will call `.setup()` on the observer to start listening for changes which will also register itself so the observer will be maintained.  Once that is done, the local refrence to the observer can be discarded.  If iCloud is not supported or available, no notifications will ever be sent and `onUpdate` will only be called once during `.setup()`
    public init(
        /// pull data from the local data source and reset.  Future call to load will be coming.
        migrateLocal: @escaping (DataStore) -> Void = { _ in },
        onUpdate: @escaping (DataStore, Bool) -> Void,
        /// use to notify user that the cloud storage is full and thus updates cannot be synced
        syncIssue: @escaping (DataStore, Int) -> Void = { _, _ in }
    ) {
        if Compatibility.iCloudIsEnabled {
            self.store = NSUbiquitousKeyValueStore.default
        } else {
            debug("iCloud is not enabled")
            // just use local store and ignore any iCloud syncing.
            self.store = UserDefaults.standard
        }
        self.migrateLocal = migrateLocal
        self.onUpdate = onUpdate
        self.syncIssue = syncIssue
    }
    
    var isSetup = false
    public func setup() {
        guard !isSetup else {
            debug("Attempting to call setup() on a DataStoreObserver more than once!", level: .ERROR)
            return // do nothing
        }
        if Compatibility.iCloudIsEnabled {
            // migrate local storage first
            migrateLocal(UserDefaults.standard)
        }

        // initial load/sync
        onUpdate(store, true)

        // save to global observers to hold on to object for future notifications without having to store this object anywhere.
        Self.observers.append(self)

        if Compatibility.iCloudIsEnabled {
            // create observer to monitor for changes in the store
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(updateKVStoreItems),
                name: type(of: store).notificationName,
                object: store)

            store.synchronize() // used for iCloud but not necessary for UserDefaults
        }
    }
    
    @objc private func updateKVStoreItems(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        
        // Get the reason for the notification (initial download, external change or quota violation change).
        guard let reasonForChange = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            debug("Unable to get reason for KVStore change.", level: .WARNING)
            // If a reason could not be determined, do not update anything.
            return
        }
        // The reason for the key-value notification change is one of the following:
        // Update only for changes from the server.
        switch reasonForChange {
        case NSUbiquitousKeyValueStoreServerChange:
            //NSUbiquitousKeyValueStoreServerChange: Value(s) were changed externally from other users/devices.
            debug("Value(s) were changed externally from other users/devices.", level: .DEBUG)
            // this is one we want to update!
        case NSUbiquitousKeyValueStoreInitialSyncChange:
            // NSUbiquitousKeyValueStoreInitialSyncChange: Initial downloads happen the first time a device is connected to an iCloud account, and when a user switches their primary iCloud account.
            debug("Initial download from iCloud.", level: .NOTICE)
            // this is one we want to update!
        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            // NSUbiquitousKeyValueStoreQuotaViolationChange: The app’s key-value store has exceeded its space quota on the iCloud server.
            debug("The app’s key-value store has exceeded its space quota on the iCloud server.", level: .ERROR)
            syncIssue(store, reasonForChange)
            return
        case NSUbiquitousKeyValueStoreAccountChange:
            // NSUbiquitousKeyValueStoreAccountChange: The user has changed the primary iCloud account.
            debug("The user has changed the primary iCloud account.", level: .NOTICE)
            syncIssue(store, reasonForChange)
            return
        default:
            debug("Unknown reason for change: \(reasonForChange)", level: .ERROR)
            syncIssue(store, reasonForChange)
            return
        }
        // To obtain key-values that have changed, use the key NSUbiquitousKeyValueStoreChangedKeysKey from the notification’s userInfo.
        // guard let keys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else { return }
        // NOTE: Previous version would go through and check keys and items to look for changes.  For this, we should just load the data and set the messages object.  Since struct, shouldn't cause any updates except changes should automatically be visible due to SwiftUI checking state changes.
        onUpdate(store, false)
    }
    
    @available(*, deprecated, message: "This is no longer the way to initialize.  Instead, create a `DataStoreObserver` with the configuration, extract the `store` property, then run `.setup()` on the observer to start monitoring for changes.")
    public static func getObservedStore(
        /// pull data from the local data source and reset.  Future call to load will be coming.
        migrateLocal: @escaping (DataStore) -> Void = { _ in },
        load: @escaping (DataStore) throws -> Void, // if error, don't synchronize.  DataStore passed will indicate if local or not in case needed.
        onUpdate: @escaping (DataStore) -> Void
    ) -> DataStore {
        let observer = DataStoreObserver(migrateLocal: migrateLocal, onUpdate: { store, initialUpdate in
            if initialUpdate {
                do {
                    try load(store)
                } catch {
                    debug("Legacy load error: \(error)", level: .ERROR)
                }
            } else {
                onUpdate(store)
            }
        })
        observer.setup()
        return observer.store
    }
}

// MARK: - property wrapper for automatic linking
public protocol MergePolicy {
    associatedtype Content: Codable
    func merge(local: inout Content, remote: Content)
}
// remote updates will always replace local values.  Default behavior.
public struct ReplaceMergePolicy<ReplaceContent: Codable>: MergePolicy {
    public typealias Content = ReplaceContent
    public func merge(local: inout Content, remote: Content) {
        local = remote
    }
}
extension MergePolicy where Content: Codable {
    public static var replace: ReplaceMergePolicy<Content> {
        ReplaceMergePolicy<Content>()
    }
}
// Will add remote value to the local value if the content is able to be added.
public struct JoinMergePolicy<JoinContent: Codable & AdditiveArithmetic>: MergePolicy {
    public typealias Content = JoinContent
    public func merge(local: inout Content, remote: Content) {
        local += remote
    }
}
extension MergePolicy where Content: Codable & AdditiveArithmetic {
    public static var join: JoinMergePolicy<Content> {
        JoinMergePolicy<Content>()
    }
}

/*
@propertyWrapper
struct DataStoreBacked<Value> {
    var wrappedValue: Value {
        get {
            let value = storage.value(forKey: key) as? Value
            return value ?? defaultValue
        }
        set {
            storage.setValue(newValue, forKey: key)
        }
    }

    private let key: String
    private let defaultValue: Value
    private let storage: DataStore
    private let mergePolicy: MergePolicy // to indicate how to sync.
    #warning("For arrays, support merge policy that will join the two arrays.  For sets, do the same.  For strings, concatenate.  For numbers, add.  Make so we can set up a custom MergePolicy that we can pass in that will support doing things like Monetization where we can decide how to merge depending on values.  Will want to clear local store when merging...")

    init(wrappedValue defaultValue: Value,
         key: String,
         storage: UserDefaults = .standard) {
        self.defaultValue = defaultValue
        self.key = key
        self.storage = storage
    }
}

@available(iOS 13, *)
@MainActor
public protocol DataStoreBacked: ObservableObject, Codable {
    func merge(with: Self, direction: MergeDirection)
}
@available(iOS 13, *)
public extension DataStoreBacked {
    func init(from store: DataStore, clearing: Bool = false) {


        let mirror = Mirror(reflecting: self)
        for case let (key?, value) in mirror.children {
            let value = store.object(forKey: key)
            // TODO: check for type matching and existance??
            
            self[keyPath: KeyPath(key: key)]
            self.setValue(value, forKey: key)
            // clear local values since future updates will replace cloud values and the local values should be unused.  If iCloud is enabled, the value above will only be used when this is first run or there are no values in iCloud.
            if clearing {
                store.removeObject(forKey: key)
            }
        }


        // convert to JSON so we can get the keys for this
        guard let dictionary = self.asDictionary() else {
            debug("Unable to convert DataStoreBacked object to a dictionary for key fetching.", level: .ERROR)
            return
        }
        let keys = dictionary.keys
        debug("Keys: \(keys)")
        for key in keys {
            let value = store.object(forKey: key)
            // TODO: check for type matching??
            self[keyPath: KeyPath(key: key)]
            self.setValue(value, forKey: key)
            // clear local values since future updates will replace cloud values and the local values should be unused.  If iCloud is enabled, the value above will only be used when this is first run or there are no values in iCloud.
            if clearing {
                store.removeObject(forKey: key)
            }
        }
    }
    func enableSynchronization() {
        let observer = DataStoreObserver(migrateLocal: {
            store in
            debug("Migrating local")
            self.load(from: store, clearing: true)
        }, onUpdate: { store, initialLoad in
            if initialLoad && !store.isLocal {
                // merge local UserDefaults value with iCloud value (if we previously used without iCloud and we had something stored in iCloud, we may want to combine the values so user doesn't lose anything)
                let copy = self.copy
                copy.load(from: store, clearing: false)
                self.merge(with: copy, direction: .initial)
            } else {
                // overwrite with cloud/store variable since we will synchronize or save/write to cloud at first chance.
                self.load(from: store)
            }
        })
        Self.dataStore = observer.store
        //            main { // allow this init to return before setting up!
        observer.setup()
        debug("new data store set: \(Self.dataStore?.description ?? "nil!")")
        //            }
        //Create a protocol for a datastore synced ObservableObject that supports Coding that will automatically pull coding keys to sync values with the store.  Have a merge policy function that must be included that will dictate how conflicting values are merged when iCloud changes and there are conflicts.  Should use standard types that can take the codable values and merge.  Have the test data model use this type for ease of setting.  Use this for creating settings objects that are automatically synced and we don't have to handle all the updates.  Should automatically do restore and sync.  Will also need to be manually synchronized by calling `.enableSynchronization()` so that it can start synchronization and monitoring for changes.  Since we require this to be an ObservableObject and not a struct, should be called at end of `init()` or can be called separately.
       
    }
}
*/
*/
// MARK: - Testing
#if canImport(SwiftUI)
import SwiftUI

extension String {
    static let string1Key = "string1"
    static let string2Key = "string2"
    static let tokensAvailableKey = "tokensAvailable"
    public static let compatibilityVersionsRunKey = "compatibilityVersionsRun"
    static let lastSavedKey = "lastSaved"
    static let string1Initial = "Initialized String 1"
    static let string2Initial = "Initialized String 2"
}
/*
@available(macOS 12, *)
extension DataStore {
    var testDescription: String {
        " (from \(isLocal ? "Local" : "iCloud"))"
    }
    func reset() {
        self.removeObject(forKey: .string1Key)
        self.removeObject(forKey: .string2Key)
        self.removeObject(forKey: .tokensAvailableKey)
        self.removeObject(forKey: .compatibilityVersionsRunKey)
        self.removeObject(forKey: .lastSavedKey)
        self.synchronize() // make sure this gets propagated
        debug("\(self.testDescription) Data store should be reset")
    }
}*/

#if compiler(>=5.9) && canImport(Combine)
@available(iOS 15, macOS 12, tvOS 15, watchOS 9, *)
@MainActor
class DataStoreTestModel: ObservableObject {
    @MainActor
    static var shared = DataStoreTestModel()

    @CloudStorage(.string1Key) var string1 = String.string1Initial
    @CloudStorage(.string2Key) var string2 = String.string2Initial
    @CloudStorage("string3") var string3 = "String 3 initial"
    @CloudStorage(.tokensAvailableKey)
    var tokensAvailable = 0
    @CloudStorage("doubleTest") var doubleTest = CustomDoubleType.large
    // store as a single comma-separated String for simplicity
    @CloudStorage(.compatibilityVersionsRunKey) var moduleVersionsRunStorage: String?
    var moduleVersionsRun: [Version] {
        get {
//            if moduleVersionsRunStorage == nil {
//                // first run!
            let resolvedVersions = [Version](rawValue: moduleVersionsRunStorage ?? "", required: Compatibility.version)
            // make sure to propagate back if changed!
            if resolvedVersions.rawValue != moduleVersionsRunStorage {
                // but do on separate thread since updates aren't supported within view rendering
                delay(0.01) {
                    main {
                        self.moduleVersionsRunStorage = resolvedVersions.rawValue
                    }
                }
            }
            return resolvedVersions
        }
        set {
            moduleVersionsRunStorage = newValue.rawValue
        }
    }
    @CloudStorage(.lastSavedKey) var lastSavedStorage = Date.timeIntervalSinceReferenceDate
    var lastSaved: Date {
        get {
            Date(timeIntervalSinceReferenceDate: lastSavedStorage)
        }
        set {
            lastSavedStorage = newValue.timeIntervalSinceReferenceDate
        }
    }
    
    @MainActor
    init() {
        // do once!
        
        // migrate local values to cloud values for testing.  This won't automatically happen with cloud storage so must do manually if this is what we want.
        
        if let existingString1 = UserDefaults.standard.object(forKey: .string1Key) as? String, !string1.contains(existingString1) { // legacy support
            debug("Migrating local string1: \(existingString1) to cloud string1: \(string1)", level: .NOTICE)
            string1 = "\(existingString1),\(string1)"
            // zero out local version so we don't repeat
            UserDefaults.standard.removeObject(forKey: .string1Key)
        }
        
/*        if Self.dataStore == nil {
            let observer = DataStoreObserver(migrateLocal: {
                store in
                debug("Migrating local")
                self.string1 = store.string(forKey: .string1Key) ?? "no local string1 value"
                self.string2 = store.string(forKey: .string2Key) ?? "no local string2 value"
                self.tokensAvailable = store.integer(forKey: .tokensAvailableKey)
                // clear local values since future updates will replace cloud values and the local values should be unused.  If iCloud is enabled, the value above will only be used when this is first run or there are no values in iCloud.
                store.set("CLEARED String 1", forKey: .string1Key)
                store.set("CLEARED String 2", forKey: .string2Key)
                store.set(0, forKey: .tokensAvailableKey)
                store.set(Date.now.mysqlDateTime, forKey: .lastSavedKey)
            }, onUpdate: { store, initialLoad in
                let storeTokens = store.integer(forKey: .tokensAvailableKey)
                let storeString1 = store.string(forKey: .string1Key) ?? "no cloud string1 value"
                let storeString2 = store.string(forKey: .string2Key) ?? "no cloud string2 value"
                self.lastSaved = Date(from: store.string(forKey: .lastSavedKey) ?? "", format: .mysqlDateTimeFormat) ?? Date(timeIntervalSinceReferenceDate: 0)
                if initialLoad && !store.isLocal {
                    // merge local UserDefaults value with iCloud value (if we previously used without iCloud and we had something stored in iCloud, we may want to combine the values so user doesn't lose anything)
                    self.tokensAvailable += storeTokens
                    self.string1 += ":store:\(storeString1)"
                    self.string2 += ":store:\(storeString2)"
                    // if we launch the app and the user has no tokens, grant tokens at launch.
                    if self.tokensAvailable == 0 {
                        self.tokensAvailable += 5
                    }
                    // save total value back to dataStore if different
                    if storeTokens != self.tokensAvailable {
                        store.set(self.tokensAvailable, forKey: .tokensAvailableKey)
                        store.set(Date.now.mysqlDateTime, forKey: .lastSavedKey)
                    }
                } else {
                    // overwrite with cloud/store variable since we will synchronize or save/write to cloud at first chance.
                    self.string1 = storeString1
                    self.string2 = storeString2
                    self.tokensAvailable = storeTokens
                }
            })
            Self.dataStore = observer.store
//            main { // allow this init to return before setting up!
                observer.setup()
                debug("new data store set: \(Self.dataStore?.description ?? "nil!")")
//            }
        }*/
    }
    
    // monitoring property should automatically save so no longer need to do manually.
/*    func save() {
        guard let store = Self.dataStore else {
            debug("Attempting to save but dataStore is nil!", level: .ERROR)
            return
        }
        debug("Saving data: \(String(describing: self)) to \(store.description)")
        store.set(self.string1, forKey: .string1Key)
        store.set(self.string2, forKey: .string2Key)
        store.set(self.tokensAvailable, forKey: .tokensAvailableKey)
        self.lastSaved = Date.now
        store.set(Date.now.mysqlDateTime, forKey: .lastSavedKey)
        store.synchronize() // make sure this gets propagated
    }
    
    func reset() { // no need to
        DataStoreType.local.shared.reset()
        DataStoreType.iCloud.shared.reset()
    }*/
}

enum CustomDoubleType: Double, RawRepresentable, Sendable {
    case zero = 0.0
    case negative = -1
    case superneg = -2
    case large = 100
    case pi = 3.14
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 9, *)
@MainActor
public struct DataStoreTestView: View {
    @ObservedObject var model = DataStoreTestModel.shared
    @CloudStorage(.string2Key) var string2 = String.string2Initial
    @CloudStorage(.appVersionsRunKey) var appVersionsRun: String?
    @CloudStorage(.appTestLastRunKey) var appTestLastRun = Date.nowBackport
    public init() {}
    public var body: some View {
        List {
            Section("DataStore values") {
                Text("App Run Versions:")
                ClearableTextField(label: "App Run Versions", text: Binding(get: {
                    appVersionsRun
                }, set: {
                    appVersionsRun = $0
                }))
                ClearableTextField(label: "App First Run", text: Binding(get: {
                    appTestLastRun.stringValue
                }, set: { newValue in
                    if let newValue, let date = Date(parse: newValue) {
                        appTestLastRun = date
                    } else {
                        appTestLastRun = .nowBackport
                    }
                }))
                Text("Debug tests:")
                ClearableTextField(label: "Label String 1", text: Binding(get: {
                    model.string1
                }, set: {
                    debug("binding1 set to \($0 ?? "nil")")
                    model.string1 = $0 ?? ""
                    model.lastSaved = .nowBackport
//                    model.save()
                }))
                ClearableTextField(label: "Label String 2", text: Binding(get: {
                    model.string2
                }, set: {
                    debug("binding2 set \($0 ?? "nil")")
                    model.string2 = $0 ?? ""
                    model.lastSaved = .nowBackport
//                    model.save()
                }))
                ClearableTextField(label: "Label String 3", text: Binding(get: {
                    model.string3
                }, set: {
                    debug("binding3 set \($0 ?? "nil")")
                    model.string3 = $0 ?? ""
                    model.lastSaved = .nowBackport
//                    model.save()
                }))
                ClearableTextField(label: "Label Tokens Available", text: Binding(get: {
                    "\(model.tokensAvailable)"
                }, set: {
                    debug("bindingTokens set \($0 ?? "nil")")
                    model.tokensAvailable = Int($0 ?? "-2") ?? -1
                    model.lastSaved = .nowBackport
//                    model.save()
                }))
                ClearableTextField(label: "Label Double Test", text: Binding(get: {
                    "\(model.doubleTest.rawValue)"
                }, set: {
                    debug("bindingDoubleTest set \($0 ?? "nil")")
                    model.doubleTest = CustomDoubleType(rawValue: Double($0 ?? "-2") ?? -1) ?? .negative
                    model.lastSaved = .nowBackport
//                    model.save()
                }))
                ClearableTextField(label: "Module Run Versions", text: Binding(get: {
                    model.moduleVersionsRun.map { $0.rawValue }.joined(separator: ", ")
                }, set: {
                    debug("bindingModuleRunVersions set \($0 ?? "nil")")
                    defer {
                        model.lastSaved = .nowBackport
                        //                    model.save()
                    }
                    model.moduleVersionsRun = [Version](rawValue: $0 ?? "", required: Compatibility.version)
                    // may change so update binding (if multiple 0 values, it won't update UI because technically the value isn't changing).
                }))
                Text("Last saved: \(model.lastSaved)")
//                Button("Reset") {
//                    model.reset()
//                }
                Button("Synchronize") {
                    DataStoreType.iCloud.shared.synchronize()
                }
                HStack {
                    Text("iCloud:").opacity(0.5)
                    Image(systemName: Application.iCloudStatus.symbolName)
                    Text("\(Application.iCloudStatus.description)")
                }
            }
        }
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 9, *)
#Preview {
    DataStoreTestView()
}
#endif
#endif
#endif
