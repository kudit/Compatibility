// MARK: - Compatibility command-line demonstration
// This small executable proves that the package can expose the same Compatibility
// APIs to a macOS command-line tool without changing the Swift Playgrounds app.

import Compatibility
import Foundation

/// Writes command output directly to standard output because this executable's
/// result is its public interface; library diagnostics continue to use `debug()`.
private func writeOutput(_ message: String) {
    let output = "\(message)\n"
    FileHandle.standardOutput.write(Data(output.utf8))
}

/// Prints a concise usage summary for the intentionally small demonstration CLI.
private func printUsage() {
    writeOutput("Usage: compatibilityCLI <banana|parseDate> <value>")
    writeOutput("  banana Bob")
    writeOutput("  parseDate \"2023-01-02 17:12:00\"")
}

let arguments = Array(CommandLine.arguments.dropFirst())
guard let command = arguments.first else {
    printUsage()
    exit(64)
}

let value = arguments.dropFirst().joined(separator: " ")
guard !value.isEmpty else {
    printUsage()
    exit(64)
}

switch command {
case "banana":
    // Reuse Compatibility's public String extension so the CLI demonstrates a
    // non-Foundation API that client executables can access directly.
    writeOutput(value.banana)

case "parseDate":
    // Reuse the documented multi-format parser and emit a stable ISO-8601 value
    // so command output is easy to compare in scripts and build demonstrations.
    guard let date = Date(parse: value) else {
        writeOutput("Unable to parse date: \(value)")
        exit(65)
    }
    writeOutput(date.pretty)

default:
    printUsage()
    exit(64)
}
