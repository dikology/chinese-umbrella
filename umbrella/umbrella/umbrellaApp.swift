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

    init() {
        // Preload dictionary in background
        Task {
            do {
                try DIContainer.dictionaryService.preloadDictionary()
                print("Dictionary preloaded successfully")
            } catch {
                print("Failed to preload dictionary: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                // Main app content when authenticated
                ContentView(authViewModel: authViewModel)
                    .environment(\.managedObjectContext, coreDataManager.viewContext)
            } else {
                // Authentication screen when not authenticated
                AuthScreen(viewModel: authViewModel)
                    .environment(\.managedObjectContext, coreDataManager.viewContext)
            }
        }
    }
}
