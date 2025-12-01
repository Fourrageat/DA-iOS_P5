//
//  AccountDetailViewModel.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import Foundation

/// View model that exposes account details for display.
/// Fetches the current balance and a list of recent transactions from a repository.
class AccountDetailViewModel: ObservableObject {
    // Formatted current balance shown in the UI
    @Published var totalAmount: String = "..."
    // Subset of recent transactions displayed on the account screen
    @Published var recentTransactions: [Transaction] = []
    
    // Repository abstraction used to retrieve account information
    var repository: AccountDetailRepositoryType
    
    /// Creates a new account detail view model.
    /// - Parameter repository: Repository used to retrieve account information. Defaults to a concrete implementation.
    init(repository: AccountDetailRepositoryType = AccountDetailRepository()) {
        self.repository = repository
    }
    
    /// Fetches account data and updates the published properties.
    /// - Note: Runs on the main actor to safely update UI-bound state.
    @MainActor
    func fetchData() async {
        
        do {
            // Retrieve the authentication token from the keychain
            guard let token = try? Keychain.get("auth_token") else {
                return
            }
            // Fetch account details from the repository
            let response = try await repository.getAccount(token: token)
            totalAmount = "€\(response.currentBalance)"
            // Map repository transactions to lightweight UI models (only the most recent 3)
            recentTransactions = response.transactions.prefix(3).map { transaction in
                Transaction(label: transaction.label, value: "\(transaction.value)")
            }
            
        } catch {
            // Consider surfacing a user-friendly error or logging
            print(error)
        }
    }
}

