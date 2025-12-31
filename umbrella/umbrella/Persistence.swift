//
//  Persistence.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()

    @MainActor
    static let preview: CoreDataManager = {
        let result = CoreDataManager(inMemory: true)
        let viewContext = result.container.viewContext

        // Create preview data for development
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Preview Core Data setup failed: \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ChineseReaderData")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Handle different error scenarios appropriately
                let errorMessage = """
                Core Data load error: \(error.localizedDescription)
                Code: \(error.code)
                Domain: \(error.domain)

                Possible causes:
                • The parent directory does not exist or cannot be created
                • The persistent store is not accessible due to permissions
                • The device is out of space
                • The store could not be migrated to the current model version

                User Info: \(error.userInfo)
                """

                // In development, we can be more aggressive with fatal errors
                // In production, implement proper error recovery
                fatalError(errorMessage)
            }
        }

        // Enable automatic merging of changes from parent contexts
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Enable undo management for better data integrity
        container.viewContext.undoManager = UndoManager()
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Background Context

    lazy var backgroundContext: NSManagedObjectContext = {
        let context = container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil // Background contexts don't need undo
        return context
    }()

    // MARK: - Save Operations

    func saveContext(_ context: NSManagedObjectContext = CoreDataManager.shared.viewContext) throws {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("Core Data save error: \(nsError.localizedDescription)")
            print("Error details: \(nsError.userInfo)")

            // In a production app, implement proper error recovery
            // For now, we re-throw to let the caller handle it
            throw error
        }
    }

    func saveContextAsync(_ context: NSManagedObjectContext? = nil) async throws {
        let contextToUse = context ?? CoreDataManager.shared.backgroundContext
        guard contextToUse.hasChanges else { return }

        try await contextToUse.perform {
            do {
                try contextToUse.save()
            } catch {
                print("Async Core Data save error: \(error.localizedDescription)")
                throw error
            }
        }
    }

    // MARK: - Batch Operations

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }

    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await container.performBackgroundTask(block)
    }
}

// Legacy alias for backward compatibility
typealias PersistenceController = CoreDataManager
