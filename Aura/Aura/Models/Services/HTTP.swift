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

struct HTTP {
    
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
        if let headers = headers {
            for (k, v) in headers { request.setValue(v, forHTTPHeaderField: k) }
        }
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
}
