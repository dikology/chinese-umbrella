//
//  MarkedWordEntity.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation
import CoreData

/// Core Data entity for MarkedWord
@objc(CDMarkedWord)
public class CDMarkedWord: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var word: String
    @NSManaged public var readingDate: Date
    @NSManaged public var contextSnippet: String
    @NSManaged public var pageNumber: Int16
    @NSManaged public var isSynced: Bool
    @NSManaged public var markedCount: Int16

    // Relationships
    @NSManaged public var user: UserEntity
    @NSManaged public var book: CDBook
    @NSManaged public var page: CDBookPage
}

extension CDMarkedWord {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDMarkedWord> {
        return NSFetchRequest<CDMarkedWord>(entityName: "MarkedWord")
    }

    // Conversion to domain model
    public func toDomain() -> AppMarkedWord {
        AppMarkedWord(
            id: id,
            userId: user.id ?? UUID(), // Handle optional id with fallback
            word: word,
            readingDate: readingDate,
            contextSnippet: contextSnippet,
            textId: book.id ?? UUID(), // Handle optional id with fallback
            pageNumber: Int(pageNumber),
            markedCount: Int(markedCount)
        )
    }

    // Update from domain model
    func update(from markedWord: AppMarkedWord) {
        word = markedWord.word
        readingDate = markedWord.readingDate
        contextSnippet = markedWord.contextSnippet
        pageNumber = Int16(markedWord.pageNumber)
        markedCount = Int16(markedWord.markedCount)
    }
}
