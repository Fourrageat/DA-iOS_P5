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
enum AccountRepositoryError: Error {
    /// The constructed URL is invalid.
    case invalidURL
    /// The server responded with an invalid HTTP status code.
    case badStatus(code: Int)
    /// JSON decoding failed.
    case decodingFailed(underlying: Error)
}

// MARK: - Service

protocol AccountDetailRepositoryType {
    /// Fetches account details using the authentication token.
    /// - Parameter token: Authentication token to include in the header.
    /// - Throws: Errors related to networking or decoding.
    /// - Returns: An `AccountDetailsResponse` instance containing account data.
    func getAccount(token: String) async throws -> AccountDetailResponse
}

struct AccountDetailRepository: AccountDetailRepositoryType {
    
    private let baseURl: URL = HTTP.baseURL()
    
    func getAccount(token: String) async throws -> AccountDetailResponse {
        let url = baseURl.appendingPathComponent("/account")
        do {
            let response: AccountDetailResponse = try await HTTP.get(
                url: url,
                headers: ["token": token]
            )
            return response
        } catch let httpError as HTTPError {
            switch httpError {
            case .badStatus(let code, _):
                throw AccountRepositoryError.badStatus(code: code)
            case .decodingFailed(let underlying):
                throw AccountRepositoryError.decodingFailed(underlying: underlying)
            case .invalidURL:
                throw AccountRepositoryError.invalidURL
            default:
                throw httpError
            }
        }
    }
}

