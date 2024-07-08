import Foundation

// TODO: Once Swift Testing is available, can re-write all this code into test classes that conform to Swift Testing so that we can also run code in Previews and Test Applications?
public typealias TestClosure = () async throws -> Void

// don't make this public to avoid compiling test stuff into framework, however, do make public so apps can add in their own tests.
public protocol Testable {
    // actor isolated since each Test is @MainActor isolated due to being an ObservableObject.
    @MainActor static var tests: [Test] { get }
}

// TODO: NEXT: Convert these to Testing expectations so we don't have to write custom error descriptions.
/// Sets an expectation for testing.  In the future, convert to Swift #expect calls so we get better context without specifying a debugString.
public func expect(_ condition: Bool, _ debugString: String? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) throws {
    guard condition else {
        if let debugString {
            throw CustomError(debugString)
        } else {
            let context = debugContext(isMainThread: Thread.isMainThread, file: file, function: function, line: line, column: column)
            throw CustomError(context)
        }
    }
}

// Test Handlers
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
    #if canImport(Combine)
    @Published
    #endif
    public var progress: TestProgress = .notStarted
    
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
                self.progress = .pass
            } catch {
                self.progress = .fail("\(error)")
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
public extension Test {
    static func dummyAsyncThrows() async throws {
    }
}

#if canImport(SwiftUI)
import SwiftUI
#Preview {
    TestsListView(tests: KuThreading.tests + Int.tests)
}
#endif
