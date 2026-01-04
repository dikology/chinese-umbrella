//
//  ContentView.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let currentUser: AppUser
    let diContainer: DIContainer

    init(currentUser: AppUser, diContainer: DIContainer) {
        self.currentUser = currentUser
        self.diContainer = diContainer
    }

    var body: some View {
        LibraryScreen(
            viewModel: LibraryViewModel(
                bookRepository: diContainer.bookRepository,
                userId: currentUser.id,
                logger: LoggingService.shared
            ),
            diContainer: diContainer
        )
    }
}

#Preview {
    ContentView(
        currentUser: AppUser(id: UUID(), email: "test@test.com", displayName: "Test User"),
        diContainer: DIContainer.preview
    )
        .environment(\.managedObjectContext, DIContainer.preview.coreDataManager.viewContext)
}
