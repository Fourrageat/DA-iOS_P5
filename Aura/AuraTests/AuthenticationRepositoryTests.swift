//
//  AccountDetailRepositoryTests.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 28/11/2025.
//

import XCTest
@testable import Aura

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

    func testAuthenticateReturnsToken() async throws {
        StubURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/auth")

            let url = URL(string: "https://example.com/auth")!
            let response = StubURLProtocol.makeResponse(url: url, status: 200)
            let data = "{\"token\":\"abc123\"}".data(using: .utf8)!
            return (response, data)
        }

        let service = AuthenticationRepository()
        let token = try await service.authenticate(username: "user1", password: "pass1")
        XCTAssertEqual(token, "abc123")
    }

    func testAuthenticateThrowsSpecificErrorOn400() async {
        StubURLProtocol.requestHandler = { _ in
            let url = URL(string: "https://example.com/auth")!
            let response = StubURLProtocol.makeResponse(url: url, status: 400)
            let data = Data("{\"error\":\"Bad Request\"}".utf8)
            return (response, data)
        }

        let service = AuthenticationRepository()
        do {
            _ = try await service.authenticate(username: "user", password: "pass")
            XCTFail("Expected 400 specific error not thrown")
        } catch {
            // Prefer matching a domain-specific error if available
            if let repoError = error as? AuthenticateRepositoryError {
                switch repoError {
                case .badStatus:
                    break
                default:
                    XCTFail("Unexpected repo error: \(repoError)")
                }
            } else {
                // Fallback: validate status code surfaced via NSError
                let nsError = error as NSError
                XCTAssertEqual(nsError.code, 400)
            }
        }
    }

    func testAuthenticatePropagatesServerMessage() async {
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
            if let repoError = error as? AuthenticateRepositoryError {
                switch repoError {
                case .badStatus:
                    break
                default:
                    XCTFail("Unexpected repo error: \(repoError)")
                }
            } else {
                // Fallback: validate status code surfaced via NSError
                let nsError = error as NSError
                XCTAssertEqual(nsError.code, 400)
            }
        }
    }

    func testAuthenticateFailsOnInvalidJSON() async {
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

