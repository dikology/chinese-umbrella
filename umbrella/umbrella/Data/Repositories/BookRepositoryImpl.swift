//
//  BookRepositoryImpl.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation
import CoreData

/// Core Data implementation of BookRepository
class BookRepositoryImpl: BookRepository {
    private let coreDataManager: CoreDataManager

    init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
    }

    func saveBook(_ book: AppBook) async throws -> AppBook {
        let context = coreDataManager.viewContext

        return try await context.perform {
            // Check if book already exists
            let fetchRequest = Book.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
            fetchRequest.fetchLimit = 1

            let existingBook = try context.fetch(fetchRequest).first

            let bookEntity: Book
            if let existingBook = existingBook {
                // Update existing book
                existingBook.update(from: book)
                bookEntity = existingBook
            } else {
                // Create new book
                bookEntity = Book(context: context)
                bookEntity.id = book.id
                bookEntity.createdDate = book.createdDate
                bookEntity.update(from: book)

                // Set owner relationship (assuming we have a current user)
                // For now, we'll need to set this when we have user context
            }

            // Save pages
            try self.savePages(book.pages, for: bookEntity, in: context)

            try context.save()
            return bookEntity.toDomain()
        }
    }

    func getBook(by id: UUID) async throws -> AppBook? {
        let context = coreDataManager.viewContext

        return try await context.perform {
            let fetchRequest = Book.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            let bookEntity = try context.fetch(fetchRequest).first
            return bookEntity?.toDomain()
        }
    }

    func getBooks(for userId: UUID) async throws -> [AppBook] {
        let context = coreDataManager.viewContext

        return try await context.perform {
            let fetchRequest = Book.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "owner.id == %@", userId as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedDate", ascending: false)]

            let bookEntities = try context.fetch(fetchRequest)
            return bookEntities.map { $0.toDomain() }
        }
    }

    func updateBook(_ book: AppBook) async throws -> AppBook {
        return try await saveBook(book)
    }

    func deleteBook(_ bookId: UUID) async throws {
        let context = coreDataManager.viewContext

        try await context.perform {
            let fetchRequest = Book.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", bookId as CVarArg)
            fetchRequest.fetchLimit = 1

            if let bookEntity = try context.fetch(fetchRequest).first {
                context.delete(bookEntity)
                try context.save()
            }
        }
    }

    func searchBooks(query: String, userId: UUID) async throws -> [AppBook] {
        let context = coreDataManager.viewContext

        return try await context.perform {
            let fetchRequest = Book.fetchRequest()
            let userPredicate = NSPredicate(format: "owner.id == %@", userId as CVarArg)
            let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
            let authorPredicate = NSPredicate(format: "author CONTAINS[cd] %@", query)
            let searchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, authorPredicate])
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [userPredicate, searchPredicate])
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedDate", ascending: false)]

            let bookEntities = try context.fetch(fetchRequest)
            return bookEntities.map { $0.toDomain() }
        }
    }

    func getRecentBooks(for userId: UUID, limit: Int = 10) async throws -> [AppBook] {
        let context = coreDataManager.viewContext

        return try await context.perform {
            let fetchRequest = Book.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "owner.id == %@", userId as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedDate", ascending: false)]
            fetchRequest.fetchLimit = limit

            let bookEntities = try context.fetch(fetchRequest)
            return bookEntities.map { $0.toDomain() }
        }
    }

    func updateReadingProgress(bookId: UUID, pageIndex: Int) async throws {
        let context = coreDataManager.viewContext

        try await context.perform {
            let fetchRequest = Book.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", bookId as CVarArg)
            fetchRequest.fetchLimit = 1

            if let bookEntity = try context.fetch(fetchRequest).first {
                bookEntity.currentPageIndex = Int16(pageIndex)
                bookEntity.updatedDate = Date()
                try context.save()
            }
        }
    }

    // MARK: - Private Methods

    private func savePages(_ pages: [AppBookPage], for bookEntity: Book, in context: NSManagedObjectContext) throws {
        // Remove existing pages
        if let existingPages = bookEntity.pages as? Set<BookPage> {
            for page in existingPages {
                context.delete(page)
            }
        }

        // Create new pages
        for page in pages {
            let pageEntity = BookPage(context: context)
            pageEntity.id = page.id
            pageEntity.book = bookEntity
            pageEntity.createdAt = Date()
            pageEntity.update(from: page)

            // Save word segments
            try saveWordSegments(page.words, for: pageEntity, in: context)
        }
    }

    private func saveWordSegments(_ segments: [AppWordSegment], for pageEntity: BookPage, in context: NSManagedObjectContext) throws {
        for segment in segments {
            let segmentEntity = WordSegment(context: context)
            segmentEntity.id = segment.id
            segmentEntity.page = pageEntity
            segmentEntity.update(from: segment)
        }
    }
}
