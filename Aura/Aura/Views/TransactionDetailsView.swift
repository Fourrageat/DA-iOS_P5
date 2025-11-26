//
//  TransactionDetailsView.swift
//  Aura
//
//  Created by Baptiste Fourrageat on 17/11/2025.
//

import SwiftUI

struct TransactionDetailsView: View {
    @ObservedObject var viewModel: AccountDetailViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                Text("All Transactions")
                    .font(.headline)
                    .padding([.horizontal])
                
                TransactionList(transactions: viewModel.recentTransactions)
            }
            .padding(.top, 10)
        }
        .task {
            await viewModel.fetchData()
        }
    }
}
