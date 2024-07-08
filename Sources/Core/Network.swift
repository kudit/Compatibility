//
//  File.swift
//  
//
//  Created by Ben Ku on 7/6/24.
//

import Foundation

public typealias PostData = [String: Sendable]
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
        try expect(results.contains("Gwinnett"), results)
    }
    @MainActor
    internal static let testFetchGETCheck: TestClosure = {
        let query = TEST_DATA.queryString ?? "ERROR"
        let results = try await fetchURL(urlString: "https://plickle.com/pd.php?\(query)")
        try expect(results.contains("[name] => Jack & \"Jill\""), results)
    }
    @MainActor
    internal static let testFetchPOSTCheck: TestClosure = {
        let results = try await fetchURL(urlString: "https://plickle.com/pd.php", postData:TEST_DATA)
        try expect(results.contains("'name' => 'Jack & \\\"Jill\\\"',"), results)
    }
    @MainActor
    static let networkTests = [
        Test("POST data query encoding", testPostDataQueryEncoding),
        Test("fetchURL Gwinnett check", testFetchGwinnettCheck),
        Test("fetchURL GET check", testFetchGETCheck),
        Test("fetchURL POST check", testFetchPOSTCheck),
    ]
}

public enum NetworkError: Error, CustomStringConvertible, Sendable {
    // Throw when unable to parse a URL
    case urlParsing(urlString: String)
    
    case postDataEncoding(_ data: PostData)
    
    // Invalid HTTP response (with response code)
    case invalidResponse(code: Int? = nil)
    
    case nilResponse
    
    public var description: String {
        switch self {
        case .urlParsing(let urlString):
            return "URL could not be created from \(urlString)"
        case .postDataEncoding(let data):
            return "Post Data could not be encoded from \(data)"
        case .invalidResponse(let code):
            return "Invalid Response (\(code != nil ? "\(code!)" : "No code")) received from the server"
        case .nilResponse:
            return "nil Data received from the server"
        }
    }
}

extension URLSession {
    func legacyData(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            guard let url = request.url else {
                return continuation.resume(throwing: URLError(.badURL))
            }
            let task = self.dataTask(with: url) { data, response, error in
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

/// Fetch data from URL including optional postData.  Will report included file information and automatically debug output to the logs.
func fetchURL(urlString: String, postData: PostData? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) async throws -> String {
    debug("Fetching URL [\(urlString)]...", level: .NOTICE, file: file, function: function, line: line, column: column)
    // create the url with URL
    guard let url = URL(string: urlString) else {
        throw NetworkError.urlParsing(urlString: urlString)
    }
    
    // now create the URLRequest object using the url object
    var request = URLRequest(url: url)
    if let parameters = postData {
        request.httpMethod = "POST" //set http method as POST
        
        // declare the parameter as a dictionary that contains string as key and value combination. considering inputs are valid
        
        //let parameters: [String: Any] = ["id": 13, "name": "jack"]
        guard let data = postData?.queryEncoded else {
            throw NetworkError.postDataEncoding(parameters)
        }
        request.httpBody = data
    } else {
        request.httpMethod = "GET" //set http method as GET
    }
    debug("FETCHING: \(request)", level: .DEBUG, file: file, function: function, line: line, column: column)
    
    var data: Data
    // create dataTask using the session object to send data to the server
    if #available(iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
        (data, _) = try await URLSession.shared.data(for: request)
    } else {
        // Fallback on earlier versions
        (data, _) = try await URLSession.shared.legacyData(for: request)
    }
    
    //debug("DEBUG RESPONSE DATA: \(data)")
    
    if let responseString = String(data: data, encoding: .utf8) {
        //debug("DEBUG RESPONSE STRING: \(responseString)")
        return responseString
    } else {
        throw NetworkError.invalidResponse()
    }
}

#if canImport(SwiftUI)
import SwiftUI
#Preview {
    TestsListView(tests: PostData.networkTests)
}
#endif
