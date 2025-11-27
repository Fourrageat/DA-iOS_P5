//
//  AccountDetailsService.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 25/11/2025.
//

import Foundation

// MARK: - DTOs

/// Represents a banking transaction.
struct TransactionResponse: Codable {
    /// Monetary amount of the transaction.
    let value: Decimal
    /// Transaction label/description.
    let label: String
}

/// API response containing account details.
struct AccountDetailResponse: Codable {
    /// Current account balance.
    let currentBalance: Decimal
    /// List of recent transactions.
    let transactions: [TransactionResponse]
}

// MARK: - Service-specific Errors

/// Possible errors when fetching account details.
enum AccountServiceError: Error {
    /// The constructed URL is invalid.
    case invalidURL
    /// The server responded with an invalid HTTP status code.
    case badStatus(code: Int)
    /// JSON decoding failed.
    case decodingFailed(underlying: Error)
}

// MARK: - Service

/// Abstraction for fetching account details.
protocol AccountDetailServicing {
    /// Fetches account details using the authentication token.
    /// - Parameter token: Authentication token to include in the header.
    /// - Throws: Errors related to networking or decoding.
    /// - Returns: An `AccountDetailsResponse` instance containing account data.
    func getAccount(token: String) async throws -> AccountDetailResponse
}


struct AccountDetailService: AccountDetailServicing {
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
    func getAccount(token: String) async throws -> AccountDetailResponse {
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
            return try decoder.decode(AccountDetailResponse.self, from: data)
        } catch {
            throw AccountServiceError.decodingFailed(underlying: error)
        }
    }
}

#if DEBUG
extension AccountDetailService {
    /// Example response stub for previews or tests.
    public static func previewStub() -> AccountDetailResponse {
        return AccountDetailResponse(
            currentBalance: Decimal(string: "1234.56") ?? 0,
            transactions: [
                TransactionResponse(value: Decimal(string: "-50.75") ?? 0, label: "Déjeuner"),
                TransactionResponse(value: Decimal(string: "-120.00") ?? 0, label: "Courses"),
                TransactionResponse(value: Decimal(string: "2000.00") ?? 0, label: "Salaire")
            ]
        )
    }
}
#endif

