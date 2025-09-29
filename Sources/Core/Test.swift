// TODO: Once Swift Testing is available, can re-write all this code into test classes that conform to Swift Testing so that we can also run code in Previews and Test Applications?  Use macros to duplicate #expect( functionality syntax?  Or can we use somehow in UI still?
public typealias TestClosure = @Sendable () async throws -> Void

// This could be anything, not necessary a struct or class, so if we need this, have a list of tests rather than a Testable object
//// don't make this public to avoid compiling test stuff into framework, however, do make public so apps can add in their own tests.
//public protocol Testable {
//    // actor isolated since each Test is @MainActor isolated due to being an ObservableObject.
//    @available(watchOS 6, *)
//    @MainActor static var tests: [Test] { get }
//}

// TODO: NEXT: Convert these to Testing expectations so we don't have to write custom error descriptions.  Also move to Test static method that is shadowed in the global space.
/// Sets an expectation for testing.  In the future, convert to Swift #expect calls so we get better context without specifying a debugString.
public func expect(_ condition: Bool, _ debugString: String? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) throws {
    guard condition else {
        // set breakpoint on this line if we want to debug/inspect errors (note that this slows enough to mess with time stamp checks so disable once we know everything is working).
        if let debugString {
            throw CustomError(debugString)
        } else {
#if canImport(Foundation) && !(os(WASM) || os(WASI))
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

// NOTE: Really wish there was a way of writing a possibly async function or doing this using a generic so we don't have to duplicate code.
// TODO: Find a way to prevent conflicts here when run simultaneously.  This really should only be used for testing.
/// Suppress debug messages during this execution block.  Allows fetching the debug string as normal.
public func debugSuppress(_ block: () throws -> Void) rethrows {
    let log = Compatibility.settings.debugLog
    #if canImport(Foundation) && !(os(WASM) || os(WASI))
    let suppressThread = Thread.current // restrict the silencing to this thread/closure assuming no background tasks are doing printing
    #endif
    Compatibility.settings.debugLog = { message in
        #if canImport(Foundation) && !(os(WASM) || os(WASI))
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
@available(iOS 13, tvOS 13, watchOS 6, *) // due to Concurrency
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
#if !(os(WASM) || os(WASI))
@MainActor
#endif
@available(iOS 13, tvOS 13, watchOS 6, *)
public final class Test: ObservableObject {
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
    public var task: TestClosure
    @Published public var progress: TestProgress = .notStarted
    
    public init(_ title: String, _ task: @escaping TestClosure ) {
        self.title = title
        self.task = task
    }
    
    @available(iOS 13, tvOS 13, watchOS 6, *)
    public func run() {
        progress = .running
#if !(os(WASM) || os(WASI))
        // make sure to run the "work" in a separate thread since we don't want any of this running on the main thread and potentially bogging things down
        background {
            do {
                //await PHP.sleep(2)
                try await self.task()
                main { // editing progress must happen on main actor
                    self.progress = .pass
                }
            } catch {
                main {
                    debug(error.localizedDescription, level: .ERROR)
                    self.progress = .fail("\(error.localizedDescription)")
                }
            }
        }
        #else
        self.progress = .fail("Unable to run tests in WASM")
        #endif
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
@available(iOS 13, tvOS 13, watchOS 6, *)
public extension Test {
    static func dummyAsyncThrows() async throws {
    }
}

@available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
public extension Test {
    static let namedTests: OrderedDictionary<String, [Test]> = {
        var tests: OrderedDictionary = [
            "Version Tests": Version.tests,
            "Int Tests": Int.tests,
            "Double Tests": Double.tests,
            "Collection Tests": collectionTests,
            "String Tests": String.tests,
            "Dictionary Tests": dictionaryTests,
            "Debug Tests": DebugLevel.tests,
        ]
#if canImport(Foundation) && !(os(WASM) || os(WASI))
        tests["Application Tests"] = Application.tests
        tests["Bundle Tests"] = Bundle.tests
        tests["Date Tests"] = Date.tests
        tests["CharacterSet Tests"] = CharacterSet.tests
        tests["Threading Tests"] = KuThreading.tests
        tests["URL Tests"] = URL.tests
#if canImport(Combine)
        // unavailable on Linux
        tests["Network Tests"] = PostData.tests
#endif
#endif
        return tests
    }()
}

#if canImport(SwiftUI) && canImport(Foundation)
import SwiftUI
@available(iOS 13, tvOS 13, watchOS 6, *)
#Preview {
    TestsListView(tests: KuThreading.tests + Int.tests)
}
#endif
#endif
