//
//  MoneyTransferService.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 26/11/2025.
//

import Foundation

// MARK: - DTOs
struct TransferRequest: Codable {
    let recipient: String
    let amount: Decimal
}

// MARK: - Service
protocol MoneyTranfertRepositoryType {
    func transfert(recipient: String, amount: Decimal, token: String) async throws -> Void
}

struct MoneyTranfertRepository: MoneyTranfertRepositoryType {
    
    private let baseURL: URL = HTTP.baseURL()

    func transfert(recipient: String, amount: Decimal, token: String) async throws -> Void {
        let url = baseURL.appendingPathComponent("/account/transfer")
        do {
            let _: EmptyResponse = try await HTTP.request(
                url: url,
                method: "POST",
                headers: ["token": token],
                body: TransferRequest(recipient: recipient, amount: amount)
            )
        } catch let httpError as HTTPError {
            switch httpError {
            case .badStatus(let code, let msg):
                throw NSError(
                    domain: "AuthenticationService",
                    code: code,
                    userInfo: [NSLocalizedDescriptionKey: msg ?? "Unknown error"]
                )
            case .decodingFailed(let underlying):
                throw underlying
            default:
                throw httpError
            }
        }
    }
}
