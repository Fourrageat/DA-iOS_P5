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
    
    private var isAmountValid: Bool {
        let trimmed = viewModel.amount.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        // Replace comma with dot to support both separators
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        if let value = Double(normalized), value > 0 { return true }
        return false
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
                    .onChange(of: viewModel.amount) { oldValue, newValue in
                        // Allow digits and one decimal separator (dot or comma), and strip leading '+' or '-'
                        let separators = [".", ","]
                        var filtered = newValue.replacingOccurrences(of: "+", with: "")
                        filtered = filtered.replacingOccurrences(of: "-", with: "")
                        // Keep only digits and separators
                        filtered = filtered.filter { $0.isNumber || separators.contains(String($0)) }
                        // Ensure at most one separator (prefer the first encountered)
                        var result = ""
                        var hasSeparator = false
                        for ch in filtered {
                            if ch == "." || ch == "," {
                                if !hasSeparator { hasSeparator = true; result.append(ch) }
                            } else {
                                result.append(ch)
                            }
                        }
                        // Remove leading zeros like "00" but keep "0" and "0.x"
                        if result.hasPrefix("00") {
                            while result.hasPrefix("00") { result.removeFirst() }
                            if result.isEmpty { result = "0" }
                        }
                        // Update only if changed to avoid cursor jump loops
                        if result != newValue {
                            viewModel.amount = result
                        }
                    }
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
            .disabled(!(isUsernameValid && isAmountValid))
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

