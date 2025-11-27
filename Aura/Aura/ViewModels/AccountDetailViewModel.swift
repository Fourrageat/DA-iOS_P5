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
    
    var service: AccountDetailServicing
    
    init(service: AccountDetailServicing = AccountDetailService()) {
        self.service = service
    }
    
    @MainActor
    func fetchData() async {
        
        do {
            guard let token = try? Keychain.get("auth_token") else {
                return
            }
            let response = try await service.getAccount(token: token)
            totalAmount = "€\(response.currentBalance)"
            // Map service transactions to local view model transactions
            recentTransactions = response.transactions.prefix(3).map { transaction in
                Transaction(label: transaction.label, value: "\(transaction.value)")
            }
            
        } catch {
            print(error)
        }
    }
}
