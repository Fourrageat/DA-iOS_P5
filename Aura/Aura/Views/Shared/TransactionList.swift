//
//  TransactionList.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 26/11/2025.
//

import SwiftUI

struct TransactionList: View {
    let transactions: [Transactions]
    
    var body: some View {
        ForEach(transactions, id: \.label) { transaction in
            HStack {
                Image(systemName: transaction.value.contains("-") ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill")
                    .foregroundColor(transaction.value.contains("-") ? .red : .green)
                Text(transaction.label)
                Spacer()
                Text(transaction.value)
                    .fontWeight(.bold)
                    .foregroundColor(transaction.value.contains("-") ? .red : .green)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding([.horizontal])
        }
    }
}

