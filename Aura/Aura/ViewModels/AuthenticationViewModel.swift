//
//  AuthenticationViewModel.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import Foundation

/// View model responsible for handling user authentication flow.
/// Exposes input fields, feedback state, and coordinates with an authentication repository.
class AuthenticationViewModel: ObservableObject {
    // UI feedback state
    @Published var showAlert: Bool = false
    @Published var message: String = ""
    @Published var icon: String = ""

    // User input fields
    @Published var username: String = ""
    @Published var password: String = ""
    
    // Callback invoked when authentication succeeds (e.g., to navigate to the next screen)
    var onLoginSucceed: (() -> Void)?
    
    // Repository abstraction used to perform authentication requests
    let repository: AuthenticationRepositoryType
    
    /// Creates a new authentication view model.
    /// - Parameter repository: Repository used to authenticate users. Defaults to a concrete implementation.
    init(repository: AuthenticationRepositoryType = AuthenticationRepository()) {
        self.repository = repository
    }
    
    /// Attempts to authenticate the user with the provided credentials.
    /// Updates UI feedback state and stores the received token on success.
    @MainActor
    func login() async {
        print("Attempting login for username: \(username)")
        
        // Perform authentication via the repository
        do {
            let response = try await repository.authenticate(username: username, password: password)
            // Notify listeners of successful authentication
            onLoginSucceed?()
            // Store token in Keychain. Retrieve later with: `let token = try? Keychain.get("auth_token")`
            do {
                try Keychain.set(response, for: "auth_token")
            } catch {
                print("Failed to store token in Keychain: \(error)")
                throw error
            }

        } catch {
            // Surface the error to the UI
            showAlert = true
            // Map specific error codes to user-friendly messages
            if let nsError = error as NSError?, nsError.code == 400 {
                username = ""
                password = ""
                message = "Bad credentials. Please try again."
                icon = "nosign"
            } else {
                message = error.localizedDescription
                icon = "exclamationmark.circle"
            }
            // Log the error for diagnostics
            print("Authentication failed with error: \(error)")
        }
    }
}

