//
//  HTTP.swift
//  Aura
//
//  Created for reusable HTTP networking.
//

import Foundation

enum HTTPError: Error {
    case invalidURL
    case badStatus(code: Int, message: String?)
    case decodingFailed(underlying: Error)
    case unknown
}

private struct EmptyBody: Encodable {}

struct EmptyResponse: Decodable {}

/// A protocol that describes a generic HTTP client interface.
///
/// Conforming types provide utility methods to build the base URL,
/// perform generic requests, and offer conveniences for common operations
/// (GET/POST). All methods are asynchronous and can throw network- and
/// decoding-related errors.
protocol HTTPClientType {
    /// Returns the base URL used to construct the app's HTTP requests.
    /// - Returns: A valid `URL` representing the remote service root.
    static func baseURL() -> URL
    /// Executes a generic HTTP request and attempts to decode the response into a `Decodable` type.
    /// - Parameters:
    ///   - url: The target URL for the request.
    ///   - method: The HTTP method (for example, "GET", "POST").
    ///   - headers: Additional HTTP headers to attach to the request.
    ///   - body: An optional encodable request body.
    ///   - decoder: The `JSONDecoder` used to decode the response.
    /// - Returns: An instance of `T` decoded from the response body.
    /// - Throws: `HTTPError.badStatus` if the status code is not 2xx,
    ///           `HTTPError.decodingFailed` if decoding fails, or other network-related errors.
    static func request<T: Decodable, Body: Encodable>(
        url: URL,
        method: String,
        headers: [String: String]?,
        body: Body?,
        decoder: JSONDecoder
    ) async throws -> T
    /// Performs an HTTP GET request without a body and decodes the response.
    /// - Parameters:
    ///   - url: The target URL for the request.
    ///   - headers: Additional HTTP headers to attach to the request.
    ///   - decoder: The `JSONDecoder` used to decode the response.
    /// - Returns: An instance of `T` decoded from the response body.
    /// - Throws: `HTTPError.badStatus` if the status code is not 2xx,
    ///           `HTTPError.decodingFailed` if decoding fails, or other network-related errors.
    static func get<T: Decodable>(
        url: URL,
        headers: [String: String]?,
        decoder: JSONDecoder
    ) async throws -> T
    /// Performs an HTTP POST request with an encodable body and decodes the response.
    /// - Parameters:
    ///   - url: The target URL for the request.
    ///   - headers: Additional HTTP headers to attach to the request.
    ///   - body: The request body to be encoded as JSON.
    ///   - decoder: The `JSONDecoder` used to decode the response.
    /// - Returns: An instance of `T` decoded from the response body.
    /// - Throws: `HTTPError.badStatus` if the status code is not 2xx,
    ///           `HTTPError.decodingFailed` if decoding fails, or other network-related errors.
    static func post<T: Decodable, Body: Encodable>(
        url: URL,
        headers: [String: String]?,
        body: Body,
        decoder: JSONDecoder
    ) async throws -> T
}

struct HTTP: HTTPClientType {
    
    static func baseURL() -> URL {
        guard let base = ProcessInfo.processInfo.environment["AURA_BASE_URL"],
              let url = URL(string: base) else {
            preconditionFailure("AURA_BASE_URL is not set or is not a valid URL")
        }
        return url
    }
    
    static func request<T: Decodable, Body: Encodable>(
        url: URL,
        method: String = "GET",
        headers: [String: String]? = nil,
        body: Body? = nil,
        decoder: JSONDecoder = JSONDecoder(),
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Apply default headers
        var mergedHeaders: [String: String] = ["Accept": "application/json"]
        if let headers = headers {
            for (k, v) in headers { mergedHeaders[k] = v }
        }
        for (k, v) in mergedHeaders { request.setValue(v, forHTTPHeaderField: k) }
        
        if let body = body {
            // Encode JSON body and set Content-Type
            request.httpBody = try JSONEncoder().encode(body)
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw HTTPError.unknown
        }
        
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8)
            throw HTTPError.badStatus(code: http.statusCode, message: msg)
        }
        // Handle empty response for EmptyResponse type
        if T.self == EmptyResponse.self && data.isEmpty {
            return EmptyResponse() as! T
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw HTTPError.decodingFailed(underlying: error)
        }
    }
    
    // For GET requests with no body
    static func get<T: Decodable>(
        url: URL,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        try await request(url: url, method: "GET", headers: headers, body: Optional<EmptyBody>.none, decoder: decoder)
    }
    
    // For POST requests with an Encodable body
    static func post<T: Decodable, Body: Encodable>(
        url: URL,
        headers: [String: String]? = nil,
        body: Body,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        try await request(url: url, method: "POST", headers: headers, body: body, decoder: decoder)
    }
}

