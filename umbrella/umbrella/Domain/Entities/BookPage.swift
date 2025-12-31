//
//  BookPage.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation

/// Represents a single page of a book with OCR text and word segmentation
struct AppBookPage: Identifiable, Codable, Hashable {
    let id: UUID
    let bookId: UUID
    let pageNumber: Int
    let originalImagePath: String // Local file path to original image
    let extractedText: String
    let words: [AppWordSegment] // Segmented words with positions
    let wordsMarked: Set<String> // User-marked words on this page

    init(
        id: UUID = UUID(),
        bookId: UUID,
        pageNumber: Int,
        originalImagePath: String,
        extractedText: String,
        words: [AppWordSegment] = [],
        wordsMarked: Set<String> = []
    ) {
        self.id = id
        self.bookId = bookId
        self.pageNumber = pageNumber
        self.originalImagePath = originalImagePath
        self.extractedText = extractedText
        self.words = words
        self.wordsMarked = wordsMarked
    }

    // MARK: - Computed Properties

    var markedWordsCount: Int {
        wordsMarked.count
    }

    var totalWordsCount: Int {
        words.count
    }

    var hasMarkedWords: Bool {
        !wordsMarked.isEmpty
    }

    // MARK: - Word Operations

    func isWordMarked(_ word: String) -> Bool {
        wordsMarked.contains(word)
    }

    func getMarkedWords() -> [AppWordSegment] {
        words.filter { wordsMarked.contains($0.word) }
    }

    func getUnmarkedWords() -> [AppWordSegment] {
        words.filter { !wordsMarked.contains($0.word) }
    }

    // MARK: - Validation

    var isValid: Bool {
        pageNumber > 0 && !originalImagePath.isEmpty && !extractedText.isEmpty
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AppBookPage, rhs: AppBookPage) -> Bool {
        lhs.id == rhs.id
    }
}
