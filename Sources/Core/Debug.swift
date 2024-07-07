import Foundation

// for flags in swift packages: https://stackoverflow.com/questions/38813906/swift-how-to-use-preprocessor-flags-like-if-debug-to-implement-api-keys
//swiftSettings: [
//    .define("VAPOR")
//]


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
    public init(_ message: String, level: DebugLevel = DebugLevel.defaultLevel, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
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

extension Notification.Name {
    static let currentDebugLevelChanged = Notification.Name("currentDebugLevelChanged")
}

@MainActor
public class ObservableDebugLevel: ObservableObject {
    public static var shared = ObservableDebugLevel()
    @Published public var value = DebugLevel.currentLevel
    public init() { // use shared
        // subscribe to debuglevel changes
        NotificationCenter.default.addObserver(forName: .currentDebugLevelChanged, object: nil, queue: nil) { _ in
            main {
                debug("Notification of level change!", level: .currentLevel)
                self.value = DebugLevel.currentLevel
            }
        }
    }
}

public extension Set<DebugLevel> {
    static var all: Self = [.ERROR, .WARNING, .NOTICE, .DEBUG]
    static var important: Self = [.ERROR, .WARNING]
    static var informational: Self = [.NOTICE, .WARNING]
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
    @MainActor
    public static var currentLevel: DebugLevel = DebugLevel.DEBUG
    /// Allow monitoring by subscribing to `.currentDebugLevelChanged` notification.
    {
        didSet {
            debug("Changed current debug level to \(DebugLevel.currentLevel)", level: .NOTICE)
            NotificationCenter.default.post(name: .currentDebugLevelChanged, object: nil)
        }
    }
    
    /// Set to change the level of debug statments without a level parameter.
    public static var defaultLevel = DebugLevel.ERROR
    
    /// Set this to a set of levels where we should include the context info.  Defaults to `.important` so that Notices and Debug messages are less noisy and easier to see.
    public static var levelsToIncludeContext: Set<DebugLevel> = .important
    
    /// Set this to `true` to log failed color parsing notices when returning `nil`
    public static var colorLogging = false
    
    /// setting this to false will make debug() act exactly like print()
    public static var includeContext = true
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
    @MainActor
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
public func debug(_ message: Any, level: DebugLevel = DebugLevel.defaultLevel, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
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
    let isMainThread = Thread.isMainThread // capture before we switch to main thread for printing
    main { // to ensure that the current debug level (which must be called on the main actor with new concurrency) is thread-safe.  Should be okay since print is effectively UI anyways...
        guard DebugLevel.isAtLeast(level) else {
            return
        }
        if DebugLevel.includeContext {
            let context = debugContext(isMainThread: isMainThread, file: file, function: function, line: line, column: column)
            print("\(DebugLevel.levelsToIncludeContext.contains(level) ? context : "")\(level.emoji) \(message)")
        } else {
            print(message)
        }
    }
}
