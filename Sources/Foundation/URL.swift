//
//  String.swift
//  KuditFrameworks
//
//  Created by Ben Ku on 1/8/16.
//  Copyright © 2016 Kudit. All rights reserved.
//

import Foundation

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


extension URL: Comparable {
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
    /// download data asynchronously and return the data or nil if there is a failure
    @available(iOS 15, macCatalyst 15.0, *)
    func download() async throws -> Data {
        do {
            if #available(macOS 12.0, *) {
                let (fileURL, response) = try await URLSession.shared.download(from: self)
                debug("URL Download response: \(response)", level: .DEBUG)

                // load data from local file URL
                let data = try Data(contentsOf: fileURL)
                return data
            } else {
                // Fallback on earlier versions
                let request = URLRequest(url: self)
                let (data, _) = try await URLSession.shared.legacyData(for: request)
                return data
            }
        } catch URLError.appTransportSecurityRequiresSecureConnection {
            // replace http with https
            return try await self.secured.download()
        }
    }
}
