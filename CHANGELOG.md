# ChangeLog

NOTE: Version needs to be updated in the following places:
- [ ] Xcode project version (in build settings - normal and watch targets should inherit)
- [ ] Package.swift iOSApplication product displayVersion.
- [ ] Color.version constant (must be hard coded since inaccessible in code)
- [ ] Tag with matching version in GitHub.

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

## Roadmap:
Planned features and anticipated API changes.  If you want to contribute, this is a great place to start.

- [ ] Once Swift Testing is officially released, convert Testing functions to @Test functions and change expect function calls to #expect calls and remove custom debug statements.
- [ ] Make App Icon more orange at top.

## Proposals:
This is where proposals can be discussed for potential movement to the roadmap.

- [ ] Should we raise tvOS and watchOS and macOS and other platforms to match the iOS 15 requirement to prune unnecessary legacy code?  Cannot have less than iOS 15.2 due to Swift Playgrounds.
- [ ] Debug: see if there's a way to add interpolation as a parameter to customize the output format.  Perhaps using a debug output formatter object that can be set?
- [ ] Debug: allow setting a closure that will pre-process debug statements to allow for injection in debug statements?
