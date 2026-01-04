//
//  umbrellaApp.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import SwiftUI
import CoreData

/// Observable object to manage app initialization state
@Observable
final class AppInitializationState {
    var currentUser: AppUser?
    var isInitializing = true
    private let diContainer: DIContainer

    init(diContainer: DIContainer) {
        self.diContainer = diContainer
    }

    @MainActor
    func initializeApp() async {
        // Preload dictionary in background
        Task {
            do {
                try diContainer.dictionaryService.preloadDictionary()
                print("Dictionary preloaded successfully")
            } catch {
                print("Failed to preload dictionary: \(error)")
            }
        }

        // Get or create anonymous user
        do {
            let anonymousService = diContainer.anonymousUserService
            currentUser = try await anonymousService.getOrCreateAnonymousUser()
            isInitializing = false
        } catch {
            print("Failed to initialize anonymous user: \(error)")
            // Create fallback user
            currentUser = AppUser(
                email: "fallback@local.device",
                displayName: "Local User"
            )
            isInitializing = false
        }
    }
}

@main
struct umbrellaApp: App {
    @State private var appState: AppInitializationState
    let diContainer = DIContainer()

    init() {
        let container = diContainer
        _appState = State(initialValue: AppInitializationState(diContainer: container))

        // Initialize app state asynchronously
        let state = appState
        Task {
            await state.initializeApp()
        }
    }

    var body: some Scene {
        WindowGroup {
            if appState.isInitializing {
                // Show splash/loading screen while initializing
                LoadingView()
            } else if let user = appState.currentUser {
                // Go directly to main app
                ContentView(currentUser: user, diContainer: diContainer)
                    .environment(\.managedObjectContext, diContainer.coreDataManager.viewContext)
            }
        }
    }
}
