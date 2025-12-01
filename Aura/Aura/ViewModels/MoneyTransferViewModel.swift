//
//  MoneyTransferViewModel.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import Foundation

/// View model that coordinates the money transfer flow.
/// Holds user inputs, validates them, and calls the repository to perform the transfer.
class MoneyTransferViewModel: ObservableObject {
    // User input fields
    @Published var recipient: String = ""
    @Published var amount: String = ""
    @Published var transferMessage: String = ""

    // UI feedback state
    @Published var showAlert: Bool = false
    @Published var message: String = ""
    @Published var icon: String = ""

    // Repository abstraction that performs the transfer request
    var service: MoneyTransferRepositoryType = MoneyTransferRepository()
    
    /// Creates a new money transfer view model.
    /// - Parameter service: Repository used to perform transfer requests. Defaults to a concrete implementation.
    init(service: MoneyTransferRepositoryType = MoneyTransferRepository()) {
        self.service = service
    }
    
    /// Validates input, performs the transfer via the repository, and updates the UI state.
    /// - Note: Runs on the main actor to safely update UI-bound properties.
    @MainActor
    func sendMoney() async {
        
        // Retrieve the authentication token from the keychain
        do {
            guard let token = try? Keychain.get("auth_token") else {
                return
            }
            
            // Convert the typed amount to a numeric value
            guard let value = Decimal(string: amount) else {
                return
            }

            // Basic input validation before performing the transfer
            if !recipient.isEmpty && !amount.isEmpty {
                // Execute the transfer request
                try await service.transfer(recipient: recipient, amount: value, token: token)
            }
            
            // Update UI to reflect success
            showAlert = true
            message = "Success"
            icon = "checkmark.circle"
            // Reset input fields after success
            recipient = ""
            amount = ""
            
        } catch {
            // Update UI to reflect failure
            showAlert = true
            message = "Error"
            icon = "exclamationmark.circle"
            // Log the error for diagnostics
            print(error)
        }
    }
}

