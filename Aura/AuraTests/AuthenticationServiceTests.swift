import Foundation
import XCTest
@testable import Aura

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

final class AuthenticationServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(StubURLProtocol.self)
        setenv("AURA_BASE_URL", "https://example.com", 1)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(StubURLProtocol.self)
        StubURLProtocol.reset()
        super.tearDown()
    }

//    func testAuthenticateReturnsToken() async throws {
//        StubURLProtocol.requestHandler = { request in
//            XCTAssertEqual(request.httpMethod, "POST")
//            XCTAssertEqual(request.url?.path, "/auth")
//            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
//
//            guard let body = request.httpBody else {
//                throw NSError(domain: "StubURLProtocol", code: -1, userInfo: [NSLocalizedDescriptionKey: "No body"])
//            }
//            let decoded = try JSONDecoder().decode(AuthRequest.self, from: body)
//            XCTAssertEqual(decoded.username, "user1")
//            XCTAssertEqual(decoded.password, "pass1")
//
//            let url = URL(string: "https://example.com/auth")!
//            let response = makeResponse(url: url, status: 200)
//            let data = "{\"token\":\"abc123\"}".data(using: .utf8)!
//            return (response, data)
//        }
//
//        let service = AuthenticationService()
//        let token = try await service.authenticate(username: "user1", password: "pass1")
//        XCTAssertEqual(token, "abc123")
//    }

    func testAuthenticateThrowsSpecificErrorOn400() async {
        StubURLProtocol.requestHandler = { _ in
            let url = URL(string: "https://example.com/auth")!
            let response = makeResponse(url: url, status: 400)
            let data = Data("Bad credentials".utf8)
            return (response, data)
        }

        let service = AuthenticationService()
        do {
            _ = try await service.authenticate(username: "user", password: "pass")
            XCTFail("Expected error not thrown")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "AuthenticationService")
            XCTAssertEqual(nsError.code, 400)
        }
    }

    func testAuthenticatePropagatesServerMessage() async {
        StubURLProtocol.requestHandler = { _ in
            let url = URL(string: "https://example.com/auth")!
            let response = makeResponse(url: url, status: 500)
            let data = Data("Internal Server Error".utf8)
            return (response, data)
        }

        let service = AuthenticationService()
        do {
            _ = try await service.authenticate(username: "user", password: "pass")
            XCTFail("Expected error not thrown")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "AuthenticationService")
            XCTAssertEqual(nsError.code, 500)
            XCTAssertEqual(nsError.localizedDescription, "Internal Server Error")
        }
    }

    func testAuthenticateFailsOnInvalidJSON() async {
        StubURLProtocol.requestHandler = { _ in
            let url = URL(string: "https://example.com/auth")!
            let response = makeResponse(url: url, status: 200)
            let data = "{\"tokn\":\"missing\"}".data(using: .utf8)!
            return (response, data)
        }

        let service = AuthenticationService()
        do {
            _ = try await service.authenticate(username: "user", password: "pass")
            XCTFail("Expected decoding error not thrown")
        } catch {
            if error is DecodingError {
                // expected
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}

