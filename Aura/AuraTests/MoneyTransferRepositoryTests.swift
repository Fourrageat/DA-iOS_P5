//
//  AccountDetailRepositoryTests.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 28/11/2025.
//

import XCTest
@testable import Aura

/// Tests for `MoneyTransferRepository` covering success, HTTP error handling, and decoding failures.
/// Uses `StubURLProtocol` to intercept requests and return controlled responses.
final class MoneyTransferRepositoryTests: XCTestCase {
    // Register the stub protocol and set a deterministic base URL for tests
    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(StubURLProtocol.self)
        setenv("AURA_BASE_URL", "https://example.com", 1)
    }

    // Unregister the stub protocol and reset shared state
    override func tearDown() {
        URLProtocol.unregisterClass(StubURLProtocol.self)
        StubURLProtocol.reset()
        super.tearDown()
    }
    
    /// Verifies that a successful POST returns 200 and the repository completes without throwing.
    func testPostMoneySuccess() async {
        // Stub a 200 OK for the transfer endpoint and verify request shape
        var handlerCalled = false
        StubURLProtocol.requestHandler = { request in
            handlerCalled = true
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/account/transfer")
            XCTAssertEqual(request.value(forHTTPHeaderField: "token"), "tkn-123")

            let url = URL(string: "https://example.com/account/transfer")!
            let response = StubURLProtocol.makeResponse(url: url, status: 200)
            return (response, Data())
        }
        
        // Execute the transfer via the repository
        let repository = MoneyTransferRepository()

        do {
            try await repository.transfer(
                recipient: "toto",
                amount: 100.95,
                token: "tkn-123"
            )
            
        } catch {
            XCTFail("Expected transfer to succeed, but threw: \(error)")
        }
        
        XCTAssertTrue(handlerCalled, "Request handler should have been called")
    }
    
    /// Verifies that a 400 response results in an error being thrown by the repository.
    func testPostMoneyFailure() async {
        // Stub a 400 Bad Request with a JSON error body
        var handlerCalled = false
        StubURLProtocol.requestHandler = { request in
            handlerCalled = true
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/account/transfer")
            XCTAssertEqual(request.value(forHTTPHeaderField: "token"), "tkn-123")

            let url = URL(string: "https://example.com/account/transfer")!
            let response = StubURLProtocol.makeResponse(url: url, status: 400)
            let body = try! JSONSerialization.data(withJSONObject: ["error": "Bad Request"], options: [])
            return (response, body)
        }

        let repository = MoneyTransferRepository()

        // Perform the call and assert it throws
        do {
            try await repository.transfer(
                recipient: "toto",
                amount: 100.95,
                token: "tkn-123"
            )
            XCTFail("Expected transfer to fail, but it succeeded")
        } catch {
            // Expected path: ensure we got some error
            XCTAssertNotNil(error)
        }

        XCTAssertTrue(handlerCalled, "Request handler should have been called")
    }
    
    /// Verifies that an invalid response body surfaces as a decoding error.
    func testPostMoneyDecodingFailed() async {
        // Stub a 200 OK with a non-JSON body to trigger decoding failure
        var handlerCalled = false
        StubURLProtocol.requestHandler = { request in
            handlerCalled = true
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/account/transfer")
            XCTAssertEqual(request.value(forHTTPHeaderField: "token"), "tkn-123")

            let url = URL(string: "https://example.com/account/transfer")!
            let response = StubURLProtocol.makeResponse(url: url, status: 200)
            return (response, Data("not-json".utf8))
        }

        let repository = MoneyTransferRepository()

        do {
            try await repository.transfer(
                recipient: "toto",
                amount: 100.95,
                token: "tkn-123"
            )
            XCTFail("Expected decoding to fail, but it succeeded")
        } catch {
            XCTAssertNotNil(error)
        }

        XCTAssertTrue(handlerCalled, "Request handler should have been called")
    }
}

