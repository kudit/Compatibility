<img src="/Development/Resources/Assets.xcassets/AppIcon.appiconset/Icon.png" height="128">

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fkudit%2FCompatibility%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/kudit/Compatibility)

# Compatibility.swiftpm
Compatibility is a set of code that is designed to improve compatibility to allow using modern APIs on older platforms as well as provide simplified syntax for things.  Also includes a Debug module and a Test harness module.  Debug is a set of code that is designed for easily writing and enabling/disabling debug statements in code.  This allows for easily breaking only certain levels of statements and having consistent flags in the output for easier reading of debug output.  Also includes compatibility functions on Int.

The primary goals are to be easily maintainable by multiple individuals, employ a consistent API that can be used across all platforms, and to be maintainable using Swift Playgrounds on iPad and macOS.  APIs are typically present even on platforms that don't support all features so that availability checks do not have to be performed in external code, and where irrelevant, code can simply return optionals.


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
```

In Xcode, open the package, select the automatically discovered `compatibilityCLI` scheme, choose **My Mac** as the run destination, and run it with the desired arguments. The `CompatibilitySwiftPMTests` target is included in the same package scheme's Test action.

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


# Styleguide (for contributors and agents)
When updating versions, please be sure to update the hardcoded versions to be in sync with the most recent Changelog entry: Package.swift version variable, Xcode project MARKETING_VERSION property, and module version constant (if this is a module).

## Changelog rules:
- Keep Changelog entries in `## vX.X.X YYYY-MM-DD` format, with short line-separated notes under the current version.
- Before editing the active changelog entry, compare the top changelog version with the latest committed Git version.
- If the top changelog entry is the same version as the latest committed Git version, create a new version entry and update the hardcoded version numbers in the package, library constant, and Xcode project settings.
- If the top changelog entry does not match the latest committed Git version (or there is no Git version), do not update the hardcoded versions; append notes to the current changelog entry instead.
- For every prompt-driven change, append the prompt text to the current changelog entry as `PROMPT: [PROMPT TEXT]`.  Prompt lines are useful working context; keep them in private app repos, but review or remove private prompt text before public commits.
- The prompts should follow the concise changelog descriptions separated by a blank line.
- If a project does not have a changelog, offer to create one using the same general format as this repository's `CHANGELOG.md`.
- Modules should have separate README.md and CHANGELOG.md files.  Final apps may simply have a README.md with a Changelog section near the top.
- Changelog sections should be as follows (regardless if this is a Swift project or other script or code):
```
# Changelog

## vX.X.X YYYY-MM-DD
Description

[PROMPT:]

## Known Issues
Known issues and bugs that need to be addressed.
- [ ] List near-term planned work. This should be more actionable than the general future-request section and should focus on likely next implementation items, known technical improvements, and release blockers.  Vibecoding prompts can be included here as well.

## Roadmap
Planned features and anticipated API changes.  If you want to contribute, this is a great place to start.
Group by future version numbers.

## Proposals
This is where proposals can be discussed for potential movement to the roadmap.
- [ ] Future Version Feature Requests. List longer-term ideas, speculative features, UX improvements, technical debt, privacy updates, platform expansion ideas, monetization improvements, and references/links for future research.  This section may be informal and can include copied notes, links, partial ideas, and implementation sketches.
```

## Code style rules:
- Preserve existing behavior, public identifiers, legacy compatibility paths, and user-visible syntax unless the prompt explicitly asks for a breaking change.
- Keep code changes tightly scoped to the requested behavior and the surrounding local patterns.
- When adding or modifying code, include clear inline comments that explain what the new code is doing and why it is necessary.
- Prefer succinct comments for obvious code and changelog summaries, but use complete documentation and inline comments around code particularly when the implementation affects compatibility, migration, or platform-specific behavior.
- Preserve existing wording, formatting, and documentation style where practical. New sections should blend into the surrounding style rather than rewriting unrelated documentation.
- Preserve existing comments unless they are clearly obsolete or the prompt explicitly requests cleanup.
- To make diff reconciliation easier, make sure there is a comment at the top of every changed section indicating the reason for the changes.  These can be concise.
- When generating copy intended to be pasted into files, GitHub, Xcode, or terminals, prefer plain Markdown/code blocks rather than ChatGPT's rich editing UI unless the user explicitly requests an editable draft.

## Swift rules:
- Include `github.com/kudit/Compatibility` as a dependency for Swift projects and leverage its features and affordances whenever possible rather than writing helper functions.
- Use Compatibility's `debug()` function for logging rather than `print()`.
- Err on the side of being too verbose in Swift documentation and comments so future compatibility decisions remain clear but don't be unnecessarily verbose (clarity is key).
- When implementing features, prefer compatibility paths over removing older behavior. Existing APIs and legacy behavior should continue to function unless a breaking change is explicitly requested.
- Keep changes narrowly scoped to the requested work. Avoid unrelated refactoring unless it was requested or materially improves the requested feature.
- When creating modules, there should be a separate CHANGELOG.md and a README.md file with implementation instructions.  Apps should use the styleguide below for just a `README.md` file with a Changelog section at the top.

## Design Goals:

- Backwards compatibility where practical.
- Consistent APIs across Apple platforms.
- Well documented public interfaces.
- Minimal breaking changes.
- Swift Playgrounds compatibility whenever possible.


# App Store Styleguide
Included for reference and utility and as a best practices model.  Feel free to substitute your own style guide or suggest improvements.
Keep the `README.md` practical as both a developer working document and App Store preparation document.

PROMPT For new apps:
```
Use github.com/kudit/Compatibility as a dependency. Adopt the coding style and README/changelog instructions at the bottom of that project's README.md. Generate a README.md following the Compatibility App Store Styleguide. Reconstruct the implementation history represented in this conversation into changelog entries, creating one version per prompt: v0.0.1 for the first prompt, v0.0.2 for the second prompt, and so on. Each entry should include the prompt text plus a succinct summary of decisions, instructions, and changes. Swift apps should prefer Compatibility APIs where relevant, including debug() instead of print(), Application.track(), and Compatibility JSON/string/date helpers.
```


README.md Outline:
```
# App Name

[Optionally include outstanding bugs and issues or prompts that need to be addressed BEFORE pushing changes and locking the version.]

# Changelog
Maintain a reverse-chronological changelog, newest version first using the rules above.
Each entry should follow the same format indicated above, except if this release is targeted for the App Store, the simple user-facing App Store changes to use as the public "what changed in this version" release notes for that version should be first, followed by **App Store Updates above** on its own line as a separator, followed by any internal developer focused changes.  If there is a new version that isn't submitted to the App Store in between, the App Store Updates section should be moved up to the top until those changes are pushed to the app store with that version.
Example:
v0.0.1 2026-07-06
User-facing note
**App Store Updates above**
Internal developer note

PROMPT: Included here but changes should be described in such a way that this line can be safely removed before committing.

# App Store Copy

## Title
[App Store Title]

## Subtitle (30)
123456789012345678901234567890
[Subtitle.  Uses the monospacing numbers above to ensure that it fits in 30 characters]

## Promotional Text (170)
Write App Store promotional text. Keep the heading’s character limit visible. The text should be short, direct, and marketing-oriented.

## Description (4,000)
Write the full App Store description. Keep the heading’s character limit visible. Include:
* Clear opening value proposition
* Main use cases
* Key features
* Paid/free behavior if relevant
* Privacy or data-handling notes if relevant
* Support/contact information
* Terms or policy URL if needed

## Keywords (100)
1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
[List App Store keywords. Keep the heading’s character limit and the reference numberline visible. Use comma-separated keywords and preserve the 100-character target/limit awareness.  Commas should not be followed by a space to save characters.]

## Pricing Analysis
[Document pricing assumptions, monetization logic, historical pricing changes, subscription tiers, consumables, unlocks, ad behavior, and any notes about how paid/free usage works.]
[Include date-based pricing sections when pricing changes over time.]

# Legacy Information
[Include any legacy information we don't want to delete but may not be relevant anymore.]
[Only public libraries need public-safe cleanup. Private app READMEs may keep PAT references, App Review notes, DTS history, upload warnings, pricing experiments, and other working context when useful.]
```
