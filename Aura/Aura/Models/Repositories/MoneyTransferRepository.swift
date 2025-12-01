//
//  MoneyTransferService.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 26/11/2025.
//

import Foundation

// MARK: - DTOs

/// Request payload for initiating a money transfer.
struct TransferRequest: Codable {
    /// Monetary amount of the transaction.
    let recipient: String
    /// Transaction label/description.
    let amount: Decimal
}

/// Possible errors when fetching account details.
enum MoneyTransferRepositoryError: Error {
    /// The constructed URL is invalid.
    case invalidURL
    /// The server responded with an invalid HTTP status code.
    case badStatus(code: Int)
    /// JSON decoding failed.
    case decodingFailed(underlying: Error)
}

// MARK: - Service

protocol MoneyTransferRepositoryType {
    /// Sends a money transfer request.
    ///
    /// - Parameters:
    ///   - recipient: Recipient identifier (email or FR phone number, e.g., `0612345678`).
    ///   - amount: Amount to transfer in euros. Must be strictly positive.
    ///   - token: Authentication token to include in the request headers.
    /// - Throws: An error if the network request fails or the server returns an error.
    ///
    /// - Important: This method does not perform input validation. Ensure `recipient` and `amount` are validated by the caller.
    func transfer(recipient: String, amount: Decimal, token: String) async throws -> Void
}

struct MoneyTransferRepository: MoneyTransferRepositoryType {
    
    private let baseURL: URL = HTTP.baseURL()

    func transfer(recipient: String, amount: Decimal, token: String) async throws -> Void {
        let url = baseURL.appendingPathComponent("/account/transfer")
        do {
            let _: EmptyResponse = try await HTTP.post(
                url: url,
                headers: ["token": token],
                body: TransferRequest(recipient: recipient, amount: amount)
            )
        } catch let httpError as HTTPError {
            switch httpError {
            case .badStatus(let code, _):
                throw MoneyTransferRepositoryError.badStatus(code: code)
            case .decodingFailed(let underlying):
                throw MoneyTransferRepositoryError.decodingFailed(underlying: underlying)
            case .invalidURL:
                throw MoneyTransferRepositoryError.invalidURL
            default:
                throw httpError
            }
        }
    }
}

