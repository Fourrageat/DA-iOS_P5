//
//  TransactionDetailsViewModel.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 26/11/2025.
//

import Foundation

/// View model responsible for fetching and exposing transaction details for display.
/// Uses an `AccountDetailRepositoryType` repository to retrieve data and maps it to lightweight `Transaction` items.
class TransactionDetailsViewModel: ObservableObject {
    // Published list of transactions consumed by the UI
    @Published var transactions: [Transaction] = []
    
    // Abstraction over the data source (network, mock, etc.) used to fetch account details
    var repository: AccountDetailRepositoryType
    
    /// Creates a new view model.
    /// - Parameter repository: Repository used to fetch account details. Defaults to a concrete implementation.
    init(repository: AccountDetailRepositoryType = AccountDetailRepository()) {
        self.repository = repository
    }
    
    /// Fetches transactions from the repository and updates the published list.
    /// - Note: Executed on the main actor to ensure UI-safe updates.
    @MainActor
    func fetchTransactions() async {
        // Attempt to retrieve the authentication token from the keychain
        do {
            guard let token = try? Keychain.get("auth_token") else {
                return
            }
            let response = try await repository.getAccount(token: token)
            // Map repository response to lightweight UI models
            transactions = response.transactions.map { transaction in
                Transaction(label: transaction.label, value: "\(transaction.value)")
            }
            
        } catch {
            // In production, consider surfacing a user-facing error or logging
            print(error)
        }
    }
}

