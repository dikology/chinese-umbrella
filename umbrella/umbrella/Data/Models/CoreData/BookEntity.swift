//
//  BookEntity.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation
import CoreData

/// Core Data entity for Book
@objc(Book)
public class Book: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var author: String?
    @NSManaged public var createdDate: Date
    @NSManaged public var updatedDate: Date
    @NSManaged public var isSynced: Bool
    @NSManaged public var currentPageIndex: Int16
    @NSManaged public var isLocal: Bool

    // Relationships
    @NSManaged public var owner: AppUserEntity
    @NSManaged public var pages: Set<BookPage>
    @NSManaged public var markedWords: Set<MarkedWord>
}

extension Book {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Book> {
        return NSFetchRequest<Book>(entityName: "Book")
    }

    // Computed properties for easier access
    var pagesArray: [BookPage] {
        let set = pages as? Set<BookPage> ?? []
        return set.sorted { $0.pageNumber < $1.pageNumber }
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
    func toDomain() -> AppBook {
        let pages = pagesArray.map { $0.toDomain() }
        return AppBook(
            id: id,
            title: title,
            author: author,
            pages: pages,
            currentPageIndex: Int(currentPageIndex),
            isLocal: isLocal
        )
    }

    // Update from domain model
    func update(from book: AppBook) {
        title = book.title
        author = book.author
        updatedDate = book.updatedDate
        currentPageIndex = Int16(book.currentPageIndex)
        isLocal = book.isLocal
    }
}
