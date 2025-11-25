//
//  AccountDetailsService.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 25/11/2025.
//

import Foundation

// MARK: - Data Models

/// Represents a banking transaction.
public struct Transaction: Codable {
    /// Monetary amount of the transaction.
    public let value: Decimal
    /// Transaction label/description.
    public let label: String
}

/// API response containing account details.
public struct AccountDetailsResponse: Codable {
    /// Current account balance.
    public let currentBalance: Decimal
    /// List of recent transactions.
    public let transactions: [Transaction]
}

// MARK: - Service-specific Errors

/// Possible errors when fetching account details.
public enum AccountServiceError: Error {
    /// The constructed URL is invalid.
    case invalidURL
    /// The server responded with an invalid HTTP status code.
    case badStatus(code: Int)
    /// JSON decoding failed.
    case decodingFailed(underlying: Error)
}

// MARK: - Account Details Service

public struct AccountDetailsService {
    private let baseUrl: URL = {
        guard let base = ProcessInfo.processInfo.environment["AURA_BASE_URL"],
              let url = URL(string: base) else {
            preconditionFailure("AURA_BASE_URL is not set or is not a valid URL")
        }
        return url
    }()
    
    /// Fetches account details using the authentication token.
    /// - Parameter token: Authentication token to include in the header.
    /// - Throws: `AccountServiceError` in case of network or decoding issues.
    /// - Returns: An `AccountDetailsResponse` instance containing account data.
    public func getAccount(token: String) async throws -> AccountDetailsResponse {
        let url = baseUrl.appendingPathComponent("/account")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "token")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AccountServiceError.badStatus(code: -1)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AccountServiceError.badStatus(code: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .throw
        decoder.userInfo = [:] // no special config needed for Decimal
        
        do {
            return try decoder.decode(AccountDetailsResponse.self, from: data)
        } catch {
            throw AccountServiceError.decodingFailed(underlying: error)
        }
    }
}

#if DEBUG
extension AccountDetailsService {
    /// Example response stub for previews or tests.
    public static func previewStub() -> AccountDetailsResponse {
        return AccountDetailsResponse(
            currentBalance: Decimal(string: "1234.56") ?? 0,
            transactions: [
                Transaction(value: Decimal(string: "-50.75") ?? 0, label: "Déjeuner"),
                Transaction(value: Decimal(string: "-120.00") ?? 0, label: "Courses"),
                Transaction(value: Decimal(string: "2000.00") ?? 0, label: "Salaire")
            ]
        )
    }
}
#endif

