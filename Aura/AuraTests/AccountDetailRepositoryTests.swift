//
//  AccountDetailRepositoryTests.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 28/11/2025.
//

import XCTest
@testable import Aura

final class AccountDetailRepositoryTests: XCTestCase {
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
    
    func testGetAccountSuccess() async throws {
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

        let repo = AccountDetailRepository()
        let details = try await repo.getAccount(token: "tkn-123")
        XCTAssertEqual(details.currentBalance, 1234.56, accuracy: 0.0001)
        XCTAssertEqual(details.transactions.count, 2)
        XCTAssertEqual(details.transactions[0].value, -20.5)
        XCTAssertEqual(details.transactions[0].label, "Coffee")
        XCTAssertEqual(details.transactions[1].value, 200.0)
        XCTAssertEqual(details.transactions[1].label, "Salary")
    }

    func testGetAccountMapsBadStatusToServiceError() async {
        StubURLProtocol.requestHandler = { _ in
            let url = URL(string: "https://example.com/account")!
            let response = StubURLProtocol.makeResponse(url: url, status: 403)
            let data = Data("Forbidden".utf8)
            return (response, data)
        }

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

    func testGetAccountDecodingFailureIsMapped() async {
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

    func testBaseURLIsReadFromEnv() async throws {
        // Ensure the URL is constructed from AURA_BASE_URL by observing the requested URL
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

