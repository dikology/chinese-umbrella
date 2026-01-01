//
//  ContentView.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let authViewModel: AuthViewModel

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }

    var body: some View {
        LibraryScreen(viewModel: LibraryViewModel(
            bookRepository: DIContainer.bookRepository,
            authViewModel: authViewModel
        ))
    }
}

#Preview {
    ContentView(authViewModel: AuthViewModel(authUseCase: AuthUseCase(repository: AuthRepositoryImpl(), keychainService: KeychainService())))
}
