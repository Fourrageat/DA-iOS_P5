//
//  MoneyTransferViewModel.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import Foundation

class MoneyTransferViewModel: ObservableObject {
    @Published var recipient: String = ""
    @Published var amount: String = ""
    @Published var transferMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var message: String = ""
    @Published var icon: String = ""
    
    func sendMoney() async {
        print("Sending money to \(recipient) for amount \(amount)")
        let service: MoneyTranfertServicing = MoneyTranfertService()
        do {
            guard let token = try? Keychain.get("auth_token") else {
                await MainActor.run { [weak self] in
                    self?.recipient = ""
                    self?.amount = ""
                }
                return
            }
            
            guard let value = Decimal(string: amount) else {
                return
            }

            if !recipient.isEmpty && !amount.isEmpty {
                let _: Void = try await service.transfert(recipient: recipient, amount: value, token: token)
            }
            self.showAlert = true
            await MainActor.run {
                self.message = "Success"
                self.icon = "checkmark.circle"
            }
            recipient = ""
            amount = ""
        } catch {
            self.showAlert = true
            await MainActor.run {
                self.message = "Error"
                self.icon = "exclamationmark.circle"
            }
            print("Error: \(error)")
        }
    }
}
