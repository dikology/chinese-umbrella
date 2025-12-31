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
    let coreDataManager = CoreDataManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataManager.viewContext)
        }
    }
}
