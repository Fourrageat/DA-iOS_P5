//
//  MoneyTransferView.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import SwiftUI

struct MoneyTransferView: View {
    @ObservedObject var viewModel = MoneyTransferViewModel()
    @State private var animationScale: CGFloat = 1.0
    @State private var fieldTouched: Bool = false
    
    private var isUsernameValid: Bool {
        var input = viewModel.recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        
        input = input.replacingOccurrences(of: " ", with: "")

        let emailPattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailPattern)

        let phonePattern = "^0[1-9][0-9]{8}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phonePattern)

        return emailPredicate.evaluate(with: input) || phonePredicate.evaluate(with: input)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Adding a fun header image
            Image(systemName: "arrow.right.arrow.left.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(Color(hex: "#94A684"))
                .padding()
                .scaleEffect(animationScale)
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        animationScale = 1.2
                    }
                }
            
            Text("Send Money!")
                .font(.largeTitle)
                .fontWeight(.heavy)

            VStack(alignment: .leading) {
                Text("Recipient (Email or Phone)")
                    .font(.headline)

                CustomUsernameField(fieldTouched: $fieldTouched, username: $viewModel.recipient, isTranserView: true, isUsernameValid: isUsernameValid)
            }
            
            VStack(alignment: .leading) {
                Text("Amount (€)")
                    .font(.headline)
                TextField("0.00", text: $viewModel.amount)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .keyboardType(.decimalPad)
            }

            Button(action: {
                Task { await viewModel.sendMoney() }
            }) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Send")
                }
                .padding()
                .background(Color(hex: "#94A684"))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(!(isUsernameValid && !viewModel.amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
            .buttonStyle(PlainButtonStyle())

            // Message
            if !viewModel.transferMessage.isEmpty {
                Text(viewModel.transferMessage)
                    .padding(.top, 20)
                    .transition(.move(edge: .top))
            }
            
            Spacer()
        }
        .padding()
        .onTapGesture {
            self.endEditing(true)  // This will dismiss the keyboard when tapping outside
        }
        .customAlertPopup(
            show: $viewModel.showAlert,
            message: $viewModel.message,
            icon: $viewModel.icon
        )
    }
}

#Preview {
    MoneyTransferView()
}

