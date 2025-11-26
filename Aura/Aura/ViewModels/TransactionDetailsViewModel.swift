//
//  TransactionDetailsViewModel.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 26/11/2025.
//

import Foundation

class TransactionDetailsViewModel: ObservableObject {
    @Published var transactions: [Transactions] = []
    
    func fetchTransactions() async {
        let service: AccountDetailServicing = AccountDetailService()
        
        do {
            guard let token = try? Keychain.get("auth_token") else {
                await MainActor.run { [weak self] in
                    self?.transactions = []
                }
                return
            }
            let response = try await service.getAccount(token: token)
            await MainActor.run { [weak self] in
                // Map service transactions to local view model transactions
                self?.transactions = response.transactions.map { transaction in
                    Transactions(label: transaction.label, value: "\(transaction.value)")
                }
            }
        } catch {
            await MainActor.run { [weak self] in
                self?.transactions = []
            }
        }
    }
}
