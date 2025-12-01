//
//  Stub.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 27/11/2025.
//

import Foundation

/// A URLProtocol subclass used to stub network requests in tests.
/// Intercepts all requests and delegates response generation to a configurable handler.
class StubURLProtocol: URLProtocol {

    // Closure that receives the intercepted request and returns a mocked response and data
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    /// Resets the stub by clearing the request handler.
    static func reset() {
        requestHandler = nil
    }
    
    /// Convenience factory for HTTPURLResponse with a given status code.
    static func makeResponse(url: URL, status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
    }

    override class func canInit(with request: URLRequest) -> Bool {
        // Intercept all requests (opt-in at configuration time)
        true
    }

    // Return the request unchanged; no canonicalization needed for stubbing
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    /// Starts loading by invoking the request handler and sending the mocked response to the client.
    override func startLoading() {
        // Ensure a handler is set; otherwise, fail fast to reveal misconfigured tests
        guard let handler = StubURLProtocol.requestHandler else {
            fatalError("StubURLProtocol.requestHandler not set")
        }
        do {
            // Let the test-provided handler generate the response and payload
            let (response, data) = try handler(request)
            // Forward the mocked response and data to the URL loading system
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    /// Stops loading. No-op for stubs.
    override func stopLoading() {
        // No-op
    }
}

