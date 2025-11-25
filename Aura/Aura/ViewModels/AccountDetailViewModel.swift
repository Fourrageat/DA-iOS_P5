//
//  AccountDetailViewModel.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import Foundation

class AccountDetailViewModel: ObservableObject {
    @Published var totalAmount: String = "Loading..."
    @Published var recentTransactions: [Transaction] = [
        Transaction(description: "Starbucks", amount: "-€5.50"),
        Transaction(description: "Amazon Purchase", amount: "-€34.99"),
        Transaction(description: "Salary", amount: "+€2,500.00")
    ]
    
    struct Transaction {
        let description: String
        let amount: String
    }
    
    func fetchData() async {
        let service: AccountDetailServicing = AccountDetailService()
        
        do {
            let token = try? Keychain.get("auth_token")
            let response = try? await service.getAccount(token: token!)
            self.totalAmount = "€\(response!.currentBalance)"
        }
    }
}
