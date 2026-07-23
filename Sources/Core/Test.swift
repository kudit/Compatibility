// TODO: Once Swift Testing is available, can re-write all this code into test classes that conform to Swift Testing so that we can also run code in Previews and Test Applications?  Use macros to duplicate #expect( functionality syntax?  Or can we use somehow in UI still?
public typealias TestClosure = @Sendable () async throws -> Void

/// A portable snapshot of the source location that initiated an operation.
///
/// Passing one value is useful when an asynchronous helper needs to retain and forward a caller's
/// location. Existing APIs continue exposing individual source arguments for source compatibility,
/// while new APIs can accept `SourceContext` when carrying the complete location is clearer.
public struct SourceContext: Sendable {
    public let file: String
    public let function: String
    public let line: Int
    public let column: Int

    /// Captures the call site by default.
    public init(
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) {
        self.file = file
        self.function = function
        self.line = line
        self.column = column
    }
}

// This could be anything, not necessary a struct or class, so if we need this, have a list of tests rather than a Testable object
//// don't make this public to avoid compiling test stuff into framework, however, do make public so apps can add in their own tests.
//public protocol Testable {
//    // actor isolated since each Test is @MainActor isolated due to being an ObservableObject.
//    @available(watchOS 6, *)
//    @MainActor static var tests: [Test] { get }
//}

// TODO: NEXT: Convert these to Testing expectations so we don't have to write custom error descriptions.  Also move to Test static method that is shadowed in the global space.
/// Sets an expectation for a reusable Compatibility test.
///
/// The source location defaults mirror Swift Testing's diagnostics while remaining callable from
/// live applications, previews, older systems, and test runners that do not provide Swift Testing.
public func expect(_ condition: Bool, _ debugString: String? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) throws {
    guard condition else {
        // set breakpoint on this line if we want to debug/inspect errors (note that this slows enough to mess with time stamp checks so disable once we know everything is working).
        if let debugString {
            throw CustomError(debugString)
        } else {
#if canImport(Foundation)
            let isMainThread = Thread.isMainThread
#else
            let isMainThread = true
#endif
            let context = Compatibility.settings.debugFormat(
                "",
                DebugLevel.OFF,
                isMainThread,
                Compatibility.settings.debugEmojiSupported,
                true,
                true,
                file, function, line, column)

            throw CustomError(context)
        }
    }
}

/// Requires two equatable values to be equal and reports both values when they differ.
///
/// - Parameters:
///   - actual: The value produced by the code under test.
///   - expected: The value the test requires.
///   - message: Optional context appended to the generated actual-versus-expected diagnostic.
public func expectEqual<Value: Equatable>(_ actual: Value, _ expected: Value, _ message: String? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) throws {
    // Build the comparison text here so UI runs receive the same useful values that Swift Testing displays.
    let context = message.map { " \($0)" } ?? ""
    try expect(actual == expected, "Expected \(String(reflecting: expected)), but received \(String(reflecting: actual)).\(context)", file: file, function: function, line: line, column: column)
}

/// Requires two equatable values to differ and reports the shared value when they do not.
public func expectNotEqual<Value: Equatable>(_ actual: Value, _ unexpected: Value, _ message: String? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) throws {
    // Include the unexpected value so a failure remains actionable outside a debugger.
    let context = message.map { " \($0)" } ?? ""
    try expect(actual != unexpected, "Expected a value other than \(String(reflecting: unexpected)), but received it.\(context)", file: file, function: function, line: line, column: column)
}

// NOTE: Really wish there was a way of writing a possibly async function or doing this using a generic so we don't have to duplicate code.
// TODO: Find a way to prevent conflicts here when run simultaneously.  This really should only be used for testing.
/// Suppress debug messages during this execution block.  Allows fetching the debug string as normal.
public func debugSuppress(_ block: () throws -> Void) rethrows {
    let log = Compatibility.settings.debugLog
    #if canImport(Foundation)
    let suppressThread = Thread.current // restrict the silencing to this thread/closure assuming no background tasks are doing printing
    #endif
    Compatibility.settings.debugLog = { message in
        #if canImport(Foundation)
        if Thread.current != suppressThread {
            log(message) // do normal logging
        }
        #else
        log(message)
        #endif
    }
    defer {
        Compatibility.settings.debugLog = log
    }
    try block()
}
/// Suppress debug messages during this async execution block.  Allows fetching the debug string as normal.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *) // due to Concurrency
//@MainActor
public func debugSuppress(_ block: () async throws -> Void) async rethrows {
    let log = Compatibility.settings.debugLog
    // unable to get thread in async functions so just ignore and hope it doesn't run concurrently interrupting other debug messages.
    Compatibility.settings.debugLog = { _ in }
    defer {
        Compatibility.settings.debugLog = log
    }
    try await block()
}

// Testing is only supported with Swift 5.9+
#if compiler(>=5.9)
// Test Handlers
@MainActor
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
/// A reusable named test that can run in Compatibility's live UI or an external test framework.
///
/// `TestCase` intentionally borrows XCTest's familiar terminology, but it is not an
/// `XCTestCase` subclass or a drop-in replacement. Each value describes one closure-based test,
/// while optional setup and teardown closures provide lightweight lifecycle hooks.
public final class TestCase: ObservableObject, @unchecked Sendable {
    private final class WeakReference<T: AnyObject>: @unchecked Sendable {
        weak var value: T?

        init(_ value: T?) {
            self.value = value
        }
    }

    public enum TestProgress: Sendable {
        case notStarted
        case running
        case pass
        case fail(String) // for error message
        public var symbol: String {
            switch self {
            case .notStarted:
                return "❇️"
            case .running:
                return "🔄"
            case .pass:
                return "✅"
            case .fail:
                return "⛔"
            }
        }
        public var errorMessage: String? {
            if case let .fail(string) = self {
                return string
            }
            return nil
        }
    }
    public let title: String
    public let setUp: TestClosure?
    public var test: TestClosure
    public let tearDown: TestClosure?
    /// Source-compatible name for the test closure.
    ///
    /// `test` reads more naturally beside `setUp` and `tearDown`, while `task` remains available
    /// because it was public before `TestCase` adopted lifecycle terminology.
    @available(*, deprecated, renamed: "test")
    public var task: TestClosure {
        get { test }
        set { test = newValue }
    }
    @Published public var progress: TestProgress = .notStarted
    
    /// Creates a reusable test with optional lifecycle closures.
    ///
    /// Teardown is attempted even when setup or the test throws, matching the cleanup expectation
    /// familiar from XCTest without claiming `XCTestCase` API or inheritance compatibility.
    public init(
        _ title: String,
        setUp: TestClosure? = nil,
        test: @escaping TestClosure,
        tearDown: TestClosure? = nil
    ) {
        self.title = title
        self.setUp = setUp
        self.test = test
        self.tearDown = tearDown
    }

    /// Creates a reusable test without separate setup or teardown work.
    public convenience init(_ title: String, _ test: @escaping TestClosure) {
        self.init(title, test: test)
    }

    /// Executes the test closure directly for an external test framework.
    ///
    /// Swift Testing and XCTest adapters should prefer this awaited path because thrown expectation
    /// failures retain the external runner's native test context without polling observable UI state.
    public func execute() async throws {
        do {
            try await setUp?()
            try await test()
        } catch {
            // Cleanup should still run after a failure; preserve the original failure when cleanup succeeds.
            do {
                try await tearDown?()
            } catch {
                debug("Test teardown also failed: \(error)", level: .ERROR)
            }
            throw error
        }
        try await tearDown?()
    }
    
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    public func run() {
        if case .running = progress {
            return
        }
        let setUp = self.setUp
        let test = self.test
        let tearDown = self.tearDown
        let weakSelf = WeakReference(self)
        progress = .running
        // Run on the detached executor, then publish the result back on the main actor. WebAssembly's
        // cooperative executor preserves the same actor semantics even when its host is single threaded.
        Task.detached(priority: .userInitiated) { [setUp, test, tearDown, weakSelf] in
            do {
                do {
                    try await setUp?()
                    try await test()
                } catch {
                    // Mirror execute() cleanup while keeping this detached UI path independent of self.
                    do {
                        try await tearDown?()
                    } catch {
                        debug("Test teardown also failed: \(error)", level: .ERROR)
                    }
                    throw error
                }
                try await tearDown?()
                await MainActor.run {
                    weakSelf.value?.progress = .pass
                }
            } catch {
                await MainActor.run {
                    debug(error.localizedDescription, level: .ERROR)
                    weakSelf.value?.progress = .fail("\(error.localizedDescription)")
                }
            }
        }
    }
    
    public func isFinished() -> Bool {
        switch progress {
        case .pass, .fail:
            return true
        default:
            return false
        }
    }

    public func succeeded() -> Bool {
        switch progress {
        case .pass:
            return true
        default:
            return false
        }
    }

    public var errorMessage: String? {
        progress.errorMessage
    }
    
    public var description: String {
        var errorString = ""
        if let errorMessage = progress.errorMessage {
            errorString = "\n\t\(errorMessage)"
        }
        return "\(progress): \(title)\(errorString)"
    }
}

/// The original test type name retained for source compatibility with Compatibility 1.16.
///
/// Use ``TestCase`` in new code to avoid colliding with Swift Testing's `Test` type.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@available(*, deprecated, renamed: "TestCase")
public typealias Test = TestCase

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension TestCase {
    static func dummyAsyncThrows() async throws {
    }
}

@available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
public extension TestCase {
    /// Every reusable Compatibility test, grouped in deterministic display and execution order.
    ///
    /// This is the package's canonical test catalog. The in-app UI and Swift Testing bridge both
    /// consume this property so a test is authored once and remains runnable in either environment.
    @MainActor
    static let namedTests: OrderedDictionary<String, [TestCase]> = {
        var tests: OrderedDictionary = [
            "Expectation Tests": [
                TestCase("Equality diagnostics") {
                    // Exercise the public comparison helpers on their success paths without intentionally failing the shared suite.
                    try expectEqual(["Compatibility", "TestCase"], ["Compatibility", "TestCase"])
                    try expectNotEqual(Compatibility.version, Version("0.0.0"))
                },
            ],
            "String Tests": String.tests,
            "Dictionary Tests": dictionaryTests,
            "Mixed Type Field Tests": MixedTypeField.tests,
            "Version Tests": Version.tests,
            "Module Tests": moduleTests,
            "Enum Tests": CloudStatus.tests,
            "Int Tests": Int.tests,
            "Double Tests": Double.tests,
            "Collection Tests": collectionTests,
            "Debug Tests": DebugLevel.tests,
            "Application Tests": Application.tests,
        ]
#if canImport(Foundation)
        tests.merge([
            "Coding Tests": codingTests,
        ]) { current, _ in current }
#endif
#if canImport(Foundation)
        tests["Bundle Tests"] = Bundle.tests
        tests["File Manager Tests"] = FileManager.tests
        tests["Pasteboard Tests"] = Pasteboard.tests
        tests["CharacterSet Tests"] = CharacterSet.tests
        tests["URL Tests"] = URL.tests
        tests["Date Tests"] = Date.tests
        tests["Threading Tests"] = Compatibility.threadingTests
#if canImport(Combine) || canImport(FoundationNetworking)
        // FoundationNetworking supplies URLSession through libcurl on Linux.
        tests["Network Tests"] = PostData.tests
#endif
#endif
        return tests
    }()
}

@available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
public extension Compatibility {
    /// Compatibility's global test catalog.
    @MainActor
    static var tests: OrderedDictionary<String, [TestCase]> {
        TestCase.namedTests
    }
}

#if canImport(SwiftUI) && canImport(Foundation)
import SwiftUI
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview {
    TestsListView(tests: Compatibility.threadingTests + Int.tests)
}
#endif
#endif
