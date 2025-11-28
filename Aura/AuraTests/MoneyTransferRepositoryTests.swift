//
//  AccountDetailRepositoryTests.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 28/11/2025.
//

import XCTest
@testable import Aura

final class MoneyTransferRepositoryTests: XCTestCase {
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
    
    func testPostMoneySuccess() async {
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
    
    func testPostMoneyFailure() async {
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
    
    func testPostMoneyDecodingFailed() async {
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
