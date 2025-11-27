//
//  CustomUsernameField.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 27/11/2025.
//

import SwiftUI

private struct CustomUsernameField: View {
    @Binding var fieldTouched: Bool
    @Binding var username: String
    let isTranserView: Bool

    private var isEmailValid: Bool {
        // Simple regex for email validation
        let email = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        return NSPredicate(format: "SELF MATCHES[c] %@", pattern).evaluate(with: email)
    }
    
//    private var isFrenchPhoneValid: Bool {
//        let raw = username.trimmingCharacters(in: .whitespacesAndNewlines)
//
//        // Normaliser: supprimer les séparateurs visuels
//        let phone = raw.replacingOccurrences(of: "[\\s.-]", with: "", options: .regularExpression)
//
//        // Regex:
//        let pattern = "^(?:\+33|0033|0)?(?:[1-5]|6|7|9)\d{8}$"
//
//        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: phone)
//    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Adresse email", text: $username, onEditingChanged: { isEditing in
                if isEditing {
                    fieldTouched = true
                }
            })
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(fieldTouched && !isEmailValid ? Color.red : Color.clear, lineWidth: 2)
            )
            .autocapitalization(.none)
            .keyboardType(.emailAddress)
            .disableAutocorrection(true)
            .textContentType(.username)
            .textInputAutocapitalization(.never)

            if fieldTouched && !isEmailValid {
                Text("Enter a valid email.")
                    .font(.footnote)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 5)
            }
        }
    }
}
