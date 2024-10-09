//
//  File.swift
//  
//
//  Created by Ben Ku on 7/6/24.
//

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
    case dataError(_ data: Data)
    
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
        case .dataError(let data):
            return "Unable to parse string out of data: \(String(describing: data))"
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

#if canImport(Combine)// || canImport(FoundationNetworking) // for Linux support of URLRequest - apparently still doesn't work even if we were to include that, so gate this to not be available on linux :(
//#if canImport(FoundationNetowrking)
//import FoundationNetworking
//#endif

@available(iOS 13, tvOS 13, watchOS 6, *)
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
        let results = try await fetchURL(urlString: "https://www.GwinnettCounty.com")
        debug("RESULTS: \(results)", level: .DEBUG)
        try expect(results.contains("Gwinnett"), results)
    }
    @MainActor
    internal static let testFetchGETCheck: TestClosure = {
        let query = TEST_DATA.queryString ?? "ERROR"
        let results = try await fetchURL(urlString: "https://plickle.com/pd.php?\(query)")
        debug("RESULTS: \(results)", level: .DEBUG)
        try expect(results.contains("[name] => Jack & \"Jill\""), results)
    }
    @MainActor
    internal static let testFetchPOSTCheck: TestClosure = {
        let results = try await fetchURL(urlString: "https://plickle.com/pd.php", postData:TEST_DATA)
        debug("RESULTS: \(results)", level: .DEBUG)
        try expect(results.contains("'name' => 'Jack & \\\"Jill\\\"',"), results)
    }
    @MainActor
    static let tests = [
        Test("POST data query encoding", testPostDataQueryEncoding),
        Test("fetchURL Gwinnett check", testFetchGwinnettCheck),
        Test("fetchURL GET check", testFetchGETCheck),
        Test("fetchURL POST check", testFetchPOSTCheck),
    ]
}

@available(iOS 13, tvOS 13, watchOS 6, *)
extension URLRequest {
    func legacyData(for session: URLSession) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            guard let url = self.url else {
                return continuation.resume(throwing: URLError(.badURL))
            }
            let task = session.dataTask(with: url) { data, response, error in
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
    /// Fetch data from URL including optional postData.  Will report included file information and automatically debug output to the logs.
    @available(iOS 13, tvOS 13, watchOS 6, *) // for concurrency
    public static func fetchURLData(urlString: String, postData: PostData? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) async throws -> Data {
        debug("Fetching URL [\(urlString)]...", level: .NOTICE, file: file, function: function, line: line, column: column)
        // create the url with URL
        guard let url = URL(string: urlString) else {
            throw NetworkError.urlParsing(urlString: urlString).debug(level: .ERROR, file: file, function: function, line: line, column: column)
        }
        
        // now create the URLRequest object using the url object
        var request = URLRequest(url: url)
        
        // encode the postData if provided, otherwise set the method to GET.
        if let parameters = postData {
            request.httpMethod = "POST" //set http method as POST
            
            // declare the parameter as a dictionary that contains string as key and value combination. considering inputs are valid
            
            //let parameters: [String: Any] = ["id": 13, "name": "jack"]
            guard let data = postData?.queryEncoded else {
                throw NetworkError.postDataEncoding(parameters).debug(level: .ERROR, file: file, function: function, line: line, column: column)
            }
            request.httpBody = data
        } else {
            request.httpMethod = "GET" //set http method as GET
        }
        //debug("FETCHING: \(request)", level: .DEBUG, file: file, function: function, line: line, column: column)
        
        var data: Data
        var response: URLResponse
        // create dataTask using the session object to send data to the server
        do {
            if #available(iOS 15, watchOS 8, tvOS 15, *) {
                (data, response) = try await URLSession.shared.data(for: request)
            } else {
                // Fallback on earlier versions
                (data, response) = try await request.legacyData(for: URLSession.shared)
            }
        } catch {
            if let error = error as? URLError, error.code.rawValue == -1003 {
                throw NetworkError.missingEntitlement.debug(level: .ERROR, file: file, function: function, line: line, column: column)
            } else {
                throw error.debug(level: .ERROR, file: file, function: function, line: line, column: column)
            }
        }

        //debug("DEBUG RESPONSE DATA: \(data)")
        // Check response status code exists (should nearly always pass)
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            debug("No status code in HTTP response.  Possibly offline?: \(String(describing: response))", level: .ERROR)
            throw NetworkError.invalidResponse().debug(level: .ERROR, file: file, function: function, line: line, column: column)
        }

        // check status code (should always be 200)
        guard statusCode == 200 else {
            throw NetworkError.invalidResponse(code: statusCode).debug(level: .ERROR, file: file, function: function, line: line, column: column)
        }
        
        return data
    }
    /// Fetch a string from the provided URL.  If `postData` is provided, will use `POST` method instead of `GET`.
    public static func fetchURL(urlString: String, postData: PostData? = nil, encoding: String.Encoding = .utf8, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) async throws -> String {
        let data = try await fetchURLData(urlString: urlString, postData: postData, file: file, function: function, line: line, column: column)

        // convert result data to string
        guard let responseString = String(data: data, encoding: encoding) else {
            throw NetworkError.dataError(data).debug(level: .ERROR, file: file, function: function, line: line, column: column)
        }
        //debug("Response String:\n\(responseString)", level: .SILENT) // this could be way too chatty if happens all the time.  Just debug at the calling site if needed.
        return responseString
    }
}
@available(iOS 13, tvOS 13, watchOS 6, *) // for concurrency
public func fetchURLData(urlString: String, postData: PostData? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) async throws -> Data {
    try await Compatibility.fetchURLData(urlString: urlString, postData: postData, file: file, function: function, line: line, column: column)
}
@available(iOS 13, tvOS 13, watchOS 6, *) // for concurrency
public func fetchURL(urlString: String, postData: PostData? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) async throws -> String {
    try await Compatibility.fetchURL(urlString: urlString, postData: postData, file: file, function: function, line: line, column: column)
}

@available(iOS 15, tvOS 13, watchOS 6, *)
public extension URL {
    /// download data asynchronously and return the data or nil if there is a failure
    func download() async throws -> Data {
        do {
            if #available(macOS 12, tvOS 15, watchOS 8, *) {
                let (fileURL, response) = try await URLSession.shared.download(from: self)
                debug("URL Download response: \(response)", level: .DEBUG)
                
                // load data from local file URL
                let data = try Data(contentsOf: fileURL)
                return data
            } else {
                // Fallback on earlier versions
                let request = URLRequest(url: self)
                let (data, _) = try await request.legacyData(for: URLSession.shared)
                return data
            }
        } catch URLError.appTransportSecurityRequiresSecureConnection {
            // replace http with https
            return try await self.secured.download()
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
