//
//  Shell.swift
//  Compatibility
//
//  Created by Ben Ku on 3/28/25.
//


#if os(macOS)
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
    @discardableResult // Add to suppress warnings when you don't want/need the result
    static func safeShell(_ command: String, shell: String = "/bin/zsh", logCommand: Bool = true) throws -> String {
        if logCommand {
            debug("Attempting to run shell command:\n\(command)", level: .NOTICE)
        }
        
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: shell) //<--updated
        task.standardInput = nil
        
        try task.run() //<--updated
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            throw CustomError("Failed to parse shell output as UTF-8", level: .ERROR) // this should never happen
        }
        
        return output
    }
}

public func safeShell(_ command: String, shell: String = "/bin/zsh", logCommand: Bool = true) throws -> String {
    return try Compatibility.safeShell(command, shell: shell, logCommand: logCommand)
}
#endif
