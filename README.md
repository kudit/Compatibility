<img src="/Development/Resources/Assets.xcassets/AppIcon.appiconset/Icon.png" height="128">

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fkudit%2FCompatibility%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/kudit/Compatibility)

# Compatibility.swiftpm
Compatibility is a set of code that is designed to improve compatibility to allow using modern APIs on older platforms as well as provide simplified syntax for things.  Also includes a Debug module and a Test harness module.  Debug is a set of code that is designed for easily writing and enabling/disabling debug statements in code.  This allows for easily breaking only certain levels of statements and having consistent flags in the output for easier reading of debug output.  Also includes compatibility functions on Int.

The primary goals are to be easily maintainable by multiple individuals, employ a consistent API that can be used across all platforms, and to be maintainable using Swift Playgrounds on iPad and macOS.  APIs are typically present even on platforms that don't support all features so that availability checks do not have to be performed in external code, and where irrelevant, code can simply return optionals.


## Features
- Can develop and modify without Xcode using Swift Playgrounds on iPad!
- Threading features to make syntax easier (`Task.main {}` and `Task.background {}`).
- Sleep feature for simple delays in tasks.
- Testing framework for providing tests inline in frameworks that can be output/tested using #Previews.
- Several SwiftUI features that have been added have been "Backported" so that you can use the new features on new platforms but have an automatic fallback for older platforms that do not support the feature.
- Emoji prefixing of debug outputs.
- Automatically including context in debug output to make finding the source of the debug easier.
- `.DEBUG` and `.NOTICE` level statements will only be output during DEBUG build configurations and will not be output when compiled for RELEASE build configurations. 
- Easily set breakpoints on various levels of debug statements.
- Provides a simple CustomError type that can be initialized with a string for throwing errors when you don't care about the type of error thrown.


## Requirements
- iOS 11+ (15.2+ minimum required for Swift Playgrounds support)
- macOS 10.10+ for Foundation and command-line-compatible APIs (SwiftPM cannot declare earlier macOS); SwiftUI APIs require macOS 10.15+, and the development app/tests currently target macOS 11+ or 12+ where noted.
- macCatalyst 13.0+ (first version available)
- tvOS 11.0+ (UI only supported on tvOS 15+, 17+ required for most SwiftUI features)
- watchOS 4.0+ (UI only supported on watchOS 8+)
- visionOS 1.0+
- Theoretically should work with Linux, Windows, and Vapor, but haven't fully tested.  If you would like to help, please let us know.


## Known Issues
*See CHANGELOG.md for known issues and roadmap*
Note that the DataStore tests only work if entitlements and privacyinfo are included (therefore, they will not be functional in Previews and Swift Playgrounds).


## Installation
Install by adding this as a package dependency to your code.  This can be done in Xcode or Swift Playgrounds!

### Swift Package Manager

#### Swift 5+
You can try these examples in a Swift Playground by adding package: `https://github.com/kudit/Compatibility`

Or you can manually enter the following in the Package.swift file:
```swift
dependencies: [
    .package(url: "https://github.com/kudit/Compatibility.git", from: "1.0.0"),
]
```
Make sure the target includes the library:
```swift
            .product(name: "Compatibility Library", package: "compatibility"), // apparently needs to be lowercase.  Also note this is "Compatibility Library" not "Compatibility"
```

## Usage
First make sure to import the framework:
```swift
import Compatibility
```

Here are some usage examples.

### Get the version of Compatibility that is imported.
```swift
let version = Compatibility.version
```

### Simple debug statement (can be used to replace debugging `print` statements) at the default debug level (which can be changed).
```swift
debug("This is a test string \(true ? "with" : "without") interpolation")
```

### Debug statement at a specified level:
```swift
debug("Fatal error!  This will be output to console typically even in production code.", level: .ERROR)
```

### Debug-only code:
If you have a feature you want to only show in debugging, you can add the following:
```Swift
if Application.isDebug {
    // execute test/debug-only code.  This will only run in DEBUG configurations and will be removed during RELEASE compilations.
}
```

### Running code on various threads and delaying execution of code:
```swift
Task.background {
    // run long-running code on background thread
    await Task.sleep(seconds: 4) // wait for 4 seconds before continuing
    Task.delay(0.4) { // run this code after 0.4 seconds (similar to calling await sleep() and then executing code)
        Task.main {
            // run this code back on the main thread
        }
    }
}
```

### Parsing a date from any built-in supported Compatibility format:
```swift
let mysql = Date(parse: "2023-01-02 17:12:00")
let spelledOut = Date(parse: "January 2, 2023")
let numeric = Date(parse: "20230102171200")
```

### Command-line demonstration and SwiftPM tests
The `compatibilityCLI` executable target and `CompatibilitySwiftPMTests` test target live in `Development` so the existing Swift Playgrounds app remains unchanged. They are conditionally omitted from a Swift Playgrounds manifest, but are available to SwiftPM and Xcode on macOS.

From the package directory, select the macOS destination and run:
```sh
swift run compatibilityCLI banana Bob
swift run compatibilityCLI parseDate "2023-01-02 17:12:00"
swift test
swift test --enable-code-coverage
swift test --show-codecov-path
```

In Xcode, open the package, select the automatically discovered `compatibilityCLI` scheme, choose **My Mac** as the run destination, and run it with the desired arguments. The `CompatibilitySwiftPMTests` target is included in the same package scheme's Test action.

The checked-in `CompatibilityTest` application scheme uses `CompatibilityTest.xctestplan` to run both the unit-test bundle and the UI-test bundle. Because UI tests run in a separate process, they launch the demo with `TESTING=1` in `XCUIApplication.launchEnvironment`, allowing `Build.isRunningTests` and the Testing environment row to report `true`. Xcode does not automatically copy the test runner's XCTest configuration into the app under test.

### Trick to generate warning that can easily be disabled without using `#warning()`:
Defaults to true so application will need to call a function during init/launch:
```swift
if false { // this will generate a warning if left as false
    debug("This should be run in init.")
}
```

### Application version tracking and firstRun checks:
This should be run in the App init.
```swift
init() {
    Application.track() // ensures Application.main.isFirstRun and Application.main.versions variables are properly set.
    if Application.main.isFirstRun {
        debug("First Run!")
    }
    debug("All versions run: \(Application.main.versionsRun)")
}
```

### Storing data to iCloud Key Value Store if available.
This is super useful so we don't have to worry about whether the user has iCloud enabled or what happens if they log out.  However, this will use either iCloud or UserDefaults.  It will not attempt to merge or migrate data between the two when switching.  Note that even if you don't use iCloud, you will need to include the entitlements file or this will try to use iCloud storage but fail to save if the user is logged in to iCloud.  The app should do the correct thing automatically and will use the last updated value per key to resolve conflicts.  If you need more fine-grained control, cache the value and monitor for changes to update the cached value.  If you use this, you will need to add an entitlement as this uses iCloud Key Value Store.  An example entitlement for the sample app can be found at ```Compatibility.swiftpm/Development/Resources/Entitlements.entitlements```
If you use a similar structure to the development Xcode project, you will want to set the `Code Signing Entitlements` build setting to `Resources/Entitlements.entitlements`.
If you have a watchOS app, you may need to set the key manually vs pulling from the identifier so that the watchOS app and the iOS app use the same store: ex: ```$(TeamIdentifierPrefix)com.kudit.CompatibilityTest``` (note there is no period before the `com`)
If you want it to automatically set and don't have a watchOS app, set the `iCloud Key-Value Store` entitlement entry to this: ```$(TeamIdentifierPrefix)$(CFBundleIdentifier)```

 This feature requires iOS 13, tvOS 13, and watchOS 9 for cloud usage as that is the minimum for NSUbiquitousKeyValueStore.  If code uses older versions, you will need to add a PrivacyInfo file since UserDefaults can be used to fingerprint.  Example file can be found in the package at ```Compatibility.swiftpm/Development/Resources/PrivacyInfo.xcprivacy``` 
 
 ```swift
 
// either specify a default value or make it an optional
 @CloudStorage("keyString") var myKey: Bool = false
 @CloudStorage("key2String") var myOtherKey: Double?
 ```

### Migrating old UserDefaults value to new @CloudStorage store when adding to apps that previously used @AppStorage or UserDefaults (do during model/app init):
```swift
// check that existing value exists in UserDefaults and that this value hasn't already been migrated.
if let existingString1 = UserDefaults.standard.object(forKey: .string1Key) as? String, !string1.contains(existingString1) { // legacy support
    debug("Migrating local string1: \(existingString1) to cloud string1: \(string1)", level: .NOTICE)
    string1 = "\(existingString1),\(string1)"
    // zero out local version so we don't do this again in the future.  If we log out of iCloud, we will lose the data but that is expected behavior.
    UserDefaults.standard.removeObject(forKey: .string1Key)
}
```

### Adding custom protocol storage support to `@CloudStorage`
```swift
public protocol CustomProtocol {
    init(string: String)
    var stringValue: String { get }
}
@available(iOS 13, tvOS 13, watchOS 6, *)
extension CloudStorage where Value: CustomProtocol {
    public init(wrappedValue: Value, _ key: String) {
        self.init(
            keyName: key,
            syncGet: { CloudStorageSync.shared.string(for: key).flatMap(Value.init) ?? wrappedValue },
            syncSet: { newValue in CloudStorageSync.shared.set(newValue.stringValue, for: key) })
    }
}
```


All these tests can be demonstrated using previews or by running the app executable that is bundled in the Development folder of the module.

### Declaring module metadata
Frameworks and packages can conform to `Module` so applications and support tools can collect versions and structured diagnostic information through one consistent contract.

```swift
public enum Support: Module {
    /// The version is kept in code because Swift packages cannot read their manifest version at runtime.
    public static let version: Version = "1.0.0"

    /// Open-source modules opt in with a repository string; private modules omit this property and receive `nil`.
    public static let openSourceRepository: String? = "https://github.com/example/Support"

    /// Register direct dependencies so callers only need to include their highest-level modules.
    public static let dependencies: [Module.Type] = [Compatibility.self]

    /// Ordered sections shared by automated runners and Compatibility's live test UI.
    @MainActor
    public static let tests: OrderedDictionary<String, [TestCase]> = [
        "Support Model": [
            TestCase("Default state") {
                try expectEqual(SupportModel().state, .ready)
            },
        ],
    ]

    /// Portable information is synchronous so it remains usable without a concurrency runtime.
    public static var moduleInfo: [Field] {
        [Field("\(moduleName) Version", version)]
    }

    /// Detailed information may await actor-isolated state, calculation, or network work.  This can include moduleInfo or customize if necessary.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    public static func loadDetailedModuleInfo() async -> [Field] {
        moduleInfo + [Field("Deferred Detail", "Available")]
    }
}
```

Register the highest-level modules once near process startup. `Application.track(including:)` automatically
includes Compatibility and recursively registers the supplied modules' dependencies:

```swift
Application.track(including: [Support.self])
```

Command-line tools and other processes that do not use `Application` can register the same graph directly:

```swift
Support.include()
AnotherModule.include()
```

`Build.allModules` preserves dependency-first registration order and keeps only the first module for each
`moduleIdentifier`. The default identifier is the fully qualified conforming type name, so modules normally
only need to declare `version`; `dependencies`, `moduleInfo`, and repository metadata are opt-in.
`Application.track(including:)` closes registration automatically before asynchronous reporting begins.
Command-line tools should call `Build.finishModuleRegistration()` after their final `include()` or
`Build.register(...)` call so late mutations are rejected while concurrent readers use `Build.allModules`.

`openSourceRepository` is stored as `String?` so it remains available in WASM, WASI, embedded Swift, and other environments without Foundation. Code that needs a Foundation URL can convert it at the point of use with `URL(string:)`.

Conformers that opt in must declare the property as `String?`. A nonoptional inferred `String` does not witness the optional protocol requirement, so the protocol extension's default `nil` would otherwise be used by generic `Module` functionality.

`openSourceLicense` is an asynchronous optional property with a default implementation where Swift concurrency and Foundation networking are supported. An `await Support.openSourceLicense` access lazily asks GitHub's repository-license API for the detected license on the repository's default branch. Private modules return `nil`; non-GitHub repositories, unsupported platforms, network failures, and repositories without a detectable license return repository guidance instead. The value is not loaded or cached as part of `moduleInfo`; callers that reuse the text should retain the returned value.

Each `Module` can expose ordered test sections through `Module.tests`. The default is empty, so modules without reusable tests need no boilerplate. `AllTestsListView(additionalTests:)` consumes the complete graph already recursively discovered and deduplicated by `Build.register`, reverses its dependency-first order for presentation, and eagerly starts every registered module test without tying execution to row visibility. Application sections appear first, top-level modules precede dependencies, and foundational modules appear last. Every module receives a name-and-version heading plus an explicit empty state when it provides no tests. `ModuleTestsListView(module:additionalTests:)` remains available for a focused single-module screen.

Compatibility's in-app test UI and Swift Testing suite share the same `TestCase` values from `Compatibility.tests`. `TestCase` deliberately avoids colliding with Swift Testing's `Test`; the old `Test` spelling remains available as a source-compatible alias. Add reusable framework checks to the conforming module's `tests` collection rather than duplicating assertions in a separate `@Test`. The parameterized Swift Testing bridge reports every Compatibility section as a separate test case in CI and Xcode.

`expect(_:)` remains the flexible Boolean primitive for live apps, previews, Playgrounds, and older systems. Prefer `expectEqual(_:_:)` and `expectNotEqual(_:_:)` for comparisons because their thrown diagnostics include actual and expected values. Swift Testing macros cannot be backported or invoked indirectly by a normal function, so the package does not make Swift Testing a runtime dependency; its Swift Testing target instead runs the same `TestCase` closures and reports their thrown failures.

`Compatibility.main` and `Compatibility.background` preserve dispatch or single-threaded fallbacks where Swift concurrency is unavailable. On concurrency-capable systems, prefer the shorter `Task.main` and `Task.background` forwarding conveniences without spelling `Task` generic arguments. `Task.sleep(seconds:)` and `Task.delay(_:)` similarly forward to the established Compatibility helpers. Source arguments remain available for source compatibility, while `SourceContext` can carry a complete file, function, line, and column snapshot through asynchronous work.

Tests that access GitHub, iCloud, the system pasteboard, or persistent CloudStorage are opt-in. Set
`INTEGRATION_TESTING=1` in the Xcode scheme, command environment, or launched in-app test process to run the
shared Integration Tests section. Normal test runs use deterministic in-memory or temporary-directory checks.

### Using the pasteboard

`Pasteboard` provides the same API across UIKit, AppKit, watchOS, tvOS, and pure-Swift builds. Apple platforms
with a general system pasteboard use it directly; platforms without one use process-local storage so code still
compiles and round-trips values without claiming to communicate with other applications.

```swift
Pasteboard.system.copy("Text")
let text = Pasteboard.system.readString()

let savedItems = Pasteboard.system.read()
defer { Pasteboard.system.copy(savedItems) }
```

`PasteboardItem` preserves ordered items and their typed raw-byte representations. The older
`Compatibility.copyToPasteboard(_:)` API remains as a deprecated forwarding wrapper.

Test apps that need stable anonymous diagnostics can set
`Application.forceUnknownAppIdentifierForTesting = true`; the override is evaluated each time the identifier is read.
Services without main-actor access can inspect nonisolated `Application.iCloudAvailable`; application code
should prefer main-actor-isolated `Application.iCloudIsEnabled`, which also respects app configuration and
unsupported runtime environments.

`Module` itself and its synchronous `moduleInfo` requirement have no concurrency availability gate. Keep values there when they can be produced immediately so older Apple systems, command-line tools, WASM, and other portable clients can report useful information. `loadDetailedModuleInfo()` is separately available on iOS 13, macOS 10.15, tvOS 13, watchOS 6, and non-Apple toolchains with a Swift concurrency runtime. Its default returns `moduleInfo`, while conformers can return the portable fields plus additional deferred information.

Swift `async` does not automatically move CPU-heavy calculations to another thread. Conformers remain responsible for selecting an appropriate actor or executor, and WebAssembly commonly uses cooperative execution rather than background threads. Modules that need application or UI state can isolate only that read with `await MainActor.run { ... }`. `CompatibilityEnvironmentTestView` displays `moduleInfo` immediately, shows loading progress, and replaces it with the complete result from `loadDetailedModuleInfo()` when ready.


## Contributing
If you have the need for a specific feature that you want implemented or if you experienced a bug, please open an issue.
If you extended the functionality yourself and want others to use it too, please submit a pull request.


## Donations
This was a lot of work. If you find this useful, particularly in a commercial product, please consider making a donation at https://paypal.me/kudit.


## License
Feel free to use this in projects, however, please include a link back to this project and credit somewhere in the app.  Example Markdown and string interpolation for the version:
```swift
Text("Open source projects used include [Compatibility](https://github.com/kudit/Compatibility) v\(Compatibility.version)")
```


## Contributors
The complete list of people who contributed to this project is available [here](https://github.com/kudit/Compatibility/graphs/contributors).
A big thanks to everyone who has contributed! 🙏
Special thanks to this project for the CloudStorage base (cleaned up for broader compatibility here): https://github.com/nonstrict-hq/CloudStorage


# Contributing

Contributor and coding-agent rules now live in [CONTRIBUTING.md](CONTRIBUTING.md), including version boundaries, prompt logging, documentation expectations, compatibility practices, and shared-test guidance.
