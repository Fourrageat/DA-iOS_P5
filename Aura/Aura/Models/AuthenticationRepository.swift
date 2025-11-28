//
//  AuthenticationModel.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 10/11/2025.
//

import Foundation

// MARK: - DTOs
struct AuthRequest: Codable {
    let username: String
    let password: String
}

struct AuthResponse: Codable {
    let token: String
}

// MARK: - Service
protocol AuthenticationRepositoryType {
    func authenticate(username: String, password: String) async throws -> String
}

struct AuthenticationRepository: AuthenticationRepositoryType {
    private let baseUrl: URL = {
        guard let base = ProcessInfo.processInfo.environment["AURA_BASE_URL"],
              let url = URL(string: base) else {
            preconditionFailure("AURA_BASE_URL is not set or is not a valid URL")
        }
        return url
    }()

    func authenticate(username: String, password: String) async throws -> String {
        let url = baseUrl.appendingPathComponent("/auth")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = AuthRequest(username: username, password: password)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200..<300).contains(http.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "AuthenticationService",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: serverMessage]
            )
        }

        let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
        let token = decoded.token
        return token
    }
}

