//
//  AppViewModel.swift
//  Aura
//
//  Created by Vincent Saluzzo on 29/09/2023.
//

import Foundation

class AppViewModel: ObservableObject {
    @Published var isLogged: Bool
    
    init() {
        isLogged = false
    }
    
    var authenticationViewModel: AuthenticationViewModel {
        let viewModel = AuthenticationViewModel()
        viewModel.onLoginSucceed = {
            DispatchQueue.main.async { [weak self] in
                self?.isLogged = true
            }
        }
        return viewModel
    }
    
    var accountDetailViewModel: AccountDetailViewModel {
        return AccountDetailViewModel()
    }
}
