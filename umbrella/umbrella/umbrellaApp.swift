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
                LoggingService.shared.info("Dictionary preloaded successfully")
            } catch {
                LoggingService.shared.error("Failed to preload dictionary", error: error)
            }
        }

        // Get or create anonymous user
        do {
            let anonymousService = diContainer.anonymousUserService
            currentUser = try await anonymousService.getOrCreateAnonymousUser()
            isInitializing = false
        } catch {
            LoggingService.shared.auth("Failed to initialize anonymous user", level: .error)
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
    let diContainer: DIContainer

    init() {
        // Check if we should run in preview mode (with mock data)
        let isPreviewMode = ProcessInfo.processInfo.environment["UMBRELLA_PREVIEW_MODE"] == "true" ||
                           UserDefaults.standard.bool(forKey: "umbrellaPreviewMode")

        diContainer = isPreviewMode ? DIContainer.preview : DIContainer()
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
