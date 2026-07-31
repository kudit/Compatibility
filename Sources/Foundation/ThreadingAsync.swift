//
//  ThreadingAsync.swift
//  Compatibility
//
//  Async-only threading conveniences that complement the deployment-compatible
//  synchronous and fire-and-forget APIs in Threading.swift.
//

#if compiler(>=5.9) && !hasFeature(Embedded)

public extension Compatibility {
    /// Runs work on the main actor, waits for completion, and returns its value.
    ///
    /// This intentionally complements rather than replaces the existing
    /// `Compatibility.main { }` helper in `Threading.swift`. The existing helper is
    /// fire-and-forget and remains available on deployment targets that predate Swift
    /// concurrency. Use this awaited overload when subsequent work depends on completion
    /// or when the main-actor operation returns a value.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    static func main<Result: Sendable>(
        _ operation: @MainActor @Sendable () throws -> Result
    ) async rethrows -> Result {
        try await MainActor.run(resultType: Result.self, body: operation)
    }
}

#if arch(wasm32)

public extension Compatibility {
    /// Starts asynchronous work using WebAssembly's cooperative task executor.
    ///
    /// A generic WebAssembly host does not guarantee detached threads or Dispatch.
    /// This therefore preserves asynchronous scheduling semantics without claiming
    /// that the operation executes in parallel with the caller.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    static func background(
        _ operation: @Sendable @escaping () async -> Void
    ) {
        Task {
            await operation()
        }
    }

    /// Runs nonthrowing asynchronous work and returns its value on WebAssembly.
    ///
    /// The generic result also supports optional values, so a separate optional-result
    /// overload would only duplicate this API and create unnecessary overload ambiguity.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    static func background<Result: Sendable>(
        _ operation: @Sendable @escaping () async -> Result
    ) async -> Result {
        await operation()
    }

    /// Runs throwing asynchronous work and returns its value on WebAssembly.
    ///
    /// This is `async throws` rather than `rethrows` so its signature matches the
    /// detached-task implementation used by threaded hosts.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    static func background<Result: Sendable>(
        _ operation: @Sendable @escaping () async throws -> Result
    ) async throws -> Result {
        try await operation()
    }

    /// Provides the asynchronous seconds-based sleep spelling on WebAssembly.
    ///
    /// Swift concurrency is available in the full runtime, but a generic browser or
    /// WASI host does not guarantee a suspending timer. Until Compatibility gains a
    /// host timer hook, this reports the limitation and returns immediately. The
    /// synchronous compatibility spelling in `Threading.swift` remains source-compatible.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    static func sleep(
        seconds: Double,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) async {
        Compatibility.debug(
            "Sleep requested for \(seconds) seconds, but this WebAssembly host has no registered suspending timer; no delay occurred.",
            isMainThread: true,
            level: .WARNING,
            file: file,
            function: function,
            line: line,
            column: column
        )
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Task where Success == Never, Failure == Never {
    /// WebAssembly counterpart to the asynchronous `Task.background` helper on threaded hosts.
    static func background(
        _ operation: @Sendable @escaping () async -> Void
    ) {
        Compatibility.background(operation)
    }

    /// Runs nonthrowing cooperative background work and returns its value.
    static func background<Result: Sendable>(
        _ operation: @Sendable @escaping () async -> Result
    ) async -> Result {
        await Compatibility.background(operation)
    }

    /// Runs throwing cooperative background work and returns its value.
    static func background<Result: Sendable>(
        _ operation: @Sendable @escaping () async throws -> Result
    ) async throws -> Result {
        try await Compatibility.background(operation)
    }

    /// WebAssembly counterpart to the seconds-based `Task.sleep` convenience.
    static func sleep(
        seconds: Double,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) async {
        await Compatibility.sleep(
            seconds: seconds,
            file: file,
            function: function,
            line: line,
            column: column
        )
    }
}

#endif // arch(wasm32)
#endif // compiler(>=5.9) && !hasFeature(Embedded)
