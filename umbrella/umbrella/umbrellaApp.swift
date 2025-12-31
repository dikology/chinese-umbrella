//
//  umbrellaApp.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import SwiftUI
import CoreData

@main
struct umbrellaApp: App {
    @State private var authViewModel = DIContainer.authViewModel
    let coreDataManager = CoreDataManager.shared

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                // Main app content when authenticated
                ContentView()
                    .environment(\.managedObjectContext, coreDataManager.viewContext)
                    .environment(authViewModel)
            } else {
                // Authentication screen when not authenticated
                AuthScreen(viewModel: authViewModel)
                    .environment(\.managedObjectContext, coreDataManager.viewContext)
            }
        }
    }
}
