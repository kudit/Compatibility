//
//  Date.swift
//
//
//  Created by Ben Ku on 8/12/22.
//

//
//  NSDate.swift
//  KuditFrameworks
//
//  Created by Ben Ku on 2/7/16.
//  Copyright © 2016 Kudit. All rights reserved.
//

#if canImport(Darwin)
import Darwin
#elseif canImport(Android)
import Android
#elseif os(Linux)
import Glibc
#endif

#if !canImport(Foundation)
typealias TimeInterval = Double
#else
public extension Date {
    //    Legacy.  Use String constant instead.
    //static let MySQLTimestampFormat = "yyyy-MM-dd HH:mm:ss"
    
    // TODO: add a conversion from PHP format string to Swift ISO Format string
    
    /// Equivalent to `Date.now` but supported on iOS < 15
    static var nowBackport: Date {
        if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            return Date.now
        } else {
            // Fallback on earlier versions
            return Date()
        }
    }
    
    /// Gets a date 24 hours before now in the past.  If for some reason this can't be calculated, will return `.now` (but this should never happen).
    static var yesterday: Date {
        return .nowBackport.previousDay
    }

    /// Gets a date 24 hours from today in the future.  If for some reason this can't be calculated, will return `.now` (but this should never happen).
    static var tomorrow: Date {
        return .nowBackport.nextDay
    }
    
    /// Return the first moment of the date for tomorrow.   Typically this will be midnight of the day. Useful for setting notifications that are day-specific.
    static var tomorrowMidnight: Date {
        return .tomorrow.firstMoment
    }
    
    // MARK: - Convenience date shifting
    /// Gets the next date from the specified date in the future (usually 24 hours but may be off if across daylight savings time boundaries).  If for some reason this can't be calculated, will return the original date (but this should never happen).
    var nextDay: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: self) ?? self
    }

    /// Gets the previous date from the specified date in the past (usually 24 hours but may be off if across daylight savings time boundaries).  If for some reason this can't be calculated, will return the original date (but this should never happen).
    var previousDay: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: self) ?? self
    }

    /// Return the first moment of the date.  Useful for setting notifications that are day-specific.
    var firstMoment: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    
    // MARK: - Midnight relative functions
    /// create a date given the number of seconds since midnight.
    init(timeIntervalSinceMidnight: TimeInterval) {
        self.init(timeInterval:timeIntervalSinceMidnight, since:Date().midnight)
    }
    var midnight: Date {
        var components = (Calendar.current as NSCalendar).components([.year, .month, .day, .hour, .minute, .second], from: self)
        // Now we'll reset the hours and minutes of the date components so that it's now pointing at midnight (start) for the day
        components.hour = 0
        components.minute = 0
        components.second = 0
        // Next, we'll turn it back in to a date:
        return Calendar.current.date(from: components)!
    }
    var timeIntervalSinceMidnight: TimeInterval {
        return self.timeIntervalSince(midnight)
    }
    
    // MARK: - Year convenience
    /// return the integer value of the year component.
    var year:Int {
        return Calendar.current.component(.year, from: self)
    }
    // NEXT: add month and day values?
    
    // MARK: - Tests
    /// Compare dates ignoring the time components.
    func isSameDate(as otherDate: Date) -> Bool {
        // changed NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit to new values since deprecated in iOS 8 (I think these should be available starting with iOS 7, so shouldn't hurt compatibility)
        let calendar = Calendar.current
        var components = (calendar as NSCalendar).components([.era, .year, .month, .day], from: otherDate)
        let compareDate = calendar.date(from: components)
        components = (calendar as NSCalendar).components([.era, .year, .month, .day], from: self)
        let normalizedDate = calendar.date(from: components)
        return (compareDate == normalizedDate!)
    }
    
    /// `true` if the receiving date is in the past.
    var hasPassed: Bool {
        return self.timeIntervalSinceNow < 0
    }
    
    /// `true` if the receiving date is today.
    var isToday: Bool {
        return self.isSameDate(as: Date())
    }
    
    /// `true` if receiving date was yesterday.
    var isYesterday: Bool {
        return self.isSameDate(as: Date(timeIntervalSinceNow: -60*60*24))
    }
    
    // age related (are these really used??)
    // For getting time intervals, use various strategies for clocks in: https://stackoverflow.com/questions/24755558/measure-elapsed-time-in-swift
    func isOlderThan(days: Double) -> Bool {
        return self.isOlderThan(hours: days * 24)
    }
#if !DEBUG
    @available(*, deprecated, renamed: "isOlderThan(days:)", message: "renamed")
    func isOlderThanDays(_ days: Double) -> Bool {
        return self.isOlderThan(days: days)
    }
#endif
    
    func isOlderThan(hours: Double) -> Bool {
        return self.isOlderThan(seconds: hours * 60 * 60)
    }
#if !DEBUG
    @available(*, deprecated, renamed: "isOlderThan(hours:)", message: "renamed")
    func isOlderThanHours(_ hours: Double) -> Bool {
        return isOlderThan(hours: hours)
    }
#endif
    
    func isOlderThan(seconds: Double) -> Bool {
        let delta = -self.timeIntervalSinceNow
        return delta > seconds
    }
#if !DEBUG
    @available(*, deprecated, renamed: "isOlderThan(seconds:)", message: "renamed")
    func isOlderThanSeconds(_ seconds: Double) -> Bool {
        return isOlderThan(seconds: seconds)
    }
#endif
    // TODO: add hasBeen(days:, etc?  Or does hasPassed take care of this?  Is there a default method that handles the above cases too?  Perhaps elapsedTime with a TimeInterval?
    
    /// Unix timestamp
    static var unixTimestamp: Int {
        return Int(NSDate().timeIntervalSince1970)
    }
    @MainActor
    internal static let testTime: TestClosure = {
        //debug("Interval: \(NSDate().timeIntervalSince1970)")
        //debug("Time(): \(PHP.time())")
        let interval = Int(NSDate().timeIntervalSince1970)
        let time = Date.unixTimestamp
        try expect(interval == time, "\(interval) != \(time)")
    }
    
    @MainActor
    internal static let testTimes: TestClosure = {
        let nowTest = nowBackport
        #if !(os(WASM) || os(WASI))
        try expect(nowBackport.mysqlDateTime == nowTest.mysqlDateTime, "\(nowBackport) != \(nowTest)")
        // tests without expectations
        let tomorrow = Self.tomorrow
        let tomorrowMidnight = Self.tomorrowMidnight
        let results = "\(tomorrow.mysqlDate), \(tomorrowMidnight.mysqlDateTime)"
        try expect(results == results, "\(results)")
        try expect(tomorrow.isSameDate(as: tomorrowMidnight), "\(tomorrow.numericDateTime) DATE MISMATCH \(tomorrowMidnight.numericDateTime)")
        try expect(tomorrowMidnight.isOlderThan(days: -1), "\(tomorrowMidnight.numericDateTime) DATE is not older than -1 days")

        let midnightIntervaled = Date(timeIntervalSinceMidnight: 0)
        let midnight = Self.nowBackport.midnight
        try expect(midnightIntervaled == midnight, "Time mismatch \(midnightIntervaled) != \(midnight)")
        try expect(midnight.timeIntervalSinceMidnight == 0, "\(midnight.timeIntervalSinceMidnight) != 0")
        
        try expect(midnight.isToday, "midnight should be today")
        
        let yesterday = Date(timeIntervalSinceNow: -60*60*24)
        try expect(yesterday.midnight.isYesterday, "yesterday midnight should be yesterday")
        try expect(yesterday.nextDay.isToday, "yesterday.nextDay should be today")

        let epoch = Date(timeIntervalSince1970: 0)
        
        try expect(epoch.hasPassed, "epoch should have passed")
        
        try expect(epoch.year == 1969, "\(epoch.year) != 1969") // since epoch is technically the moment before midnight 1/1/1970
        
        let next = epoch.nextDay
        try expect(next.mysqlDate == "1970-01-01", "\(next.mysqlDate) != 1970-01-01") // note using mysqlDateTime gives unexpected value of 19:00 hours for some reason...
        #endif
    }
}

// Testing is only supported with Swift 5.9+
#if compiler(>=5.9) && canImport(Foundation) && !(os(WASM) || os(WASI))
@available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
public extension Date {
    @MainActor
    static let tests = [
        Test("MySQL DateTime format string", testFormatStrings),
        Test("init with format", testInit),
        Test("formatted", testFormatted),
        Test("pretty", testPretty),
        Test("timestamp", testTime),
        Test("times", testTimes),
    ]
}

#if canImport(SwiftUI)
import SwiftUI
@available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
#Preview {
    VStack {
        Text("\(String(describing: Date(from: "2023-01-02 17:12:00", format: "yyyy-MM-dd HH:mm:ss")))")
        Text("\(String(describing: Date(from: "1/2/2023 5:12", format: "M/d/y h:mm")))")
        Text("\(String(describing: Date(from: "2023-01-02 17:12:00", format: "yyyy-MM-dd HH:mm:ss")?.formatted(withFormat: "Y-M-d h:m")))")
        Text("\(String(describing: Date(from: "2023-01-02 17:12:00", format: "yyyy-MM-dd HH:mm:ss")?.pretty))")
    }
}
@available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
#Preview("Tests") {
    TestsListView(tests: Date.tests)
}
#endif
#endif
#endif
