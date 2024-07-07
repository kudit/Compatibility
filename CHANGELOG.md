# ChangeLog

NOTE: Version needs to be updated in the following places:
- [ ] Xcode project version (in build settings - normal and watch targets should inherit)
- [ ] Package.swift iOSApplication product displayVersion.
- [ ] Color.version constant (must be hard coded since inaccessible in code)
- [ ] Tag with matching version in GitHub.

v1.0 TODO Initial code and features pulled from KuditFrameworks.  Converted CGFloat to Double for more Swifty code.  Broke code up into separate files for clarity since this is all now contained in this module.  Reworked testing framework to throw instead of returning messages that only have utility when there's a problem.


## Bugs to fix:
Known issues that need to be addressed.

- [ ] Menu buttons in tvOS do not work.

## Roadmap:
Planned features and anticipated API changes.  If you want to contribute, this is a great place to start.

- [ ] Once Swift Testing is officially released, convert Testing functions to @Test functions and change expect function calls to #expect calls and remove custom debug statements.

## Proposals:
This is where proposals can be discussed for potential movement to the roadmap.

- [ ] Debug: see if there's a way to add interpolation as a parameter to customize the output format.  Perhaps using a debug output formatter object that can be set?
- [ ] Debug: allow setting a closure that will pre-process debug statements to allow for injection in debug statements?
