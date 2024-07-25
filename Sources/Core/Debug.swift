// for flags in swift packages: https://stackoverflow.com/questions/38813906/swift-how-to-use-preprocessor-flags-like-if-debug-to-implement-api-keys
//swiftSettings: [
//    .define("VAPOR")
//]
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
public enum CustomError: Error, Sendable, CustomStringConvertible {
    case custom(String)
    public init(_ message: String, level: DebugLevel = .SILENT /* Do not warn by default.  Can't be DebugLevel.defaultLevel because that needs to be on the main thread */, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        debug(message, level: level, file: file, function: function, line: line, column: column)
        self = .custom(message)
    }
    public var description: String {
        switch self {
        case .custom(let string):
            return string
        }
    }
}

public extension Set<DebugLevel> {
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
    case SILENT
    /// Change this value in production to DebugLevvel.ERROR to minimize logging.
    // set default debugging level to .DEBUG (use manual controls to turn OFF if not debug during app tracking since previews do not have app tracking set up nor does it have compiler flags or app init.
    public static let currentLevel: DebugLevel = Compatibility.isDebug ? .DEBUG : .WARNING
    
    /// Set to change the level of debug statments without a level parameter.
    public static let defaultLevel = DebugLevel.DEBUG // needs to be a let in order for this to be concurrency safe without restricting to @MainActor.  Fork the project and change if you must.  Using .DEBUG since, well, it is a `debug()` call...
    
    /// Set this to a set of levels where we should include the context info.  Defaults to `.important` so that Notices and Debug messages are less noisy and easier to see.
    public static let levelsToIncludeContext: Set<DebugLevel> = .important // again, needs to be let in order for concurrency safety.  Unfortunately this means forking the project if you want to change but typically won't need to be changed at runtime anyway.
        
    /// setting this to false will make debug() act exactly like print()
    public static let includeContext = true // unfortunately again needs to be let for concurrency.  Can also be passed as a parameter to override.
    
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
        return Self.currentLevel.isAtLeast(level)
    }
}

/// Generates context string
public func debugContext(isMainThread: Bool, file: String, function: String, line: Int, column: Int) -> String {
    let threadInfo = isMainThread ? "" : "^"
    let simplerFile = URL(fileURLWithPath: file).lastPathComponent
    let simplerFunction = function.replacingOccurrences(of: "__preview__", with: "_p_")
    // TODO: Add timestamps to debug calls so we can see how long things take?  Have a debug format static string so we can propertly interleave or customize.
    let context = "\(simplerFile)(\(line)) : \(simplerFunction)\(threadInfo)\n"
    return context
}

//DebugLevel.currentLevel = .ERROR
/**
 Ku: Debug helper for printing info to screen including file and line info of call site.  Also can provide a log level for use in loggers or for globally turning on/off logging. (Modify DebugLevel.currentLevel to set level to output.  When launching app, probably can set this to DebugLevel.OFF
 
 - Parameter message: The message to report.
 - Parameter level: The logging level to use.
 - Parameter file: For bubbling down the #file name from a call site.
 - Parameter function: For bubbling down the #function name from a call site.
 - Parameter line: For bubbling down the #line number from a call site.
 - Parameter column: For bubbling down the #column number from a call site. (Not used currently but here for completeness).
 */
//@discardableResult
public func debug(_ message: Any, level: DebugLevel? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
    Compatibility.debug(message, level: level, file: file, function: function, line: line, column: column)
}
public extension Compatibility {
    /**
     Ku: Debug helper for printing info to screen including file and line info of call site.  Also can provide a log level for use in loggers or for globally turning on/off logging. (Modify DebugLevel.currentLevel to set level to output.  When launching app, probably can set this to DebugLevel.OFF
     
     - Parameter message: The message to report.
     - Parameter level: The logging level to use.
     - Parameter file: For bubbling down the #file name from a call site.
     - Parameter function: For bubbling down the #function name from a call site.
     - Parameter line: For bubbling down the #line number from a call site.
     - Parameter column: For bubbling down the #column number from a call site. (Not used currently but here for completeness).
     */
    @discardableResult
    static func debug(_ message: Any, level: DebugLevel? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> String {
        let isMainThread = Thread.isMainThread // capture before we switch to main thread for printing
        let message = String(describing: message) // convert to sendable item to avoid any thread issues.

        let resolvedLevel = level ?? .defaultLevel
        checkBreakpoint(level: resolvedLevel)
        
        guard DebugLevel.isAtLeast(resolvedLevel) else {
            return "" // don't actually print
        }
        var debugMessage = message
        if DebugLevel.includeContext {
            let context = debugContext(isMainThread: isMainThread, file: file, function: function, line: line, column: column)
            debugMessage = "\(DebugLevel.levelsToIncludeContext.contains(resolvedLevel) ? context : "")\(resolvedLevel.emoji) \(message)"
        }
        print(debugMessage)
        return debugMessage
    }
}
