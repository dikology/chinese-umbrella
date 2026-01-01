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

    @Test func testCoreDataModelLoadsSuccessfully() async throws {
        // Test that the CoreData model can be loaded without errors
        let container = CoreDataManager(inMemory: true)
        let context = container.viewContext

        // If we get here without throwing, the model loaded successfully
        #expect(container.container.managedObjectModel.entities.count > 0)
    }

    @Test func testAllCoreDataEntitiesCanBeInstantiated() async throws {
        // Test that all custom NSManagedObject subclasses can be instantiated
        let container = CoreDataManager(inMemory: true)
        let context = container.viewContext

        // Test Book entity
        let book = NSEntityDescription.insertNewObject(forEntityName: "Book", into: context) as? CDBook
        #expect(book != nil, "CDBook entity should be instantiable")
        #expect(book is CDBook, "Book entity should be of type CDBook")

        // Test BookPage entity
        let bookPage = NSEntityDescription.insertNewObject(forEntityName: "BookPage", into: context) as? CDBookPage
        #expect(bookPage != nil, "CDBookPage entity should be instantiable")
        #expect(bookPage is CDBookPage, "BookPage entity should be of type CDBookPage")

        // Test WordSegment entity
        let wordSegment = NSEntityDescription.insertNewObject(forEntityName: "WordSegment", into: context) as? CDWordSegment
        #expect(wordSegment != nil, "CDWordSegment entity should be instantiable")
        #expect(wordSegment is CDWordSegment, "WordSegment entity should be of type CDWordSegment")

        // Test MarkedWord entity
        let markedWord = NSEntityDescription.insertNewObject(forEntityName: "MarkedWord", into: context) as? CDMarkedWord
        #expect(markedWord != nil, "CDMarkedWord entity should be instantiable")
        #expect(markedWord is CDMarkedWord, "MarkedWord entity should be of type CDMarkedWord")

        // Test User entity
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: context) as? UserEntity
        #expect(user != nil, "UserEntity should be instantiable")
        #expect(user is UserEntity, "User entity should be of type UserEntity")

        // Test UserPreferences entity
        let userPreferences = NSEntityDescription.insertNewObject(forEntityName: "UserPreferences", into: context) as? UserPreferences
        #expect(userPreferences != nil, "UserPreferences should be instantiable")
        #expect(userPreferences is UserPreferences, "UserPreferences entity should be of type UserPreferences")
    }

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

    @Test func testCoreDataFetchRequests() async throws {
        // Test that fetch requests work for all entities
        let container = CoreDataManager(inMemory: true)
        let context = container.viewContext

        // Test fetch requests for each entity type
        let entitiesToTest = [
            ("Book", CDBook.self),
            ("BookPage", CDBookPage.self),
            ("WordSegment", CDWordSegment.self),
            ("MarkedWord", CDMarkedWord.self),
            ("User", UserEntity.self),
            ("UserPreferences", UserPreferences.self)
        ]

        for (entityName, entityType) in entitiesToTest {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
            fetchRequest.fetchLimit = 1

            do {
                let results = try context.fetch(fetchRequest)
                // If we get here without throwing, the fetch request worked
                #expect(true, "Fetch request for '\(entityName)' should succeed")
            } catch {
                #expect(false, "Fetch request for '\(entityName)' should not throw error: \(error)")
            }
        }
    }
}
