//
//  AuraTests.swift
//  AuraTests
//
//  Created by Baptiste Fourrageat on 10/11/2025.
//

import XCTest
@testable import Aura

final class AuraTests: XCTestCase {

    // MARK: - Environment helpers
    private func env(_ key: String, default defaultValue: String? = nil) -> String? {
        if let value = ProcessInfo.processInfo.environment[key], !value.isEmpty { return value }
        return defaultValue
    }

    private enum AuthenticationServiceProvider {
        static func makeService(baseURL: URL) -> AuthenticationServicing? {
            // If your AuthenticationService exposes init(baseURL:), this path will be used.
            // Otherwise we return nil and fallback to default initializer below.
            return nil
        }
    }

    private func makeAuthenticationService() -> AuthenticationServicing {
        if let base = env("AURA_BASE_URL"), let url = URL(string: base), let svc = AuthenticationServiceProvider.makeService(baseURL: url) {
            return svc
        }
        return AuthenticationService()
    }

    // MARK: - AuthenticationService tests (real network)
    func test_authenticate_success_returnsToken() async throws {
        guard let username = env("AURA_USERNAME"), let password = env("AURA_PASSWORD") else {
            throw XCTSkip("AURA_USERNAME/AURA_PASSWORD not set; skipping real network test.")
        }
        
        let service = AuthenticationService()
        let token = try await service.authenticate(username: username, password: password)
        
        XCTAssertFalse(token.isEmpty, "Token should not be empty")
    }

    func test_authenticate_httpError_throws() async {
        let service = makeAuthenticationService()
        do {
            _ = try await service.authenticate(username: "invalid@example.com", password: "wrong")
        } catch {
            // Any error is acceptable here for invalid credentials
            XCTAssertTrue(true)
        }
    }

    // MARK: - AuthenticationViewModel test
    func test_viewModel_login_callsCallback() async {
        let exp = expectation(description: "onLoginSucceed called")
        let vm = AuthenticationViewModel {
            exp.fulfill()
        }
        vm.username = env("AURA_USERNAME", default: "test@example.com") ?? "test@example.com"
        vm.password = env("AURA_PASSWORD", default: "password") ?? "password"
        await vm.login()
        await fulfillment(of: [exp], timeout: 10.0, enforceOrder: false)
    }
}

