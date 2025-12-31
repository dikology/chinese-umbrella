//
//  BookPageEntity.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation
import CoreData

/// Core Data entity for BookPage
@objc(BookPage)
public class CDBookPage: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var pageNumber: Int16
    @NSManaged public var extractedText: String
    @NSManaged public var imageFilePath: String
    @NSManaged public var createdAt: Date
    @NSManaged public var isSynced: Bool

    // Relationships
    @NSManaged public var book: CDBook
    @NSManaged public var wordSegments: Set<CDWordSegment>
    @NSManaged public var markedWordsOnPage: Set<CDMarkedWord>
}

extension CDBookPage {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDBookPage> {
        return NSFetchRequest<CDBookPage>(entityName: "BookPage")
    }

    // Computed properties
    var wordSegmentsArray: [CDWordSegment] {
        return wordSegments.sorted { $0.startIndex < $1.startIndex }
    }

    var markedWordsArray: [CDMarkedWord] {
        return Array(markedWordsOnPage)
    }

    var markedWordsCount: Int {
        markedWordsOnPage.count
    }

    var wordsMarked: Set<String> {
        Set(markedWordsOnPage.map { $0.word })
    }

    // Conversion to domain model
    public func toDomain() -> AppBookPage {
        let words = wordSegmentsArray.map { $0.toDomain() }
        return AppBookPage(
            id: id,
            bookId: book.id,
            pageNumber: Int(pageNumber),
            originalImagePath: imageFilePath,
            extractedText: extractedText,
            words: words,
            wordsMarked: wordsMarked
        )
    }

    // Update from domain model
    func update(from page: AppBookPage) {
        pageNumber = Int16(page.pageNumber)
        extractedText = page.extractedText
        imageFilePath = page.originalImagePath
        // Note: words and wordsMarked relationships would need to be updated separately
    }
}
