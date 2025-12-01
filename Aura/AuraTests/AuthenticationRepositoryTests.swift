//
//  AuthenticationRepositoryTests.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 28/11/2025.
//

import XCTest
@testable import Aura

/// Tests for `AuthenticationRepository` covering success, HTTP error handling, and decoding failures.
/// Uses `StubURLProtocol` to intercept network calls and return controlled responses.
final class AuthenticationRepositoryTests: XCTestCase {
    // Register the stub protocol and set a base URL for tests
    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(StubURLProtocol.self)
        setenv("AURA_BASE_URL", "https://example.com", 1)
    }

    // Unregister the stub protocol and reset state
    override func tearDown() {
        URLProtocol.unregisterClass(StubURLProtocol.self)
        StubURLProtocol.reset()
        super.tearDown()
    }

    /// Verifies that a valid response yields the expected token.
    func testAuthenticateReturnsToken() async throws {
        // Stub a 200 OK with a JSON body containing the token
        StubURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/auth")

            let url = URL(string: "https://example.com/auth")!
            let response = StubURLProtocol.makeResponse(url: url, status: 200)
            let data = "{\"token\":\"abc123\"}".data(using: .utf8)!
            return (response, data)
        }

        // Execute the request via the repository
        let service = AuthenticationRepository()
        let token = try await service.authenticate(username: "user1", password: "pass1")
        XCTAssertEqual(token, "abc123")
    }

    /// Verifies that a 400 response yields a domain-specific error when possible, or exposes the status via NSError.
    func testAuthenticateThrowsSpecificErrorOn400() async {
        // Stub a 400 Bad Request response
        StubURLProtocol.requestHandler = { _ in
            let url = URL(string: "https://example.com/auth")!
            let response = StubURLProtocol.makeResponse(url: url, status: 400)
            let data = Data("{\"error\":\"Bad Request\"}".utf8)
            return (response, data)
        }

        // Perform the call and assert that an error is thrown
        let service = AuthenticationRepository()
        do {
            _ = try await service.authenticate(username: "user", password: "pass")
            XCTFail("Expected 400 specific error not thrown")
        } catch {
            // Prefer validating the repository's domain-specific error
            if let repoError = error as? AuthenticateRepositoryError {
                switch repoError {
                case .badStatus:
                    break
                default:
                    XCTFail("Unexpected repo error: \(repoError)")
                }
            } else {
                // Fallback path: validate surfaced status code
                let nsError = error as NSError
                XCTAssertEqual(nsError.code, 400)
            }
        }
    }

    /// Verifies that server-side failures propagate as errors and can carry server messages.
    func testAuthenticatePropagatesServerMessage() async {
        // Stub a 500 Internal Server Error response
        StubURLProtocol.requestHandler = { _ in
            let url = URL(string: "https://example.com/auth")!
            let response = StubURLProtocol.makeResponse(url: url, status: 500)
            let data = Data("Internal Server Error".utf8)
            return (response, data)
        }

        let service = AuthenticationRepository()
        do {
            _ = try await service.authenticate(username: "user", password: "pass")
            XCTFail("Expected error not thrown")
        } catch {
            // Validate domain-specific error when available
            if let repoError = error as? AuthenticateRepositoryError {
                switch repoError {
                case .badStatus:
                    break
                default:
                    XCTFail("Unexpected repo error: \(repoError)")
                }
            } else {
                // Fallback path: validate surfaced status code
                let nsError = error as NSError
                XCTAssertEqual(nsError.code, 400)
            }
        }
    }

    /// Verifies that invalid JSON triggers a decoding error (wrapped or raw).
    func testAuthenticateFailsOnInvalidJSON() async {
        // Stub a 200 OK with an invalid/malformed JSON body
        StubURLProtocol.requestHandler = { _ in
            let url = URL(string: "https://example.com/auth")!
            let response = StubURLProtocol.makeResponse(url: url, status: 200)
            let data = "{\"tokn\":\"missing\"}".data(using: .utf8)!
            return (response, data)
        }

        let service = AuthenticationRepository()
        do {
            _ = try await service.authenticate(username: "user", password: "pass")
            XCTFail("Expected decoding error not thrown")
        } catch {
            // Validate wrapped decoding error and optionally inspect underlying DecodingError
            if let repoError = error as? AuthenticateRepositoryError {
                switch repoError {
                case .decodingFailed(let underlying):
                    // Optionally assert the underlying decoding error shape
                    if case DecodingError.keyNotFound(let key, _) = underlying {
                        XCTAssertEqual(key.stringValue, "token")
                    }
                    // expected
                default:
                    XCTFail("Unexpected repo error: \(repoError)")
                }
            } else if error is DecodingError {
                // If the repository ever stops wrapping, still accept raw decoding errors
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}

