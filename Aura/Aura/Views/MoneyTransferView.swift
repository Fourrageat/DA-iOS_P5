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
                    TextField("Enter recipient's info", text: $viewModel.recipient)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .keyboardType(.emailAddress)
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
        }
}


#Preview {
    MoneyTransferView()
}

