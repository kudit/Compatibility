
// Here since all releated to Debug code.
/// DEFAULT BEHAVIOR (can be overridden by a custom CompatibilitySettings assigned to Compatibilty.settings in an extension.  If `COMPATIBILITY_CUSTOM_SETTINGS` SwiftSetting flag  is not set, this is the behavior that will be used.
public struct CompatibilityConfiguration {
    /// Override to change the which debug levels are output.  This level and higher (more important) will be output.
    public var debugLevelCurrent: DebugLevel = {
        if #available(iOS 13, tvOS 13, watchOS 6, *) {
            return Application.isDebug ? .DEBUG : .WARNING
        } else {
            return .DEBUG
        }
    }()
    
    /// Override to change the level of debug statments without a level parameter.
    public var debugLevelDefault = DebugLevel.DEBUG
    
    /// Override to use the level symbol rather than the emoji (if we're outputting in an environment that does not support emoji).
    public var debugEmojiSupported = true
    
    /// Set this to a set of levels where we should include the context info.  Defaults to `.important` so that `NOTICE` and `DEBUG` messages are less noisy and easier to see.  Set this to `.none` to make `debug()` act exactly like `print()` at all levels.
    public var debugLevelsToIncludeContext = DebugLevels.important
    
    /// Set whether timestamps should be included in debug messages.  If you need to customize the format of timestamps, use the `debugFormat()` override.
    public var debugIncludeTimestamp = false
    
    /// Generates string with context.  Set level to `.OFF` to just return the context without the message portion.
    public var debugFormat = { (message: String, level: DebugLevel, isMainThread: Bool, emojiSupported: Bool, includeContext: Bool, includeTimestamp: Bool, file: String, function: String, line: Int, column: Int) -> String in
        let message = "\(emojiSupported ? level.emoji : level.symbol) \(message)"
        if includeContext {
            let threadInfo = isMainThread ? "" : "^"
            let simplerFile = URL(fileURLWithPath: file).lastPathComponent
            let simplerFunction = function.replacingOccurrences(of: "__preview__", with: "_p_")
            var timestamp = ""
            if includeTimestamp {
                timestamp = "\(Date.nowBackport.mysqlDateTime): "
            }
            return "\(timestamp)\(simplerFile)(\(line)) : \(simplerFunction)\(threadInfo)\(level == .OFF ? "" : "\n\(message)")"
        } else {
            return message
        }
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
        return Compatibility.debug(description, level: level ?? DebugLevel.defaultLevel, file: file, function: function, line: line, column: column)
    }
}
extension CustomError: CustomStringConvertible {
    public var description: String {
        message
    }
}
extension CustomError: LocalizedError {
    public var localizedDescription: String {
        message
    }
    public var errorDescription: String? {
        message
    }
}

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
    @available(iOS 13, tvOS 13, watchOS 6, *)
    public static let currentLevel = Compatibility.settings.debugLevelCurrent
    
    /// Set to change the level of debug statments without a level parameter.  Default is `.DEBUG`.  Can be changed using the `debugLevelDefault` setting.
    public static let defaultLevel = Compatibility.settings.debugLevelDefault
                
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
        if #available(iOS 13, tvOS 13, watchOS 6, *) {
            return Self.currentLevel.isAtLeast(level)
        } else {
            // Fallback on earlier versions
            return Self.DEBUG.isAtLeast(level)
        }
    }
}

/// Generates context string
#if !DEBUG
@available(*, deprecated, renamed: "Compatibility.settings.debugFormat()")
public func debugContext(isMainThread: Bool, file: String, function: String, line: Int, column: Int) -> String {
    Compatibility.settings.debugFormat(
        "",
        .OFF,
        isMainThread,
        Compatibility.settings.debugEmojiSupported,
        true,
        Compatibility.settings.debugIncludeTimestamp,
        file, function, line, column)
}
#endif

// MARK: - Debug
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
    static func debug(_ message: Any, level: DebugLevel = .defaultLevel, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> String {
        let isMainThread = Thread.isMainThread // capture before we switch to main thread for printing
        let message = String(describing: message) // convert to sendable item to avoid any thread issues.

        checkBreakpoint(level: level)
        
        guard DebugLevel.isAtLeast(level) else {
            return "" // don't actually print
        }
        var debugMessage = message
        if Compatibility.settings.debugLevelsToIncludeContext != .none {
            debugMessage = Compatibility.settings.debugFormat(
                message,
                level,
                isMainThread,
                Compatibility.settings.debugEmojiSupported,
                Compatibility.settings.debugLevelsToIncludeContext.contains(level),
                Compatibility.settings.debugIncludeTimestamp,
                file, function, line, column)
        }
        print(debugMessage)
        return debugMessage
    }
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
@discardableResult
public func debug(_ message: Any, level: DebugLevel = .defaultLevel, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) -> String {
    return Compatibility.debug(message, level: level, file: file, function: function, line: line, column: column)
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
}
