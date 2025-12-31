//
//  WordSegment.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation

/// Represents a segmented word with position information in the text
public struct AppWordSegment: Identifiable, Codable, Hashable {
    public let id: UUID
    public let word: String
    public let pinyin: String?
    public let startIndex: Int // Position in page text
    public let endIndex: Int
    public var isMarked: Bool
    public var definition: DictionaryEntry?

    init(
        id: UUID = UUID(),
        word: String,
        pinyin: String? = nil,
        startIndex: Int,
        endIndex: Int,
        isMarked: Bool = false,
        definition: DictionaryEntry? = nil
    ) {
        self.id = id
        self.word = word
        self.pinyin = pinyin
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.isMarked = isMarked
        self.definition = definition
    }

    // MARK: - Computed Properties

    var length: Int {
        endIndex - startIndex
    }

    var range: Range<Int> {
        startIndex..<endIndex
    }

    var hasDefinition: Bool {
        definition != nil
    }

    // MARK: - Validation

    var isValid: Bool {
        !word.isEmpty && startIndex >= 0 && endIndex > startIndex
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: AppWordSegment, rhs: AppWordSegment) -> Bool {
        lhs.id == rhs.id
    }
}
