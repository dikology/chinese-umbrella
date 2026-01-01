//
//  BookEntity.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation
import CoreData

/// Core Data entity for Book
@objc(CDBook)
public class CDBook: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var author: String?
    @NSManaged public var createdDate: Date
    @NSManaged public var updatedDate: Date
    @NSManaged public var isSynced: Bool
    @NSManaged public var currentPageIndex: Int16
    @NSManaged public var isLocal: Bool

    // Enhanced metadata fields (Week 8)
    @NSManaged public var language: String?
    @NSManaged public var genre: String? // Stored as raw value of BookGenre enum
    @NSManaged public var bookDescription: String?
    @NSManaged public var totalWords: Int32 // Optional in model with default value
    @NSManaged public var estimatedReadingTimeMinutes: Int16 // Optional in model with default value
    @NSManaged public var difficulty: String? // Stored as raw value of ReadingDifficulty enum
    @NSManaged public var tagsData: Data? // JSON-encoded array of strings

    // Relationships
    @NSManaged public var owner: UserEntity
    @NSManaged public var pages: Set<CDBookPage>
    @NSManaged public var markedWords: Set<CDMarkedWord>
}

extension CDBook {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDBook> {
        return NSFetchRequest<CDBook>(entityName: "Book")
    }

    // Computed properties for easier access
    var pagesArray: [CDBookPage] {
        return pages.sorted { $0.pageNumber < $1.pageNumber }
    }

    var totalPages: Int {
        pages.count
    }

    var readingProgress: Double {
        guard totalPages > 0 else { return 0.0 }
        return Double(currentPageIndex + 1) / Double(totalPages)
    }

    var isCompleted: Bool {
        Int(currentPageIndex) >= totalPages - 1
    }

    // Conversion to domain model
    public func toDomain() -> AppBook {
        let pages = pagesArray.map { $0.toDomain() }

        // Decode tags from JSON data
        var tags: [String]? = nil
        if let tagsData = tagsData {
            tags = try? JSONDecoder().decode([String].self, from: tagsData)
        }

        return AppBook(
            id: id,
            title: title,
            author: author,
            pages: pages,
            currentPageIndex: Int(currentPageIndex),
            isLocal: isLocal,
            language: language,
            genre: genre.flatMap { BookGenre(rawValue: $0) },
            description: bookDescription,
            totalWords: totalWords > 0 ? Int(totalWords) : nil,
            estimatedReadingTimeMinutes: estimatedReadingTimeMinutes > 0 ? Int(estimatedReadingTimeMinutes) : nil,
            difficulty: difficulty.flatMap { ReadingDifficulty(rawValue: $0) },
            tags: tags
        )
    }

    // Update from domain model
    func update(from book: AppBook) {
        title = book.title
        author = book.author
        updatedDate = book.updatedDate
        currentPageIndex = Int16(book.currentPageIndex)
        isLocal = book.isLocal

        // Update enhanced metadata
        language = book.language
        genre = book.genre?.rawValue
        bookDescription = book.description
        totalWords = Int32(book.totalWords ?? 0)
        estimatedReadingTimeMinutes = Int16(book.estimatedReadingTimeMinutes ?? 0)
        difficulty = book.difficulty?.rawValue

        // Encode tags as JSON data
        if let tags = book.tags {
            tagsData = try? JSONEncoder().encode(tags)
        } else {
            tagsData = nil
        }
    }
}
