//
//  Shell.swift
//  Compatibility
//
//  Created by Ben Ku on 3/28/25.
//


// don't expose this to ensure errors when compiling for other platforms when we're just using this as a shell script.  This is expected behavior to prevent compiling as a mac catalyst app.
#if os(macOS) && canImport(Foundation)
import Darwin

/// Runs the legacy shell path without Process.launch(), which reports launch failures as Objective-C exceptions.
///
/// posix_spawn predates macOS 10.10 and returns POSIX error codes that can safely become Swift errors.
/// This helper is also exercised directly by the shared tests so modern hosts validate the fallback.
private func legacyShellData(_ command: String, shell: String) throws -> Data {
    let pipe = Pipe()
    var actions: posix_spawn_file_actions_t?
    // Each POSIX function returns its own error code; errno is only used for waitpid below.
    func check(_ status: Int32) throws {
        guard status == 0 else { throw NSError(domain: NSPOSIXErrorDomain, code: Int(status)) }
    }
    try check(posix_spawn_file_actions_init(&actions))
    defer { posix_spawn_file_actions_destroy(&actions) }

    let readDescriptor = pipe.fileHandleForReading.fileDescriptor
    let writeDescriptor = pipe.fileHandleForWriting.fileDescriptor
    // Duplicate output before opening stdin: a caller with closed standard descriptors can
    // cause Pipe to reuse descriptor 0, 1, or 2. Close only originals above that reserved range.
    try check(posix_spawn_file_actions_adddup2(&actions, writeDescriptor, STDOUT_FILENO))
    try check(posix_spawn_file_actions_adddup2(&actions, writeDescriptor, STDERR_FILENO))
    try check(posix_spawn_file_actions_addopen(&actions, STDIN_FILENO, "/dev/null", O_RDONLY, 0))
    if readDescriptor > STDERR_FILENO {
        try check(posix_spawn_file_actions_addclose(&actions, readDescriptor))
    }
    if writeDescriptor > STDERR_FILENO {
        try check(posix_spawn_file_actions_addclose(&actions, writeDescriptor))
    }

    // Snapshot the environment and keep every C string alive until posix_spawn has copied it.
    // Passing the command as one -c argument preserves quoting instead of rebuilding shell text.
    let strings = [shell, "-c", command] + ProcessInfo.processInfo.environment.map { "\($0.key)=\($0.value)" }
    guard !strings.contains(where: { $0.utf8.contains(0) }) else {
        throw NSError(domain: NSPOSIXErrorDomain, code: Int(EINVAL))
    }
    let buffers = strings.map { strdup($0) }
    defer { buffers.forEach { free($0) } }
    guard buffers.allSatisfy({ $0 != nil }) else {
        throw NSError(domain: NSPOSIXErrorDomain, code: Int(ENOMEM))
    }
    var arguments = Array(buffers.prefix(3)) + [nil]
    var environment = Array(buffers.dropFirst(3)) + [nil]
    var processID: pid_t = 0
    try check(posix_spawn(&processID, shell, &actions, nil, &arguments, &environment))
    // Closing the parent's write end allows EOF when the child closes stdout/stderr.
    pipe.fileHandleForWriting.closeFile()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    // Drain before waiting so output larger than the pipe buffer cannot deadlock the child.
    // Retry interrupted waits and reap the child; nonzero shell exit codes retain safeShell's existing behavior.
    var status: Int32 = 0
    while waitpid(processID, &status, 0) == -1 {
        if errno != EINTR {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
        }
    }
    return data
}

public extension Compatibility {
    /// Executes a shell command and returns the result (or errors) as a String (if you just need to execute and don't need the result, that's okay).
    /// This will primarily be used in command line tools.
    ///
    /// - Parameter command: The shell command to run.  ex: `ls -la /Volumes`
    /// - Parameter shell: The shell executable to use.  Defaults to `/bin/zsh`
    /// - Parameter logCommand: Outputs the command to the console with a NOTICE level.  Defautls to `true`
    ///
    /// - Throws: Any errors generated when running the task or a CustomError if the output fails to convert to UTF-8 (which should never happen).
    ///
    /// - Note: This is only available in macOS and **not** macCatalyst or any other platform.
    ///   Before macOS 10.13, a POSIX spawn fallback captures the same combined stdout/stderr
    ///   and throws POSIX launch errors. A nonzero shell exit status does not itself throw.
    @discardableResult // Add to suppress warnings when you don't want/need the result
    static func safeShell(_ command: String, shell: String = "/bin/zsh", logCommand: Bool = true, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) throws -> String {
        if logCommand {
            Compatibility.debug("Attempting to run shell command:\n\(command)", level: .NOTICE, source: SourceContext(file: file, function: function, line: line, column: column))
        }
        
        let data: Data
        // The former unconditional task.executableURL / task.run() path required macOS 10.13.
        // Keep it on newer systems while providing a throwing launch path for older Intel Macs.
        if #available(macOS 10.13, *) {
            let task = Process()
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            task.arguments = ["-c", command]
            task.executableURL = URL(fileURLWithPath: shell) //<--updated
            task.standardInput = nil
            try task.run() //<--updated
            data = pipe.fileHandleForReading.readDataToEndOfFile()
        } else {
            data = try legacyShellData(command, shell: shell)
        }
        guard let output = String(data: data, encoding: .utf8) else {
            throw CustomError("Failed to parse shell output as UTF-8", level: .ERROR, file: file, function: function, line: line, column: column) // this should never happen
        }
        
        return output
    }
}

#if compiler(>=5.9)
/// Reusable coverage of the actual legacy launch implementation, independent of the host's OS version.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
internal let legacyShellTests: [TestCase] = [
    TestCase("Legacy shell output and launch errors") {
        let command = "printf '%s' 'quoted value'; printf '%s' ' error' >&2; exit 7"
        let legacy = try legacyShellData(command, shell: "/bin/sh")
        try expectEqual(String(data: legacy, encoding: .utf8), "quoted value error")
        try expectEqual(try Compatibility.safeShell(command, shell: "/bin/sh", logCommand: false), "quoted value error")
        // A pipeful of output exercises the drain-before-wait ordering without depending on network or user files.
        let largeOutput = try legacyShellData("/usr/bin/awk 'BEGIN { for (i=0; i<200000; i++) printf \"x\" }'", shell: "/bin/sh")
        try expectEqual(largeOutput.count, 200000)
        let emptyInput = try legacyShellData("/bin/cat", shell: "/bin/sh")
        try expect(emptyInput.isEmpty, "Legacy shell stdin should reach EOF through /dev/null")
        do {
            _ = try legacyShellData("exit 0", shell: "/nonexistent/Compatibility-test-shell")
            try expect(false, "A missing shell must throw rather than terminate the process")
        } catch let error as NSError where error.domain == NSPOSIXErrorDomain {
            try expectEqual(error.code, Int(ENOENT))
        }
    },
]
#endif

public func safeShell(_ command: String, shell: String = "/bin/zsh", logCommand: Bool = true, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) throws -> String {
    return try Compatibility.safeShell(command, shell: shell, logCommand: logCommand, file: file, function: function, line: line, column: column)
}
#endif
