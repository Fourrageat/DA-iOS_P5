//
//  AuthenticationViewModel.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import Foundation

class AuthenticationViewModel: ObservableObject {
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String? = nil
    @Published var username: String = ""
    @Published var password: String = ""
    
    let onLoginSucceed: (() -> ())
    
    init(_ callback: @escaping () -> ()) {
        self.onLoginSucceed = callback
    }
    
    func login() async {
        print("login with \(username) and \(password)")
        let service: AuthenticationServicing = AuthenticationService()
        do {
            let response = try await service.authenticate(username: username, password: password)
            // Handle successful authentication, e.g., trigger callback
            onLoginSucceed()
            // You can also use `response` if needed
            _ = response
            print(response)
        } catch {
            await MainActor.run {
                self.errorMessage = "Identifiants incorrects. Veuillez réessayer."
                self.showErrorAlert = true
            }
            print("Authentication failed with error: \(error)")
        }
    }
}

