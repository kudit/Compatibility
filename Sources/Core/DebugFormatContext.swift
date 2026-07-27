/// Named values supplied to a custom debug formatter.
///
/// Use `Compatibility.settings.debugFormatter` for new code. The existing
/// positional `debugFormat` closure remains source-compatible.
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

public extension CompatibilityConfiguration {
    /// Preferred labeled alternative to the legacy positional `debugFormat` closure.
    ///
    /// Assigning either property updates the same underlying formatter, so existing
    /// `debugFormat = { message, level, ... }` call sites continue to compile.
    var debugFormatter: DebugFormatter {
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
}

#if !hasFeature(Embedded)
public extension Compatibility {
    /// Logs a message using an already-captured source location.
    @discardableResult
    static func debug(
        _ message: Any,
        level: DebugLevel = .defaultLevel,
        source: SourceContext
    ) -> String {
        debug(
            message,
            level: level,
            file: source.file,
            function: source.function,
            line: source.line,
            column: source.column
        )
    }
}

/// Logs a message using an already-captured source location.
@discardableResult
public func debug(
    _ message: Any,
    level: DebugLevel = .defaultLevel,
    source: SourceContext
) -> String {
    Compatibility.debug(message, level: level, source: source)
}
#else
public extension Compatibility {
    /// Logs a message using an already-captured source location.
    @discardableResult
    static func debug(
        _ message: String,
        level: DebugLevel = .defaultLevel,
        source: SourceContext
    ) -> String {
        debug(
            message,
            isMainThread: true,
            level: level,
            file: source.file,
            function: source.function,
            line: source.line,
            column: source.column
        )
    }
}

/// Logs a message using an already-captured source location.
@discardableResult
public func debug(
    _ message: String,
    level: DebugLevel = .defaultLevel,
    source: SourceContext
) -> String {
    Compatibility.debug(message, level: level, source: source)
}
#endif

public extension TestFailure {
    /// Logs this failure at its original source location and returns it for throwing.
    @discardableResult
    func debug(level: DebugLevel = .ERROR) -> Self {
        Compatibility.debug(message, level: level, source: source)
        return self
    }
}
