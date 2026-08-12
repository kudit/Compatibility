// TODO: Needs a real file header documentation/comment.

// Here since all releated to Debug code to simplify conditional code gates.
#if hasFeature(Embedded)
public typealias DebugMessage = String
#else
public typealias DebugMessage = Any
#endif

/// Named values supplied to a custom debug formatter.
public struct DebugFormatContext: Sendable {
    public let message: String
    public let level: DebugLevel
    public let isMainThread: Bool
    public let emojiSupported: Bool
    public let includeContext: Bool
    public let includeTimestamp: Bool
    public let source: SourceContext

    public init(
        message: String,
        level: DebugLevel,
        isMainThread: Bool,
        emojiSupported: Bool,
        includeContext: Bool,
        includeTimestamp: Bool,
        source: SourceContext
    ) {
        self.message = message
        self.level = level
        self.isMainThread = isMainThread
        self.emojiSupported = emojiSupported
        self.includeContext = includeContext
        self.includeTimestamp = includeTimestamp
        self.source = source
    }
}

public typealias DebugFormatter = (DebugFormatContext) -> String

public struct CompatibilityConfiguration: PropertyIterable {
    /// Override to change the which debug levels are output.  This level and higher (more important) will be output.
    public var debugLevelCurrent: DebugLevel = Build.isDebug ? .DEBUG : .WARNING
    
    /// Override to change the level of debug statments without a level parameter.
    public var debugLevelDefault = DebugLevel.DEBUG
    
    /// Override to use the level symbol rather than the emoji (if we're outputting in an environment that does not support emoji).
    public var debugEmojiSupported = true
    
    /// Set this to a set of levels where we should include the context info.  Defaults to `.important` so that `NOTICE` and `DEBUG` messages are less noisy and easier to see.  Set this to `.none` to make `debug()` act exactly like `print()` at all levels.
    public var debugLevelsToIncludeContext = DebugLevels.important
    
    /// Set whether timestamps should be included in debug messages.  If you need to customize the format of timestamps, use the `debugFormat()` override.
    @available(*, deprecated, renamed: "debugLevelsToIncludeTimestamp", message: "Set `debugLevelsToIncludeTimestamp` instead.")
    public var debugIncludeTimestamp: Bool {
        get {
            debugLevelsToIncludeTimestamp != .none
        }
        set {
            debugLevelsToIncludeTimestamp = newValue ? .all : .none
        }
    }
    public var debugLevelsToIncludeTimestamp = DebugLevels.none
    
    /// Generates string with context.  Set level to `.OFF` to just return the context without the message portion.
    public var debugFormat = { (message: String, level: DebugLevel, isMainThread: Bool, emojiSupported: Bool, includeContext: Bool, includeTimestamp: Bool, file: String, function: String, line: Int, column: Int) -> String in
        let message = "\(emojiSupported ? level.emoji : level.symbol) \(message)"
        var timestamp = ""
        if includeTimestamp {
            #if canImport(Foundation)
            timestamp = "\(Date.nowBackport.mysqlDateTime): "
            #else
            timestamp = "UNABLE TO GET TIMESTAMP WITHOUT Foundation.Date: "
            #endif
        }
        if includeContext {
            let threadInfo = isMainThread ? "" : "^"
            #if canImport(Foundation)
            let simplerFile = URL(fileURLWithPath: file).lastPathComponent
            let simplerFunction = function.replacingOccurrences(of: "__preview__", with: "_p_")
            #else
            let simplerFile = "\(file)".components(separatedBy: "/").last ?? "UNABLE TO GET LAST PATH COMPONENT WITHOUT Foundation.URL"
            let simplerFunction = function
            #endif
            return "\(timestamp)\(simplerFile)(\(line)) : \(simplerFunction)\(threadInfo)\(level == .OFF ? "" : "\n\(message)")"
        } else {
            return "\(timestamp)\(message)"
        }
    }

    /// Preferred labeled alternative to the legacy positional `debugFormat` closure.
    /// Assigning either property updates the same underlying formatter.
    public var debugFormatter: DebugFormatter {
        get {
            let legacyFormatter = debugFormat
            return { context in
                legacyFormatter(
                    context.message,
                    context.level,
                    context.isMainThread,
                    context.emojiSupported,
                    context.includeContext,
                    context.includeTimestamp,
                    context.source.file,
                    context.source.function,
                    context.source.line,
                    context.source.column
                )
            }
        }
        set {
            debugFormat = {
                message,
                level,
                isMainThread,
                emojiSupported,
                includeContext,
                includeTimestamp,
                file,
                function,
                line,
                column in
                newValue(
                    DebugFormatContext(
                        message: message,
                        level: level,
                        isMainThread: isMainThread,
                        emojiSupported: emojiSupported,
                        includeContext: includeContext,
                        includeTimestamp: includeTimestamp,
                        source: SourceContext(
                            file: file,
                            function: function,
                            line: line,
                            column: column
                        )
                    )
                )
            }
        }
    }
    
    /// Function to handle how the debug messages are logged.  Can change to have the messages logged to a file or a string.  Default is to print to the console.
    public var debugLog = { (message: String) in
        print(message)
    }
}

public func checkBreakpoint(level: DebugLevel) {
    // Enable setting breakpoints for various debug levels.
    switch level {
    case .OFF:
        break // for breakpoint
    case .ERROR:
        break // for breakpoint
    case .WARNING:
        break // for breakpoint
    case .NOTICE:
        break // for breakpoint
    case .DEBUG:
        break // for breakpoint
    case .SILENT:
        break // for breakpoint
    }
}


//@available(*, deprecated, renamed: "CustomError")
//public typealias KuError = CustomError

// parameters to add to function that calls debug:
// , file: String = #file, function: String = #function, line: Int = #line, column: Int = #column
// debug call site additions:
// , file: file, function: function, line: line, column: column

// Documentation Template:
/**
 A custom Error that can be thrown.  Automatically prints the error as a debug message as well.
 
 - Parameter message: The message
  */
// Formerly KuError but this seems more applicable and memorable and less specific.
public struct CustomError: Error, Sendable {
    var message: String
    var level: DebugLevel?
    var file: String
    var function: String
    var line: Int
    var column: Int
    
    /// NOTE: This will only automatically warn if a debug level is provided.
    public init(_ message: String, level: DebugLevel? = nil /* Do not warn by default even if default debug level is set. */, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        self.message = message
        self.level = level
        self.file = file
        self.function = function
        self.line = line
        self.column = column
        if level != nil {
            self.debug()
        }
    }
    @discardableResult
    func debug() -> String {
        Compatibility.debug(
            description,
            level: level ?? DebugLevel.defaultLevel,
            source: SourceContext(file: file, function: function, line: line, column: column)
        )
    }
}
extension CustomError: CustomStringConvertible {
    public var description: String {
        message
    }
}
#if canImport(Foundation)
extension CustomError: LocalizedError {
    public var localizedDescription: String {
        message
    }
    public var errorDescription: String? {
        message
    }
}
#endif

public typealias DebugLevels = Set<DebugLevel>
public extension DebugLevels {
    static let none: Self = []
    static let all: Self = [.ERROR, .WARNING, .NOTICE, .DEBUG]
    static let important: Self = [.ERROR, .WARNING]
    static let informational: Self = [.NOTICE, .WARNING]
}

public enum DebugLevel: Comparable, CustomStringConvertible, CaseIterable, Sendable {
    /// Only use .OFF for setting the current debug level so *nothing* is printed.  If you wish to disable a debug message, use .SILENT
    case OFF
    case ERROR // Should not be possible.  Will lead to undefined behavior.
    case WARNING // Unlikely but could be possible error if there is bad user data or network corruption.
    case NOTICE // Informational
    case DEBUG // Lots of detailed info for debugging.  Unnecessary in production.
    case SILENT // Use to silence a message but keep the debug code in case it's needed in the future or for documentation.
    
    /// Change this value in production to `DebugLevel.ERROR` or `.OFF` to minimize logging.  Can be changed using the `debugLevelCurrent` setting.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    public static var currentLevel: DebugLevel {
        get {
            Compatibility.settings.debugLevelCurrent
        }
        set {
            Compatibility.settings.debugLevelCurrent = newValue
        }
    }
    
    /// Set to change the level of debug statments without a level parameter.  Default is `.DEBUG`.  Can be changed using the `debugLevelDefault` setting.
    public static var defaultLevel: DebugLevel {
        get {
            Compatibility.settings.debugLevelDefault
        }
        set {
            Compatibility.settings.debugLevelDefault = newValue
        }
    }

    public var emoji: String {
        switch self {
        case .OFF:
            return "💤"
        case .ERROR:
            return "🛑"
        case .WARNING:
            return "⚠️"
        case .NOTICE:
            return "ℹ️"
        case .DEBUG:
            return "🪲"
        case .SILENT: // should not typically be used
            return "🤫"
        }
    }
    public var symbol: String {
        switch self {
        case .OFF:
            return "-"
        case .ERROR:
            return "•"
        case .WARNING:
            return "!"
        case .NOTICE:
            return ">"
        case .DEBUG:
            return ":"
        case .SILENT: // should not typically be used
            return "z"
        }
    }
    public var description: String {
        switch self {
        case .OFF:
            return "OFF"
        case .ERROR:
            return "ERROR"
        case .WARNING:
            return "WARNING"
        case .NOTICE:
            return "NOTICE"
        case .DEBUG:
            return "DEBUG"
        case .SILENT:
            return "SILENT"
        }
    }
    /// use to detect if the current level is at least the level.  So if the current level is .NOTICE, .isAtLeast(.ERROR) = true but .isAtLeast(.DEBUG) = false.  Will typically be used like: if DebugLevel.currentLevel.isAtLeast(.DEBUG) to check for whether debugging output is on.  Simplify using convenience static func DebugLevel.isAtLeast(.DEBUG)
    public func isAtLeast(_ level: DebugLevel) -> Bool {
        return level <= self
    }
    /// use to detect if the current level is at least the level.  So if the current level is .NOTICE, .isAtLeast(.ERROR) = true but .isAtLeast(.DEBUG) = false.  Will typically be used like: if DebugLevel.isAtLeast(.DEBUG) to check for whether debugging output is on.
    public static func isAtLeast(_ level: DebugLevel) -> Bool {
        if #available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *) {
            return Self.currentLevel.isAtLeast(level)
        } else {
            // Fallback on earlier versions
            return Self.DEBUG.isAtLeast(level)
        }
    }
}

/// Generates context string
@available(*, deprecated, message: "Use Compatibility.settings.debugFormat with the desired formatting options instead.")
public func debugContext(isMainThread: Bool, file: String, function: String, line: Int, column: Int) -> String {
    // TODO: Convert this to the debugFormatter callsite for clarity
    Compatibility.settings.debugFormat(
        "",
        .OFF,
        isMainThread,
        Compatibility.settings.debugEmojiSupported,
        true,
        Compatibility.settings.debugIncludeTimestamp,
        file, function, line, column)
}

// MARK: - Debug
public extension Compatibility {
    /**
     Debug helper for printing info to screen including file and line info of call site.  Also can provide a log level for use in loggers or for globally turning on/off logging. (Modify DebugLevel.currentLevel to set level to output.  When launching app, set this to DebugLevel.OFF for release builds.
     
     - Parameter message: The message to report.
     - Parameter level: The logging level to use.
     - Parameter file: For bubbling down the #file name from a call site.
     - Parameter function: For bubbling down the #function name from a call site.
     - Parameter line: For bubbling down the #line number from a call site.
     - Parameter column: For bubbling down the #column number from a call site. (Not used currently but here for completeness).
     */
    @discardableResult
    static func debug(_ message: DebugMessage, level: DebugLevel = .defaultLevel, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> String {
#if hasFeature(Embedded)
        // Embedded Swift already narrows `DebugMessage` to `String`, so no dynamic conversion is needed.
        let isMainThread = true
#elseif !canImport(Foundation)
        // Full Swift runtimes without Foundation still allow `DebugMessage == Any`; stringify before
        // forwarding to the shared String-based formatter just as Foundation-backed builds do.
        let isMainThread = true
        let message = String(describing: message)
#else
        let isMainThread = Thread.isMainThread // capture before we switch to main thread for printing
        let message = String(describing: message) // convert to sendable item to avoid any thread issues.
#endif
        return debug(message, isMainThread: isMainThread, level: level, file: file, function: function, line: line, column: column)
    }

    /// Logs a message using an already-captured source location.
    @discardableResult
    static func debug(_ message: DebugMessage, level: DebugLevel = .defaultLevel, source: SourceContext) -> String {
        debug(
            message,
            level: level,
            file: source.file,
            function: source.function,
            line: source.line,
            column: source.column
        )
    }

    /// Put most of the business logic here for compatibility with WASM.  isMainThread: is required to differentiate but can be removed in global definition
    @discardableResult
    static func debug(_ message: String, isMainThread: Bool, level: DebugLevel = .defaultLevel, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> String {
        guard DebugLevel.isAtLeast(level) else { // check current debug level from settings
            return "" // don't actually print
        }
        let debugMessage = Compatibility.settings.debugFormat(
            message,
            level,
            isMainThread,
            Compatibility.settings.debugEmojiSupported,
            Compatibility.settings.debugLevelsToIncludeContext.contains(level),
            Compatibility.settings.debugLevelsToIncludeTimestamp.contains(level),
            file, function, line, column)
        
        // log message
        Compatibility.settings.debugLog(debugMessage)
        
        // do this AFTER Printing so we can see what the message is in the console
        checkBreakpoint(level: level)
        
        return debugMessage
    }
}
//DebugLevel.currentLevel = .ERROR
/**
 Debug helper for printing info to screen including file and line info of call site.  Also can provide a log level for use in loggers or for globally turning on/off logging. (Modify DebugLevel.currentLevel to set level to output.  When launching app, set this to DebugLevel.OFF for release builds.

 - Parameter message: The message to report.
 - Parameter level: The logging level to use.
 - Parameter file: For bubbling down the #file name from a call site.
 - Parameter function: For bubbling down the #function name from a call site.
 - Parameter line: For bubbling down the #line number from a call site.
 - Parameter column: For bubbling down the #column number from a call site. (Not used currently but here for completeness).
 */
@discardableResult
public func debug(_ message: DebugMessage, level: DebugLevel = .defaultLevel, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> String {
    return Compatibility.debug(message, level: level, file: file, function: function, line: line, column: column)
}

/// Logs a message using an already-captured source location.
@discardableResult
public func debug(_ message: DebugMessage, level: DebugLevel = .defaultLevel, source: SourceContext) -> String {
    return Compatibility.debug(message, level: level, source: source)
}

// MARK: Debug(error)
// This is to provide debugging at calltime when creating errors.
public extension Error {
    /**
     Outputs the error's localized description at the specified debug level and return.  Can append to errors to debug output at the throwing location rather than the caught location.
     
     - Parameter level: The logging level to use.
     - Parameter file: For bubbling down the #file name from a call site.
     - Parameter function: For bubbling down the #function name from a call site.
     - Parameter line: For bubbling down the #line number from a call site.
     - Parameter column: For bubbling down the #column number from a call site. (Not used currently but here for completeness).
     */
    func debug(level: DebugLevel = .defaultLevel, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> Self {
        Compatibility.debug(self.localizedDescription, level: level, file: file, function: function, line: line, column: column)
        return self
    }
    #if !canImport(Foundation)
    var localizedDescription: String {
        "There was an error but without Foundation, we're using the default `localizedDescription`."
    }
    #endif
}

public extension TestFailure {
    /// Logs this failure at its original source location and returns it for throwing.
    @discardableResult
    func debug(level: DebugLevel = .ERROR) -> Self {
        Compatibility.debug(message, level: level, source: source)
        return self
    }
}


// Testing and main-actor isolation are supported on current full-runtime WASM builds.
#if compiler(>=5.9)
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension DebugLevel {
    @MainActor
    internal static let testDebugConfig: TestClosure = {
        // These tests temporarily replace process-global debug settings. Capture the complete
        // configuration before making any changes so the surrounding application or test suite
        // observes exactly the same settings after this test finishes.
        let previousSettings = Compatibility.settings

        // `defer` runs whether the test succeeds or throws. This is important because an
        // expectation failure exits the closure immediately; a normal assignment at the bottom
        // would be skipped and could leave later tests using this temporary logger or formatter.
        defer {
            Compatibility.settings = previousSettings
        }

        DebugLevel.defaultLevel = .WARNING // testing override default level
        DebugLevel.currentLevel = .NOTICE // testing override current level

        var concurrentOutput = ""
        Compatibility.settings.debugLog = { message in
            concurrentOutput.append(message)
        } // don't output anything into console during these tests

        try expect(Compatibility.settings.debugLevelDefault == .WARNING, "expected default debug level to be .WARNING but found \(Compatibility.settings.debugLevelDefault)")

        Compatibility.settings.debugEmojiSupported = false // testing symbols
//        Compatibility.settings.debugIncludeTimestamp = true // test deprecated code
        Compatibility.settings.debugLevelsToIncludeTimestamp = .all // test timestamps
        let defaultFormat = Compatibility.settings.debugFormat
        Compatibility.settings.debugFormat = { (message: String, level: DebugLevel, isMainThread: Bool, emojiSupported: Bool, includeContext: Bool, includeTimestamp: Bool, file: String, function: String, line: Int, column: Int) -> String in

            let defaultOutput = defaultFormat(message, level, isMainThread, emojiSupported, includeContext, includeTimestamp, file, function, line, column)
            return """
Message: \(message)
Level: \(level)
isMainThread: \(isMainThread)
emojiSupported: \(emojiSupported)
includeContext: \(includeContext)
includeTimestamp: \(includeTimestamp)
file: \(file)
Normal output: \(defaultOutput)
"""
        }
        
        #if canImport(Foundation)
        let timestamp = Date.nowBackport.mysqlDateTime
        #else
        let timestamp = "UNABLE TO GET TIMESTAMP WITHOUT Foundation.Date"
        #endif
        let debugText = debug("TestCase return output")
                
        try expect(debugText.contains("!"), "expected debug warning symbol to be ! but found \(debugText)")
        try expect(debugText.contains(timestamp), "expected \(timestamp) but found \(debugText)")

        let blankText = debug("TestCase return output", level: .DEBUG) // less than the current level so should be silent
        try expect(blankText == "", "expected empty string but found \(blankText)")

        // `previousSettings` is restored automatically by the `defer` above.
        // Output captured while the temporary logger was active remains intentionally suppressed.
//        Compatibility.settings.debugLog(concurrentOutput)
//        debug("TEST OUTPUT", level: .ERROR)
    }

    @MainActor
    internal static let testDebug: TestClosure = {
        var debugError = CustomError("NOT OUTPUT")
        var output = "OVERWRITE"
        debugSuppress {
            debugError = CustomError("test custom error", level: .WARNING) // to test
            debugError = CustomError("test custom error").debug(level: .WARNING) // to test
            output = debugError.debug()
        }
        #if canImport(Foundation)
        output = debugError.localizedDescription
        try expect(output.contains("custom error"), "expected custom error to be in the output but found \(output)")
        #endif
        output = debugError.description
        try expect(output.contains("custom error"), "expected custom error to be in the output but found \(output)")
        
        // go through symbols for testing
        for level in DebugLevel.allCases {
            try expect(level.symbol == "\(level.symbol)")
            try expect(level.emoji == "\(level.emoji)")
            try expect(level.description == "\(level)")
        }
    }

    @MainActor
    static let tests = [
        // Both tests mutate process-global debug state (`Compatibility.settings` or the
        // logger used by `debugSuppress`). Serialized mode prevents them from overlapping
        // each other or any parallel reusable test while those temporary changes are active.
        TestCase("debug configuration tests", executionMode: .serialized, testDebugConfig),
        TestCase("debug tests", executionMode: .serialized, testDebug),
    ]
}
#endif