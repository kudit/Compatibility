//
//  Threading.swift
//  KuditFrameworks
//
//  Created by Ben Ku on 5/7/16.
//  Copyright © 2016 Kudit. All rights reserved.
//

import Foundation

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
public func sleep(seconds: Double, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) async {
    let duration = UInt64(seconds * 1_000_000_000)
    do {
        try await Task.sleep(nanoseconds: duration)
    } catch {
        // do nothing but make debug log if we can.
        debug("Sleep function was interrupted", level: .DEBUG, file: file, function: function, line: line, column: column)
    }
}
@MainActor
internal let testSleep3: TestClosure = {
    let then = Date.timeIntervalSinceReferenceDate
    let seconds: TimeInterval = 3
    await sleep(seconds: seconds)
    let now = Date.timeIntervalSinceReferenceDate
    try timeTolerance(start: then, end: now, expected: seconds)
}
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

///// run code on a background thread
//// Use Task { } instead to do background tasks.  Use await/async on a function that calls this.
public func background(_ closure: @escaping () async -> Void) {
    // run this block code on a background thread
    // old queue method:
//    DispatchQueue.global().async {
//        // background code here
//        closure()
//    }
    // new concurrency method:
    Task.detached(priority: .background) {
        // background code here
        await closure()
    }
}
// Restored background { for image processing or other large async task: Avoid heavy synchronous work within Task. Use custom DispatchQueue when heavy work like image processing is required.https://wojciechkulik.pl/ios/swift-concurrency-things-they-dont-tell-you
@MainActor
internal let testBackground: TestClosure = {
    let start = Date.timeIntervalSinceReferenceDate
    let end = await withCheckedContinuation { continuation in
        background {
            sleep(4)
            let end = Date.timeIntervalSinceReferenceDate
            continuation.resume(returning: end)
        }
    }
    try timeTolerance(start: start, end: end, expected: 4)
}

/// run code on the main thread
public func main(_ closure: @MainActor @escaping () -> Void) {
//    DispatchQueue.main.async {
//        // finish up on main thread
//        closure()
//    }
    Task { @MainActor in
        // finish up on main thread
        closure()
    }
}
public func main(_ closure: @MainActor @escaping () throws -> Void) {
    Task { @MainActor in
        // finish up on main thread
        try closure()
    }
}
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
    DispatchQueue.main.asyncAfter(
        // delay below was previously: Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        deadline: DispatchTime.now() + delay, execute: closure)
}

@MainActor
internal let testDelay: TestClosure = {
    let start = Date.timeIntervalSinceReferenceDate
    let delayTime = 0.4
    let end = await withCheckedContinuation { continuation in
        delay(delayTime) {
            let end = Date.timeIntervalSinceReferenceDate
            continuation.resume(returning: end)
        }
    }
    try timeTolerance(start: start, end: end, expected: delayTime)
}

struct KuThreading: Testable {
    @MainActor
    public static let tests: [Test] = [
        Test("sleep 3", testSleep3),
        Test("sleep 2", testSleep2),
        Test("background 4", testBackground),
        Test("main", testMain),
        Test("delay(0.4)", testDelay),
    ]
}

#if canImport(SwiftUI)
import SwiftUI
#Preview("Tests") {
    TestsListView(tests: KuThreading.tests)
}
#endif
