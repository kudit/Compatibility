# ChangeLog

NOTE: Version needs to be updated in the following places:
- [ ] Xcode project version (in build settings - normal and watch targets should inherit)
- [ ] Package.swift iOSApplication product displayVersion.
- [ ] Color.version constant (must be hard coded since inaccessible in code)
- [ ] Tag with matching version in GitHub.

v1.0.2 7/8/2024 Fixed some data race issues and fixed breaking support for watchOS and Linux.  Added condition for @Published to ensure compilation on Linux.  Made PostData require a Sendable type and added Sendable conformance to NetworkError.  Fixed sendability of Message to prevent issues using `debug()`.

v1.0.1 7/7/2024 Fixed missing date in change log.  Moved DebugLevel.defaultLevel in initializers into nil initializers so can make sure to reference static property not in the initializer.  Changed default color to orange.  Changed several static vars to lets for concurrency safety.  Enabled `main {}` to be used with throwing functions.  Added `.spi.yml` file for Swift Package Index compiler.

v1.0 7/6/2024 Initial code and features pulled from KuditFrameworks.  Converted CGFloat to Double for more Swifty code.  Broke code up into separate files for clarity since this is all now contained in this module.  Reworked testing framework to throw instead of returning messages that only have utility when there's a problem.



## Bugs to fix:
Known issues that need to be addressed.

- [ ] Menu buttons in tvOS do not work.

## Roadmap:
Planned features and anticipated API changes.  If you want to contribute, this is a great place to start.

- [ ] Once Swift Testing is officially released, convert Testing functions to @Test functions and change expect function calls to #expect calls and remove custom debug statements.
- [ ] Make App Icon more orange at top.

## Proposals:
This is where proposals can be discussed for potential movement to the roadmap.

- [ ] Debug: see if there's a way to add interpolation as a parameter to customize the output format.  Perhaps using a debug output formatter object that can be set?
- [ ] Debug: allow setting a closure that will pre-process debug statements to allow for injection in debug statements?
