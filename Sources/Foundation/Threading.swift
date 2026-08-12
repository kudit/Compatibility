//
//  Threading.swift
//  KuditFrameworks
//
//  Created by Ben Ku on 5/7/16.
//  Copyright © 2016 Kudit. All rights reserved.
//

// MARK: - Thread Backports

#if (os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(Linux)) && canImport(Foundation)
// Apple platforms and Linux use Foundation's Thread and Dispatch implementations.
#else
/// Minimal thread identity for single-threaded platforms.
///
/// This intentionally reports every call as main-thread work; it does not pretend to provide
/// parallel execution where the platform runtime has none.
struct Thread: Sendable, Equatable {
    static let isMainThread = true
    static let current = Thread()
}

#if !arch(wasm32)
/// Minimal dispatch deadline used by platforms that lack Foundation but support callable closures.
struct DispatchTime: Sendable, CustomStringConvertible {
#if canImport(Foundation)
    var time = Date.nowBackport
#endif

    static func now() -> DispatchTime {
        DispatchTime()
    }

    var description: String {
#if canImport(Foundation)
        return time.description
#else
        return "UNAVAILABLE"
#endif
    }

    static func + (lhs: DispatchTime, rhs: Double) -> DispatchTime {
#if canImport(Foundation)
        return DispatchTime(time: lhs.time + rhs)
#else
        return DispatchTime()
#endif
    }
}

/// Synchronous dispatch fallback for non-Foundation platforms without WebAssembly restrictions.
struct DispatchQueue: Sendable {
    static let main = DispatchQueue()

    static func global() -> DispatchQueue {
        .main
    }

    @preconcurrency func async(execute work: @escaping @Sendable @convention(block) () -> Void) {
        debug("Asynchronous execution is unavailable; running the block synchronously.", level: .WARNING)
        work()
    }

    @preconcurrency func asyncAfter(deadline: DispatchTime, execute work: @escaping @Sendable @convention(block) () -> Void) {
        debug("Delayed execution is unavailable; running the block immediately instead of at \(deadline).", level: .WARNING)
        work()
    }
}
#endif
#endif

#if canImport(Foundation)
/// Verifies that delayed work did not complete early or drift beyond the bounded host tolerance.
private func timeTolerance(start: TimeInterval, end: TimeInterval, expected: TimeInterval) throws {
    let timeElapsed = end - start
    let delta = timeElapsed - expected
    try expect(delta >= 0, "Somehow took less time than expected: \(timeElapsed) / \(expected)")
    // Permit up to eight seconds of host scheduling drift without restoring the former 30-second window.
    let timeTolerance: TimeInterval = min(8, max(1, expected * 2))
    try expect(delta < timeTolerance, "took \(delta) seconds (expecting \(expected) sec difference)")
}
#endif

// MARK: - Sleep

#if arch(wasm32)
public extension Compatibility {
    /// WebAssembly compatibility spelling for sleep.
    ///
    /// A generic WebAssembly host does not guarantee a suspending timer, so this returns immediately
    /// while preserving cross-platform source compatibility for code that does not require a delay.
    static func sleep(
        seconds: Double,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) {
        sleep(
            seconds: seconds,
            source: SourceContext(file: file, function: function, line: line, column: column)
        )
    }

    /// Source-forwarding form for helpers that already captured the original call site.
    static func sleep(seconds: Double, source: SourceContext) {
        // This gate describes the missing timer primitive, not missing Swift concurrency support:
        // browser hosts must schedule a JavaScript timer while WASI hosts use host-specific clocks.
        Compatibility.debug(
            "Sleep is unavailable on this WebAssembly runtime; no delay occurred. Prefer an asynchronous host timer for browser or WASI code.",
            level: .WARNING,
            source: source
        )
    }
}

/// Legacy WebAssembly sleep spelling retained as an immediate compatibility fallback.
@available(*, deprecated, renamed: "Compatibility.sleep(seconds:)", message: "Use Compatibility.sleep(seconds:) instead.")
public func sleep(
    seconds: Double,
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    column: Int = #column
) {
    Compatibility.sleep(
        seconds: seconds,
        source: SourceContext(file: file, function: function, line: line, column: column)
    )
}
#else
public extension Compatibility {
    /// Suspends the current asynchronous task for a number of seconds.
    ///
    /// Cancellation is reported at the original call site and otherwise remains nonthrowing for
    /// compatibility with the original helper.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    static func sleep(
        seconds: Double,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) async {
        await sleep(
            seconds: seconds,
            source: SourceContext(file: file, function: function, line: line, column: column)
        )
    }

    /// Source-forwarding form for helpers that already captured the original call site.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    static func sleep(seconds: Double, source: SourceContext) async {
        let duration = UInt64(seconds * 1_000_000_000)
        do {
            try await Task.sleep(nanoseconds: duration)
            // Potential fallback for earlier versions/backport?  Likely unnecessary/unusable due to async but may be useful for a synchronous fallback?:
            // sleep(UInt32(seconds)) // give fetch from server time to finish
        } catch {
            // do nothing but make debug log if we can.
            Compatibility.debug("Sleep function was interrupted", level: .DEBUG, source: source)
        }
    }
}

/// Legacy unqualified sleep retained for source compatibility.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@available(*, deprecated, renamed: "Task.sleep(seconds:)", message: "Use Task.sleep(seconds:) or Compatibility.sleep(seconds:) instead.")
public func sleep(
    seconds: Double,
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    column: Int = #column
) async {
    await Compatibility.sleep(
        seconds: seconds,
        source: SourceContext(file: file, function: function, line: line, column: column)
    )
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Task where Success == Never, Failure == Never {
    /// Preferred concise spelling for Compatibility's seconds-based sleep helper.
    static func sleep(
        seconds: Double,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) async {
        await Compatibility.sleep(
            seconds: seconds,
            source: SourceContext(file: file, function: function, line: line, column: column)
        )
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
private let sleepTests: [TestCase] = [
    TestCase("Task.sleep 0.05") {
#if canImport(Foundation)
        let start = Date.timeIntervalSinceReferenceDate
        // A short real suspension verifies the helper without making every live-UI run wait seconds.
        await Task.sleep(seconds: 0.05)
        try timeTolerance(start: start, end: Date.timeIntervalSinceReferenceDate, expected: 0.05)
#endif
    },
    TestCase("Task.sleep 0.1") {
#if canImport(Foundation)
        let start = Date.timeIntervalSinceReferenceDate
        // A second duration guards against accidentally hardcoding the first test interval.
        await Task.sleep(seconds: 0.1)
        try timeTolerance(start: start, end: Date.timeIntervalSinceReferenceDate, expected: 0.1)
#endif
    },
    TestCase("Task.sleep 2 (visual confirmation)") {
#if canImport(Foundation)
        let start = Date.timeIntervalSinceReferenceDate
        // Keep a visibly long row so the live test UI makes running and passing transitions easy to inspect.
        await Task.sleep(seconds: 2)
        try timeTolerance(start: start, end: Date.timeIntervalSinceReferenceDate, expected: 2)
#endif
    },
    TestCase("Task.sleep 3 (visual confirmation)") {
#if canImport(Foundation)
        let start = Date.timeIntervalSinceReferenceDate
        // This runs alongside the two-second row in runners that support concurrent test execution.
        await Task.sleep(seconds: 3)
        try timeTolerance(start: start, end: Date.timeIntervalSinceReferenceDate, expected: 3)
#endif
    },
]
#endif

// MARK: - Background Tasks

// A background helper must actually move work away from the caller. Do not provide a WASM/Embedded
// syntax-only fallback that executes synchronously: that masks threading assumptions and can turn
// otherwise-correct code into blocking work. These APIs are therefore unavailable on WASM/Embedded.
#if !arch(wasm32) && !hasFeature(Embedded)
public extension Compatibility {
    /// Runs potentially long synchronous work away from the main queue when threads are available.
    static func background(
        _ closure: @Sendable @escaping () -> Void,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) {
        DispatchQueue.global().async {
//          Compatibility.debug("Running background block", level: .DEBUG, source: SourceContext(file: file, function: function, line: line, column: column))
            closure()
        }
    }

    /// Starts nonthrowing asynchronous work in a detached background task.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    static func background(_ closure: @Sendable @escaping () async -> Void) { // TODO: Should this capture SourceContext for debugging?
        Task.detached(priority: .background) {
//            Compatibility.debug("Running asynchronous background block", level: .DEBUG, source: SourceContext(file: file, function: function, line: line, column: column))
            await closure()
        }
    }

    /// Runs throwing asynchronous work in a detached task and returns its value.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    static func background<ReturnType: Sendable>(
        _ closure: @Sendable @escaping () async throws -> ReturnType
    ) async throws -> ReturnType {
#if canImport(Foundation)
        return try await Task.detached(priority: .background, operation: closure).value
#else
        // A full Swift runtime can still provide detached tasks without Foundation.
        return try await Task.detached(priority: .background, operation: closure).value
#endif
    }

    /// Runs nonthrowing asynchronous work that returns an optional value.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    static func background<ReturnType: Sendable>(
        _ closure: @Sendable @escaping () async -> ReturnType?
    ) async -> ReturnType? {
        await Task.detached(priority: .background, operation: closure).value
    }
}

/// Runs synchronous work away from the main queue using the concise, deployment-compatible spelling.
///
/// Use ``Compatibility/background(_:file:function:line:column:)`` when another API, such as
/// SwiftUI's `View.background`, makes the unqualified name ambiguous. Callers that already require
/// iOS 13, macOS 10.15, tvOS 13, or watchOS 6 should instead use `Task.background`.
public func background(_ closure: @Sendable @escaping () -> Void) {
    // Keep this concise API independent of Swift concurrency so callers can deploy before iOS 13.
    Compatibility.background(closure)
}

/// Legacy unqualified asynchronous background helper retained for source compatibility.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@available(*, deprecated, renamed: "Task.background", message: "Use Compatibility.background or Task.background instead.")
public func background(_ closure: @Sendable @escaping () async -> Void) {
    Compatibility.background(closure)
}

/// Legacy unqualified throwing background helper retained for source compatibility.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@available(*, deprecated, renamed: "Task.background", message: "Use Compatibility.background or Task.background instead.")
public func background<ReturnType: Sendable>(
    _ closure: @Sendable @escaping () async throws -> ReturnType
) async throws -> ReturnType {
    try await Compatibility.background(closure)
}

/// Legacy unqualified optional-returning background helper retained for source compatibility.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@available(*, deprecated, renamed: "Task.background", message: "Use Compatibility.background or Task.background instead.")
public func background<ReturnType: Sendable>(
    _ closure: @Sendable @escaping () async -> ReturnType?
) async -> ReturnType? {
    await Compatibility.background(closure)
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Task where Success == Never, Failure == Never {
    /// Preferred concise spelling for nonthrowing detached background work.
    static func background(_ closure: @Sendable @escaping () async -> Void) {
        Compatibility.background(closure)
    }

    /// Preferred concise spelling for throwing detached background work.
    static func background<ReturnType: Sendable>(
        _ closure: @Sendable @escaping () async throws -> ReturnType
    ) async throws -> ReturnType {
        try await Compatibility.background(closure)
    }

    /// Preferred concise spelling for optional-returning detached background work.
    static func background<ReturnType: Sendable>(
        _ closure: @Sendable @escaping () async -> ReturnType?
    ) async -> ReturnType? {
        await Compatibility.background(closure)
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
private let backgroundTests: [TestCase] = [
    TestCase("Compatibility.background execution") {
        let executed = await withCheckedContinuation { continuation in
            Compatibility.background {
                // Dispatch-backed execution avoids background-priority task starvation in loaded test runners.
                continuation.resume(returning: true)
            }
        }
        try expect(executed, "Compatibility.background did not execute its closure")
    },
]
#endif

// MARK: - Main

// As with background work, do not claim a main-dispatch helper exists on WASM/Embedded by simply
// executing the closure inline. Code that requires this scheduling API should fail to compile there
// until that runtime has a real implementation with the advertised semantics.
#if !arch(wasm32) && !hasFeature(Embedded)
public extension Compatibility {
    /// Schedules work on the main actor using concurrency or the older dispatch fallback.
    static func main(
        _ closure: @Sendable @MainActor @escaping () -> Void,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) {
        if #available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *) {
            Task { @MainActor in
                //                debug("Running main-thread block", level: .DEBUG, file: file, function: function, line: line, column: column)
                closure()
            }
        } else {
            DispatchQueue.main.async { @MainActor in
                closure()
            }
        }
    }
}

/// Schedules work on the main actor using the concise, deployment-compatible spelling.
///
/// Use ``Compatibility/main(_:file:function:line:column:)`` when an unqualified `main` name is ambiguous.
/// Callers that already require iOS 13, macOS 10.15, tvOS 13, or watchOS 6 can instead use `Task.main`.
public func main(
    _ closure: @Sendable @MainActor @escaping () -> Void,
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    column: Int = #column
) {
    // Keep this concise API available before Swift concurrency by forwarding to the dispatch-capable implementation.
    Compatibility.main(closure, file: file, function: function, line: line, column: column)
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Task where Success == Never, Failure == Never {
    /// Preferred concise spelling for scheduling main-actor work.
    static func main(
        _ closure: @Sendable @MainActor @escaping () -> Void,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) {
        Compatibility.main(closure, file: file, function: function, line: line, column: column)
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
private let mainTests: [TestCase] = [
    TestCase("main") {
#if os(macOS) && canImport(Foundation)
        let volumesOutput = try safeShell("ls -la /Volumes")
        try expect(volumesOutput.contains("Macintosh HD"), "Unexpected shell output: \(volumesOutput)")
#endif
        let ranOnMainThread = await withCheckedContinuation { continuation in
            // Exercise the concise spelling so future deprecation or availability regressions are caught.
            main {
                continuation.resume(returning: Thread.isMainThread)
            }
        }
        try expect(ranOnMainThread, "main { } was not run on the main thread")
    },
]
#endif

// MARK: - Delay

public extension Compatibility {
    /// Runs a closure after a delay, using dispatch when Swift concurrency is unavailable.
    static func delay(_ seconds: Double, closure: @Sendable @escaping () -> Void) {
#if arch(wasm32)
        // WebAssembly has no blocking or asynchronous delay fallback in this compatibility layer.
        closure()
#else
        if #available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *) {
            Task {
                await Task.sleep(seconds: seconds)
                closure()
            }
        } else {
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + seconds, execute: closure)
        }
#endif
    }
}

/// Legacy unqualified delay helper retained for source compatibility.
@available(*, deprecated, renamed: "Task.delay", message: "Use Compatibility.delay or Task.delay instead.")
public func delay(_ seconds: Double, closure: @Sendable @escaping () -> Void) {
    Compatibility.delay(seconds, closure: closure)
}

#if !arch(wasm32)
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Task where Success == Never, Failure == Never {
    /// Preferred concise spelling for Compatibility's delayed closure helper.
    static func delay(_ seconds: Double, closure: @Sendable @escaping () -> Void) {
        Compatibility.delay(seconds, closure: closure)
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
private let delayTests: [TestCase] = [
    TestCase("Task.delay 0.05") {
#if canImport(Foundation)
        let start = Date.timeIntervalSinceReferenceDate
        let end = await withCheckedContinuation { continuation in
            Task.delay(0.05) {
                continuation.resume(returning: Date.timeIntervalSinceReferenceDate)
            }
        }
        try timeTolerance(start: start, end: end, expected: 0.05)
#endif
    },
]
#endif

// MARK: - Tests and Previews
#if compiler(>=5.9)
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Compatibility {
    /// Reusable threading checks grouped without adding another public namespace.
    @MainActor
    static let threadingTests: [TestCase] = {
#if arch(wasm32) || hasFeature(Embedded)
        // WASM/Embedded intentionally omit background/main helpers rather than providing synchronous
        // semantic fallbacks, and generic WASM hosts do not provide the timing guarantees tested here.
        return []
#else
        return sleepTests + backgroundTests + mainTests + delayTests
#endif
    }()
}

#if canImport(SwiftUI) && canImport(Foundation)
import SwiftUI

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("Tests") {
    TestsListView(tests: Compatibility.threadingTests)
}
#endif
#endif
