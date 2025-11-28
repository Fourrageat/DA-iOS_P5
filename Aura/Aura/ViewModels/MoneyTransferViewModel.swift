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
    
    var service: MoneyTranfertRepositoryType = MoneyTranfertRepository()
    
    init(service: MoneyTranfertRepositoryType = MoneyTranfertRepository()) {
        self.service = service
    }
    
    @MainActor
    func sendMoney() async {
        
        do {
            guard let token = try? Keychain.get("auth_token") else {
                return
            }
            
            guard let value = Decimal(string: amount) else {
                return
            }

            if !recipient.isEmpty && !amount.isEmpty {
                try await service.transfert(recipient: recipient, amount: value, token: token)
            }
            showAlert = true
            message = "Success"
            icon = "checkmark.circle"
            recipient = ""
            amount = ""
            
        } catch {
            showAlert = true
            message = "Error"
            icon = "exclamationmark.circle"
            print(error)
        }
    }
}
