//
//  TransactionDetailsView.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 17/11/2025.
//

import SwiftUI

struct TransactionDetailsView: View {
    @StateObject var viewModel: TransactionDetailsViewModel
    
    var body: some View {
        VStack {
            Text("All Transactions")
                .font(.headline)
                .padding([.horizontal])
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    TransactionsList(transactions: viewModel.transactions)
                }
            }
        }
        .task {
            await viewModel.fetchTransactions()
        }
    }
}

