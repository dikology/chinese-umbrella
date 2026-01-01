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

    func saveBook(_ book: AppBook, userId: UUID) async throws -> AppBook {
        let context = coreDataManager.viewContext

        return try await context.perform {
            // Check if book already exists
            let fetchRequest = CDBook.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
            fetchRequest.fetchLimit = 1

            let existingBook = try context.fetch(fetchRequest).first

            let bookEntity: CDBook
            if let existingBook = existingBook {
                // Update existing book
                existingBook.update(from: book)
                bookEntity = existingBook
            } else {
                // Create new book
                bookEntity = CDBook(context: context)
                bookEntity.id = book.id
                bookEntity.createdDate = book.createdDate
                bookEntity.update(from: book)

                // Set owner relationship
                let userFetchRequest = UserEntity.fetchRequest()
                userFetchRequest.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
                userFetchRequest.fetchLimit = 1

                if let userEntity = try context.fetch(userFetchRequest).first {
                    bookEntity.owner = userEntity
                } else {
                    throw BookRepositoryError.saveFailed
                }
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
            let fetchRequest = CDBook.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1

            let bookEntity = try context.fetch(fetchRequest).first
            return bookEntity?.toDomain()
        }
    }

    func getBooks(for userId: UUID) async throws -> [AppBook] {
        let context = coreDataManager.viewContext

        return try await context.perform {
            let fetchRequest = CDBook.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "owner.id == %@", userId as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedDate", ascending: false)]

            let bookEntities = try context.fetch(fetchRequest)
            return bookEntities.map { $0.toDomain() }
        }
    }

    func updateBook(_ book: AppBook) async throws -> AppBook {
        let context = coreDataManager.viewContext

        return try await context.perform {
            // Get the existing book
            let fetchRequest = CDBook.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
            fetchRequest.fetchLimit = 1

            guard let existingBook = try context.fetch(fetchRequest).first else {
                throw BookRepositoryError.bookNotFound
            }

            // Update the existing book
            existingBook.update(from: book)

            // Save pages (inline the savePages logic)
            try self.savePagesInline(book.pages, for: existingBook, in: context)

            try context.save()
            return existingBook.toDomain()
        }
    }

    // MARK: - Inline Helper Methods

    private func savePagesInline(_ pages: [AppBookPage], for bookEntity: CDBook, in context: NSManagedObjectContext) throws {
        // Remove existing pages
        for page in bookEntity.pages {
            context.delete(page)
        }

        // Create new pages
        for page in pages {
            let pageEntity = CDBookPage(context: context)
            pageEntity.id = page.id
            pageEntity.book = bookEntity
            pageEntity.createdAt = Date()
            pageEntity.update(from: page)

            // Save word segments
            try saveWordSegmentsInline(page.words, for: pageEntity, in: context)
        }
    }

    private func saveWordSegmentsInline(_ segments: [AppWordSegment], for pageEntity: CDBookPage, in context: NSManagedObjectContext) throws {
        for segment in segments {
            let segmentEntity = CDWordSegment(context: context)
            segmentEntity.id = segment.id
            segmentEntity.page = pageEntity
            segmentEntity.update(from: segment)
        }
    }

    func deleteBook(_ bookId: UUID) async throws {
        let context = coreDataManager.viewContext

        try await context.perform {
            let fetchRequest = CDBook.fetchRequest()
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
            let fetchRequest = CDBook.fetchRequest()
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
            let fetchRequest = CDBook.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "owner.id == %@", userId as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedDate", ascending: false)]
            fetchRequest.fetchLimit = limit

            let bookEntities = try context.fetch(fetchRequest)
            return bookEntities.map { $0.toDomain() }
        }
    }

    func searchBooksWithFilters(query: String?, filters: BookSearchFilters, userId: UUID) async throws -> [AppBook] {
        let context = coreDataManager.viewContext

        return try await context.perform {
            var predicates: [NSPredicate] = []

            // Base predicate for user ownership
            predicates.append(NSPredicate(format: "owner.id == %@", userId as CVarArg))

            // Text search predicate
            if let query = query, !query.isEmpty {
                let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
                let authorPredicate = NSPredicate(format: "author CONTAINS[cd] %@", query)
                let descriptionPredicate = NSPredicate(format: "bookDescription CONTAINS[cd] %@", query)
                predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, authorPredicate, descriptionPredicate]))
            }

            // Genre filter
            if let genres = filters.genres, !genres.isEmpty {
                let genrePredicates = genres.map { NSPredicate(format: "genre == %@", $0.rawValue) }
                predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: genrePredicates))
            }

            // Language filter
            if let languages = filters.languages, !languages.isEmpty {
                let languagePredicates = languages.map { NSPredicate(format: "language == %@", $0) }
                predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: languagePredicates))
            }

            // Difficulty filter
            if let difficulties = filters.difficulties, !difficulties.isEmpty {
                let difficultyPredicates = difficulties.map { NSPredicate(format: "difficulty == %@", $0.rawValue) }
                predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: difficultyPredicates))
            }

            // Word count filters
            if let minWords = filters.minWordCount {
                predicates.append(NSPredicate(format: "totalWords >= %d", minWords))
            }
            if let maxWords = filters.maxWordCount {
                predicates.append(NSPredicate(format: "totalWords <= %d", maxWords))
            }

            let fetchRequest = CDBook.fetchRequest()
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedDate", ascending: false)]

            let bookEntities = try context.fetch(fetchRequest)
            return bookEntities.map { $0.toDomain() }
        }
    }

    func getBooksByGenre(_ genre: BookGenre, userId: UUID) async throws -> [AppBook] {
        let context = coreDataManager.viewContext

        return try await context.perform {
            let fetchRequest = CDBook.fetchRequest()
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "owner.id == %@", userId as CVarArg),
                NSPredicate(format: "genre == %@", genre.rawValue)
            ])
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedDate", ascending: false)]

            let bookEntities = try context.fetch(fetchRequest)
            return bookEntities.map { $0.toDomain() }
        }
    }

    func getBooksByLanguage(_ language: String, userId: UUID) async throws -> [AppBook] {
        let context = coreDataManager.viewContext

        return try await context.perform {
            let fetchRequest = CDBook.fetchRequest()
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "owner.id == %@", userId as CVarArg),
                NSPredicate(format: "language == %@", language)
            ])
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedDate", ascending: false)]

            let bookEntities = try context.fetch(fetchRequest)
            return bookEntities.map { $0.toDomain() }
        }
    }

    func getBooksByProgressStatus(_ status: ReadingProgressStatus, userId: UUID) async throws -> [AppBook] {
        let context = coreDataManager.viewContext

        return try await context.perform {
            let fetchRequest = CDBook.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "owner.id == %@", userId as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedDate", ascending: false)]

            let bookEntities = try context.fetch(fetchRequest)
            let filteredBooks = bookEntities.map { $0.toDomain() }.filter { book in
                switch status {
                case .notStarted:
                    return book.readingProgress == 0.0
                case .inProgress:
                    return book.readingProgress > 0.0 && book.readingProgress < 1.0
                case .completed:
                    return book.isCompleted
                }
            }

            return filteredBooks
        }
    }

    func getLibraryStatistics(userId: UUID) async throws -> LibraryStatistics {
        let context = coreDataManager.viewContext

        return try await context.perform {
            let fetchRequest = CDBook.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "owner.id == %@", userId as CVarArg)

            let bookEntities = try context.fetch(fetchRequest)
            let books = bookEntities.map { $0.toDomain() }

            let totalBooks = books.count
            let totalWords = books.reduce(0) { $0 + $1.calculatedTotalWords }
            let totalReadingTime = books.reduce(0) { $0 + $1.calculatedReadingTimeMinutes }
            let completedBooks = books.filter { $0.isCompleted }.count

            // Calculate books by genre
            var booksByGenre: [BookGenre: Int] = [:]
            for book in books {
                if let genre = book.genre {
                    booksByGenre[genre, default: 0] += 1
                }
            }

            // Calculate books by language
            var booksByLanguage: [String: Int] = [:]
            for book in books {
                if let language = book.language {
                    booksByLanguage[language, default: 0] += 1
                }
            }

            let averageReadingProgress = books.isEmpty ? 0.0 : books.reduce(0.0) { $0 + $1.readingProgress } / Double(books.count)

            return LibraryStatistics(
                totalBooks: totalBooks,
                totalWords: totalWords,
                totalReadingTimeMinutes: totalReadingTime,
                completedBooks: completedBooks,
                booksByGenre: booksByGenre,
                booksByLanguage: booksByLanguage,
                averageReadingProgress: averageReadingProgress
            )
        }
    }

    func updateReadingProgress(bookId: UUID, pageIndex: Int) async throws {
        let context = coreDataManager.viewContext

        try await context.perform {
            let fetchRequest = CDBook.fetchRequest()
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

    private func savePages(_ pages: [AppBookPage], for bookEntity: CDBook, in context: NSManagedObjectContext) throws {
        // Remove existing pages
        for page in bookEntity.pages {
            context.delete(page)
        }

        // Create new pages
        for page in pages {
            let pageEntity = CDBookPage(context: context)
            pageEntity.id = page.id
            pageEntity.book = bookEntity
            pageEntity.createdAt = Date()
            pageEntity.update(from: page)

            // Save word segments
            try saveWordSegments(page.words, for: pageEntity, in: context)
        }
    }

    private func saveWordSegments(_ segments: [AppWordSegment], for pageEntity: CDBookPage, in context: NSManagedObjectContext) throws {
        for segment in segments {
            let segmentEntity = CDWordSegment(context: context)
            segmentEntity.id = segment.id
            segmentEntity.page = pageEntity
            segmentEntity.update(from: segment)
        }
    }
}
