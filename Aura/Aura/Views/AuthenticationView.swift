//
//  AuthenticationView.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import SwiftUI

struct AuthenticationView: View {
    
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var emailTouched: Bool = false
    
    let gradientStart = Color(hex: "#94A684").opacity(0.7)
    let gradientEnd = Color(hex: "#94A684").opacity(0.0) // Fades to transparent

    @ObservedObject var viewModel: AuthenticationViewModel
    
    private var isEmailValid: Bool {
        // Simple regex for email validation
        let email = viewModel.username.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        return NSPredicate(format: "SELF MATCHES[c] %@", pattern).evaluate(with: email)
    }

    var body: some View {
        
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [gradientStart, gradientEnd]), startPoint: .top, endPoint: .bottomLeading)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Image(systemName: "person.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    
                Text("Welcome !")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                
                TextField("Adresse email", text: $viewModel.username, onEditingChanged: { isEditing in
                    if isEditing {
                        emailTouched = true
                    }
                })
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(emailTouched && !isEmailValid ? Color.red : Color.clear, lineWidth: 2)
                    )
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .disableAutocorrection(true)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)

                if emailTouched && !isEmailValid {
                    Text("Veuillez saisir une adresse email valide")
                        .font(.footnote)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, -15)
                }
                
                SecureField("Mot de passe", text: $viewModel.password)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .textContentType(.password)
                
                Button(action: {
                    // Handle authentication logic here
                    Task { await viewModel.login() }
                }) {
                    Text("Se connecter")
                        .primaryButtonStyle(isEnabled: (isEmailValid && !viewModel.password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                }
                .disabled(!(isEmailValid && !viewModel.password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
            }
            .padding(.horizontal, 40)
        }
        .customAlertPopup(
            show: $viewModel.showErrorAlert,
            errorMessage: $viewModel.errorMessage,
            errorIcon: $viewModel.errorIcon
        )
        .onTapGesture {
            self.endEditing(true)  // This will dismiss the keyboard when tapping outside
        }
    }
    
}

private struct PrimaryButtonStyle: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .foregroundColor(isEnabled ? Color.white : Color.white.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? Color.black : Color.black.opacity(0.4))
            .cornerRadius(8)
    }
}

private extension View {
    func primaryButtonStyle(isEnabled: Bool) -> some View {
        self.modifier(PrimaryButtonStyle(isEnabled: isEnabled))
    }
}

#Preview {
    AuthenticationView(viewModel: AuthenticationViewModel({
        
    }))
}
