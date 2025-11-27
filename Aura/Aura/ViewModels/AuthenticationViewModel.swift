//
//  AuthenticationViewModel.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import Foundation

class AuthenticationViewModel: ObservableObject {
    @Published var showAlert: Bool = false
    @Published var message: String = ""
    @Published var icon: String = ""
    @Published var username: String = ""
    @Published var password: String = ""
    
    var onLoginSucceed: (() -> Void)?
    let service: AuthenticationServicing
    
    init(service: AuthenticationServicing = AuthenticationService()) {
        self.service = service
    }
    
    @MainActor
    func login() async {
        print("login with \(username) and \(password)")
        
        do {
            let response = try await service.authenticate(username: username, password: password)
            // Handle successful authentication, e.g., trigger callback
            onLoginSucceed?()
            // Store Token. `let token = try? Keychain.get("auth_token")` to use it
            do {
                try Keychain.set(response, for: "auth_token")
            } catch {
                print("Failed to store token in Keychain: \(error)")
                throw error
            }

        } catch {
            showAlert = true
            if let nsError = error as NSError?, nsError.code == 400 {
                username = ""
                password = ""
                message = "Bad credentials. Please try again."
                icon = "nosign"
            } else {
                message = error.localizedDescription
                icon = "exclamationmark.circle"
            }
            print("Authentication failed with error: \(error)")
        }
    }
}

