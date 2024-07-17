<img src="/Development/Resources/Assets.xcassets/AppIcon.appiconset/Icon.png" height="128">

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fkudit%2FCompatibility%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/kudit/Compatibility)

# Compatibility.swiftpm
Compatibility is a set of code that is designed to improve compatibility to allow using modern APIs on older platforms as well as provide simplified syntax for things.  Also includes a Debug module and a Test harness module.  Debug is a set of code that is designed for easily writing and enabling/disabling debug statements in code.  This allows for easily breaking only certain levels of statements as well as turning on/off debug code in groups and having consistent flags in the output for easier reading of debug output.  Also includes compatibility functions on Int.

The primary goals are to be easily maintainable by multiple individuals and be able to be used across all platforms.

This is actively maintained so if there is a feature request or change, we will strive to address within a week.

## Features

- [x] Threading features to make syntax easier (`main {}` and `background {}`).
- [x] Sleep feature for simple delays in tasks.
- [x] Testing framework for providing tests inline in frameworks that can be output/tested using #Previews.
- [x] Several SwiftUI features that have been added have been "Backported" so that you can use the new features on new platforms but have an automatic fallback for older platforms that do not support the feature.
- [x] Emoji prefixing of debug outputs.
- [x] Automatically including context in debug output to make finding the source of the debug easier.
- [x] Easily set breakpoints on various levels of debug statements.
- [x] Provides a simple CustomError type that can be initialized with a string for throwing errors when you don't care about the type of error thrown.

## Requirements

- iOS 11+ (15.2+ minimum required for Swift Playgrounds support)
- macOS 10.5+ (12.0+ for most SwiftUI features)
- macCatalyst 13.0+ (first version available)
- tvOS 11+ (17+ for most SwiftUI features)
- watchOS 4.0+
- visionOS 1.0+
- Theoretically should work with Linux, Windows, and Vapor, but haven't tested.  If you would like to help, please let us know.

## Known Issues
None

## Installation
Install by adding this as a package dependency to your code.  This can be done in Xcode or Swift Playgrounds!

### Swift Package Manager

#### Swift 5
```swift
dependencies: [
    .package(url: "https://github.com/kudit/Compatibility.git", from: "1.0.0"),
    /// ...
]
```

You can try these examples in a Swift Playground by adding package: https://github.com/kudit/Compatibility

## Usage
First make sure to import the framework:
```swift
import Compatibility
```

Here are some usage examples.

### Simple debug statement (can be used to replace debugging `print` statements) at the default debug level (which can be changed).
```swift
debug("This is a test string \(true ? "with" : "without") interpolation")
```

### Debug statement at a specified level:
```swift
debug("Fatal error!  This will be output to console typically even in production code.", level: .ERROR)
```

### Getting and setting the current debug level:
```swift
DebugLevel TODO
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


All these tests can be demonstrated using the previews in the file DemoViews.swift which can be viewed in Xcode Previews or in Swift Playgrounds!

## Contributing
If you have the need for a specific feature that you want implemented or if you experienced a bug, please open an issue.

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
