//
//  Date.swift
//
//
//  Created by Ben Ku on 8/12/22.
//

import Foundation

//
//  NSDate.swift
//  KuditFrameworks
//
//  Created by Ben Ku on 2/7/16.
//  Copyright © 2016 Kudit. All rights reserved.
//

import Foundation
#if canImport(Darwin)
import Darwin
#elseif os(Linux)
import Glibc
#endif

public extension String {
    static let mysqlDateTimeFormat = "yyyy-MM-dd HH:mm:ss"
}

#if canImport(Combine) // not available in Linux
@available(iOS 15, macOS 12.0, watchOS 8, tvOS 15, *)
public extension DateFormatter.Style {
    var dateStyle: Date.FormatStyle.DateStyle {
        switch self {
        case .none:
                .omitted
        case .short:
                .abbreviated
        case .medium:
                .numeric
        case .long:
                .long
        case .full:
                .complete
        @unknown default:
                .complete
        }
    }
}
#endif

public extension Date {
    //    Legacy.  Use String constant instead.
    //static let MySQLTimestampFormat = "yyyy-MM-dd HH:mm:ss"

    // TODO: add a conversion from PHP format string to Swift ISO Format string

    // MARK: - Initialization with string and format
    /// create a date `from` a date String in the specified `format` String
    /// see NSDateFormatter dateFormat string for information on symbols and formatting
    // http://www.unicode.org/reports/tr35/tr35-dates.html#Date_Format_Patterns
    // https://www.php.net/manual/en/datetime.format.php
    init?(from dateString: String, format: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = dateFormatter.date(from: dateString) {
            self = date
            // alternatively: self.init(timeInterval:0, since:date)
        } else {
            return nil
        }
    }
    /// create a date from a `dateString` in the specified `format`
    /// If there is a bad format or this can't happen, will set to reference date.  Use the failable init instead for better checking.`
    @available(*, deprecated, renamed: "init(dateString:formatString:)")
    init(dateString:String, format formatString:String) {
        if let date = Date(from: dateString, format: formatString) {
            self = date
        } else {
            self = .init(timeIntervalSinceReferenceDate: 0)
        }
    }
    @MainActor
    internal static let testInit: TestClosure = {
        let date = Date(from: "2023-01-02 17:12:00", format: .mysqlDateTimeFormat)
        //        let date = Date(from: "January 2, 2023 5:12pm", format: "F j, Y g:ia")
        let compareDate = Date(from: "1/2/2023 5:12pm", format: "M/d/y h:mma")
        try expect(date == compareDate, "\(String(describing: date)) != \(String(describing: compareDate))")
        //        return (date == Date(from: "01/02/2023 17:12", format: "m/d/Y G:i"), String(describing:date))
    }
    
    // MARK: - Formatting using format strings and styles
    /// format using DateFormatter.dateFormat string.  Not PHP Date format string.  For reference: https://www.advancedswift.com/date-formatter-cheatsheet-formulas-swift/#date-format-cheatsheet
    // TODO: Create a conversion from PHP Date String format to Swift Date format strings and vice versa?
    func formatted(withFormat formatString: String) -> String {
        let printFormatter = DateFormatter()
        printFormatter.dateFormat = formatString
        return printFormatter.string(from: self)
    }
    /// Return the date formmated using the `formatString`.  See NSDateFormatter for format information.
    @available(*, deprecated, renamed: "formatted(withFormat:)")
    func string(withFormat formatString: String) -> String {
        return formatted(withFormat: formatString)
    }
    /// The date formatted using the provided format string.  This is in Swift Date format NOT PHP Date format string.
    @available(macOS 12.0, *)
    @available(*, deprecated, renamed: "formatted(withFormat:)")
    func formatted(_ format: String) -> String {
        return formatted(withFormat: format)
    }
    
    /// Use date formatter style to create localized string version of the date.
    #if canImport(Combine)
    @available(iOS 15, macOS 12.0, watchOS 8, tvOS 15, *)
    @available(*, deprecated, renamed: "formatted(date:time:)")
    func string(withStyle dateFormatterStyle:DateFormatter.Style) -> String {
        return self.formatted(date: dateFormatterStyle.dateStyle, time: .omitted)
    }
    #endif
    
    @available(macOS 12.0, *)
    @MainActor
    internal static let testFormatted: TestClosure = {
        let date = Date(from: "2023-01-02 17:12:00", format: .mysqlDateTimeFormat)
        let formatted = date?.formatted(withFormat: "Y-M-d h:m")
        try expect(formatted == "2023-1-2 5:12", String(describing:formatted))
    }
    
    /// the date in a format designed for MySQL DateTime
    var mysqlDateTime: String {
        self.formatted(withFormat: .mysqlDateTimeFormat)
    }
    @MainActor
    internal static let testMysql: TestClosure = {
        try expect(String.mysqlDateTimeFormat == "yyyy-MM-dd HH:mm:ss", String.mysqlDateTimeFormat)
    }
    
    var pretty: String {
        if #available(macOS 12.0, watchOS 8, iOS 15, tvOS 15, *) {
            #if canImport(Combine) // not supported in Linux
            self.formatted(date: .abbreviated, time: .shortened)
            #else
            // Fallback on earlier versions
            self.formatted(withFormat: .mysqlDateTimeFormat)
            #endif
        } else {
            // Fallback on earlier versions
            self.formatted(withFormat: .mysqlDateTimeFormat)
        }
    }
    @MainActor
    internal static let testPretty: TestClosure = {
        let date = Date(from: "2023-01-02 17:12:00", format: .mysqlDateTimeFormat)
        let pretty = date?.pretty ?? "FAILED"
        if #available(iOS 16, *) {
            try expect(pretty == "Jan 2, 2023 at 5:12 PM", String(describing:pretty))
        } else {
            try expect(pretty == "Jan 2, 2023, 5:12 PM", String(describing:pretty))
        }
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
    @available(*, deprecated, renamed: "isOlderThan(days:)", message: "renamed")
    func isOlderThanDays(_ days: Double) -> Bool {
        return self.isOlderThan(days: days)
    }
    
    func isOlderThan(hours: Double) -> Bool {
        return self.isOlderThan(seconds: hours * 60 * 60)
    }
    @available(*, deprecated, renamed: "isOlderThan(hours:)", message: "renamed")
    func isOlderThanHours(_ hours: Double) -> Bool {
        return isOlderThan(hours: hours)
    }
    
    func isOlderThan(seconds: Double) -> Bool {
        let delta = -self.timeIntervalSinceNow
        return delta > seconds
    }
    @available(*, deprecated, renamed: "isOlderThan(seconds:)", message: "renamed")
    func isOlderThanSeconds(_ seconds: Double) -> Bool {
        return isOlderThan(seconds: seconds)
    }
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
}
@available(macOS 12.0, watchOS 6, iOS 13, tvOS 13, *)
public extension Date {
    @MainActor
    static let tests = [
        Test("MySQL DateTime format string", testMysql),
        Test("init with format", testInit),
        Test("formatted", testFormatted),
        Test("pretty", testPretty),
        Test("timestamp", testTime),
    ]
}

#if canImport(SwiftUI)
import SwiftUI
@available(iOS 13, macOS 12.0, tvOS 13, watchOS 6, *)
#Preview {
    VStack {
        Text("\(String(describing: Date(from: "2023-01-02 17:12:00", format: "yyyy-MM-dd HH:mm:ss")))")
        Text("\(String(describing: Date(from: "1/2/2023 5:12", format: "M/d/y h:mm")))")
        Text("\(String(describing: Date(from: "2023-01-02 17:12:00", format: "yyyy-MM-dd HH:mm:ss")?.formatted(withFormat: "Y-M-d h:m")))")
        Text("\(String(describing: Date(from: "2023-01-02 17:12:00", format: "yyyy-MM-dd HH:mm:ss")?.pretty))")
    }
}
@available(macOS 12.0, watchOS 6, iOS 13, tvOS 13, *)
#Preview("Tests") {
    TestsListView(tests: Date.tests)
}
#endif
