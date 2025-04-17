// TODO: Once Swift Testing is available, can re-write all this code into test classes that conform to Swift Testing so that we can also run code in Previews and Test Applications?
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
        if let debugString {
            throw CustomError(debugString)
        } else {
            let context = Compatibility.settings.debugFormat(
                "",
                .OFF,
                Thread.isMainThread,
                Compatibility.settings.debugEmojiSupported,
                true,
                Compatibility.settings.debugIncludeTimestamp,
                file, function, line, column)

            throw CustomError(context)
        }
    }
}

// Test Handlers
@available(iOS 13, tvOS 13, watchOS 6, *) // due to ObservableObject
@MainActor
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
    
    public func run() {
        progress = .running
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
                    self.progress = .fail("\(error.localizedDescription)")
                }
            }
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
    static let namedTests: OrderedDictionary = [
        "Version Tests": Version.tests,
        "Int Tests": Int.tests,
        "Collection Tests": collectionTests,
        "Date Tests": Date.tests,
        "String Tests": String.tests,
        "CharacterSet Tests": CharacterSet.tests,
        "Threading Tests": KuThreading.tests,
        "Network Tests": PostData.tests,
    ]
}

#if canImport(SwiftUI) && compiler(>=5.9)
import SwiftUI
@available(iOS 13, tvOS 13, watchOS 6, *)
#Preview {
    TestsListView(tests: KuThreading.tests + Int.tests)
}
#endif
