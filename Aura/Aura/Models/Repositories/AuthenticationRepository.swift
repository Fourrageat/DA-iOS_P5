//
//  Authentication Model
//  Aura
//
//  Created by Baptiste Fourrageat on 10/11/2025.
//

import Foundation

// MARK: - DTOs

/// Data model sent to the server to authenticate.
struct AuthRequest: Codable {
    /// Username (or login identifier).
    let username: String
    /// Plain-text password (sent over HTTPS).
    let password: String
}

/// Data model received from the server after a successful authentication.
struct AuthResponse: Codable {
    /// Access token (typically a JWT) to use for authenticated requests.
    let token: String
}

/// Possible errors when fetching account details.
enum AuthenticateRepositoryError: Error {
    /// The constructed URL is invalid.
    case invalidURL
    /// The server responded with an invalid HTTP status code.
    case badStatus(code: Int)
    /// JSON decoding failed.
    case decodingFailed(underlying: Error)
}

// MARK: - Authentication Service

/// Contract for the authentication repository.
protocol AuthenticationRepositoryType {
    /// Attempts to authenticate a user and returns an access token on success.
    /// - Parameters:
    ///   - username: The user's identifier.
    ///   - password: The user's password.
    /// - Returns: The access token (e.g., a JWT) to use for protected requests.
    /// - Throws: A network or decoding error if authentication fails.
    ///
    /// - Important: This method does not perform input validation. Ensure `recipient` and `amount` are validated by the caller.
    func authenticate(username: String, password: String) async throws -> String
}

struct AuthenticationRepository: AuthenticationRepositoryType {
    
    private let baseURL: URL = HTTP.baseURL()

    func authenticate(username: String, password: String) async throws -> String {
        let url = baseURL.appendingPathComponent("/auth")

        do {
            let response: AuthResponse = try await HTTP.post(
                url: url,
                headers: nil,
                body: AuthRequest(username: username, password: password)
            )
            return response.token
        } catch let httpError as HTTPError {
            switch httpError {
            case .badStatus(let code, _):
                throw AuthenticateRepositoryError.badStatus(code: code)
            case .decodingFailed(let underlying):
                throw AuthenticateRepositoryError.decodingFailed(underlying: underlying)
            case .invalidURL:
                throw AuthenticateRepositoryError.invalidURL
            default:
                throw httpError
            }
        }
    }
}

