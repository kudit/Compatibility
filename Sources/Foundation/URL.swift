//
//  String.swift
//  KuditFrameworks
//
//  Created by Ben Ku on 1/8/16.
//  Copyright © 2016 Kudit. All rights reserved.
//

// for NSDocumentTypeDocumentAttribute
//#if os(OSX)
//    import AppKit
//#elseif os(iOS) || os(tvOS)
//    import UIKit
//#endif

public extension URL {
    var fileBasename: String {
        return self.deletingPathExtension().lastPathComponent
    }
    var fileExists: Bool {
        FileManager.default.fileExists(atPath: self.path)
    }
    
    /// Returns the path component of the URL if present, otherwise returns an empty string.
    /// - note: This function will resolve against the base `URL`.  It will include a trailing slash if this is a directory.
    /// - Parameter percentEncoded: Whether the path should be percent encoded,
    ///   defaults to `true`.
    /// - Returns: The path component of the URL.
    func backportPath(percentEncoded: Bool = true) -> String {
#if canImport(Combine)
        if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
            return self.path(percentEncoded: percentEncoded)
        }
#endif
        // Fallback on earlier versions & Linux
        return self.path
    }

    /// Returns `true` if this is a directory, `false` if not, or `nil` if this cannot be determined
    var isDirectory: Bool? {
        guard let isDirectory = (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory else {
            return nil
        }
        return isDirectory
    }
}


#if !DEBUG
extension URL: Swift.Comparable {
    @available(*, deprecated, message: "Compare `.path` instead.")
    public static func < (lhs: URL, rhs: URL) -> Bool {
        return lhs.path < rhs.path
    }
}
#endif

public extension URL {
    /// Force the URL to https if it is HTTP
    var secured: URL {
        guard self.scheme == "http" else {
            return self
        }
        // replace http with https
        let urlString = self.absoluteString.replacingOccurrences(of: "http://", with: "https://")
        debug("Replacing unsecure URL: \(self.absoluteString) with \(urlString)", level: .NOTICE)
        guard let secureURL = URL(string: urlString) else {
            debug("Unable to convert HTTP URL to HTTPS: \(urlString)", level: .ERROR)
            return self
        }
        return secureURL
    }
}
