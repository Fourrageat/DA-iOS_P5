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
protocol MoneyTranfertServicing {
    func transfert(recipient: String, amount: Decimal, token: String) async throws -> Void
}

struct MoneyTranfertService: MoneyTranfertServicing {
    private let baseUrl: URL = {
        guard let base = ProcessInfo.processInfo.environment["AURA_BASE_URL"],
              let url = URL(string: base) else {
            preconditionFailure("AURA_BASE_URL is not set or is not a valid URL")
        }
        return url
    }()

    func transfert(recipient: String, amount: Decimal, token: String) async throws -> Void {
        let url = baseUrl.appendingPathComponent("/account/transfer")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "token")

        let body = TransferRequest(recipient: recipient, amount: amount)
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
    }
}
