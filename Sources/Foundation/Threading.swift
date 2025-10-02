//
//  Threading.swift
//  KuditFrameworks
//
//  Created by Ben Ku on 5/7/16.
//  Copyright © 2016 Kudit. All rights reserved.
//

#if (os(WASM) || os(WASI))
/// Backport of main that does nothing since threads are not supported on WASM
public func main(_ closure: @Sendable @escaping () -> Void) {
    closure()
}
#endif

#if (os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || os(visionOS) || os(Linux)) && canImport(Foundation) // Don't run on WASM or Android
// Use built-in Thread and Dispatch
#elseif !(os(WASM) || os(WASI)) // not supported on WASM or Android
// Backport Thread for code on WASM or Android
// None of this is public since this is just for internal supports.
struct Thread: Sendable, Equatable {
    static let isMainThread = true
    static let current = Thread()
}
struct DispatchTime : Sendable, CustomStringConvertible {
    #if canImport(Foundation)
    var time = Date.nowBackport
    #endif
    static func now() -> DispatchTime {
        return DispatchTime()
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
        return DispatchTime() // UNAVAILABLE
        #endif
    }
}
struct DispatchQueue: Sendable {
    static let main = DispatchQueue()
    static func global() -> DispatchQueue {
        return .main
    }
    @preconcurrency func async(execute work: @escaping @Sendable @convention(block) () -> Void) {
        debug("This code was supposed to be executed asynchronously but will be executed synchronously since async is not supported on this platform.", level: .WARNING)
        work()
    }
    @preconcurrency func asyncAfter(deadline: DispatchTime, execute work: @escaping @Sendable @convention(block) () -> Void) {
        debug("This code was supposed to be executed at \(deadline) but will be executed immediately instead.", level: .WARNING)
        // eventually, figure out how to execute delayed, but for now, just execute immediately
        work()
    }
}
#endif


func timeTolerance(start: TimeInterval, end: TimeInterval, expected: TimeInterval) throws {
    let timeElapsed = end - start
    // should never be negative
    let delta = timeElapsed - expected
    try expect(delta >= 0, "Somehow took less time than expected: \(timeElapsed) / \(expected)")
    let timeTolerances: TimeInterval = 0.4 // shouldn't be more than .4 seconds late and shouldn't ever be early
    try expect(delta < timeTolerances, "took \(delta) seconds (expecting \(expected) sec difference)")
}

#if !(os(WASM) || os(WASI)) // unable to run this on WASM
// Implemented as static funcs with global wrappers in case something like View creates similarly named functions like background and we need to reference this specific version.

// would have made this a static function on task but extending it apparently has issues??
// Sleep extension for sleeping a thread in seconds
@available(iOS 13, tvOS 13, watchOS 6, *) // for concurrency
public func sleep(seconds: Double, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) async {
    await Compatibility.sleep(seconds: seconds, file: file, function: function, line: line, column: column)
}
public extension Compatibility {
    @available(iOS 13, tvOS 13, watchOS 6, *) // for concurrency
    static func sleep(seconds: Double, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) async {
        let duration = UInt64(seconds * 1_000_000_000)
        do {
            try await Task.sleep(nanoseconds: duration)
            //            // Fallback on earlier versions
            //            sleep(UInt32(seconds)) // give fetch from server time to finish
        } catch {
            // do nothing but make debug log if we can.
            debug("Sleep function was interrupted", level: .DEBUG, file: file, function: function, line: line, column: column)
        }
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *) // for concurrency
@MainActor
internal let testSleep3: TestClosure = {
    #if canImport(Foundation)
    let then = Date.timeIntervalSinceReferenceDate
    let seconds: TimeInterval = 3
    await sleep(seconds: seconds)
    let now = Date.timeIntervalSinceReferenceDate
    try timeTolerance(start: then, end: now, expected: seconds)
    #endif
}
@available(iOS 13, tvOS 13, watchOS 6, *) // for concurrency
@MainActor
internal let testSleep2: TestClosure = {
    #if canImport(Foundation)
    let start = Date.timeIntervalSinceReferenceDate
    await sleep(seconds: 2)
    let end = Date.timeIntervalSinceReferenceDate
    try timeTolerance(start: start, end: end, expected: 2)
    #endif
}

//// TODO: make sure all this is replace with new async-await code.
///// Support locking to make sure multiple threads aren't trying to operate simultaneously.
///// Requires a reference-type object.
//// TODO: Note: used in WebCache
//public func synchronized(_ lock: AnyObject, closure: () -> Void) {
//    objc_sync_enter(lock)
//    defer { // make sure this gets released even if exit the loop prematurely
//        objc_sync_exit(lock)
//    }
//    closure()
//}

// MARK: - Background Tasks
// Restored background { for image processing or other large async task: Avoid heavy synchronous work within Task. Use custom DispatchQueue when heavy work like image processing is required.https://wojciechkulik.pl/ios/swift-concurrency-things-they-dont-tell-you

/// run potentially long-running code on a background thread
@available(iOS 13, tvOS 13, watchOS 6, *)
public func background(_ closure: @Sendable @escaping () async -> Void) {
    Compatibility.background(closure)
}
/// Run potentially long-running code on a background thread.  Available as a fallback for earlier versions that don't support concurrency or for code that doesn't await (synchronous but possibly long-running)
public func background(_ closure: @Sendable @escaping () -> Void) {
    Compatibility.background(closure)
}
@available(iOS 13, tvOS 13, watchOS 6, *)
public func background<ReturnType: Sendable>(_ closure: @Sendable @escaping () async throws -> ReturnType) async throws -> ReturnType {
    try await Compatibility.background(closure)
}
@available(iOS 13, tvOS 13, watchOS 6, *)
public func background<ReturnType: Sendable>(_ closure: @Sendable @escaping () async -> ReturnType?) async -> ReturnType? {
    await Compatibility.background(closure)
}
public extension Compatibility {
    @available(iOS 13, tvOS 13, watchOS 6, *)
    static func background(_ closure: @Sendable @escaping () async -> Void) {
        // run this block code on a background thread
        // new concurrency method:
        Task.detached(priority: .background) {
            // background code here
            await closure()
        }
    }
    /// Run potentially long-running code on a background thread.  Available as a fallback for earlier versions that don't support concurrency or for code that doesn't await (synchronous but possibly long-running)
    static func background(_ closure: @Sendable @escaping () -> Void) {
        if #available(iOS 13, tvOS 13, watchOS 6, *) {
            let asyncFunc: @Sendable () async -> Void = {
                closure()
            }
            background {
                await asyncFunc()
            }
        } else {
            // Fallback on earlier versions
            // old queue method:
            DispatchQueue.global().async {
                // background code here
                closure()
            }
        }
    }
    /// Throwable return background task.
    @available(iOS 13, tvOS 13, watchOS 6, *)
    static func background<ReturnType: Sendable>(_ closure: @Sendable @escaping () async throws -> ReturnType) async throws -> ReturnType {
        #if canImport(Foundation)
        let longRunningTask = Task.detached(priority: .background) {
            return try await closure()
        }
        let result = await longRunningTask.result
        return try result.get()
        #else
        return try await closure()
        #endif
    }
    /// Non-throwing return background task.  Return type must be an optional since there could be some error thrown by `result.get()` (though practically that should never happen)
    @available(iOS 13, tvOS 13, watchOS 6, *)
    static func background<ReturnType: Sendable>(_ closure: @Sendable @escaping () async -> ReturnType?) async -> ReturnType? {
        let longRunningTask = Task.detached(priority: .background) {
            return await closure()
        }
        let result = await longRunningTask.result
#if compiler(>=6) // DEBUG // compiler(>=6) doesn't seem to work in Xcode with Swift 6.  We would just switch but Swift Playgrounds still only supports Swift 5.10 and iOS 17.  DEBUG does seem to allow differentiation between XCode and Playgrounds though may cause errors in release builds.  compiler does seem to work!!
        return result.get()
#else
        do {
            return try result.get()
        } catch {
            debug("This shouldn't ever happen and is no longer a try in Swift 6!", level: .ERROR)
            return nil
        }
#endif
    }
}

@MainActor
internal let testBackground: TestClosure = {
#if canImport(Foundation)
    let start = Date.timeIntervalSinceReferenceDate
    let end: TimeInterval
    if #available(iOS 13, tvOS 13, watchOS 6, *) {
        end = await withCheckedContinuation { continuation in
            background {
                await sleep(seconds: 4)
                let end = Date.timeIntervalSinceReferenceDate
                continuation.resume(returning: end)
            }
        }
    } else {
        // NOTE: We don't expect this to work or pass on non iOS 13+ systems.
        // Fallback on earlier versions
//        await sleep(seconds: 4)
        end = Date.timeIntervalSinceReferenceDate
        // run background just for testing (will not actually affect test though)
//        _ = try await background {
////            sleep(4)
//            debug("Legacy Background task finished.", level: .DEBUG)
//        }
    }
    try timeTolerance(start: start, end: end, expected: 4)
#endif
}

// MARK: - Main

/// run code on the main thread
public func main(_ closure: @Sendable @MainActor @escaping () -> Void) {
    Compatibility.main(closure)
}
public extension Compatibility {
    /// run code on the main thread
    #if !(os(WASM) || os(WASI))
    static func main(_ closure: @Sendable @MainActor @escaping () -> Void) {
        if #available(iOS 13, tvOS 13, watchOS 6, *) {
            Task { @MainActor in
                // finish up on main thread
                closure()
            }
        } else {
            // Fallback on earlier versions
            DispatchQueue.main.async { @MainActor in
                // finish up on main thread
                closure()
            }
        }
    }
    #else
    /// Run code on main thread - all code is executed on main thread already in embedded systems.
    static func main(_ closure: @Sendable @escaping () -> Void) {
        closure()
    }
    #endif
}

@available(iOS 13, tvOS 13, watchOS 6, *)
@MainActor
internal let testMain: TestClosure = {
    #if os(macOS) && canImport(Foundation)
    // test shell script
    let volumesOutput = try safeShell("ls -la /Volumes")
//    debug(volumesOutput)
    try expect(volumesOutput.contains("Macintosh HD"), "Unexpected shell output: \(volumesOutput)")
    #endif
    
    let runOnMainThread = await withCheckedContinuation { continuation in
        main {
            let isMainThread = Thread.isMainThread
            continuation.resume(returning: isMainThread)
        }
    }
    try expect(runOnMainThread, "main { } was not run on the main thread!")
}

// from http://stackoverflow.com/questions/24034544/dispatch-after-gcd-in-swift
/**
Utility function to delay execution of code by a certain amount of seconds.

Usage:
```
delay(0.4) {
// do stuff
}
```
*/
/// run the block of code on the main thread after the `delay` (in seconds) have passed.
public func delay(_ delay:Double, closure: @Sendable @escaping () -> Void) {
    Compatibility.delay(delay, closure: closure)
}
public extension Compatibility {
    /**
    Utility function to delay execution of code by a certain amount of seconds.

    Usage:
    ```
    delay(0.4) {
    // do stuff
    }
    ```
    */
    /// run the block of code on the current thread after the `delay` (in seconds) have passed.  If this is before iOS 13, tvOS 13, and watchOS 6, will be run on the main thread rather than the same thread..
    static func delay(_ delay:Double, closure: @Sendable @escaping () -> Void) {
        if #available(iOS 13, tvOS 13, watchOS 6, *) {
            Task {
                await sleep(seconds: delay)
                closure()
            }
        } else {
            // Fallback on earlier versions
            DispatchQueue.global().asyncAfter(
                // delay below was previously: Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                deadline: DispatchTime.now() + delay, execute: closure)
        }
    }
}

@available(iOS 13, tvOS 13, watchOS 6, *) // for concurrency
@MainActor
internal let testDelay: TestClosure = {
    #if canImport(Foundation)
    let start = Date.timeIntervalSinceReferenceDate
    let delayTime = 0.4
    var end: TimeInterval
    end = await withCheckedContinuation { continuation in
        delay(delayTime) {
            let end = Date.timeIntervalSinceReferenceDate
            continuation.resume(returning: end)
        }
    }
//    } else {
//        // Fallback on earlier versions
//        delay(delayTime) {
//            debug("Legacy delay task finished.", level: .DEBUG)
//        }
//        // run delay just for testing (will not actually affect test though)
//        await sleep(seconds: delayTime)
//        end = Date.timeIntervalSinceReferenceDate
//    }
    try timeTolerance(start: start, end: end, expected: delayTime)
    #endif
}

// Testing is only supported with Swift 5.9+
#if compiler(>=5.9)
@available(iOS 13, tvOS 13, watchOS 6, *)
struct KuThreading {
    @MainActor
    public static let tests: [Test] = [
        Test("main", testMain),
        Test("delay(0.4)", testDelay),
        Test("sleep 2", testSleep2),
        Test("sleep 3", testSleep3),
        Test("background 4", testBackground),
    ]
}

#if canImport(SwiftUI) && canImport(Foundation)
import SwiftUI
@available(iOS 13, tvOS 13, watchOS 6, *)
#Preview("Tests") {
    TestsListView(tests: KuThreading.tests)
}
#endif
#endif
#endif
