//
//  AccountDetailRepositoryTests.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 28/11/2025.
//

import XCTest
@testable import Aura

/// Tests for `AccountDetailRepository` covering success, HTTP error mapping, decoding failures.
/// Uses `StubURLProtocol` to intercept requests and return controlled responses.
final class AccountDetailRepositoryTests: XCTestCase {
    // Register the stub protocol and set a deterministic base URL for tests
    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(StubURLProtocol.self)
        setenv("AURA_BASE_URL", "https://example.com", 1)
    }

    // Unregister the stub protocol and reset any shared state
    override func tearDown() {
        URLProtocol.unregisterClass(StubURLProtocol.self)
        StubURLProtocol.reset()
        super.tearDown()
    }
    
    /// Verifies that a successful response is decoded into account details and transactions.
    func testGetAccountSuccess() async throws {
        // Stub a 200 OK with a valid JSON payload
        StubURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/account")
            XCTAssertEqual(request.value(forHTTPHeaderField: "token"), "tkn-123")

            let url = URL(string: "https://example.com/account")!
            let response = StubURLProtocol.makeResponse(url: url, status: 200)
            let json = """
            {
              "currentBalance": 1234.56,
              "transactions": [
                {"value": -20.5, "label": "Coffee"},
                {"value": 200.0, "label": "Salary"}
              ]
            }
            """.data(using: .utf8)!
            return (response, json)
        }

        // Execute the request via the repository
        let repo = AccountDetailRepository()
        let details = try await repo.getAccount(token: "tkn-123")
        XCTAssertEqual(details.currentBalance, 1234.56, accuracy: 0.0001)
        XCTAssertEqual(details.transactions.count, 2)
        XCTAssertEqual(details.transactions[0].value, -20.5)
        XCTAssertEqual(details.transactions[0].label, "Coffee")
        XCTAssertEqual(details.transactions[1].value, 200.0)
        XCTAssertEqual(details.transactions[1].label, "Salary")
    }

    /// Verifies that non-2xx responses are mapped to a domain-specific error with the status code.
    func testGetAccountMapsBadStatusToServiceError() async {
        // Stub a 403 Forbidden response
        StubURLProtocol.requestHandler = { _ in
            let url = URL(string: "https://example.com/account")!
            let response = StubURLProtocol.makeResponse(url: url, status: 403)
            let data = Data("Forbidden".utf8)
            return (response, data)
        }

        // Perform the call and assert that an error is thrown
        let repo = AccountDetailRepository()
        do {
            _ = try await repo.getAccount(token: "tkn")
            XCTFail("Expected error not thrown")
        } catch let error as AccountRepositoryError {
            switch error {
            case .badStatus(let code):
                XCTAssertEqual(code, 403)
            default:
                XCTFail("Unexpected AccountServiceError: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    /// Verifies that malformed JSON is surfaced as a decoding error wrapped by the repository.
    func testGetAccountDecodingFailureIsMapped() async {
        // Stub a 200 OK with invalid JSON for the expected schema
        StubURLProtocol.requestHandler = { _ in
            let url = URL(string: "https://example.com/account")!
            let response = StubURLProtocol.makeResponse(url: url, status: 200)
            // Invalid JSON for expected schema (missing required fields / wrong keys)
            let data = Data("{\"balance\": 10}".utf8)
            return (response, data)
        }

        let repo = AccountDetailRepository()
        do {
            _ = try await repo.getAccount(token: "tkn")
            XCTFail("Expected decoding error not thrown")
        } catch let error as AccountRepositoryError {
            switch error {
            case .decodingFailed(let underlying):
                XCTAssertTrue(underlying is DecodingError)
            default:
                XCTFail("Expected decodingFailed, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    /// Verifies that the repository constructs the base URL from the AURA_BASE_URL environment variable.
    func testBaseURLIsReadFromEnv() async throws {
        // Stub a minimal successful response and assert the requested URL matches the env var
        StubURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://example.com/account")
            let url = URL(string: "https://example.com/account")!
            let response = StubURLProtocol.makeResponse(url: url, status: 200)
            let data = Data("{\"currentBalance\":0,\"transactions\":[]}".utf8)
            return (response, data)
        }

        let repo = AccountDetailRepository()
        _ = try await repo.getAccount(token: "any")
    }
}

