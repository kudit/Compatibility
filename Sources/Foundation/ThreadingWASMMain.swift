//
//  ThreadingWASMMain.swift
//  Compatibility
//
//  Full-runtime WebAssembly has Swift concurrency but not Dispatch-backed threading.
//  Keep the main-actor scheduling convenience there without pretending that work can
//  be moved to a background thread or that host timer services exist.
//

#if arch(wasm32) && !hasFeature(Embedded)

public extension Compatibility {
    /// Schedules work onto Swift's main actor on full-runtime WebAssembly.
    ///
    /// Unlike the former synchronous fallback, this uses Swift concurrency and does not
    /// claim that an arbitrary caller is already executing in the main-actor isolation domain.
    static func main(
        _ closure: @Sendable @MainActor @escaping () -> Void,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) {
        Task { @MainActor in
            closure()
        }
    }
}

/// Schedules work onto Swift's main actor using the concise cross-platform spelling.
public func main(
    _ closure: @Sendable @MainActor @escaping () -> Void,
    file: String = #file,
    function: String = #function,
    line: Int = #line,
    column: Int = #column
) {
    Compatibility.main(closure, file: file, function: function, line: line, column: column)
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Task where Success == Never, Failure == Never {
    /// WebAssembly counterpart to the main-actor scheduling convenience on threaded hosts.
    static func main(
        _ closure: @Sendable @MainActor @escaping () -> Void,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) {
        Compatibility.main(closure, file: file, function: function, line: line, column: column)
    }
}

#endif
