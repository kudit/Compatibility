//
//  File.swift
//
//
//  Created by Ben Ku on 8/12/22.
//

#if canImport(Foundation)
public extension FileManager {
    enum FileError: Error, Sendable {
        case noDirectorySpecified
    }

    /// Returns the visible, immediate entries in a directory.
    ///
    /// This skips hidden entries and does not recursively descend into subdirectories. Returned URLs can
    /// represent either files or directories, and their order is determined by the file system rather than
    /// sorted by this method.
    ///
    /// - Parameter directory: The file URL of the directory whose direct children should be listed.
    /// - Returns: URLs for the non-hidden entries immediately inside `directory`.
    /// - Throws: A file-system error when the directory does not exist, is inaccessible, or cannot be read.
    func entries(in directory: URL) throws -> [URL] {
        // Prefetch the name resource key because callers commonly display the returned entry names.
        return try contentsOfDirectory(at: directory, includingPropertiesForKeys: [.nameKey], options: .skipsHiddenFiles)
    }

    /// Returns the visible, immediate entries in a directory.
    ///
    /// This skips hidden entries and does not recursively descend into subdirectories. Returned URLs can
    /// represent either files or directories, and their order is determined by the file system rather than
    /// sorted by this method.
    ///
    /// - Parameter directory: The file URL of the directory whose direct children should be listed.
    /// - Returns: URLs for the non-hidden files and directories immediately inside `directory`.
    /// - Throws: A file-system error when the directory does not exist, is inaccessible, or cannot be read.
    @available(*, deprecated, renamed: "entries(in:)")
    func files(in directory: URL) throws -> [URL] {
        // Preserve source compatibility while directing new code to the more accurate entry-based name.
        return try entries(in: directory)
    }
}

#if compiler(>=5.9)
@available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
extension FileManager {
    /// Shared file-manager tests used by both the in-app runner and Swift Testing.
    @MainActor
    internal static let tests: [Test] = [
        Test("Visible directory entries") {
            let manager = FileManager.default
            let fixture = manager.temporaryDirectory.appendingPathComponent("CompatibilityFileManagerTests-\(UUID().uuidString)", isDirectory: true)
            let visibleFile = fixture.appendingPathComponent("Visible.txt")
            let visibleDirectory = fixture.appendingPathComponent("Visible Directory", isDirectory: true)
            let hiddenFile = fixture.appendingPathComponent(".Hidden.txt")

            // Build a unique fixture so the result does not depend on user files, ordering, or prior test runs.
            try manager.createDirectory(at: fixture, withIntermediateDirectories: false)
            defer {
                // Always restore the temporary directory even when an expectation fails.
                try? manager.removeItem(at: fixture)
            }
            try Data().write(to: visibleFile)
            try manager.createDirectory(at: visibleDirectory, withIntermediateDirectories: false)
            try Data().write(to: hiddenFile)

            let entryNames = try manager.entries(in: fixture).map(\.lastPathComponent).sorted()
            try expect(entryNames == ["Visible Directory", "Visible.txt"], "Expected visible immediate files and directories, got: \(entryNames)")
        },
    ]
}
#endif
#endif
#if !canImport(CoreML) && canImport(Foundation) // this isn't available on linux or WASM!
public extension FileManager {
    /// A compatibility fallback for platforms whose Foundation does not expose Apple's iCloud identity token.
    ///
    /// The Apple implementation returns an opaque token when the user is signed into iCloud. Platforms
    /// without that API always return `nil`, allowing shared code to treat iCloud identity as unavailable.
    var ubiquityIdentityToken: String? { nil }
}
#endif
