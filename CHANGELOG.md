# ChangeLog

NOTE: Version needs to be updated in the following places:
- [ ] Xcode project version (in build settings - normal and watch targets should inherit)
- [ ] Package.swift iOSApplication product displayVersion.
- [ ] Compatibility.version constant (must be hard coded since inaccessible in code)
- [ ] Update changelog and tag with matching version in GitHub.

v1.11.27 10/5/2025 Missed a conditional check around the date requirement of `DateStringRepresentation` since this isn't present in WASM.

v1.11.26 10/5/2025 Added back `DateString` as a type so that we can use in WASM as a type (but without working date features).

v1.11.25 10/5/2025 Added `CaseNameConvertible` stub for WASM so that it can be used but until we have a backport, there will not be a way to get this to work on WASM.

v1.11.24 10/4/2025 Fixing errors with macOS availability checks.

v1.11.23 10/4/2025 Fixing errors with version dependencies.

v1.11.22 10/4/2025 Removed import for `.rainbow` to prevent circular dependencies and simply have a private implementation of `.rainbow`. ** BROKEN **

v1.11.21 10/4/2025 Tried to re-work color inclusion in `ClosureTestView` so that import of Color will properly overwrite when compiling.  Impossible due to cyclic inclusions? ** BROKEN **

v1.11.20 10/3/2025 Added additional WASM fix in Test.

v1.11.19 10/2/2025 Added `main {}` backport for WASM so we don't have to adjust code.  Attempted to address `any Error` embedded swift error by removing `expect()` func from WASM. **Supports all platforms EXCEPT WASM but passes all other Swift Package Index Checks!**

v1.11.18 10/1/2025 Additional WASM exclusions.  Added additional test functionality for symbols in ClosureTest. **Supports all platforms including WASM and Android and passes all Swift Package Index Checks!**

v1.11.17 9/30/2025 Additional WASM exclusions.  Added alternate implementation of `debug()` to avoid dynamic casting to `Any`. **Supports all platforms EXCEPT WASM but passes all other Swift Package Index Checks!**

v1.11.16 9/29/2025 Additional WASM exclusions to enable clean compile on WASM.  Not sure why Foundation check is passing on WASM.  **Supports all platforms EXCEPT WASM on Swift 6.2 beta but passes all other Swift Package Index Checks!**

v1.11.15 9/28/2025 Additional WASM fixes.  Added Double(String) backport when Foundation isn't available.  **Supports all platforms EXCEPT WASM but passes all other Swift Package Index Checks!**

v1.11.14 9/28/2025 Added additional WASM gates. (os(WASM) OR os(WASI)) => (os(macOS) OR os(iOS)) for testing.

v1.11.13 9/27/2025 Fixed weird fallback code but only in test so just removed.  Added additional WASM gates around codable.  **Supports all platforms EXCEPT WASM but passes all other Swift Package Index Checks!**

v1.11.12 9/26/2025 Fixed AppIconWatch being included in Watch App.  Fixed issue with MixedTypeField Int not being able to be converted to Double.

v1.11.11 9/26/2025 Additional Android/WASM fixes.  Added #if canImport(Android) and os(WASI) (in addition to WASM).

v1.11.10 9/25/2025 Fixed tvOS issues.  Removed `@MainActor` from WASM builds by adding !os(WASM) (os(WASMX#) -> !os(WASM#))

v1.11.9 9/24/2025 Added import for Color to the RadialLayout preview so that included packages won't warn.  Change MixedTypeFieldDictionary to default to an unordered dictionary so JSON encoding matches and cleaned up and simplified and optimized code.  This will mean that the output is inconsistent but that’s what the `sortedKeys` option is for.  Added Backport for `controlSize`.  Re-worked all the `swiftUIValue` conversions to be consistent.  Re-worked `firstKey` extension to work on any DictionaryConvertible so that it works on ordered dictionaries as well. **Fails tvOS**

v1.11.8 9/23/2025 Fixed issue on visionOS (Glass is not supported there). **Supports all platforms EXCEPT WASM in 6.2 beta but passes all other Swift Package Index Checks!**

v1.11.7 9/22/2025 Re-worked `AStack` so that we can get the orientation chosen in the body block should we need to add different layouts in different orientations. Did require type-erasure via AnyView unfortunately.  If you know of a better way to do this, let me know.  Also fixed warning about Watch icon by separating into a separate icon set.

v1.11.6 9/20/2025 Made trimmed functions on StringProtocol rather than String to make easier when splitting strings.  Changed `appendUnique` and `containsAny` and `containsAll` to require `Equatable` rather than `Comparable`. **Supports all platforms EXCEPT WASM in 6.2 beta but passes all other Swift Package Index Checks!**

v1.11.5 9/18/2025 Fixed issue with certain Application functions accidentally not being public anymore.  **Supports all platforms including WASM and Android and passes all Swift Package Index Checks!**

v1.11.4 9/18/2025 Added some fixes for test cases to bring code coverage to 87% without Foundation, 58% with.

v1.11.3 9/18/2025 Added some additional backports for when Foundation is missing.  Changed Application from requiring Foundation and Combine to having different definitions when Foundation is available allowing most of the compiler checks to be valid even without Foundation or Combine.  Added back Testing framework when Foundation is missing, just excluding tests that require Foundation.  Improved DoubleConvertible to piggy back on BinaryInteger and BinaryFloatingPoint for larger compatibility.  Added MixedTypeField bridge for Foundation-less JSON encoding and decoding.  **Supports all platforms including WASM and Android and passes all Swift Package Index Checks!**

v1.11.2 9/15/2025 Fixed some broken code when Foundation is missing.  Added backport of `components(separatedBy:)` in that case.  Removed test using `localizedDescription` when Foundation is missing.  Removed `retroactive` from Swift < 6.0.  Added lots of tests but somehow code coverage was reduced to 49%.

v1.11.1 9/14/2025 Fixed issue with default value string optional being too generic and conflicting with default String implementation.

v1.11.0 9/14/2025 Removed more functions and added fallback for when Foundation is not available (like WASM).  Fixed `.glassEffect()` backport.  Made default value string optional more generic to account for Character? or Numeric?.  Added `prettyJSON` output convenience var.   Added compact version of Version.  Upgraded PropertyIterable to allow for fetching KeyPaths and now when fetching properites, they are an OrderedDictionary rather than an unordered one.  Added `MixedTypeField` for decoding mixed type JSON arrays.  Added tests to bring test coverage to 57%.

v1.10.18 8/25/2025 Apparently forgot to actually add `glassEffect()` backport in v1.10.16. Also added `statusBarHidden()` backport since unavailable in tvOS, etc.  Enabled `backgroundMaterial()` in iOS 13 and adjusted fallback behavior.  Added iOS 26 icon (doesn't work?).  Added `compilerVersion` since this reports differently from `swiftVersion` apparently.

v1.10.17 8/13/2025 Fixed issues with WASM and Watch OS errors.  Added Backport.Material for bridging when Material is not available.  Added check for Foundation support where needed.  Threading and several other bits of functionality now require Foundation to use.  Several other pieces can still be used without Foundation. Added tests to bring test coverage to 56%.   ** ALL SWIFTPACKAGEINDEX TESTS PASSED! ** 

v1.10.16 8/11/2025 Added `presentationBackground()` to the demo.  Added `AdaptiveLayout` and `AStack` (test in material sheet). (Failed watchOS and WASM with Swift 6.2 beta)

v1.10.15 6/11/2025 Addressed Thread Sendable and Dispatch issues by adding a fallback for WASM and Android.  **Supports all platforms including WASM and Android and passes all Swift Package Index Checks!**

v1.10.14 6/11/2025 Removed circular dependency on Color and reverted to extension.  Color version should be used externally when included since Compatibility rainbow extension is not public.

v1.10.13 6/11/2025 Added Color import when available for RadialLayout preview (so builds when included with Color framework.)

v1.10.12 6/11/2025 Fixed issue where [Color] not available on non-Apple platforms.  Added missing Thread in WASM and Android by backporting stubs.

v1.10.11 6/10/2025 Extracted `.rainbow` included for previews to use the Color version when available.  Improved RadialLayout preview.  Added public initializer for RadialLayout so can be used outside project.  Removed warnings running in Swift Playgrounds for Application tests.  Note: When building, Swift Playgrounds 4.6.4 currently has a bug where it has trouble choosing the root application target rather than included module app targets which causes issues for #Previews.  Removed requirement of Darwin.C when not Linux and can't import Darwin (was the cause of WASM and Android compile failures).  Removed odd instances of availability checking for tvOS 20 (which now that we have tvOS 26, that passes).  Added Collection conformance to OrderedSet.  Added tests to bring test coverage to 47%. (Failed Linux, WASM, Android)

v1.10.10 6/6/2025 Added public visibility of Visibility backport.  Added `persistentSystemOverlays` backport.  Added tests to bring test coverage to 46%.  Updated Version string parsing.  Added a failable initializer for parsing strings.  Updated the implementation of the `string:defaultValue:` initializer.  Fixed so version character stripping isn't just trimming.

v1.10.9 5/14/2025 re-worked compiler directives to fix issues with Linux visibility.

v1.10.8 5/14/2025 Pulled `swfitVersion` to `Application` from `Device.CurrentDevice` so we can show what version the Playground is running.  Find a way to expose swift Playgrounds version.)  Added tests and added `debugSuppress` closure.  Added `debugLog` function for changing how messages are output.  Test coverage increased to 45%.  Updated conditionalized Playground code in Package (starting in 4.6, `#if SwiftPlaygrounds` is available).  Now does seem to work in Swift Playgrounds 4.6.4 again!

v1.10.7 5/4/2025 Fixed bug with Linux SPI Test missing isURL in asURL function.  Fixed some bugs with differences in Linux code.  Tests came in handy here.  Added better backport for `backportPath`. *PASSES ALL SWIFTPACKAGEINDEX TESTS (including Swift 5.8 - 6.1!)*

v1.10.6 5/4/2025 Added Int.string to quickly do String(value) so that it can be output without commas.  Added `containsAll` to String and Collections.

v1.10.5 5/4/2025 Fixing bug with Linux SPI Test.  Added `Date.yesterday` and `Date().previousDay`.  Added `Double().isInteger` test.  Added additional tests bringing code coverage to 42%.  Noted that adding OrderedDictionaries does not seem to work... *FAILS LINUX SPI TEST*

v1.10.4 5/4/2025 Updated so that levels that include timestamps can be customized.  Added debug tests.  Fixed so setting the default debug level AFTER being set actually changes the value.  Changed so `DebugLevel.currentLevel` and `.defaultLevel` reference the settings and aren't set at init so they can be changed by tests.  Need to ensure this doesn't violate any concurrency issues... Additional tests added bringing code coverage to 35%.  Added `.backport.scrollViewDisabled()`.  Added Pasteboard manipulation.  Fixed bug in `trimming([String])` where it was only trimmed once rather than repeatedly for all terms until finished. *FAILS LINUX SPI TEST*

v1.10.3 4/28/2025 Fixed typo with date of 1.10.2. Moved where the breakpoint check happens in `debug()` so that it happens AFTER printing the error to the console for easier debugging. Added documentation for `caseName`.  Added additional Int tests.  Only flag if packages fail tests from now on.  Otherwise, assume all swift package index tests pass (removing *PASSES ALL SWIFTPACKAGEINDEX TESTS (including Swift 5.8 - 6.1!)* from below to clean up change log).  Still fails in Swift Playgrounds 4.6.4  (FB17377610) but should work in 4.6.0—3.

v1.10.2 4/26/2025 Added `String.collapse()`.  Added `allCharacters` and `asString` to `CharacterSet`.  Added `String.lines`.  Added `String.whitespaceStripped`.  Added additional tests.

v1.10.1 4/25/2025 Added `Sendable` conformance to `DateString` and `DateTimeString`.

v1.10.0 4/25/2025 Added `DateTimeString` and `DateString` types (structs with underlying String backing) for clearer storage of Date strings.  Moved all date formatting code to `DateString.swift` so formatting can be used on `Date` or `DateString` or `DateTimeString`.  Changed `numericDateFormat` to `numericDateTimeFormat` for consistency and clarity.  NOTE: This is a breaking change but if you're using `Date.numericDateTime` this won't change.  Improved tests so that failing tests will fail testing.  Added several additional test coverage.

v1.9.9 4/24/2025 Added @discardableResult wrapper to debug wrapper.  Tested old package format for swift playgrounds (still needs to be different now).  Renamed `MySQLDateString` to `MySQLDateTimeString`.  Added `Date.mysqlDate` (separate from `mysqlDateTime`).  Added additional Date tests for code coverage.

v1.9.8 4/20/2025 Fixed issues with running in Swift Playgrounds (Testing code was being included and we needed to condition out).  Consolidated duplicate `#if` statements in Package.swift for clarity. 

v1.9.7 4/17/2025 Fixed visibility issue with tests being inaccessible in conditional compilation.  Moved tests outside availability checks.

v1.9.6 4/17/2025 Fixed issues where @CloudStorage was unavailable due to conditional removal.

v1.9.5 4/17/2025 Added Swift Testing so we can check code coverage.  Removed all deprecated functions from testing by adding `#if !DEBUG`.  Moved `namedTests` to `Tests` rather than UI.

v1.9.4 4/16/2025 Fixed build issues for Linux under Swift 5.8.  Added explicit `return`s since assumed returns and simplified syntax isn't available until Swift 5.9.  `CloudStorage` now requires Swift 5.9.

v1.9.3 4/16/2025 Reordered keywords for `nonisolated(unsafe)` and added conditional compilation to hopefully prevent errors in Swift 5.9.  Attempted to better handle compiler checks for Swift 5.8 to maintain compatibility.  Now requires Swift 5.9 for anything that might have an @available check (so most UI code).

v1.9.2 4/16/2025 Updated year in copyright and forced so copyright stays current.  Fixed Swift Playground asset warnings (Xcode as playgrounds still has duplicate build warnings).  This was helpful: https://sarunw.com/posts/how-to-fix-duplicate-references-warning/

v1.9.1 4/15/2025 Fix concurrency errors and Linux errors.

v1.9.0 4/14/2025 Crafted entire settings override framework for package configuration settings. Created method for customizing Compatibility settings (and other package settings) using SwiftSettings flag.  Added instructions to the README.  Changed CustomErrors to be structs instead of enums so we can include contextual information for custom handling.  Added ability to add timestamp to `debug()` calls for scripts.

v1.8.1 3/28/2025 Fixed so `safeShell()` is on `Compatibility` and is public.

v1.8.0 3/28/2025 Added `backportPath` on URLs and added encoding tests.  Added `isDirectory` to URLs.  Added `safeShell()` method of shell execution (only available in macOS).

v1.7.1 3/24/2025 Added `bottomBackport` test and fixed so works on macOS.  Re-worked `tomorrow` to use new `nextDay` and `firstMoment` functions.

v1.7.0 3/12/2025 Changed so `normalized` returns a non-optional.  This is technically a breaking change (hence the minor version increment) but hopefully usage is minimal (plus the fix is easy by simply removing any forced unwraps or checks).  Added backport `navigationDestination` and `textSelection`.  Moved Triangle Showcase up so can test on Apple TV (seems to cut tabs after this).  Fixed crashing issue with iOS 15 and `BackportNavigationStack`/`.navigationWrapper()` code. (Renamed NavigationStack to BackportNavigationStack to prevent unintented naming conflicts.)

v1.6.8 3/10/2025 Fixed since `.focusable` is not available in iOS < 17.  Fixed missing package version update in v1.6.7.  Found a fix for packages and Swift Playgrounds v4.6+ (the iOSApplication name needs to be DIFFERENT whereas previous versions required it to be the SAME).

v1.6.7 3/10/2025 Shifted around `Version.zero` to non-constrained extension to make more sense.  Added `resetVersionsRun()` for testing.  Fixed internal scoping of String versions run keys just in case we need to use outside the framework.  Added `tomorrow` and `tomorrowMidnight` date values.  Added test section for output formats.  Improved `Backport.LabeledContent` for compatibility with older devices (but now requires iOS 15 to use).  Removed pageViewStyle from TabViews on tvOS since it doesn't really work. 

v1.6.6 2/28/2025 Fixed internal `Version.zero` (doh!).

v1.6.5 2/28/2025 Cleaned up redundant code for `Date.pretty()`.  Works fine under Swift Playgrounds 4.5.1 but not under Swift Playgrounds 4.6.2 (and 4.6?).  Added `Version.zero`. 

v1.6.4 1/17/2025 Added debugging output when replacing the identifier in preview/playground environment to fix issue with Score identifier being com.kudit.Score-.  Added check to prevent preview output alerting that iCloud doesn't work from spamming the logs.  Added in app name and identifier to compatibility info.  Fixed unnecessary check for iOS warning in Backport.

v1.6.3 1/15/2025 Added some documentation to `asJSON()` function.  Fixed internal definition of Triangle initializer.

v1.6.2 1/14/2025 Fixed double encoding of ampersands in `htmlEncoded` strings due to random access nature of dictionaries.  Added test.  Added double quote `"` to `&quot;` encoding. 

v1.6.1 1/14/2025 Fixed build limited availablility issue with watchOS.

v1.6.0 1/14/2025 Added `pluralEnding()`.  Added `.backport.onTapGesture {}`.

v1.5.4 12/6/2024 Added Backport.LabeledContent().  Added Date support to @CloudStorage.

v1.5.3 11/29/2024 Attempted additional fixes to support Swift 5.8.  Assumed returns are made explicit.  Apparently neither `swift(` or `compiler(` work in linux with swift 5.8 for SPI, so giving up again.

v1.5.2 11/28/2024 #Preview isn't the issue, it's literally the @available checks we need to filter out.  `swift(` doesn't seem to work so trying replacing them all with `compiler(`.

v1.5.1 11/26/2024 Added `#if swift(>=5.9)` checks around `#Preview` macros which aren't supported in Swift 5.8.  If this doesn't work, try replacing `#if swift(` with `#if compiler(`.

v1.5.0 11/26/2024 Removed duplicate `delay` code to fix errors with Swift 6.  Does mean that some code may not work and will need to be adjusted (if you need `delay { @MainActor in`, simply do `delay { main {` instead).

v1.4.11 11/26/2024 Fixed so `scrollContentBackground` works on iOS 15.  Added a test to demonstrate.

v1.4.10 11/26/2024 Addressing additional conversion issues that might be issues with Swift 6 for Swift Playgrounds iPad.  Added some additional `@MainActor` annotations for compatibility in Swift Playgrounds iPad.

v1.4.9 11/25/2024 Addressing Swift 6 errors with using sync from non-isolated context.  Reduced requirement to Swift 5.8 to see if we can now pass additional Swift Package Index tests.

v1.4.8 11/22/2024 Added `.fraction` option for backport `presentationDetents` and added test in `MaterialTestView`.  Also fixed missing version update in Compatibility.swift.

v1.4.7 11/21/2024 Fixed issue with watchOS failing due to lack of `compact` product style.

v1.4.6 11/20/2024 Restored package version to Swift 5.9 since 5.8 doesn't seem to work in SPI.  Added documentation to fill(strokeWidth:) function to be clear this is the Compatibility version.  Added synchronization button for DataStore test UI.  Added additional backports.  Added UIRequiresFullScreen key to info to silence warning when building iPad versions. 

v1.4.5 11/5/2024 Changed package version to Swift 5.8 to see if this will work to get all checks in Swift Package Index (does not).  Restored URL comparison but deprecated for transition assistance.

v1.4.4 11/4/2024 Removed circular dependancy on Color.

v1.4.3 11/4/2024 Added import of Color when available in Radial Layout previews.

v1.4.2 11/4/2024 Added OverlappingStack and RadialLayout.

v1.4.1 11/4/2024 Added compiler check for Threading `background` tasks so that warnings are silenced in Swift 6 but still works in Swift Playgrounds.  Removed URL comparison since causes warnings in Swift 6 and doesn't seem used most places (and where used, can simply reference the path comparison that it wraps).  Fixed issues with watchOS.  Fixed compile issues with Linux by removing `iCloudToken` variable.  Addressed @retroactive warnings in a way that works with Swift Playgrounds.  Added Embossed modifier.

v1.4.0 11/4/2024 Fixed some preview issues with legacy deprecated compatibility code.  Added `scrollContentBackground` backport.  Added `safeAreaPadding` backport.  Added `disableSmartQuotes` view modifier.  Can simulate @CloudStorage acting like UserDefaults by setting `Application.iCloudSupported = false`.  Removed cloud monitoring notifications when using UserDefaults.  Added `.precision(significantFigures)` output for Doubles.

v1.3.16 10/23/2024 Updated Compatibility version key to include SF Symbol versions.  Added `debugVersion` string to `Application` so can add debug flag if compiled for debug and don't have to use version.rawValue to use in string interpolation.  Added `numericFormat` as another `Date` format and `numericDateTime` as a quick value.  Added `buildNumber` and `buildDate` features to `Bundle`.  Extracted `Bundle` extension to it's own file.

v1.3.15 10/13/2024 Attempting to fix Linux issue by refactoring HTML entities to use a loop rather than a long concatenation.

v1.3.14 10/13/2024 Attempting to fix Linux issue.  Possibly related to warnings since Swift 6?  We can't address those until Swift Playgrounds updates for Swift 6.  Tried a conditional compile but Xcode still sees as Swift 5.10 (but maybe this will fix enough for Linux?).

v1.3.13 10/13/2024 Fixed so HTML entities doesn't encode ASCII characters and orders ampersand encoding first so we don't end up with duplicate encodings of encodings.

v1.3.12 10/12/2024 Added HTML entities conversion.

v1.3.11 10/9/2024 Fixed missing availability check on `fetchURL`.

v1.3.10 10/9/2024 Improved error checking to report missing entitlements for network connectivity.  Added `Data` return version of `fetchURL` that works similarly with the same error checking that is used under the hood by `fetchURL`.  Added ability to easily log an error at the throwing site rather than having to debug at the catching site.  Changed errors from having a description to having a localizedDescription to better conform to the error protocol.  Should still work for output.

v1.3.9 10/9/2024 Fixed so builds run from Playgrounds app returns the proper identifier for Kudit Connect.  Also noticed that the version number previously was not updated anywhere!

v1.3.8 10/7/2024 Fixed issue with Placard initializer being internal.  Has several issues with Swift 6 that can't be fixed until Swift Playgrounds is updated as the fixes are errors in Swift Playgrounds.  Added example Settings for macOS.

v1.3.7 8/16/2024 Added automatic mapping for `@CloudStorage` where value is a `RawRepresentable` type that is a Double.  Added instructions for automatic mapping to custom types.

v1.3.6 8/14/2024 Specified `.description` for issues with Swift 5.9 not being able to interpolate.  Added more fault-tolerance to `Version` parsing by trimming any non-numeric characters.  Added pretty output of `[Version]` for display.  Changed `Application` to a `@MainActor class` and removed `CustomStringConvertible` conformance since realistically, we'll want the same instance not a copy.  Hopefully this will address the last of the data race and Swift 5.9 errors.

v1.3.5 8/13/2024 Tweaked threading code to hopefully fix all data race errors.

v1.3.4 8/13/2024 Fixed watchOS app testing (needed to add/remove keys in Info.plist and update Entitlements to be hard-coded not dynamic).  Added test for when iCloud not available to use `UserDefaults` store.  Changed `iCloudSupported` test to assume supported on devices since this works even when logged out.  Simplified initialization of `CloudStorageSync`.  Improved appearance and behavior of `ClearableTextField` for better experience on Apple Watch (wasn't working at all before).

v1.3.3 8/13/2024 Fixed issue for Linux and data race error.

v1.3.2 8/13/2024 Fixed bug with sendable closure for `delay` by adding @MainActor versions.

v1.3.1 8/12/2024 Addressed some data race errors and Linux compatibility issues.

v1.3.0 8/12/2024 Fixed Environment checks not being public.  Fixed so `ClearableTextField` will gain focus when pressing clear button (but now requires iOS 15).  Fixed so `CloudStorageSync` works in Playgrounds.  Added `Application` for Monetization.  Moved environment checks back to `Application` now that it's included.  Moved CloudStorageSync var to static func so it doesn't pollute the global namespace.  Reduced version requirement for propertywrapper so Application doesn't have to be completely marked and can fallback to UserDefaults for older OS versions.  Added backport compatibility for `@Published` (may not actually work for updating views however).

v1.2.7 8/11/2024 Fixed a couple more data-race safety errors.  Made test closures sendable.

v1.2.6 8/11/2024 Addressing data-race error and Linux compatibility.  Added additional check for 2017 platforms to gate against linux but allow code in older iOS.

v1.2.5 8/10/2024 Tweaked [Version] RawRepresentable to be more universal and not Compatibility specific.  Improved checks so that @CloudStorage can be used in older versions of watchOS, it just will use UserDefaults instead.  Restored DataStore for fallback compatibility.  Updated README with examples.  Fixed runtime publishing data-race errors.

v1.2.4 8/10/2024 Attempting to fix linux support.

v1.2.3 8/9/2024 Fixed several data race safety issues.  Fixed linux support. 

v1.2.2 8/8/2024 Standardized Package.swift, CHANGELOG.md, README.md, and LICENSE.txt files.  Standardized deployment targets.  Added DataStore code and added tests.  Added Date.nowBackport for supporting earlier versions.  Moved Environmental checks from Device so we can use in more places and needed for testing DataStores in previews.  Added `asDictionary()` method for Codable objects similar to `asJSON()`.  Standardized ordering and labelling of all `available` checks to iOS, macOS, tvOS, watchOS, visionOS (the order in which each platform got swift language support).  Also removed unnecessary `.0` from versions and unnecessary `macCatalyst` checks.  Fixed `Version` so that when encoded it stores as a `String` instead of as a struct.  Changed `Compatibility` to enum since it isn't really a structure and avoids accidentally instantiating.  Updated `ClearableTextField` to only update value when the field looses focus instead of every character (also fixed issue where that was not public).

v1.2.1 7/27/2024 Moved fetchURL code into a Compatibility extension so can specifically target.  Doh!  Debug was printing at the right time I think, they were just set to .SILENT!  Fix for data race error.  Added additional sendable conformances on enums and made FileManager extension public.  Changed documentation for delay to be clear it runs on the same thread and doesn't force to main or background.

v1.2.0 7/25/2024 Added additional onChange 2 parameter compatibility version and added ability to specify initial setting (and added documentation to match the new (current) implementations).  Moved threading functions into static Compatibility functions so that we can reference in case we're in a class that shadows the same function name (like running background {} from within a view that is trying to create a view).  Added returning background { } calls for cases where we need to await the results of the long-running background task.  Re-worked debugLevel features of debug statements so we aren't switching threads with the print statement to ensure debug statements output immediately and don't get printed out of order.  Added Compatibility.isDebug flag for testing if we've built for release or debug.  Added additional Backport code including `scrollClipDisabled()`.  Added set additions for OrderedSet and OrderedDictionary and added merging/interoperability between OrderedDictionary and Dictionary.

v1.1.0 7/19/2024 Added withoutZeros function to Double.  Added .backport.navigationTitle() function for older iOS.  Fixed JSON coding issue (since we're using codable, don't need to verify that all the contents are actually JSON supported NSObjects).  Added additional version tests.  Added injection tests with a count to include expected failure and run count.  Fixed so debug breakpoints are accessible from the proper thread instead of being stranded on the main thread.  Added Placard shape.  Added Triangle shaped.  Fixed .backport.background(color)

v1.0.18 7/17/2024 Added license usage example.  Added ability to pass in additional tests to the AllTestsListView(["Section Name": tests, "Section Name 2": tests2]).  Added fix for OperatingSystemVersion in swift Playgrounds (needed to do typalias wrapper trick).  Needed to make Linux hack of ObservableObject have public send() function to prevent complaints about internal acccess.  Added OrderedDictionary and OrderedSet based on swift-collections code but simplified (originally tried adding swift-collections as a dependency but it doesn't support watchOS 4).

v1.0.17 7/15/2024 Fixed build failures for watchOS and Linux due to ByteView SwiftUI non-conditional inclusion.  Updated icon for new themeing.  Fixed wrong default count style in public ByteView initializer.

v1.0.16 7/14/2024 Added public intializer for BytesView.

v1.0.15 7/14/2024 Added check for macOS 12 in Development app.  Improved demo app.  Added BytesView.  Added improved test views.

v1.0.14 7/12/2024 Removed unnecessary utf8data extension since Data(String.utf8) works as a non-optional.  Added Codable conformance for Version.  Updated/enhanced Version tests.  Added JSON encoding/decoding simple functions and removed unnecessary similar code.  Removed unnecessary Foundation imports.  Made changes to get Linux support validation (passes all SwiftPackageIndex tests for all platforms and safe from data races!).

v1.0.13 7/11/2024 Undid structure form of HTML and PostData since it won't code/decode properly automatically in KuditFrameworks.  Seeing if typealias will work again (it does if we wrap the typealias in a structure).  Added an HTML test for attributedString.  Removed redundant old attributedStringFromHTML code.

v1.0.12 7/11/2024 Needed to make HTML sendable.

v1.0.11 7/11/2024 Not sure why the tvOS didn't warn about async function availability (probably because of app target), but warning in Color so fixing here.  Fixed so runs in Swift Playgrounds (missed testing this and there were some issues with global typealiases so converted PostData and HTML to structs).  Restored Network code by checking for combine OR FoundationNetowrking for Linux.  Added network requirement so tests pass in Swift Playgrounds.  Added networking tests to All Tests.

v1.0.10 7/11/2024 Fixed missed watchOS check for version availability.

v1.0.9 7/11/2024 Added support for iOS 11, tvOS 11, watchOS 4 to match DeviceKit.  Removed Testable protocol since it doesn't really make sense.  Figured out how to conditionally include platform requirement for Swift Playgrounds without modifying module requirement.

v1.0.8 7/11/2024 Moved all URLRequest functions into Network code and gated around a FoundationNetworking import check for Linux which may or may not include this.  Fixed target versions (Xcode project).

v1.0.7 7/10/2024 Removed color logging static variable from DeviceLevel and moved to Color package instead.  Added compiler checks so logical functions can work in iOS 13 but the UI mostly requires iOS 15.

v1.0.6 7/9/2024 Broke macOS and watchOS with last update.  Re-worked TabView Backport to be more compatible and easier.  Added some preview tests. 

v1.0.5 7/9/2024 Updated Xcode minimum versions to match package.  Added Backport .overlay and .foregroundStyle and .background for older tvOS.

v1.0.4 7/8/2024 Attempted to fix issues with Linux compatibility (swapped legacyData around so extension of URLRequest instead of URLSession).  Added additional #if canImport(Combine) checks.

v1.0.3 7/8/2024 Reduced tvOS version requirements to tvOS 13 (though menu and other UI features are not supported).

v1.0.2 7/8/2024 Fixed some data race issues and fixed breaking support for watchOS and Linux.  Added condition for @Published to ensure compilation on Linux.  Made PostData require a Sendable type and added Sendable conformance to NetworkError.  Fixed sendability of Message to prevent issues using `debug()`.

v1.0.1 7/7/2024 Fixed missing date in change log.  Moved DebugLevel.defaultLevel in initializers into nil initializers so can make sure to reference static property not in the initializer.  Changed default color to orange.  Changed several static vars to lets for concurrency safety.  Enabled `main {}` to be used with throwing functions.  Added `.spi.yml` file for Swift Package Index compiler.

v1.0 7/6/2024 Initial code and features pulled from KuditFrameworks.  Converted CGFloat to Double for more Swifty code.  Broke code up into separate files for clarity since this is all now contained in this module.  Reworked testing framework to throw instead of returning messages that only have utility when there's a problem.



## Bugs to fix:
Known issues that need to be addressed.
- [ ] Menu buttons in tvOS do not work at all.  Figure out why menus don't work at all in tvOS.  Figure out how to backport
- [ ] pagination in tvOS works but after pagination, view content isn't accessible.
- [ ] Placard view looks weird in macOS.
- [ ] Background tasks can cause crash issues when run from SwiftUI in iOS 15.  Guessing this has to do with threading and background tasks attempting to update values that may have been released?  Can reproduce by switching between All tests view and another view quickly on iPhone 7 simulator.  Fix by having the tests stored in a global singleton rather than as part of the view state?

## Roadmap:
Planned features and anticipated API changes.  If you want to contribute, this is a great place to start.
- [ ] Standardize test formats and creations.  Add #if canImport(Testing) to add as actual testable things instead of `try expect(` do `#expect(` so that we can get exactly where the tests fail.  Then see if we can sub-class into the tests.  See if we can still run in the UI as part of the app?
- [ ] Add more tests for improved code coverage.
- [ ] TODO: Add a failable initializer so that there is a way to init a date with a string but the format must be one of the supported formats.
- [ ] Add option to pad function to allow padding on left and use this in function for prefixing with a number of 0s.  Left padding function: https://stackoverflow.com/questions/32338137/padding-a-swift-string-for-printing
- [ ] Add isFirstRunOnDevice to differentiate from isFirstRun (across devices).
- [ ] Update tab view to use backport version that can extend content into safe area but still respects safe area for scrolling and clearing (for Color test app).  Have content of tab view extend into safe area but the contents not completely ignore safe area.
- [ ] Use this answer to create a FullPageTabView that will have the desired behavior and allow setting a color for the selected and deselected (defaults to .primary and .tertiary). Allow overriding symbol on each view by taking the tabItem view if present? https://stackoverflow.com/questions/78472655/swiftui-tabview-safe-area
- [ ] Fix pagination dots not using primary color depending on dark mode (always white).  Perhaps create custom tab view style that is pageTinted(Color).  Add to Compatibility and then update this stack: https://stackoverflow.com/questions/68143240/tabview-dot-index-color-does-not-change
- [ ] Add some shading at the bottom so the pagination dots show and make sure they are above the Kudit LLC to avoid the safe area.
- [ ] Add .rotated(n) function on arrays for cycling things like the .rainbow array.
- [ ] Add coding tests.
- [ ] Add the new document view controller model for compatibility with iOS 17 and 18 (check Viewer code for reference)
- [ ] Once Swift Testing is officially released, convert Testing functions to @Test functions and change expect function calls to #expect calls and remove custom debug statements.
- [ ] Fix tvOS usage of controls within a page view (seems to only control pagination and not buttons inside)
- [ ] Re-work page view on watchOS to use the vertical page view style or perhaps a navigation stack.  Color doesn't look great on watchOS.

## Proposals:
This is where proposals can be discussed for potential movement to the roadmap.
- [ ] 1.11.0: Remove Version from OperatingSystemVersion typealias so we don't have to do retroactive conformances?  Is there someplace where OperatingSystemVersion is used where a custom Version type would need to be bridged?
- [ ] Have debugSuppress suppress all messages except expect debug messages which should always print normally.
- [ ] should we rename `background {}` to `Background {}` and `Main {}` and `Delay(#) {}` to match `Task {}`?
- [ ] Debug: see if there's a way to add interpolation as a parameter to customize the output format.  Perhaps using a debug output formatter object that can be set?
- [ ] Regroup String to better apply to StringProtocol and String seperately.  Also figure out how to optimize trim functions by returning Substrings?
- [ ] Debug: allow setting a closure that will pre-process debug statements to allow for injection in debug statements?
- [ ] Protocol for a DataStore synced ObservableObject that will automatically add property wrappers for @DataStoreBacked to properties that aren't ignored? may be too difficult (add in a future path perhaps with macros to automatically synthesize code and coding keys etc??  Macros aren't easily able to be written like property wrappers, so this may not happen.)

TODO include configuration to pipe error and warnings to stderror for use in command line applications.
Create an example Command line app that can be built and run.  Create specialized target?
/**
extension CommandLine {
    
    static var progName: String {
        return String(cString: getprogname())
    }
    
    struct File: TextOutputStream {
        
        static let stdout = Self(FileHandle.standardOutput)
        static let stderr = Self(FileHandle.standardError)
        
        init(_ file: FileHandle) { self.file = file }
        
        let file: FileHandle
        
        func write(_ string: String) {
            self.file.write( .init(string.utf8) )
        }
    }
    
    enum ToolError : Error {
        case usage
        case silent
    }
}

extension TextOutputStream where Self == CommandLine.File {
    static var stdout: CommandLine.File { get { CommandLine.File.stdout } set { } }
    static var stderr: CommandLine.File { get { CommandLine.File.stderr } set { } }
}

func mainThrowing() throws {
    let mode = CommandLine.arguments.dropFirst(1).first
    let name = CommandLine.arguments.dropFirst(2).first
    switch mode {
    case "host": runAsHost(name: name)
    case "client": runAsClient(name: name)
    default: throw CommandLine.ToolError.usage
    }
}

func main() -> Never {
    do {
        try mainThrowing()
        exit(EXIT_SUCCESS)
    } catch CommandLine.ToolError.usage {
        print("usage: \(CommandLine.progName) host <name>", to: &.stderr)
        print("       \(CommandLine.progName) client <name>", to: &.stderr)
    } catch CommandLine.ToolError.silent {
        // do nothing
    } catch {
        print("error: \(error)", to: &.stderr)
    }
    exit(EXIT_FAILURE)
}

**/


Add in layout backport:
// TODO: #warning("Create wrapping HStack that can specify the min and max number of items per row and bases on available space/proposed space to determine whether to break up or not.  Have layout that does vertical if not enough horizontal space (can use to flow layout on Apple Watch and tight space vs wider iPad spaces)")
// TODO: #warning("Create ViewThatFitsBackport that will use ViewThatFits in new version or will use Geometry readers to determine in older iOS < 16.  https://useyourloaf.com/blog/swiftui-view-that-fits/")
Consider adding compatibility layout changes to address presentation on Apple Watch and small screens: https://github.com/sampettersson/Placement.

Use @autoclosures to create protocols for Defaultable that can be initialized with a default value (like Color) whenever they have failable initializers.
https://www.swiftbysundell.com/articles/using-autoclosure-when-designing-swift-apis/

## Reminders:
Static class vars/lets are done lazily.

```swift
#warning("Can be used to create a compiler warning.")
```

If get error TypeAlias is not available in Module.Module, convert to struct and seems to fix it.  Public top-level typealiases seem to cause issues. 

Test including capabilities for compatibility in a project that doesn't have entitlements that doesn't use the user default

Can test Linux by changing `canImport(Combine)` to `canImport(CombineBAD)` 
