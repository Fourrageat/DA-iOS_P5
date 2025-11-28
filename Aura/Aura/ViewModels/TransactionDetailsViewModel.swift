//
//  TransactionDetailsViewModel.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 26/11/2025.
//

import Foundation

class TransactionDetailsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    
    var service: AccountDetailRepositoryType
    
    init(service: AccountDetailRepositoryType = AccountDetailRepository()) {
        self.service = service
    }
    
    @MainActor
    func fetchTransactions() async {
        
        do {
            guard let token = try? Keychain.get("auth_token") else {
                return
            }
            let response = try await service.getAccount(token: token)
            // Map service transactions to local view model transactions
            transactions = response.transactions.map { transaction in
                Transaction(label: transaction.label, value: "\(transaction.value)")
            }
            
        } catch {
            print(error)
        }
    }
}
