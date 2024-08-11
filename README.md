<img src="/Development/Resources/Assets.xcassets/AppIcon.appiconset/Icon.png" height="128">

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fkudit%2FCompatibility%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/kudit/Compatibility)

# Compatibility.swiftpm
Compatibility is a set of code that is designed to improve compatibility to allow using modern APIs on older platforms as well as provide simplified syntax for things.  Also includes a Debug module and a Test harness module.  Debug is a set of code that is designed for easily writing and enabling/disabling debug statements in code.  This allows for easily breaking only certain levels of statements and having consistent flags in the output for easier reading of debug output.  Also includes compatibility functions on Int.

The primary goals are to be easily maintainable by multiple individuals, employ a consistent API that can be used across all platforms, and to be maintainable using Swift Playgrounds on iPad and macOS.  APIs are typically present even on platforms that don't support all features so that availability checks do not have to be performed in external code, and where irrelevant, code can simply return optionals.

This is actively maintained so if there is a feature request or change, we will strive to address within a week.


## Features
- Can develop and modify without Xcode using Swift Playgrounds on iPad!
- Threading features to make syntax easier (`main {}` and `background {}`).
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
- macOS 10.5+ (UI only supported on macOS 12+)
- macCatalyst 13.0+ (first version available)
- tvOS 11.0+ (UI only supported on tvOS 15+, 17+ required for most SwiftUI features)
- watchOS 4.0+ (UI only supported on watchOS 8+)
- visionOS 1.0+
- Theoretically should work with Linux, Windows, and Vapor, but haven't tested.  If you would like to help, please let us know.


## Known Issues
*See CHANGELOG.md for known issues and roadmap*
Note that the DataStore tests only work if entitlements and privacyinfo are included (therefore, they will not be functional in Previews and Swift Playgrounds).


## Installation
Install by adding this as a package dependency to your code.  This can be done in Xcode or Swift Playgrounds!

### Swift Package Manager

#### Swift 5+
You can try these examples in a Swift Playground by adding package: `https://github.com/kudit/Compatibility`

If the repository is private, use the following link to import: `https://<your-PAT-string>@github.com/kudit/Compatibility.git`

Or you can manually enter the following in the Package.swift file:
```swift
dependencies: [
    .package(url: "https://github.com/kudit/Compatibility.git", from: "1.0.0"),
]
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
if Compatibility.isDebug {
    // execute test/debug-only code.  This will only run in DEBUG configurations and will be removed during RELEASE compilations.
}
```

### Running code on various threads and delaying execution of code:
```swift
background {
    // run long-running code on background thread
    sleep(4) // wait for 4 seconds before continuing
    delay(0.4) { // run this code after 0.4 seconds (similar to calling await sleep() and then executing code)
        main {
            // run this code back on the main thread
        }
    }
}
```

### Storing data to iCloud Key Value Store if available.
This is super useful so we don't have to worry about whether the user has iCloud enabled or what happens if they log out.  The app should do the correct thing automatically and will use the last updated value per key to resolve conflicts.  If you need more fine-grained control, cache the value and monitor for changes to update the cached value.  If you use this, you will need to add an entitlement as this uses iCloud Key Value Store.  An example entitlement that automatically pulls the identifier from the project can be found at `Compatibility.swiftpm/Development/Resources/Entitlements.entitlements` 

 This feature requires iOS 13, tvOS 13, and watchOS 9 for cloud usage as that is the minimum for NSUbiquitousKeyValueStore.  If code uses older versions, you will need to add a PrivacyInfo file since UserDefaults can be used to fingerprint.  Example file can be found in the package at `Compatibility.swiftpm/Development/Resources/PrivacyInfo.xcprivacy` 
 
 ```swift
 
// either specify a default value or make it an optional
 @CloudStorage("keyString") var myKey: Bool = false
 @CloudStorage("key2String") var myOtherKey: Double?
 ```

All these tests can be demonstrated using previews or by running the app executable that is bundled in the Development folder of the module.


## Contributing
If you have the need for a specific feature that you want implemented or if you experienced a bug, please open an issue.
If you extended the functionality yourself and want others to use it too, please submit a pull request.


## Donations
This was a lot of work.  If you find this useful particularly if you use this in a commercial product, please consider making a donation to http://paypal.me/kudit


## License
Feel free to use this in projects, however, please include a link back to this project and credit somewhere in the app.  Example Markdown and string interpolation for the version:
```swift
Text("Open Source projects used include [Compatibility](https://github.com/kudit/Compatibility) v\(Compatibility.version)
```


## Contributors
The complete list of people who contributed to this project is available [here](https://github.com/kudit/Compatibility/graphs/contributors).
A big thanks to everyone who has contributed! 🙏
Special thanks to this project for the CloudStorage base (cleaned up for broader compatibility here): https://github.com/nonstrict-hq/CloudStorage
