//
//  Build.swift
//  Compatibility
//
//  Created by Ben Ku on 7/14/26.
//


// Environment struct that can get the build environment info since Application isn't supported on legacy platforms.  This allows pulling these out into a struct rather than an ObservableObject which is necessary for some of the Application features.
public struct Build {
    /// Modules registered for build and support reporting, ordered with dependencies before their dependents.
    ///
    /// Register top-level modules with ``register(_:)`` or ``Module/include()`` during process startup.
    /// Registration recursively includes dependencies and preserves the first occurrence of each
    /// ``Module/moduleIdentifier``. Registration is intended to finish before concurrent access begins.
    public private(set) static var allModules = [Module.Type]()

    /// Whether module registration has been closed for this process.
    ///
    /// ``Application/track(including:file:function:line:column:)`` closes registration after adding its
    /// top-level modules. Command-line tools can call ``finishModuleRegistration()`` after their startup
    /// registrations. Once closed, the module list is immutable and safe for concurrent readers.
    public private(set) static var isModuleRegistrationFinished = false

    /// Registers one or more top-level modules and all of their dependencies.
    ///
    /// Dependencies are placed before the module that declared them so reports read from the lowest-level
    /// component to the highest-level component. Repeated registration is harmless because module identifiers
    /// are unique within ``allModules``.
    ///
    /// - Parameter modules: Top-level modules used by this process.
    public static func register(_ modules: Module.Type...) {
        // Forward variadic calls to the collection overload so app and command-line clients share one traversal.
        register(modules)
    }

    /// Registers a collection of top-level modules and all of their dependencies.
    ///
    /// - Parameter modules: Top-level modules used by this process.
    public static func register(_ modules: [Module.Type]) {
        guard !isModuleRegistrationFinished else {
            // Reject late mutation because support reports may already be reading the process-global list.
            debug("Attempted to register modules after module registration finished.", level: .WARNING)
            return
        }
        var visitingIdentifiers = [String]()
        for module in modules {
            register(module, visitingIdentifiers: &visitingIdentifiers)
        }
    }

    /// Closes module registration so the resulting ordered list can be read concurrently without mutation.
    ///
    /// Call this after startup registration in processes that do not use ``Application/track(including:file:function:line:column:)``.
    public static func finishModuleRegistration() {
        // A one-way state transition keeps the startup API simple on platforms without modern synchronization primitives.
        isModuleRegistrationFinished = true
    }

    /// Recursively registers one module while preventing dependency cycles from recursing forever.
    private static func register(_ module: Module.Type, visitingIdentifiers: inout [String]) {
        let identifier = module.moduleIdentifier
        guard !allModules.contains(where: { $0.moduleIdentifier == identifier }),
              !visitingIdentifiers.contains(identifier) else {
            return
        }

        // Record the active traversal path before descending so circular dependency declarations terminate safely.
        visitingIdentifiers.append(identifier)
        for dependency in module.dependencies {
            register(dependency, visitingIdentifiers: &visitingIdentifiers)
        }
        visitingIdentifiers.removeLast()

        // A sibling dependency may have registered this module while the recursive traversal was in progress.
        guard !allModules.contains(where: { $0.moduleIdentifier == identifier }) else {
            return
        }
        allModules.append(module)
    }

#if compiler(>=5.9)
    /// Replaces registration state so shared tests can restore the process-global registry after exercising it.
    internal static func replaceRegisteredModulesForTesting(with modules: [Module.Type], registrationFinished: Bool = false) {
        // Keep this test-only mutation internal so package clients cannot bypass normal dependency registration.
        allModules = modules
        isModuleRegistrationFinished = registrationFinished
    }
#endif

    /// will be true if we're in a debug configuration and false if we're building for release
    public static let isDebug = _isDebugAssertConfiguration()

    // Documentation on the following compiler directives: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/statements/#Compiler-Control-Statements

    /// Returns the version number of Swift being used to compile (use these checks for Swift Package Index version checks).
    public static var compilerVersion: String {
#if compiler(>=9.0)
        "X.x"
#elseif compiler(>=8.0)
        "8.x"
#elseif compiler(>=7.0)
        "7.x"
#elseif compiler(>=6.5)
        "6.x"
#elseif compiler(>=6.4)
        "6.4"
#elseif compiler(>=6.3)
        "6.3"
#elseif compiler(>=6.2)
        "6.2"
#elseif compiler(>=6.1)
        "6.1"
#elseif compiler(>=6.0)
        "6.0"
#elseif compiler(>=5.12)
        "5.12"
#elseif compiler(>=5.11)
        "5.11"
#elseif compiler(>=5.10)
        "5.10"
#elseif compiler(>=5.9)
        "5.9"
#elseif compiler(>=5.8)
        "5.8"
#elseif compiler(>=5.7)
        "5.7"
#elseif compiler(>=4.0)
        "4.x"
#elseif compiler(>=3.0)
        "3.x"
#elseif compiler(>=2.0)
        "2.x"
#elseif compiler(>=1.0)
        "1.x"
#else
        "Unsupported"
#endif
    }

    /// Returns the version number of Swift being used to run?
    public static var swiftVersion: String {
#if swift(>=9.0)
        "X.x"
#elseif swift(>=8.0)
        "8.x"
#elseif swift(>=7.0)
        "7.x"
#elseif swift(>=6.5)
        "6.x"
#elseif swift(>=6.4)
        "6.4"
#elseif swift(>=6.3)
        "6.3"
#elseif swift(>=6.2)
        "6.2"
#elseif swift(>=6.1)
        "6.1"
#elseif swift(>=6.0)
        "6.0"
#elseif swift(>=5.12)
        "5.12"
#elseif swift(>=5.11)
        "5.11"
#elseif swift(>=5.10)
        "5.10"
#elseif swift(>=5.9)
        "5.9"
#elseif swift(>=5.8)
        "5.8"
#elseif swift(>=5.7)
        "5.7"
#elseif swift(>=4.0)
        "4.x"
#elseif swift(>=3.0)
        "3.x"
#elseif swift(>=2.0)
        "2.x"
#elseif swift(>=1.0)
        "1.x"
#else
        "Unsupported"
#endif
    }

    // MARK: - Environmental info
    public enum Environment: String, Sendable, RawRepresentable, CaseIterable, Identifiable, CaseNameConvertible, SymbolRepresentable {
        case debug = "Debug"
        /// The current process is running from an application bundle whose extension is `.app`.
        case app = "App"
        /// The current process is a standalone executable rather than an app, test, or extension bundle.
        case commandLineTool = "Command Line Tool"
        /// The current process is executing under XCTest or Swift Testing's XCTest-compatible runner.
        case testing = "Testing"
        case simulator = "Simulator"
        case playground = "Playground"
        case preview = "Preview"
        case realDevice = "Real Device"
        case designedForiPad = "Designed for iPad"
        case macCatalyst = "Mac Catalyst"

        public var id: Self {
            return self
        }

        /// Returns whether this environment is active for the current build/runtime.
        ///
        /// This is public so package clients can show the same environment state that
        /// Compatibility uses internally without duplicating the platform checks.
        public var test: Bool {
            switch self {
            case .debug: return Build.isDebug
            case .app: return Build.isApp
            case .commandLineTool: return Build.isCommandLineTool
            case .testing: return Build.isRunningTests
            case .simulator: return Build.isSimulator
            case .playground: return Build.isPlayground
            case .preview: return Build.isPreview
            case .realDevice: return Build.isRealDevice
            case .designedForiPad: return Build.isDesignedForiPad
            case .macCatalyst: return Build.isMacCatalyst
            }
        }

        /// An SF Symbol name for the environment test.
        public var symbolName: String {
            switch self {
            case .debug:
                return "ladybug"
            case .app:
                return "app.badge.fill"
            case .commandLineTool:
                return "terminal" // apple.terminal starting with iOS 17
            case .testing:
                return "checkmark.circle"
            case .realDevice:
                return "square.fill"
            case .simulator:
                return "squareshape.squareshape.dotted"
            case .playground:
                return "swift"
            case .preview:
                return "curlybraces.square"
            case .designedForiPad:
                return "ipad.badge.play"
            case .macCatalyst:
                return "macwindow.on.rectangle"
            @unknown default:
                return "questionmark.circle"
            }
        }

        /// A portable Unicode representation suitable for terminals and plain-text logs.
        ///
        /// SF Symbols are named vector assets and cannot be represented reliably as text,
        /// while emoji remain meaningful across Apple terminals, CI logs, and other platforms.
        /// Their artwork may vary by operating system, but each scalar remains stable text.
        public var emoji: String {
            switch self {
            case .debug: return "🪲"
            case .app: return "📦"
            case .commandLineTool: return "⌨️"
            case .testing: return "🧪"
            case .simulator: return "🖥️"
            case .playground: return "🛝"
            case .preview: return "👁️"
            case .realDevice: return "📱"
            case .designedForiPad: return "📲"
            case .macCatalyst: return "💻"
            @unknown default: return "❓"
            }
        }

        /// String Description for environment
        public var label: String {
            return self.rawValue
        }
    }

    /// Returns a set of Build.Environment objects where the test is true for this build.
    public static func environments() -> [Build.Environment] {
        return Build.Environment.allCases.filter(\.test)
    }
    /// Returns `true` if running on the simulator vs actual device.
    public static var isSimulator: Bool {
#if targetEnvironment(simulator)
        // your simulator code
        return true
#else
        // your real device code
        return false
#endif
    }

    // In macOS Playgrounds Preview: swift-playgrounds-dev-previews.swift-playgrounds-app.hdqfptjlmwifrrakcettacbhdkhn.501.KuditFramework
    // In macOS Playgrounds Running: swift-playgrounds-dev-run.swift-playgrounds-app.hdqfptjlmwifrrakcettacbhdkhn.501.KuditFrameworksApp
    // In iPad Playgrounds Preview: swift-playgrounds-dev-previews.swift-playgrounds-app.agxhnwfqkxciovauscbmuhqswxkm.501.KuditFramework
    // In iPad Playgrounds Running: swift-playgrounds-dev-run.swift-playgrounds-app.agxhnwfqkxciovauscbmuhqswxkm.501.KuditFrameworksApp
    // warning: {"message":"This code path does I/O on the main thread underneath that can lead to UI responsiveness issues. Consider ways to optimize this code path","antipattern trigger":"+[NSBundle allBundles]","message type":"suppressable","show in console":"0"}
    /// Returns `true` if running in Swift Playgrounds.
    public static var isPlayground: Bool {
#if SwiftPlaygrounds
        debug("New Swift Playgrounds test!", level: .WARNING)
        return true
#elseif canImport(Foundation)
        // Swift Playgrounds 4.7 has been sensitive to both custom compilation
        // conditions and closure-heavy checks here, so keep this as plain runtime code.
        return bundleIdentifierContains("swift-playgrounds")
#else
        return false
#endif
    }

    /// Returns `true` if running in an Xcode or Swift Playgrounds `#Preview` macro.
#if canImport(Foundation)
    public static var isPreview: Bool {
        let previewEnvironment = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        // Swift Playgrounds uses separate bundle identifiers for the preview canvas and
        // the running app but apparently the process reports XCODE_RUNNING_FOR_PREVIEWS.
        let isSwiftPlaygroundsRunBundle = bundleIdentifierContains("swift-playgrounds-dev-run")
        return previewEnvironment && !isSwiftPlaygroundsRunBundle // don't report as preview if we're running a swift playgrounds app
    }
#else
    public static var isPreview: Bool {
        return false
    }
#endif

    /// Helper for looking up a bundle identifier.
    private static func bundleIdentifierContains(_ string: String) -> Bool {
#if canImport(Foundation)
        // Avoid `contains(where:)` here because Swift Playgrounds has reported misleading
        // parser errors in this area; a simple loop is boring in the best possible way.
        // previous code:         if Bundle.allBundles.contains(where: { ($0.bundleIdentifier ?? "").contains("swift-playgrounds") }) {
        for bundle in Bundle.allBundles {
            if let bundleIdentifier = bundle.bundleIdentifier, bundleIdentifier.contains(string) {
                return true
            }
        }
#endif
        return false
    }

    /// Returns `true` if NOT running in preview, playground, or simulator.
    public static var isRealDevice: Bool {
        return !isPreview && !isPlayground && !isSimulator
    }

    /// Returns `true` if Built for iPad mode not a native mode (for macOS and visionOS).
    public static var isDesignedForiPad: Bool {
#if targetEnvironment(macCatalyst) || os(watchOS) || os(tvOS) || os(WASM) || os(WASI) || os(Linux)
        // Catalyst is a native Mac target rather than Apple's iPad-compatible app
        // runtime, so keep it separate from "Designed for iPad" reporting.
        return false
#elseif canImport(Combine)
        // Check for iPad mode on visionOS. Access the new Foundation property through
        // Objective-C key-value coding so older SDKs, including the SDK bundled with
        // Swift Playgrounds 4.7, do not have to resolve `isiOSAppOnVision` at compile time.
        // The runtime availability check ensures the key exists before it is queried.
        if #available(iOS 26.1, macOS 26.1, watchOS 26.1, tvOS 26.1, visionOS 26.1, *) {
//            if ProcessInfo.processInfo.isiOSAppOnVision {
            if ProcessInfo.processInfo.value(forKey: "isiOSAppOnVision") as? Bool == true {
                return true
            }
        }
        if #available(iOS 14, watchOS 7, macOS 11, tvOS 14, *) { // not available on watchOS 6
            return ProcessInfo.processInfo.isiOSAppOnMac
        }
#if canImport(UIKit)
        // visionOS can run compatible iPad apps where the process is not an iOS app
        // on Mac, so use UIKit's interface idiom as a second signal for designed-for-iPad mode.
        return UIDevice.current.userInterfaceIdiom == .pad
#else
        // Fallback on earlier versions & unsupported platforms
        return false
#endif
#else
        // Fallback on earlier versions & unsupported platforms
        return false
#endif
    }

    /// Returns `true` if is macCatalyst app on macOS
    nonisolated // Not @MainActor
    public static var isMacCatalyst: Bool {
#if targetEnvironment(macCatalyst)
        return true
#else
        return false
#endif
    }

    /// Returns `true` when the current process is running from an `.app` bundle.
    ///
    /// This is a runtime packaging check rather than a compile-time platform check.
    /// It is `true` for normally launched Apple apps and Swift Playgrounds app runs.
    /// Xcode and Swift Playgrounds previews normally run through an app-like preview
    /// host, so a preview may report both `isApp` and `isPreview` as `true`.
    /// Tests are reported independently by `isRunningTests`; a hosted test can therefore
    /// be a test even when its runner's main bundle is not the application under test.
    public static var isApp: Bool {
#if canImport(Foundation)
        return Bundle.main.bundleURL.pathExtension.lowercased() == "app"
#else
        // Bundle metadata is unavailable without Foundation, so the process cannot be
        // classified reliably as an app from this compatibility layer.
        return false
#endif
    }

    /// Returns `true` when the current process appears to be a standalone command-line executable.
    ///
    /// A command-line tool's main bundle path normally has no extension. Checking for that
    /// shape avoids treating `.xctest`, `.appex`, and other non-app bundles as command-line
    /// tools, which would happen if this were implemented as merely `!isApp`.
    /// This value is normally `false` in app runs, Swift Playgrounds, previews, and tests.
    public static var isCommandLineTool: Bool {
#if canImport(Foundation)
        return Bundle.main.bundleURL.pathExtension.isEmpty && !isRunningTests
#else
        // Without Foundation there is no portable runtime bundle inspection available.
        return false
#endif
    }

    /// Returns `true` when the current process is executing a test bundle, test runner, or app launched by Compatibility UI tests.
    ///
    /// Xcode supplies `XCTestConfigurationFilePath` to XCTest-compatible runs. Test runners
    /// also conventionally contain `xctest` or end in SwiftPM's generated `PackageTests`
    /// suffix. Modern SwiftPM launches Swift Testing through `swiftpm-testing-helper` with
    /// a `--testing-library` argument, so those runtime markers are recognized as well without
    /// requiring Compatibility itself to depend on either test framework.
    /// A UI test executes in a separate process from its app, so the UI test must pass a truthy
    /// `TESTING` launch environment value for the launched app to report testing.
    /// This is intentionally independent of `isApp`: hosted application and UI tests can
    /// have app-like hosts while still needing to identify themselves as test processes.
    public static var isRunningTests: Bool {
#if canImport(Foundation)
        let environment = ProcessInfo.processInfo.environment
        if environment["XCTestConfigurationFilePath"] != nil {
            return true
        }
        let processName = ProcessInfo.processInfo.processName.lowercased()
        let arguments = ProcessInfo.processInfo.arguments
        // Xcode does not automatically transfer the test runner's XCTest configuration to
        // the separate app process, so recognize the generic environment convention used by UI tests.
        let isUITestHost = isTruthyEnvironmentValue(environment[testingEnvironmentVariable])
        return processName.contains("xctest")
            || processName.hasSuffix("packagetests")
            || processName == "swiftpm-testing-helper"
            || arguments.contains("--testing-library")
            || isUITestHost
#else
        // Test-runner metadata is not portably available without Foundation.
        return false
#endif
    }

    /// Generic environment-variable name that UI tests can pass to the separate application process.
    public static let testingEnvironmentVariable = "TESTING"

    /// Generic environment-variable name used to opt into tests that touch live system services.
    public static let integrationTestingEnvironmentVariable = "INTEGRATION_TESTING"

    /// Whether live integration tests such as iCloud, GitHub, and system-pasteboard checks should run.
    ///
    /// Set the `INTEGRATION_TESTING` environment value to `1`, `true`, `yes`, or `on`. These tests are
    /// excluded by default because they can require accounts, network access, privacy permission, or user state.
    public static var runsIntegrationTests: Bool {
#if canImport(Foundation)
        return isTruthyEnvironmentValue(ProcessInfo.processInfo.environment[integrationTestingEnvironmentVariable])
#else
        return false
#endif
    }

#if canImport(Foundation)
    /// Recognizes common shell and property-list spellings used for enabled environment flags.
    private static func isTruthyEnvironmentValue(_ value: String?) -> Bool {
        guard let value = value?.lowercased() else { return false }
        return value == "1" || value == "true" || value == "yes"
    }
#endif
}

// Color support for Build.Environment
#if canImport(SwiftUI) && canImport(Foundation)
import SwiftUI
import Foundation

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Build.Environment {
    /// A stable display color for presenting this environment alongside its symbol.
    var color: Color {
        switch self {
        case .debug:
            return .red
        case .app:
            return .yellow
        case .commandLineTool:
            return .gray
        case .testing:
            return .yellow
        case .realDevice:
            return .green
        case .simulator:
            return .blue
        case .playground:
            return .orange
        case .preview:
            return .pink
        case .designedForiPad:
            return .purple
        case .macCatalyst:
            if #available(iOS 15.0, macCatalyst 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
                return .teal
            } else {
                return .purple
            }
        }
    }
}
#endif
