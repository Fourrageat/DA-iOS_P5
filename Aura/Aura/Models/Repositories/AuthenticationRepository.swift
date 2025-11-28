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
    
    private let baseURL: URL = HTTP.baseURL()

    func authenticate(username: String, password: String) async throws -> String {
        let url = baseURL.appendingPathComponent("/auth")
        do {
            let response: AuthResponse = try await HTTP.request(
                url: url,
                method: "POST",
                headers: nil,
                body: AuthRequest(username: username, password: password)
            )
            return response.token
        } catch let httpError as HTTPError {
            switch httpError {
            case .badStatus(let code, let msg):
                throw NSError(domain: "AuthenticationService", code: code, userInfo: [NSLocalizedDescriptionKey: msg ?? "Unknown error"])
            case .decodingFailed(let underlying):
                throw underlying
            default:
                throw httpError
            }
        }
    }
}
