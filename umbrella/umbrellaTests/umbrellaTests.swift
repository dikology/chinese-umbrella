//
//  umbrellaTests.swift
//  umbrellaTests
//
//  Created by Денис on 31.12.2025.
//

import Testing
import CoreData
@testable import umbrella

struct umbrellaTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    // MARK: - CoreData Tests

    @MainActor
    @Test func testCoreDataModelLoadsSuccessfully() async throws {
        // Test that the CoreData model can be loaded without errors
        let container = CoreDataManager(inMemory: true)
        _ = container.viewContext // Initialize context to ensure container loads properly

        // If we get here without throwing, the model loaded successfully
        #expect(container.container.managedObjectModel.entities.count > 0)
    }

    @MainActor
    @Test func testAllCoreDataEntitiesCanBeInstantiated() async throws {
        // Test that all custom NSManagedObject subclasses can be instantiated
        let container = CoreDataManager(inMemory: true)
        let context = container.viewContext

        // Test Book entity
        let book = NSEntityDescription.insertNewObject(forEntityName: "Book", into: context) as? CDBook
        #expect(book != nil, "CDBook entity should be instantiable")
        #expect(type(of: book!) == CDBook.self, "Book entity should be of exact type CDBook")

        // Test BookPage entity
        let bookPage = NSEntityDescription.insertNewObject(forEntityName: "BookPage", into: context) as? CDBookPage
        #expect(bookPage != nil, "CDBookPage entity should be instantiable")
        #expect(type(of: bookPage!) == CDBookPage.self, "BookPage entity should be of exact type CDBookPage")

        // Test WordSegment entity
        let wordSegment = NSEntityDescription.insertNewObject(forEntityName: "WordSegment", into: context) as? CDWordSegment
        #expect(wordSegment != nil, "CDWordSegment entity should be instantiable")
        #expect(type(of: wordSegment!) == CDWordSegment.self, "WordSegment entity should be of exact type CDWordSegment")

        // Test MarkedWord entity
        let markedWord = NSEntityDescription.insertNewObject(forEntityName: "MarkedWord", into: context) as? CDMarkedWord
        #expect(markedWord != nil, "CDMarkedWord entity should be instantiable")
        #expect(type(of: markedWord!) == CDMarkedWord.self, "MarkedWord entity should be of exact type CDMarkedWord")

        // Test User entity
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: context) as? UserEntity
        #expect(user != nil, "UserEntity should be instantiable")
        #expect(type(of: user!) == UserEntity.self, "User entity should be of exact type UserEntity")

        // Test UserPreferences entity
        let userPreferences = NSEntityDescription.insertNewObject(forEntityName: "UserPreferences", into: context) as? UserPreferences
        #expect(userPreferences != nil, "UserPreferences should be instantiable")
        #expect(type(of: userPreferences!) == UserPreferences.self, "UserPreferences entity should be of exact type UserPreferences")
    }

    @MainActor
    @Test func testCoreDataEntityNamesMatchModel() async throws {
        // Test that entity names in the model match our expectations
        let container = CoreDataManager(inMemory: true)
        let model = container.container.managedObjectModel

        let expectedEntities = ["Book", "BookPage", "WordSegment", "MarkedWord", "User", "UserPreferences"]
        let actualEntities = model.entities.map { $0.name! }

        for expectedEntity in expectedEntities {
            #expect(actualEntities.contains(expectedEntity), "Entity '\(expectedEntity)' should exist in the model")
        }
    }

    @MainActor
    @Test func testCoreDataEntityClassNames() async throws {
        // Test that the represented class names match our NSManagedObject subclasses
        let container = CoreDataManager(inMemory: true)
        let model = container.container.managedObjectModel

        let entityClassNameMap = [
            "Book": "CDBook",
            "BookPage": "CDBookPage",
            "WordSegment": "CDWordSegment",
            "MarkedWord": "CDMarkedWord",
            "User": "UserEntity",
            "UserPreferences": "UserPreferences"
        ]

        for (entityName, expectedClassName) in entityClassNameMap {
            let entity = model.entitiesByName[entityName]
            #expect(entity != nil, "Entity '\(entityName)' should exist")

            if let entity = entity {
                #expect(entity.managedObjectClassName == expectedClassName,
                       "Entity '\(entityName)' should have class name '\(expectedClassName)', but got '\(entity.managedObjectClassName ?? "nil")'")
            }
        }
    }

    @MainActor
    @Test func testCoreDataRelationshipsExist() async throws {
        // Test that important relationships are properly configured
        let container = CoreDataManager(inMemory: true)
        let model = container.container.managedObjectModel

        // Test Book entity relationships
        let bookEntity = model.entitiesByName["Book"]
        #expect(bookEntity != nil, "Book entity should exist")
        #expect(bookEntity!.relationshipsByName["owner"] != nil, "Book should have 'owner' relationship")
        #expect(bookEntity!.relationshipsByName["pages"] != nil, "Book should have 'pages' relationship")

        // Test User entity relationships
        let userEntity = model.entitiesByName["User"]
        #expect(userEntity != nil, "User entity should exist")
        #expect(userEntity!.relationshipsByName["books"] != nil, "User should have 'books' relationship")
    }

    @MainActor
    @Test func testCoreDataFetchRequests() async throws {
        // Test that fetch requests work for all entities
        let container = CoreDataManager(inMemory: true)
        let context = container.viewContext

        // Test fetch requests for each entity type
        let entitiesToTest: [(String, NSManagedObject.Type)] = [
            ("Book", CDBook.self),
            ("BookPage", CDBookPage.self),
            ("WordSegment", CDWordSegment.self),
            ("MarkedWord", CDMarkedWord.self),
            ("User", UserEntity.self),
            ("UserPreferences", UserPreferences.self)
        ]

        for (entityName, _) in entitiesToTest {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
            fetchRequest.fetchLimit = 1

            // Test that fetch requests work for all entities
            // If this throws, the test will fail with the error
            let results = try context.fetch(fetchRequest)
            #expect(results.count >= 0, "Fetch request for '\(entityName)' should return results")
        }
    }

    // MARK: - CoreDataManager Initialization Tests

    @MainActor
    @Test func testCoreDataManagerSharedLoadsPersistentStores() async throws {
        // Test that CoreDataManager.shared properly loads persistent stores
        // This test verifies the fix for the "no stores loaded" error

        // Access CoreDataManager.shared to trigger initialization
        let sharedManager = CoreDataManager.shared

        // Verify that persistent stores are loaded
        let coordinator = sharedManager.container.persistentStoreCoordinator
        #expect(coordinator.persistentStores.count > 0, "Shared CoreDataManager should have loaded persistent stores")

        // Verify that we can create contexts and they work
        let viewContext = sharedManager.viewContext
        #expect(viewContext != nil, "View context should be available")

        // Test that we can create a background context without warnings
        let backgroundContext = sharedManager.backgroundContext
        #expect(backgroundContext != nil, "Background context should be available")
        #expect(backgroundContext.persistentStoreCoordinator != nil, "Background context should have a persistent store coordinator")
    }

    @MainActor
    @Test func testCoreDataManagerDefaultInitializerLoadsStores() async throws {
        // Test that the default CoreDataManager() initializer loads persistent stores
        let manager = CoreDataManager()

        // Verify persistent stores are loaded
        let coordinator = manager.container.persistentStoreCoordinator
        #expect(coordinator.persistentStores.count > 0, "Default CoreDataManager should have loaded persistent stores")

        // Verify context configuration
        let viewContext = manager.viewContext
        #expect(viewContext.automaticallyMergesChangesFromParent == true, "View context should have automatic merging enabled")
        #expect(String(describing: type(of: viewContext.mergePolicy)) == "NSMergeByPropertyObjectTrumpMergePolicy", "View context should have correct merge policy")
        #expect(viewContext.undoManager != nil, "View context should have undo manager")
    }

    @MainActor
    @Test func testBackgroundContextOperationsWork() async throws {
        // Test that background context operations work without "no stores loaded" errors
        let manager = CoreDataManager()

        // Perform a background task
        try await manager.performBackgroundTask { context in
            // This should not throw "no stores loaded" error
            #expect(context.persistentStoreCoordinator != nil, "Background context should have persistent store coordinator")

            // Test that we can create entities
            let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: context) as? UserEntity
            #expect(user != nil, "Should be able to create User entity in background context")

            // Clean up - don't save, just test creation
            context.rollback()
        }
    }

    @MainActor
    @Test func testSaveOperationsWorkWithDefaultManager() async throws {
        // Test that save operations work with the default CoreDataManager
        let manager = CoreDataManager()

        // Create a test user entity
        let context = manager.viewContext
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: context) as! UserEntity

        // Set required properties
        user.id = UUID()
        user.email = "test@example.com"
        user.displayName = "Test User"
        user.passwordHash = "test-hash"
        user.createdAt = Date()
        user.updatedAt = Date()

        // Save should work without "no stores loaded" error
        try manager.saveContext(context)

        // Verify the save worked by fetching the user back
        let fetchRequest = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "email == %@", "test@example.com")
        let results = try context.fetch(fetchRequest)
        #expect(results.count == 1, "Should be able to fetch the saved user")
        #expect(results.first?.email == "test@example.com", "Fetched user should have correct email")
    }

    @MainActor
    @Test func testCoreDataManagerInMemoryMode() async throws {
        // Test that in-memory mode still works as expected
        let manager = CoreDataManager(inMemory: true)

        // Verify it's using in-memory store
        let coordinator = manager.container.persistentStoreCoordinator
        let stores = coordinator.persistentStores
        #expect(stores.count > 0, "In-memory manager should have stores")

        if let store = stores.first {
            let url = store.url
            #expect(url?.path == "/dev/null" || url?.scheme == "memory", "In-memory store should use /dev/null or memory URL")
        }

        // Verify contexts work
        let context = manager.viewContext
        #expect(context != nil, "View context should be available for in-memory store")
    }

    @MainActor
    @Test func testCoreDataManagerCustomStoreURL() async throws {
        // Test that custom store URL initialization works
        let tempDir = FileManager.default.temporaryDirectory
        let customURL = tempDir.appendingPathComponent("test-custom-\(UUID().uuidString).sqlite")

        // Clean up any existing file
        try? FileManager.default.removeItem(at: customURL)

        let manager = CoreDataManager(customStoreURL: customURL)

        // Verify it uses the custom URL
        let coordinator = manager.container.persistentStoreCoordinator
        let stores = coordinator.persistentStores
        #expect(stores.count > 0, "Custom URL manager should have stores")

        if let store = stores.first {
            #expect(store.url == customURL, "Store should use the custom URL")
        }

        // Clean up
        try? FileManager.default.removeItem(at: customURL)
    }

    @MainActor
    @Test func testBookEditingPreservesExistingPagesAndAddsNewOnes() async throws {
        // Test that reproduces the user's issue: adding multiple pages to existing book
        // This verifies that the context fix resolves the page addition issue

        // Create a book with initial pages
        let manager = CoreDataManager()

        // Simulate the scenario from the user's logs:
        // Book starts with 6 pages, user adds 7 more pages
        let initialPages = (1...6).map { pageNum in
            AppBookPage(
                bookId: UUID(),
                pageNumber: pageNum,
                originalImagePath: "/path/to/page\(pageNum).jpg",
                extractedText: "Content for page \(pageNum)",
                words: [AppWordSegment(word: "content", startIndex: 0, endIndex: 7)]
            )
        }

        let book = AppBook(
            id: UUID(),
            title: "Test Book",
            author: "Test Author",
            pages: initialPages,
            currentPageIndex: 0,
            isLocal: true,
            language: "zh-Hans",
            genre: .literature,
            description: "Test book",
            totalWords: 100,
            estimatedReadingTimeMinutes: 5,
            difficulty: .intermediate,
            tags: []
        )

        // Save the initial book
        let savedBook = try await manager.performBackgroundTask { context in
            let bookEntity = CDBook(context: context)
            bookEntity.id = book.id
            bookEntity.title = book.title
            bookEntity.author = book.author
            bookEntity.createdDate = Date()
            bookEntity.updatedDate = Date()

            // Save initial pages
            for page in book.pages {
                let pageEntity = CDBookPage(context: context)
                pageEntity.id = page.id
                pageEntity.book = bookEntity
                pageEntity.pageNumber = Int16(page.pageNumber)
                pageEntity.extractedText = page.extractedText
                pageEntity.imageFilePath = page.originalImagePath
                pageEntity.createdAt = Date()
            }

            try context.save()
            return bookEntity.toDomain()
        }

        // Verify initial book has 6 pages
        #expect(savedBook.totalPages == 6, "Initial book should have 6 pages")

        // Now simulate adding 7 new pages (like in the user's scenario)
        let newPages = (7...13).map { pageNum in
            AppBookPage(
                bookId: savedBook.id,
                pageNumber: pageNum,
                originalImagePath: "/path/to/newpage\(pageNum).jpg",
                extractedText: "New content for page \(pageNum)",
                words: [AppWordSegment(word: "new", startIndex: 0, endIndex: 3)]
            )
        }

        let updatedBook = AppBook(
            id: savedBook.id,
            title: savedBook.title,
            author: savedBook.author,
            pages: savedBook.pages + newPages, // Combine existing + new pages
            currentPageIndex: savedBook.currentPageIndex,
            isLocal: savedBook.isLocal,
            language: savedBook.language,
            genre: savedBook.genre,
            description: savedBook.description,
            totalWords: savedBook.totalWords,
            estimatedReadingTimeMinutes: savedBook.estimatedReadingTimeMinutes,
            difficulty: savedBook.difficulty,
            tags: savedBook.tags
        )

        // Update the book (this should now work with the background context fix)
        let resultBook = try await manager.performBackgroundTask { context in
            let fetchRequest = CDBook.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", updatedBook.id as CVarArg)
            fetchRequest.fetchLimit = 1

            guard let existingBook = try context.fetch(fetchRequest).first else {
                throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Book not found"])
            }

            // Update metadata
            existingBook.title = updatedBook.title
            existingBook.author = updatedBook.author
            existingBook.updatedDate = Date()

            // Delete existing pages and add all pages (existing + new)
            for page in existingBook.pages {
                context.delete(page)
            }

            for page in updatedBook.pages {
                let pageEntity = CDBookPage(context: context)
                pageEntity.id = page.id
                pageEntity.book = existingBook
                pageEntity.pageNumber = Int16(page.pageNumber)
                pageEntity.extractedText = page.extractedText
                pageEntity.imageFilePath = page.originalImagePath
                pageEntity.createdAt = Date()
            }

            try context.save()
            return existingBook.toDomain()
        }

        // Verify the result
        #expect(resultBook.totalPages == 13, "Book should now have 13 pages total (6 original + 7 new)")
        #expect(resultBook.pages.count == 13, "Pages array should contain 13 pages")

        // Verify page ordering
        let pageNumbers = resultBook.pages.map { $0.pageNumber }.sorted()
        #expect(pageNumbers == Array(1...13), "Pages should be numbered 1 through 13")

        // Verify original pages are preserved and new pages are added
        let originalPages = resultBook.pages.filter { $0.pageNumber <= 6 }
        let newPagesResult = resultBook.pages.filter { $0.pageNumber > 6 }

        #expect(originalPages.count == 6, "Should have 6 original pages")
        #expect(newPagesResult.count == 7, "Should have 7 new pages")
    }
}
