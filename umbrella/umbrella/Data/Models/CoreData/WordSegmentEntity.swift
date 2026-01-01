//
//  WordSegmentEntity.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation
import CoreData

/// Core Data entity for WordSegment
@objc(CDWordSegment)
public class CDWordSegment: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var word: String
    @NSManaged public var pinyin: String?
    @NSManaged public var startIndex: Int32
    @NSManaged public var endIndex: Int32
    @NSManaged public var isMarked: Bool

    // Relationships
    @NSManaged public var page: CDBookPage
}

extension CDWordSegment {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDWordSegment> {
        return NSFetchRequest<CDWordSegment>(entityName: "WordSegment")
    }

    // Conversion to domain model
    public func toDomain() -> AppWordSegment {
        AppWordSegment(
            id: id,
            word: word,
            pinyin: pinyin,
            startIndex: Int(startIndex),
            endIndex: Int(endIndex),
            isMarked: isMarked
        )
    }

    // Update from domain model
    func update(from segment: AppWordSegment) {
        word = segment.word
        pinyin = segment.pinyin
        startIndex = Int32(segment.startIndex)
        endIndex = Int32(segment.endIndex)
        isMarked = segment.isMarked
    }
}
