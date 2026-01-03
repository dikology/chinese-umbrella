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

    init(currentUser: AppUser) {
        self.currentUser = currentUser
    }

    var body: some View {
        LibraryScreen(viewModel: LibraryViewModel(
            bookRepository: DIContainer.bookRepository,
            userId: currentUser.id
        ))
    }
}

#Preview {
    ContentView(currentUser: AppUser(id: UUID(), email: "test@test.com", displayName: "Test User"))
        .environment(\.managedObjectContext, DIContainer.coreDataManager.viewContext)
}
