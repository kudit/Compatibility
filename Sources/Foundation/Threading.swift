//
//  Threading.swift
//  KuditFrameworks
//
//  Created by Ben Ku on 5/7/16.
//  Copyright © 2016 Kudit. All rights reserved.
//

func timeTolerance(start: TimeInterval, end: TimeInterval, expected: TimeInterval) throws {
    let timeElapsed = end - start
    // should never be negative
    let delta = timeElapsed - expected
    try expect(delta >= 0, "Somehow took less time than expected: \(timeElapsed) / \(expected)")
    let timeTolerances: TimeInterval = 0.4 // shouldn't be more than .4 seconds late and shouldn't ever be early
    try expect(delta < timeTolerances, "took \(delta) seconds (expecting \(expected) sec difference)")
}

// would have made this a static function on task but extending it apparently has issues??
// Sleep extension for sleeping a thread in seconds
@available(iOS 13, watchOS 6, tvOS 13, *) // for concurrency
public func sleep(seconds: Double, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) async {
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
@available(iOS 13, watchOS 6, tvOS 13, *) // for concurrency
@MainActor
internal let testSleep3: TestClosure = {
    let then = Date.timeIntervalSinceReferenceDate
    let seconds: TimeInterval = 3
    await sleep(seconds: seconds)
    let now = Date.timeIntervalSinceReferenceDate
    try timeTolerance(start: then, end: now, expected: seconds)
}
@available(iOS 13, watchOS 6, tvOS 13, *) // for concurrency
@MainActor
internal let testSleep2: TestClosure = {
    let start = Date.timeIntervalSinceReferenceDate
    await sleep(seconds: 2)
    let end = Date.timeIntervalSinceReferenceDate
    try timeTolerance(start: start, end: end, expected: 2)
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

/// run potentially long-running code on a background thread
@available(watchOS 6, iOS 13, tvOS 13, *)
public func background(_ closure: @escaping () async -> Void) {
    // run this block code on a background thread
    // new concurrency method:
    Task.detached(priority: .background) {
        // background code here
        await closure()
    }
}
/// Run potentially long-running code on a background thread.  Available as a fallback for earlier versions that don't support concurrency or for code that doesn't await (synchronous but possibly long-running)
public func background(_ closure: @escaping () -> Void) {
    if #available(watchOS 6.0, iOS 13, tvOS 13, *) {
        let asyncFunc: () async -> Void = {
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
// Restored background { for image processing or other large async task: Avoid heavy synchronous work within Task. Use custom DispatchQueue when heavy work like image processing is required.https://wojciechkulik.pl/ios/swift-concurrency-things-they-dont-tell-you
@MainActor
internal let testBackground: TestClosure = {
    let start = Date.timeIntervalSinceReferenceDate
    let end: TimeInterval
    if #available(watchOS 6.0, iOS 13, tvOS 13, *) {
        end = await withCheckedContinuation { continuation in
            background {
                sleep(4)
                let end = Date.timeIntervalSinceReferenceDate
                continuation.resume(returning: end)
            }
        }
    } else {
        // Fallback on earlier versions
        sleep(4)
        end = Date.timeIntervalSinceReferenceDate
        // run background just for testing (will not actually affect test though)
        background {
            sleep(4)
            debug("Legacy Background task finished.", level: .DEBUG)
        }
    }
    try timeTolerance(start: start, end: end, expected: 4)
}

/// run code on the main thread
public func main(_ closure: @MainActor @escaping () -> Void) {
    if #available(watchOS 6.0, iOS 13, tvOS 13, *) {
        Task { @MainActor in
            // finish up on main thread
            closure()
        }
    } else {
        // Fallback on earlier versions
        DispatchQueue.main.async {
            // finish up on main thread
            closure()
        }
    }
}
// TODO: Does a throwing main closure make sense?  When would this be used bridging the async operation?
//public func main(_ closure: @MainActor @escaping () throws -> Void) {
//    if #available(watchOS 6.0, *) {
//        Task { @MainActor in
//            // finish up on main thread
//            try closure()
//        }
//    } else {
//        // Fallback on earlier versions
//        DispatchQueue.main.async {
//            // finish up on main thread
//            try closure()
//        }
//    }
//}
@available(watchOS 6.0, iOS 13, tvOS 13, *)
@MainActor
internal let testMain: TestClosure = {
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
public func delay(_ delay:Double, closure:@escaping () -> Void) {
    if #available(watchOS 6.0, iOS 13, tvOS 13, *) {
        Task {
            await sleep(seconds: delay)
            closure()
        }
    } else {
        // Fallback on earlier versions
        DispatchQueue.main.asyncAfter(
            // delay below was previously: Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            deadline: DispatchTime.now() + delay, execute: closure)
    }

}

@available(iOS 13, watchOS 6, tvOS 13, *) // for concurrency
@MainActor
internal let testDelay: TestClosure = {
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
}

@available(watchOS 6, iOS 13, tvOS 13, *)
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

#if canImport(SwiftUI)
import SwiftUI
@available(watchOS 6, iOS 13, tvOS 13, *)
#Preview("Tests") {
    TestsListView(tests: KuThreading.tests)
}
#endif
