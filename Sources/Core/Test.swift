public typealias TestClosure = @Sendable () async throws -> Void

/// A portable snapshot of the source location that initiated an operation.
public struct SourceContext: Sendable, CustomStringConvertible {
    public let file: String
    public let function: String
    public let line: Int
    public let column: Int

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

    public var description: String {
        "\(file):\(line):\(column) in \(function)"
    }
}

/// An expectation failure that retains the original source location for command-line and external test runners.
public struct TestFailure: Error, Sendable, CustomStringConvertible {
    public let message: String
    public let source: SourceContext

    public init(_ message: String, source: SourceContext = SourceContext()) {
        self.message = message
        self.source = source
    }

    public var description: String {
        "\(message) [\(source)]"
    }
}

#if canImport(Foundation)
extension TestFailure: LocalizedError {
    public var errorDescription: String? { description }
}
#endif

/// Sets an expectation for a reusable Compatibility test.
public func expect(
    _ condition: Bool,
    _ debugString: String? = nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    column: Int = #column
) throws {
    guard condition else {
        let source = SourceContext(file: file, function: function, line: line, column: column)
        let message: String
        if let debugString {
            message = debugString
        } else {
#if canImport(Foundation)
            let isMainThread = Thread.isMainThread
#else
            let isMainThread = true
#endif
            message = Compatibility.settings.debugFormat(
                "Expectation failed",
                .ERROR,
                isMainThread,
                Compatibility.settings.debugEmojiSupported,
                true,
                true,
                file,
                function,
                line,
                column
            )
        }
        debug(message, level: .ERROR, file: file, function: function, line: line, column: column)
        throw TestFailure(message, source: source)
    }
}

/// Requires two equatable values to be equal and reports both values when they differ.
public func expectEqual<Value: Equatable>(
    _ actual: Value,
    _ expected: Value,
    _ message: String? = nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    column: Int = #column
) throws {
    let context = message.map { " \($0)" } ?? ""
    try expect(
        actual == expected,
        "Expected \(String(reflecting: expected)), but received \(String(reflecting: actual)).\(context)",
        file: file,
        function: function,
        line: line,
        column: column
    )
}

/// Requires two equatable values to differ and reports the shared value when they do not.
public func expectNotEqual<Value: Equatable>(
    _ actual: Value,
    _ unexpected: Value,
    _ message: String? = nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    column: Int = #column
) throws {
    let context = message.map { " \($0)" } ?? ""
    try expect(
        actual != unexpected,
        "Expected a value other than \(String(reflecting: unexpected)), but received it.\(context)",
        file: file,
        function: function,
        line: line,
        column: column
    )
}

/// Suppresses debug messages during a synchronous execution block and always restores the prior logger.
public func debugSuppress(_ block: () throws -> Void) rethrows {
    let log = Compatibility.settings.debugLog
#if canImport(Foundation)
    let suppressThread = Thread.current
#endif
    Compatibility.settings.debugLog = { message in
#if canImport(Foundation)
        if Thread.current != suppressThread { log(message) }
#else
        log(message)
#endif
    }
    defer { Compatibility.settings.debugLog = log }
    try block()
}

/// Suppresses debug messages during an asynchronous execution block and always restores the prior logger.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public func debugSuppress(_ block: () async throws -> Void) async rethrows {
    let log = Compatibility.settings.debugLog
    Compatibility.settings.debugLog = { _ in }
    defer { Compatibility.settings.debugLog = log }
    try await block()
}

#if compiler(>=5.9)

/// Controls whether a reusable test may overlap other reusable tests.
public enum TestExecutionMode: Sendable {
    case parallel
    case serialized
}

private actor TestExecutionGate {
    static let shared = TestExecutionGate()
    private var isRunning = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func acquire() async {
        if !isRunning {
            isRunning = true
            return
        }
        await withCheckedContinuation { waiters.append($0) }
    }

    func release() {
        if waiters.isEmpty {
            isRunning = false
        } else {
            waiters.removeFirst().resume()
        }
    }
}

private struct TestExecution: Sendable {
    let title: String
    let setUp: TestClosure?
    let test: TestClosure
    let tearDown: TestClosure?
    let mode: TestExecutionMode

    func perform() async throws {
        if mode == .serialized {
            await TestExecutionGate.shared.acquire()
        }

        do {
            try await performLifecycle()
            if mode == .serialized {
                await TestExecutionGate.shared.release()
            }
        } catch {
            if mode == .serialized {
                await TestExecutionGate.shared.release()
            }
            throw error
        }
    }

    private func performLifecycle() async throws {
        let previousSettings = Compatibility.settings
        defer { Compatibility.settings = previousSettings }

        var primaryError: (any Error)?
        do {
            try await setUp?()
            try await test()
        } catch {
            primaryError = error
        }

        do {
            try await tearDown?()
        } catch {
            if let primaryError {
                debug("\(title) teardown also failed: \(error)", level: .ERROR)
                throw primaryError
            }
            throw error
        }

        if let primaryError {
            throw primaryError
        }
    }
}

@MainActor
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public final class TestCase: ObservableObject, @unchecked Sendable {
    private final class WeakReference<T: AnyObject>: @unchecked Sendable {
        weak var value: T?
        init(_ value: T?) { self.value = value }
    }

    public enum TestProgress: Sendable {
        case notStarted
        case running
        case pass
        case fail(String)

        public var symbol: String {
            switch self {
            case .notStarted: "❇️"
            case .running: "🔄"
            case .pass: "✅"
            case .fail: "⛔"
            }
        }

        public var errorMessage: String? {
            if case let .fail(message) = self { message } else { nil }
        }
    }

    public let title: String
    public let setUp: TestClosure?
    public var test: TestClosure
    public let tearDown: TestClosure?
    public let executionMode: TestExecutionMode

    @available(*, deprecated, renamed: "test")
    public var task: TestClosure {
        get { test }
        set { test = newValue }
    }

    @Published public var progress: TestProgress = .notStarted

    public init(
        _ title: String,
        executionMode: TestExecutionMode = .parallel,
        setUp: TestClosure? = nil,
        test: @escaping TestClosure,
        tearDown: TestClosure? = nil
    ) {
        self.title = title
        self.executionMode = executionMode
        self.setUp = setUp
        self.test = test
        self.tearDown = tearDown
    }

    public convenience init(
        _ title: String,
        executionMode: TestExecutionMode = .parallel,
        _ test: @escaping TestClosure
    ) {
        self.init(title, executionMode: executionMode, test: test)
    }

    private var execution: TestExecution {
        TestExecution(title: title, setUp: setUp, test: test, tearDown: tearDown, mode: executionMode)
    }

    public func execute() async throws {
        try await execution.perform()
    }

    public func run() {
        guard progress != .running else { return }
        let execution = execution
        let weakSelf = WeakReference(self)
        progress = .running

        Task.detached(priority: .userInitiated) {
            do {
                try await execution.perform()
                await MainActor.run { weakSelf.value?.progress = .pass }
            } catch {
                let message = String(describing: error)
                debug("\(execution.title) failed: \(message)", level: .ERROR)
                await MainActor.run { weakSelf.value?.progress = .fail(message) }
            }
        }
    }

    public func isFinished() -> Bool {
        switch progress {
        case .pass, .fail: true
        default: false
        }
    }

    public func succeeded() -> Bool {
        if case .pass = progress { true } else { false }
    }

    public var errorMessage: String? { progress.errorMessage }

    public var description: String {
        let error = progress.errorMessage.map { "\n\t\($0)" } ?? ""
        return "\(progress): \(title)\(error)"
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@available(*, deprecated, renamed: "TestCase")
public typealias Test = TestCase

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension TestCase {
    static func dummyAsyncThrows() async throws {}
}

@available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
public extension TestCase {
    @MainActor
    static let namedTests: OrderedDictionary<String, [TestCase]> = {
        var tests: OrderedDictionary = [
            "Expectation Tests": [
                TestCase("Equality diagnostics") {
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
        tests.merge(["Coding Tests": codingTests]) { current, _ in current }
        tests["Bundle Tests"] = Bundle.tests
        tests["File Manager Tests"] = FileManager.tests
        tests["Pasteboard Tests"] = Pasteboard.tests
        tests["CharacterSet Tests"] = CharacterSet.tests
        tests["URL Tests"] = URL.tests
        tests["Date Tests"] = Date.tests
        tests["Threading Tests"] = Compatibility.threadingTests
#if canImport(Combine) || canImport(FoundationNetworking)
        tests["Network Tests"] = PostData.tests
#endif
#endif
        return tests
    }()
}

@available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
public extension Compatibility {
    @MainActor
    static var tests: OrderedDictionary<String, [TestCase]> { TestCase.namedTests }
}

#if canImport(SwiftUI) && canImport(Foundation)
import SwiftUI
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview {
    TestsListView(tests: Compatibility.threadingTests + Int.tests)
}
#endif
#endif
