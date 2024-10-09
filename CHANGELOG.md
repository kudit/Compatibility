# ChangeLog

NOTE: Version needs to be updated in the following places:
- [ ] Xcode project version (in build settings - normal and watch targets should inherit)
- [ ] Package.swift iOSApplication product displayVersion.
- [ ] Compatibility.version constant (must be hard coded since inaccessible in code)
- [ ] Update changelog and tag with matching version in GitHub.

v1.3.11 10/9/2024 Fixed missing availability check on `fetchURL`.

v1.3.10 10/9/2024 Improved error checking to report missing entitlements for network connectivity.  Added `Data` return version of `fetchURL` that works similarly with the same error checking that is used under the hood by `fetchURL`.  Added ability to easily log an error at the throwing site rather than having to debug at the catching site.  Changed errors from having a description to having a localizedDescription to better conform to the error protocol.  Should still work for output.

v1.3.9 10/9/2024 Fixed so builds run from Playgrounds app returns the proper identifier for Kudit Connect.  Also noticed that the version number previously was not updated anywhere!

*PASSES ALL SWIFTPACKAGEINDEX TESTS*
v1.3.8 10/7/2024 Fixed issue with Placard initializer being internal.  Has several issues with Swift 6 that can't be fixed until Swift Playgrounds is updated as the fixes are errors in Swift Playgrounds.  Added example Settings for macOS.

*PASSES ALL SWIFTPACKAGEINDEX TESTS*
v1.3.7 8/16/2024 Added automatic mapping for `@CloudStorage` where value is a `RawRepresentable` type that is a Double.  Added instructions for automatic mapping to custom types.

*PASSES ALL SWIFTPACKAGEINDEX TESTS*
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
- [ ] Menu buttons in tvOS do not work at all.
- [ ] pagination in tvOS works but after pagination, view content isn't accessible.
- [ ] Placard view looks weird in macOS.

## Roadmap:
Planned features and anticipated API changes.  If you want to contribute, this is a great place to start.
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
- [ ] should we rename `background {}` to `Background {}` and `Main {}` and `Delay(#) {}` to match `Task {}`?
- [ ] Debug: see if there's a way to add interpolation as a parameter to customize the output format.  Perhaps using a debug output formatter object that can be set?
- [ ] Debug: allow setting a closure that will pre-process debug statements to allow for injection in debug statements?
- [ ] Protocol for a DataStore synced ObservableObject that will automatically add property wrappers for @DataStoreBacked to properties that aren't ignored? may be too difficult (add in a future path perhaps with macros to automatically synthesize code and coding keys etc??  Macros aren't easily able to be written like property wrappers, so this may not happen.)

Add in layout backport:
// TODO: #warning("Create wrapping HStack that can specify the min and max number of items per row and bases on available space/proposed space to determine whether to break up or not.  Have layout that does vertical if not enough horizontal space (can use to flow layout on Apple Watch and tight space vs wider iPad spaces)")
// TODO: #warning("Create ViewThatFitsBackport that will use ViewThatFits in new version or will use Geometry readers to determine in older iOS < 16.  https://useyourloaf.com/blog/swiftui-view-that-fits/")
Consider adding compatibility layout changes to address presentation on Apple Watch and small screens: https://github.com/sampettersson/Placement.


## Reminders:
Static class vars/lets are done lazily.

```swift
#warning("Can be used to create a compiler warning.")
```

If get error TypeAlias is not available in Module.Module, convert to struct and seems to fix it.  Public top-level typealiases seem to cause issues. 

Test including capabilities for compatibility in a project that doesn't have entitlements that doesn't use the user default
