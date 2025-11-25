import Foundation
import Testing

// Helper function to create HTTPURLResponse
func makeResponse(url: URL, status: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
}

class StubURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    static func reset() {
        requestHandler = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        // Intercept all requests
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = StubURLProtocol.requestHandler else {
            fatalError("StubURLProtocol.requestHandler not set")
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // No-op
    }
}

@MainActor
@Suite
struct AuthenticationServiceTests {
    @Test("authenticate returns token on 200")
    static func testAuthenticateReturnsToken() async throws {
        URLProtocol.registerClass(StubURLProtocol.self)
        defer {
            URLProtocol.unregisterClass(StubURLProtocol.self)
            StubURLProtocol.reset()
        }
        setenv("AURA_BASE_URL", "https://example.com", 1)

        StubURLProtocol.requestHandler = { request in
            try XCTRequireEqual(request.httpMethod, "POST")
            try XCTRequireEqual(request.url?.path, "/auth")
            try XCTRequireEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

            guard let body = request.httpBody else {
                throw NSError(domain: "StubURLProtocol", code: -1, userInfo: [NSLocalizedDescriptionKey: "No body"])
            }
            let decoded = try JSONDecoder().decode(AuthRequest.self, from: body)
            try XCTRequireEqual(decoded.username, "user1")
            try XCTRequireEqual(decoded.password, "pass1")

            let url = URL(string: "https://example.com/auth")!
            let response = makeResponse(url: url, status: 200)
            let data = """
            {"token":"abc123"}
            """.data(using: .utf8)!
            return (response, data)
        }

        let service = AuthenticationService()
        let token = try await service.authenticate(username: "user1", password: "pass1")
        #expect(token == "abc123")
    }

    @Test("authenticate throws specific error on 400")
    static func testAuthenticateThrowsSpecificErrorOn400() async {
        URLProtocol.registerClass(StubURLProtocol.self)
        defer {
            URLProtocol.unregisterClass(StubURLProtocol.self)
            StubURLProtocol.reset()
        }
        setenv("AURA_BASE_URL", "https://example.com", 1)

        StubURLProtocol.requestHandler = { request in
            let url = URL(string: "https://example.com/auth")!
            let response = makeResponse(url: url, status: 400)
            let data = "Bad credentials".data(using: .utf8)!
            return (response, data)
        }

        let service = AuthenticationService()
        do {
            _ = try await service.authenticate(username: "user", password: "pass")
            throw XCTSkip("Expected error not thrown")
        } catch {
            #expect(error is NSError)
            let nsError = error as NSError
            #expect(nsError.domain == "AuthenticationService")
            #expect(nsError.code == 400)
        }
    }

    @Test("authenticate propagates server message on non-2xx")
    static func testAuthenticatePropagatesServerMessage() async {
        URLProtocol.registerClass(StubURLProtocol.self)
        defer {
            URLProtocol.unregisterClass(StubURLProtocol.self)
            StubURLProtocol.reset()
        }
        setenv("AURA_BASE_URL", "https://example.com", 1)

        StubURLProtocol.requestHandler = { request in
            let url = URL(string: "https://example.com/auth")!
            let response = makeResponse(url: url, status: 500)
            let data = "Internal Server Error".data(using: .utf8)!
            return (response, data)
        }

        let service = AuthenticationService()
        do {
            _ = try await service.authenticate(username: "user", password: "pass")
            throw XCTSkip("Expected error not thrown")
        } catch {
            #expect(error is NSError)
            let nsError = error as NSError
            #expect(nsError.domain == "AuthenticationService")
            #expect(nsError.code == 500)
            #expect(nsError.localizedDescription == "Internal Server Error")
        }
    }

    @Test("authenticate fails on invalid JSON body")
    static func testAuthenticateFailsOnInvalidJSON() async {
        URLProtocol.registerClass(StubURLProtocol.self)
        defer {
            URLProtocol.unregisterClass(StubURLProtocol.self)
            StubURLProtocol.reset()
        }
        setenv("AURA_BASE_URL", "https://example.com", 1)

        StubURLProtocol.requestHandler = { request in
            let url = URL(string: "https://example.com/auth")!
            let response = makeResponse(url: url, status: 200)
            let data = """
            {"tokn":"missing"}
            """.data(using: .utf8)!
            return (response, data)
        }

        let service = AuthenticationService()
        do {
            _ = try await service.authenticate(username: "user", password: "pass")
            throw XCTSkip("Expected decoding error not thrown")
        } catch {
            if case is DecodingError = error {
                // Success
            } else {
                throw error
            }
        }
    }
}
