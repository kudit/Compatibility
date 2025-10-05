//
//  DateString.swift
//  Compatibility
//
//  Created by Ben Ku on 4/25/25.
//

// MARK: - Formatting
public extension String {
    static let invalidDateString = "invalid date" // "?"?
    static let mysqlDateFormat = "yyyy-MM-dd"
    static let mysqlDateTimeFormat = "\(mysqlDateFormat) HH:mm:ss"
    static let numericDateFormat = "yyyyMMdd"
    static let numericDateTimeFormat = "\(numericDateFormat)HHmmss"
    static let spelledOutDateFormat = "MMMM d, yyyy" // November 22, 2010
    static let spelledOutDateTimeFormat = "\(spelledOutDateFormat) h:mm:ss a" // TODO, do we need to force to capital AM/PM?
    static let abbreviatedDateFormat = "MMM d, yy"
    static let abbreviatedDateTimeFormat = "\(abbreviatedDateFormat) h:mm a"
}
//FORMULA    OUTPUT
//dd.MM.yy    16.01.23
//MM/dd/yyyy    01/16/2023
//MM-dd-yyyy HH:mm    01-16-2023 00:10
//MMM d, h:mm a    Jan 16, 0:10 AM
//EEEE, MMM d, yyyy    Monday, Jan 16, 2023
//yyyy-MM-dd’T’HH:mm:ssZ    2023-01-16T00:10:00-0600
//Date Format Cheatsheet
//FORMULA    DESCRIPTION    EXAMPLE
//yyyy    4-digit year    2022
//yy    2-digit year    22
//MM    2-digit month    01
//M    1 or 2 digit month    1
//dd    2-digit day of the month    02
//d    1 or 2 digit day of the month    2
//HH    2-digit hour (24-hour format)    13
//H    1 or 2 digit hour (24-hour format)    13
//hh    2-digit hour (12-hour format)    01
//h    1 or 2 digit hour (12-hour format)    1
//mm    2-digit minute    02
//m    1 or 2 digit minute    2
//ss    2-digit second    02
//s    1 or 2 digit second    2
//a    AM/PM for 12-hour format

#if canImport(Foundation) && !(os(WASM) || os(WASI)) // not available in WASM?
#if canImport(Combine) // not available in Linux
@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
public extension DateFormatter.Style {
    var dateStyle: Date.FormatStyle.DateStyle {
        switch self {
        case .none:
            return .omitted
        case .short:
            return .abbreviated
        case .medium:
            return .numeric
        case .long:
            return .long
        case .full:
            return .complete
        @unknown default:
            return .complete
        }
    }
}
#endif

public extension Date {
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
#if !DEBUG
    /// create a date from a `dateString` in the specified `format`
    /// If there is a bad format or this can't happen, will set to reference date.  Use the failable init instead for better checking.`
    @available(*, deprecated, renamed: "init(from:format:)")
    init(dateString:String, format formatString:String) {
        if let date = Date(from: dateString, format: formatString) {
            self = date
        } else {
            self = .init(timeIntervalSinceReferenceDate: 0)
        }
    }
#endif
    @MainActor
    internal static let testInit: TestClosure = {
        let date = Date(from: "2023-01-02 17:12:00", format: .mysqlDateTimeFormat)
        //        let date = Date(from: "January 2, 2023 5:12pm", format: "F j, Y g:ia")
        let compareDate = Date(from: "1/2/2023 5:12pm", format: "M/d/y h:mma")
        try expect(date == compareDate, "\(String(describing: date)) != \(String(describing: compareDate))")
        //        return (date == Date(from: "01/02/2023 17:12", format: "m/d/Y G:i"), String(describing:date))
    }
    
    // MARK: - Parsing
    /// Creates a date from a string.  If the string cannot be converted to a date, returns `nil`.  Supported formats include MySQL format and numeric formats.  Add additional conversions here once we support.
    init?(parse string: String) {
        // do the conversion of a string to a date using all the strategies available.
        let formatsToTry = [
            String.mysqlDateTimeFormat,
            .mysqlDateFormat,
            .numericDateTimeFormat,
            .numericDateFormat,
            .spelledOutDateTimeFormat,
            .spelledOutDateFormat,
            .abbreviatedDateTimeFormat,
            .abbreviatedDateFormat,
            // Add additional supported formats here
        ]
        
        for format in formatsToTry {
            if let date = Date(from: string, format: format) {
                self = date
                return
            }
        }
        return nil
    }
    

    // MARK: - Legacy deprecations
#if !DEBUG
    /// Return the date formmated using the `formatString`.  See NSDateFormatter for format information.
    @available(*, deprecated, renamed: "formatted(withFormat:)")
    func string(withFormat formatString: String) -> String {
        return formatted(withFormat: formatString)
    }
    /// The date formatted using the provided format string.  This is in Swift Date format NOT PHP Date format string.
    @available(macOS 12, *)
    @available(*, deprecated, renamed: "formatted(withFormat:)")
    func formatted(_ format: String) -> String {
        return formatted(withFormat: format)
    }
    
    /// Use date formatter style to create localized string version of the date.
#if canImport(Combine)
    @available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
    @available(*, deprecated, renamed: "formatted(date:time:)")
    func string(withStyle dateFormatterStyle:DateFormatter.Style) -> String {
        return self.formatted(date: dateFormatterStyle.dateStyle, time: .omitted)
    }
#endif
#endif
    
    // MARK: - Tests
#if !(os(WASM) || os(WASI))
    @MainActor
#endif
    internal static let testFormatStrings: TestClosure = {
        try expect(String.mysqlDateTimeFormat == "yyyy-MM-dd HH:mm:ss", String.mysqlDateTimeFormat)
        try expect(String.mysqlDateFormat == "yyyy-MM-dd", String.mysqlDateFormat)
        try expect(String.numericDateTimeFormat == "yyyyMMddHHmmss", String.numericDateTimeFormat)
        try expect(String.numericDateFormat == "yyyyMMdd", String.numericDateFormat)
    }
    @available(macOS 12, *)
#if !(os(WASM) || os(WASI))
    @MainActor
#endif
    internal static let testFormatted: TestClosure = {
        let date = Date(from: "2023-01-02 17:12:00", format: .mysqlDateTimeFormat)
        let formatted = date?.formatted(withFormat: "Y-M-d h:m")
        try expect(formatted == "2023-1-2 5:12", String(describing:formatted))
        let dateString: DateString = "2023-05-04"
        let mysqlDate = dateString.mysqlDate
        try expect(mysqlDate == "2023-05-04", mysqlDate)
        let dateTimeString: DateTimeString = "2023-01-02 17:12:00"
        let mysqlDateTime = dateTimeString.mysqlDateTime
        try expect(mysqlDateTime == "2023-01-02 17:12:00", mysqlDateTime)
        try expect(dateTimeString.mysqlDate == "2023-01-02", dateTimeString.mysqlDate)
    }
#if !(os(WASM) || os(WASI))
    @MainActor
#endif
    internal static let testPretty: TestClosure = {
        let dateString: DateString = "1955-11-05 01:40:30" // time should get stripped
        let dateString2: DateString = "1955-11-05 01:43:30" // time should get stripped
        try expect(dateString.pretty == "November 5, 1955", dateString.pretty)
        let dateTimeString = DateTimeString("2023-01-02 17:12:01")
        try expect(dateString < dateString2, "FAILED: \(dateString) < \(dateString2)")
        try expect(dateTimeString.description == "2023-01-02 17:12:01", dateTimeString.description)
        guard let date = dateTimeString.date else {
            try expect(false, "Could not parse date")
            return
        }
        try expect(date.numericDate == "20230102", String(describing:date.numericDate))
        try expect(date.numericDateTime == "20230102171201", String(describing:date.numericDateTime))
        let pretty = date.pretty
        var expectedPretty = "January 2, 2023 5:12:01 PM"
        if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
#if canImport(Combine)
            expectedPretty = "Jan 2, 2023 at 5:12 PM"
#endif
        }
        try expect(pretty == expectedPretty, "Unexpected pretty string.  Expected \(expectedPretty) but got \(pretty)")
    }
}

// MARK: - Representation
public protocol DateRepresentable {
    var date: Date? { get }
}
public protocol DateTimeRepresentable: DateRepresentable {}
extension Date: DateTimeRepresentable {}
public extension Date {
    /// Merely returns self (for conformance with `DateRepresentable`)
    var date: Date? {
        return self
    }
}
#else
// Stubs to enable compatibility in WASM
public protocol DateRepresentable {}
public protocol DateTimeRepresentable: DateRepresentable {}
#endif

/// A string representation of a date time.  When getting this as a date, it will attempt to parse various formats the string could be in to allow a variety of formats.  You can add other formats here to expand the support.  Add mappings in the date initializer if you need other formats supported.
public protocol DateStringRepresentation: RawRepresentable, Sendable, Hashable, Codable, Comparable, DateRepresentable, ExpressibleByStringLiteral, ExpressibleByStringInterpolation, LosslessStringConvertible where RawValue == String {
#if canImport(Foundation) && !(os(WASM) || os(WASI)) // not available in WASM?
    var date: Date? { get }
#endif
    var rawValue: String { get set }
}
public extension DateStringRepresentation {
    // Comparable conformance
    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    // LosslessStringConvertible conformance
    init(_ string: String) {
        self.init(rawValue: string)! // Should never fail
    }
    init(stringLiteral: String) {
        self.init(rawValue: stringLiteral)! // Should never fail
    }
    var description: String {
        return rawValue
    }
    
#if canImport(Foundation) && !(os(WASM) || os(WASI)) // not available in WASM?
    var date: Date? {
        return Date(parse: rawValue)
    }
#endif
}

/// A string representation of a date (without time).  When getting this as a date, it will attempt to parse various formats the string could be in to allow a variety of formats.
public struct DateString: DateStringRepresentation {
    public var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
/// A string representation of a date time.  When getting this as a date, it will attempt to parse various formats the string could be in to allow a variety of formats.
public struct DateTimeString: DateStringRepresentation, DateTimeRepresentable {
    public var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

#if canImport(Foundation) && !(os(WASM) || os(WASI)) // not available in WASM?
// MARK: - Formatted output
public extension DateRepresentable {
    // MARK: - Formatting using format strings and styles
    /// format using DateFormatter.dateFormat string.  Not PHP Date format string.  For reference: https://www.advancedswift.com/date-formatter-cheatsheet-formulas-swift/#date-format-cheatsheet
    // TODO: Create a conversion from PHP Date String format to Swift Date format strings and vice versa?
    func formatted(withFormat formatString: String) -> String {
        let printFormatter = DateFormatter()
        printFormatter.dateFormat = formatString
        if let date {
            return printFormatter.string(from: date)
        } else {
            return .invalidDateString
        }
    }
        
    /// the date in a format designed for MySQL DateTime
    var mysqlDate: String {
        self.formatted(withFormat: .mysqlDateFormat)
    }
    
    /// a flat date and time format for use in file names or build numbers
    var numericDate: String {
        self.formatted(withFormat: .numericDateFormat)
    }
    
    var pretty: String {
        guard let date else {
            return .invalidDateString
        }
        if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
#if canImport(Combine) // not supported in Linux
            return date.formatted(date: .long, time: .omitted)
#endif
        }
        // Fallback on earlier versions
        return date.formatted(withFormat: .spelledOutDateFormat)
    }
}

public extension DateTimeRepresentable {
    /// the date in a format designed for MySQL DateTime
    var mysqlDateTime: String {
        self.formatted(withFormat: .mysqlDateTimeFormat)
    }
    /// a flat date and time format for use in file names or build numbers
    var numericDateTime: String {
        self.formatted(withFormat: .numericDateTimeFormat)
    }
    var pretty: String {
        guard let date else {
            return .invalidDateString
        }
        if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
#if canImport(Combine) // not supported in Linux
            return date.formatted(date: .abbreviated, time: .shortened)
#endif
        }
        // Fallback on earlier versions
        return date.formatted(withFormat: .spelledOutDateTimeFormat)
    }
}
#endif
