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
            // Store Token. `let token = try? Keychain.get("auth_token")` to use it
            do {
                try Keychain.set(response, for: "auth_token")
            } catch {
                print("Failed to store token in Keychain: \(error)")
                throw error
            }
            let token = try? Keychain.get("auth_token")
            print(token!)
        } catch {
            self.showAlert = true
            if let nsError = error as NSError?, nsError.code == 400 {
                await MainActor.run {
                    username = ""
                    password = ""
                    self.message = "Bad credentials. Please try again."
                    self.icon = "nosign"
                }
            } else {
                await MainActor.run {
                    self.message = error.localizedDescription
                    self.icon = "exclamationmark.circle"
                }
            }
            print("Authentication failed with error: \(error)")
        }
    }
}

