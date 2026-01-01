//
//  MarkedWord.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation

/// Represents a word marked as difficult by the user
public struct AppMarkedWord: Identifiable, Codable, Hashable {
    public let id: UUID
    public let userId: UUID
    public let word: String
    public let readingDate: Date
    public let contextSnippet: String // Surrounding text for context
    public let textId: UUID // Book ID
    public let pageNumber: Int
    public var markedCount: Int // How many times this word has been marked

    init(
        id: UUID = UUID(),
        userId: UUID,
        word: String,
        readingDate: Date = Date(),
        contextSnippet: String,
        textId: UUID,
        pageNumber: Int,
        markedCount: Int = 1
    ) {
        self.id = id
        self.userId = userId
        self.word = word
        self.readingDate = readingDate
        self.contextSnippet = contextSnippet
        self.textId = textId
        self.pageNumber = pageNumber
        self.markedCount = markedCount
    }

    // MARK: - Computed Properties

    var isRecentlyMarked: Bool {
        let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        return readingDate > oneWeekAgo
    }

    var isFrequentlyMarked: Bool {
        markedCount >= 3
    }

    // MARK: - Methods

    mutating func incrementMarkCount() {
        markedCount += 1
    }

    // MARK: - Validation

    var isValid: Bool {
        !word.isEmpty && !contextSnippet.isEmpty && pageNumber > 0
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: AppMarkedWord, rhs: AppMarkedWord) -> Bool {
        lhs.id == rhs.id
    }
}

/// Session tracking for reading analytics
struct ReadingSession: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let bookId: UUID
    let startTime: Date
    var endTime: Date?
    var wordsMarked: Int
    var pagesRead: Int
    var sessionDuration: TimeInterval?

    init(
        id: UUID = UUID(),
        userId: UUID,
        bookId: UUID,
        startTime: Date = Date(),
        wordsMarked: Int = 0,
        pagesRead: Int = 0
    ) {
        self.id = id
        self.userId = userId
        self.bookId = bookId
        self.startTime = startTime
        self.wordsMarked = wordsMarked
        self.pagesRead = pagesRead
    }

    // MARK: - Computed Properties

    var isActive: Bool {
        endTime == nil
    }

    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    // MARK: - Methods

    mutating func endSession() {
        endTime = Date()
        sessionDuration = duration
    }

    mutating func markWord() {
        wordsMarked += 1
    }

    mutating func readPage() {
        pagesRead += 1
    }
}
