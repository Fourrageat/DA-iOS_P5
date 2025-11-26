//
//  AccountDetailViewModel.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import Foundation

class AccountDetailViewModel: ObservableObject {
    @Published var totalAmount: String = "..."
    @Published var recentTransactions: [Transaction] = []
    
    struct Transaction {
        let label: String
        let value: String
    }
    
    func fetchData() async {
        let service: AccountDetailServicing = AccountDetailService()
        
        do {
            guard let token = try? Keychain.get("auth_token") else {
                await MainActor.run { [weak self] in
                    self?.totalAmount = "..."
                    self?.recentTransactions = []
                }
                return
            }
            let response = try await service.getAccount(token: token)
            await MainActor.run { [weak self] in
                self?.totalAmount = "€\(response.currentBalance)"
                // Map service transactions to local view model transactions
                self?.recentTransactions = response.transactions.prefix(3).map { transaction in
                    Transaction(label: transaction.label, value: "\(transaction.value)")
                }
            }
        } catch {
            await MainActor.run { [weak self] in
                self?.totalAmount = "?"
                self?.recentTransactions = []
            }
        }
    }
}
