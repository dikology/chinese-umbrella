//
//  Book.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation

/// Book genre classification
public enum BookGenre: String, Codable, CaseIterable {
    case fiction
    case nonFiction
    case biography
    case history
    case science
    case technology
    case literature
    case education
    case business
    case other
}

/// Reading difficulty levels
public enum ReadingDifficulty: String, Codable {
    case beginner
    case intermediate
    case advanced
    case native
}

/// Book statistics for metadata and analytics
public struct BookStatistics: Codable, Hashable {
    public let totalWords: Int
    public let totalPages: Int
    public let readingProgress: Double // 0.0 to 1.0
    public let estimatedReadingTimeMinutes: Int
    public let isCompleted: Bool
    public let currentPage: Int

    public var wordsRead: Int {
        Int(Double(totalWords) * readingProgress)
    }

    public var remainingWords: Int {
        totalWords - wordsRead
    }

    public var estimatedTimeRemainingMinutes: Int {
        Int(Double(estimatedReadingTimeMinutes) * (1.0 - readingProgress))
    }
}

/// Represents a book in the user's library
public struct AppBook: Identifiable, Codable, Hashable {
    public let id: UUID
    public let title: String
    public let author: String?
    public let pages: [AppBookPage]
    public let createdDate: Date
    public var updatedDate: Date
    public var currentPageIndex: Int
    public var isLocal: Bool // true for user-uploaded, false for public library

    // Enhanced metadata for Week 8
    public var language: String? // e.g., "zh-Hans", "zh-Hant", "en"
    public var genre: BookGenre?
    public var description: String?
    public var totalWords: Int?
    public var estimatedReadingTimeMinutes: Int?
    public var difficulty: ReadingDifficulty?
    public var tags: [String]?

    init(
        id: UUID = UUID(),
        title: String,
        author: String? = nil,
        pages: [AppBookPage] = [],
        currentPageIndex: Int = 0,
        isLocal: Bool = true,
        language: String? = nil,
        genre: BookGenre? = nil,
        description: String? = nil,
        totalWords: Int? = nil,
        estimatedReadingTimeMinutes: Int? = nil,
        difficulty: ReadingDifficulty? = nil,
        tags: [String]? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.pages = pages
        self.currentPageIndex = currentPageIndex
        self.isLocal = isLocal
        self.language = language
        self.genre = genre
        self.description = description
        self.totalWords = totalWords
        self.estimatedReadingTimeMinutes = estimatedReadingTimeMinutes
        self.difficulty = difficulty
        self.tags = tags
        self.createdDate = Date()
        self.updatedDate = Date()
    }

    // MARK: - Computed Properties

    var currentPage: AppBookPage? {
        guard pages.indices.contains(currentPageIndex) else { return nil }
        return pages[currentPageIndex]
    }

    var totalPages: Int {
        pages.count
    }

    var readingProgress: Double {
        guard totalPages > 0 else { return 0.0 }
        return Double(currentPageIndex + 1) / Double(totalPages)
    }

    var isCompleted: Bool {
        currentPageIndex >= totalPages - 1
    }

    // MARK: - Enhanced Metadata Properties

    /// Calculate total word count if not explicitly set
    var calculatedTotalWords: Int {
        if let totalWords = totalWords {
            return totalWords
        }
        return pages.reduce(0) { $0 + $1.words.count }
    }

    /// Calculate estimated reading time if not explicitly set (assuming 200 words per minute)
    var calculatedReadingTimeMinutes: Int {
        if let estimatedReadingTimeMinutes = estimatedReadingTimeMinutes {
            return estimatedReadingTimeMinutes
        }
        let wordsPerMinute = 200
        return max(1, calculatedTotalWords / wordsPerMinute)
    }

    /// Determine if book contains Chinese text
    var hasChineseContent: Bool {
        return language?.starts(with: "zh") ?? false ||
               pages.contains { page in
                   page.words.contains { segment in
                       segment.word.range(of: "\\p{Han}", options: .regularExpression) != nil
                   }
               }
    }

    /// Get book statistics
    var statistics: BookStatistics {
        return BookStatistics(
            totalWords: calculatedTotalWords,
            totalPages: totalPages,
            readingProgress: readingProgress,
            estimatedReadingTimeMinutes: calculatedReadingTimeMinutes,
            isCompleted: isCompleted,
            currentPage: currentPageIndex + 1
        )
    }

    // MARK: - Validation

    var isValid: Bool {
        !title.isEmpty && totalPages >= 0 && currentPageIndex >= 0
    }

    // MARK: - Navigation Methods

    mutating func nextPage() -> Bool {
        guard currentPageIndex < totalPages - 1 else { return false }
        currentPageIndex += 1
        updatedDate = Date()
        return true
    }

    mutating func previousPage() -> Bool {
        guard currentPageIndex > 0 else { return false }
        currentPageIndex -= 1
        updatedDate = Date()
        return true
    }

    mutating func goToPage(_ index: Int) -> Bool {
        guard pages.indices.contains(index) else { return false }
        currentPageIndex = index
        updatedDate = Date()
        return true
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: AppBook, rhs: AppBook) -> Bool {
        lhs.id == rhs.id
    }
}
