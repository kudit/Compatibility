//
//  File.swift
//  
//
//  Created by Ben Ku on 7/6/24.
//
#if canImport(Foundation)

// Typealias needs to be initially part of another structure or throws compiler errors in Swift Playgrounds.
public extension Compatibility {
    typealias PostData = [String:Sendable]
}
public typealias PostData = Compatibility.PostData
public extension PostData {
    var queryString: String? {
        //return "fooish=barish&baz=buzz"
        var items = [URLQueryItem]()
        for (key, value) in self {
            items.append(URLQueryItem(name: key, value: "\(value)"))
        }
        var urlComponents = URLComponents()
        urlComponents.queryItems = items
        return urlComponents.url?.query
    }
    var queryEncoded: Data? {
        return queryString?.data(using: .utf8)
    }
}

public enum NetworkError: Error, Sendable {
    // Throw when unable to parse a URL
    case urlParsing(urlString: String)
    
    case postDataEncoding(_ postData: PostData)
    
    /// Throw when there's a server error (with HTTP error code)
    // Invalid HTTP response (with response code)
    case invalidResponse(code: Int? = nil)
    
    /// Throw when the server data cannot be converted to a String
#if compiler(>=5.9)
    case dataError(_ data: Data)
#endif
    /// Missing a required network capability in the package or entitlement for the app.
    case missingEntitlement
        
    public var localizedDescription: String {
        switch self {
        case .urlParsing(let urlString):
            return "URL could not be parsed from \"\(urlString)\""
        case .postDataEncoding(let postData):
            return "Post Data could not be encoded from: \(String(describing: postData))"
        case .invalidResponse(let code):
            return "Invalid HTTP Response: (\(code != nil ? "\(code!)" : "No code")) received from the server"
#if compiler(>=5.9)
        case .dataError(let data):
            return "Unable to parse string out of data: \(String(describing: data))"
#endif
        case .missingEntitlement:
            return """
                DEVELOPER: Check your configuration!
                If you're running from a playground, make sure you have the capability for `Network Connections (macOS) Outgoing` enabled.
                You can also add the following to the Package.swift:
                ```swift
                    capabilities: [
                        .outgoingNetworkConnections()
                    ],
                ```
                If this is an app, add the following key to the Entitlements PLIST file:
                ```xml
                    <key>com.apple.security.network.client</key>
                    <true/>
                ```
            """
        }
    }
}
extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        localizedDescription
    }
}

#if compiler(>=5.9) && (canImport(Combine) || canImport(FoundationNetworking))

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension PostData {
    // MARK: - Tests
    internal static let TEST_DATA: PostData = ["id": 13, "name": "Jack & \"Jill\"", "foo": false, "bar": "0.0"]
    @MainActor
    internal static let testPostDataQueryEncoding: TestClosure = {
        //debug(testData.queryString ?? "Unable to generate query string")
        let query = TEST_DATA.queryString ?? "Unable to generate query string"
        let expected = "name=Jack%20%26%20%22Jill%22"
        try expect(query.contains(expected), "\(query) does not contain \(expected)")
    }
    @MainActor
    internal static let testFetchGwinnettCheck: TestClosure = {
        guard Build.runsIntegrationTests else { return }
        var results = "NONE"
        try await debugSuppress {
            results = try await fetchURL(urlString: "https://www.GwinnettCounty.com")
        }
//        debug("RESULTS: \(results)", level: .DEBUG)
        try expect(results.contains("Gwinnett"), results)
    }
    @MainActor
    internal static let testFetchGETCheck: TestClosure = {
        guard Build.runsIntegrationTests else { return }
        let query = TEST_DATA.queryString ?? "ERROR"
        var results = "NONE"
        try await debugSuppress {
            results = try await fetchURL(urlString: "https://plickle.com/pd.php?\(query)")
        }
//        debug("RESULTS: \(results)", level: .DEBUG)
        try expect(results.contains("[name] => Jack & \"Jill\""), results)
        try expect(results.contains("[SCRIPT_NAME] =&gt; /pd.php"), results)
    }
    @MainActor
    internal static let testFetchPOSTCheck: TestClosure = {
        guard Build.runsIntegrationTests else { return }
        var results = "NONE"
        try await debugSuppress {
            results = try await fetchURL(urlString: "https://plickle.com/pd.php", postData:TEST_DATA)
        }
//        debug("RESULTS: \(results)", level: .DEBUG)
        try expect(results.contains("'name' => 'Jack & \\\"Jill\\\"',"), results)
        try expect(results.contains("[SCRIPT_NAME] =&gt; /pd.php"), results)
    }
    @MainActor
    internal static let testNetworkErrors: TestClosure = {
        try expect(NetworkError.urlParsing(urlString: "invalid url").localizedDescription.contains("invalid url"))
        try expect(NetworkError.postDataEncoding(["foo":"bar"]).localizedDescription == "Post Data could not be encoded from: [\"foo\": \"bar\"]", NetworkError.postDataEncoding(["foo":"bar"]).localizedDescription)
        try expect(NetworkError.invalidResponse(code: 404).localizedDescription.contains("404"))
        try expect(NetworkError.dataError(Data()).localizedDescription.contains("Unable to parse string"))
        try expect(NetworkError.missingEntitlement.localizedDescription.contains("DEVELOPER: Check your configuration"))
    }
    @MainActor
    static let tests = [
        TestCase("POST data query encoding", testPostDataQueryEncoding),
        TestCase("POST data empty and nil values") {
            let data: PostData = ["empty": ""]
            let query = data.queryString ?? ""
            try expect(query.contains("empty="))
            try expect(data.queryEncoded != nil)
        },
        TestCase("Network source-forwarding errors") {
            do {
                _ = try await Compatibility.fetchURLData(urlString: "http://[", source: SourceContext(file: #file, function: #function, line: #line, column: #column))
                try expect(false, "Invalid URLs should throw")
            } catch NetworkError.urlParsing {
                // Expected deterministic error path.
            }
        },
        TestCase("Network deterministic response paths") {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [NetworkTestURLProtocol.self]
            let session = URLSession(configuration: configuration)
            defer { session.invalidateAndCancel() }

            let source = SourceContext(file: #file, function: #function, line: #line, column: #column)
            let successRequest = URLRequest(url: URL(string: "https://compatibility.test/success")!)
            let data = try await Compatibility.fetchURLData(
                request: successRequest,
                session: session,
                useNativeAsyncAPI: true,
                source: source
            )
            try expectEqual(String(data: data, encoding: .utf8), "network test response")

            let legacyData = try await URLRequest(url: successRequest.url!).legacyData(for: session).0
            try expectEqual(String(data: legacyData, encoding: .utf8), "network test response")

            var postRequest = URLRequest(url: URL(string: "https://compatibility.test/request-check")!)
            postRequest.httpMethod = "POST"
            postRequest.httpBody = Data("value=1".utf8)
            let postResponse = try await postRequest.legacyData(for: session).0
            try expectEqual(String(data: postResponse, encoding: .utf8), "POST:value=1")

            do {
                _ = try await Compatibility.fetchURLData(
                    request: URLRequest(url: URL(string: "https://compatibility.test/not-found")!),
                    session: session,
                    useNativeAsyncAPI: false,
                    source: source
                )
                try expect(false, "Non-200 responses should fail")
            } catch NetworkError.invalidResponse(let code) {
                try expectEqual(code, 404)
            }

            do {
                _ = try await Compatibility.fetchURLData(
                    request: URLRequest(url: URL(string: "https://compatibility.test/non-http")!),
                    session: session,
                    useNativeAsyncAPI: false,
                    source: source
                )
                try expect(false, "Non-HTTP responses should fail")
            } catch NetworkError.invalidResponse(let code) {
                try expectEqual(code, nil)
            }

            do {
                _ = try await URLRequest(url: URL(string: "https://compatibility.test/transport-error")!).legacyData(for: session)
                try expect(false, "Transport errors should propagate")
            } catch let error as URLError {
                try expectEqual(error.code, .cannotConnectToHost)
            }
        },
        TestCase("URL download native and legacy session paths") {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [NetworkTestURLProtocol.self]
            let session = URLSession(configuration: configuration)
            defer { session.invalidateAndCancel() }

            let url = URL(string: "https://compatibility.test/download")!
            let nativeData = try await url.download(using: session, useNativeDownload: true)
            let legacyData = try await url.download(using: session, useNativeDownload: false)
            try expectEqual(String(data: nativeData, encoding: .utf8), "network test response")
            try expectEqual(String(data: legacyData, encoding: .utf8), "network test response")
        },
        TestCase("fetchURL Gwinnett check", testFetchGwinnettCheck),
        TestCase("fetchURL GET check", testFetchGETCheck),
        TestCase("fetchURL POST check", testFetchPOSTCheck),
        TestCase("Network Errors", testNetworkErrors),
    ]
}

/// Supplies deterministic HTTP responses to network tests without external services.
private final class NetworkTestURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "compatibility.test"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        if url.path == "/transport-error" {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
            return
        }

        let body: Data
        if url.path == "/request-check" {
            body = Data("\(request.httpMethod ?? "GET"):".utf8) + Self.requestBody(for: request)
        } else {
            body = Data("network test response".utf8)
        }
        let response: URLResponse
        if url.path == "/non-http" {
            response = URLResponse(
                url: url,
                mimeType: "text/plain",
                expectedContentLength: body.count,
                textEncodingName: "utf-8"
            )
        } else {
            let statusCode = url.path == "/not-found" ? 404 : 200
            response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "text/plain"]
            )!
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    private static func requestBody(for request: URLRequest) -> Data {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else { return Data() }

        stream.open()
        defer { stream.close() }
        var body = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            body.append(contentsOf: buffer.prefix(count))
        }
        return body
    }

    override func stopLoading() {}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension URLRequest {
    func legacyData(for session: URLSession) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            guard self.url != nil else {
                return continuation.resume(throwing: URLError(.badURL))
            }
            let task = session.dataTask(with: self) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }
                
                continuation.resume(returning: (data, response))
            }
            
            task.resume()
        }
    }
}

extension Compatibility {
    /// Fetch data from URL including optional postData. Will report the original caller in debug output.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *) // for concurrency
    public static func fetchURLData(urlString: String, postData: PostData? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) async throws -> Data {
        try await fetchURLData(
            urlString: urlString,
            postData: postData,
            source: SourceContext(file: file, function: function, line: line, column: column)
        )
    }

    /// Source-forwarding form for APIs that have already captured their caller's location.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *) // for concurrency
    public static func fetchURLData(urlString: String, postData: PostData? = nil, source: SourceContext) async throws -> Data {
        Compatibility.debug("Fetching URL [\(urlString)]...", level: .NOTICE, source: source)
        // create the url with URL
        // Foundation can construct a non-nil URL for malformed strings such as `http://[`;
        // require a scheme and host here so deterministic parse failures do not reach URLSession
        // and become misleading DNS or entitlement errors.
        guard let components = URLComponents(string: urlString),
              let url = components.url,
              components.scheme != nil,
              components.host != nil else {
            throw NetworkError.urlParsing(urlString: urlString).debug(level: .ERROR, source: source)
        }
        
        // now create the URLRequest object using the url object
        var request = URLRequest(url: url)
        
        // encode the postData if provided, otherwise set the method to GET.
        if let parameters = postData {
            request.httpMethod = "POST" //set http method as POST
            
            // declare the parameter as a dictionary that contains string as key and value combination. considering inputs are valid
            
            //let parameters: [String: Any] = ["id": 13, "name": "jack"]
            guard let data = postData?.queryEncoded else {
                throw NetworkError.postDataEncoding(parameters).debug(level: .ERROR, source: source)
            }
            request.httpBody = data
        } else {
            request.httpMethod = "GET" //set http method as GET
        }
        
        let useNativeAsyncAPI: Bool
        if #available(iOS 15, macOS 12, watchOS 8, tvOS 15, *) {
            useNativeAsyncAPI = true
        } else {
            useNativeAsyncAPI = false
        }
        return try await fetchURLData(
            request: request,
            session: .shared,
            useNativeAsyncAPI: useNativeAsyncAPI,
            source: source
        )
    }

    /// Executes a prepared request using either URLSession's async API or the legacy callback bridge.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    internal static func fetchURLData(
        request: URLRequest,
        session: URLSession,
        useNativeAsyncAPI: Bool,
        source: SourceContext
    ) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            if useNativeAsyncAPI,
               #available(iOS 15, macOS 12, watchOS 8, tvOS 15, *) {
                (data, response) = try await session.data(for: request)
            } else {
                (data, response) = try await request.legacyData(for: session)
            }
        } catch {
            if let error = error as? URLError, error.code.rawValue == -1003 {
                throw NetworkError.missingEntitlement.debug(level: .ERROR, source: source)
            } else {
                throw error.debug(level: .ERROR, source: source)
            }
        }

        // Check response status code exists (should nearly always pass)
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            let debugMessage = "No status code in HTTP response.  Possibly offline?: \(String(describing: response))"
            Compatibility.debug(debugMessage, level: .ERROR, source: source)
            throw NetworkError.invalidResponse().debug(level: .ERROR, source: source)
        }

        // check status code (should always be 200)
        guard statusCode == 200 else {
            throw NetworkError.invalidResponse(code: statusCode).debug(level: .ERROR, source: source)
        }
        
        return data
    }

    /// Fetch a string from the provided URL. If `postData` is provided, will use `POST` method instead of `GET`.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *) // for concurrency
    public static func fetchURL(urlString: String, postData: PostData? = nil, encoding: String.Encoding = .utf8, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) async throws -> String {
        try await fetchURL(
            urlString: urlString,
            postData: postData,
            encoding: encoding,
            source: SourceContext(file: file, function: function, line: line, column: column)
        )
    }

    /// Source-forwarding form for APIs that have already captured their caller's location.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *) // for concurrency
    public static func fetchURL(urlString: String, postData: PostData? = nil, encoding: String.Encoding = .utf8, source: SourceContext) async throws -> String {
        let data = try await fetchURLData(urlString: urlString, postData: postData, source: source)

        // convert result data to string
        guard let responseString = String(data: data, encoding: encoding) else {
#if compiler(>=5.9)
            throw NetworkError.dataError(data).debug(level: .ERROR, source: source)
#else
            throw CustomError("Data error: \(data)", level: .ERROR, file: source.file, function: source.function, line: source.line, column: source.column)
#endif
        }
        //debug("Response String:\n\(responseString)", level: .SILENT) // this could be way too chatty if happens all the time.  Just debug at the calling site if needed.
        return responseString
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *) // for concurrency
public func fetchURLData(urlString: String, postData: PostData? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) async throws -> Data {
    try await Compatibility.fetchURLData(
        urlString: urlString,
        postData: postData,
        source: SourceContext(file: file, function: function, line: line, column: column)
    )
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *) // for concurrency
public func fetchURL(urlString: String, postData: PostData? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) async throws -> String {
    try await Compatibility.fetchURL(
        urlString: urlString,
        postData: postData,
        source: SourceContext(file: file, function: function, line: line, column: column)
    )
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension URL {
    /// download data asynchronously and return the data or nil if there is a failure
    func download() async throws -> Data {
        let useNativeDownload: Bool
        if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            useNativeDownload = true
        } else {
            useNativeDownload = false
        }
        return try await download(using: .shared, useNativeDownload: useNativeDownload)
    }

    /// Performs a download with an injectable session and API choice for deterministic compatibility tests.
    internal func download(using session: URLSession, useNativeDownload: Bool) async throws -> Data {
        do {
            if useNativeDownload,
               #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
                let (fileURL, response) = try await session.download(from: self)
                debug("URL Download response: \(response)", level: .DEBUG)
                
                // load data from local file URL
                let data = try Data(contentsOf: fileURL)
                return data
            } else {
                // Fallback on earlier versions
                let request = URLRequest(url: self)
                let (data, _) = try await request.legacyData(for: session)
                return data
            }
        } catch let error as URLError {
#if canImport(Darwin)
            guard error.code == .appTransportSecurityRequiresSecureConnection else {
                throw error
            }
            // Apple platforms can retry an App Transport Security rejection with the secured URL.
            return try await self.secured.download()
#else
            // Non-Apple Foundation implementations do not define the App Transport Security error code.
            throw error
#endif
        }
    }
}

#if canImport(SwiftUI)
import SwiftUI
@available(iOS 13, macOS 11, tvOS 13, watchOS 6, *)
#Preview {
    TestsListView(tests: PostData.tests)
}
#endif
#endif
#endif
