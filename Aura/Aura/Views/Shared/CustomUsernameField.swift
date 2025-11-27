//
//  CustomUsernameField.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 27/11/2025.
//

import SwiftUI

struct CustomUsernameField: View {
    @Binding var fieldTouched: Bool
    @Binding var username: String
    let isTranserView: Bool
    let isUsernameValid: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField(isTranserView ? "Enter recipient's info" : "Email address", text: $username, onEditingChanged: { isEditing in
                if isEditing {
                    fieldTouched = true
                }
            })
            .padding()
            .background(isTranserView ? Color.gray.opacity(0.2) : Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(fieldTouched && !isUsernameValid && !username.isEmpty ? Color.red : Color.clear, lineWidth: 2)
            )
            .keyboardType(.emailAddress)
            .disableAutocorrection(true)
            .textContentType(.username)
            .textInputAutocapitalization(.never)

            if fieldTouched && !isUsernameValid && !username.isEmpty {
                Text(isTranserView ? "Enter a valid email or phone number." : "Enter a valid email.")
                    .font(.footnote)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 5)
            }
        }
    }
}
