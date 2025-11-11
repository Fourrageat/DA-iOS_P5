//
//  AuthenticationViewModel.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import Foundation

class AuthenticationViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    
    let onLoginSucceed: (() -> ())
    
    init(_ callback: @escaping () -> ()) {
        self.onLoginSucceed = callback
    }
    
    func login() async {
        print("login with \(username) and \(password)")
        let service = AuthenticationService()
        do {
            let response = try await service.authenticate(username: username, password: password)
            // Handle successful authentication, e.g., trigger callback
            onLoginSucceed()
            // You can also use `response` if needed
            _ = response
        } catch {
            // Handle authentication error (log or surface to UI)
            print("Authentication failed with error: \(error)")
        }
    }
}
