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
}


extension URL: Swift.Comparable {
    @available(*, deprecated, message: "Compare `.path` instead.")
    public static func < (lhs: URL, rhs: URL) -> Bool {
        return lhs.path < rhs.path
    }
}

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
