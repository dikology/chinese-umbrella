//
//  ReadingViewModel.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation
import Observation

/// ViewModel for the Reading screen
/// Manages book loading, page navigation, word selection, and marking
@Observable
final class ReadingViewModel {
    // MARK: - Published Properties

    var currentBook: AppBook?
    var currentPage: AppBookPage?
    var currentPageIndex: Int = 0
    var pageText: String = ""
    var segmentedWords: [AppWordSegment] = []
    var selectedWord: AppWordSegment?
    var dictionaryEntry: DictionaryEntry?
    var markedWordsThisSession: Set<String> = []
    var isLoading = false
    var error: String?

    // MARK: - Private Properties

    private let bookRepository: BookRepository
    private let dictionaryRepository: DictionaryRepository
    private let wordMarkerRepository: WordMarkerRepository
    private let textSegmentationService: TextSegmentationService
    private let userId: UUID
    
    // MARK: - Initialization

    init(
        userId: UUID,
        bookRepository: BookRepository,
        dictionaryRepository: DictionaryRepository,
        wordMarkerRepository: WordMarkerRepository,
        textSegmentationService: TextSegmentationService
    ) {
        self.userId = userId
        self.bookRepository = bookRepository
        self.dictionaryRepository = dictionaryRepository
        self.wordMarkerRepository = wordMarkerRepository
        self.textSegmentationService = textSegmentationService
    }

    // MARK: - Public Methods

    /// Load a book and navigate to its current page
    func loadBook(_ book: AppBook) async {
        isLoading = true
        defer { isLoading = false }

        do {
            currentBook = book
            currentPageIndex = book.currentPageIndex
            try await loadPage(currentPageIndex)
        } catch {
            self.error = "Failed to load book: \(error.localizedDescription)"
        }
    }

    /// Load a specific page by index
    func loadPage(_ index: Int) async throws {
        guard let book = currentBook, book.pages.indices.contains(index) else {
            throw ReadingError.invalidPageIndex
        }

        currentPageIndex = index
        let page = book.pages[index]
        currentPage = page
        pageText = page.extractedText

        // Load or segment words for this page
        if page.words.isEmpty {
            // If no pre-segmented words, perform segmentation
            segmentedWords = try await textSegmentationService.segmentWithPositions(text: pageText)
        } else {
            segmentedWords = page.words
        }

        // Update marked words for this page
        updateMarkedWordsForCurrentPage()

        // Update book progress
        await updateBookProgress()
    }

    /// Navigate to next page
    func nextPage() async {
        guard let book = currentBook, currentPageIndex < book.totalPages - 1 else { return }
        do {
            try await loadPage(currentPageIndex + 1)
        } catch {
            self.error = "Failed to load next page: \(error.localizedDescription)"
        }
    }

    /// Navigate to previous page
    func previousPage() async {
        guard currentPageIndex > 0 else { return }
        do {
            try await loadPage(currentPageIndex - 1)
        } catch {
            self.error = "Failed to load previous page: \(error.localizedDescription)"
        }
    }

    /// Select a word and lookup its definition
    func selectWord(_ word: AppWordSegment) async {
        selectedWord = word

        // Lookup definition
        do {
            if let definition = try await dictionaryRepository.lookup(word: word.word) {
                dictionaryEntry = definition
            } else {
                dictionaryEntry = nil
            }
        } catch {
            dictionaryEntry = nil
            self.error = "Failed to lookup word: \(error.localizedDescription)"
        }
    }

    /// Deselect currently selected word
    func deselectWord() {
        selectedWord = nil
        dictionaryEntry = nil
    }

    /// Mark a word as difficult
    func markWordAsDifficult(_ word: String) async {
        markedWordsThisSession.insert(word)

        // Update local word segments
        if let index = segmentedWords.firstIndex(where: { $0.word == word }) {
            segmentedWords[index].isMarked = true
        }

        // Persist to repository
        do {
            let markedWord = AppMarkedWord(
                userId: userId,
                word: word,
                readingDate: Date(),
                contextSnippet: extractContextSnippet(for: word),
                textId: currentBook?.id ?? UUID(),
                pageNumber: currentPageIndex + 1
            )
            _ = try await wordMarkerRepository.markWord(markedWord)
        } catch {
            self.error = "Failed to mark word: \(error.localizedDescription)"
        }
    }

    /// Unmark a word as difficult
    func unmarkWord(_ word: String) async {
        markedWordsThisSession.remove(word)

        // Update local word segments
        if let index = segmentedWords.firstIndex(where: { $0.word == word }) {
            segmentedWords[index].isMarked = false
        }

        // TODO: Remove from repository when implemented
    }

    /// Check if a word is marked as difficult
    func isWordMarked(_ word: String) -> Bool {
        markedWordsThisSession.contains(word)
    }

    // MARK: - Private Methods

    private func updateMarkedWordsForCurrentPage() {
        guard let page = currentPage else { return }

        // Update segmented words with marked status
        for i in segmentedWords.indices {
            segmentedWords[i].isMarked = page.wordsMarked.contains(segmentedWords[i].word) ||
                                        markedWordsThisSession.contains(segmentedWords[i].word)
        }
    }

    private func extractContextSnippet(for word: String) -> String {
        guard let pageText = currentPage?.extractedText else { return word }

        // Find the word in the text and extract surrounding context
        if let range = pageText.range(of: word) {
            let startIndex = pageText.index(range.lowerBound, offsetBy: -20, limitedBy: pageText.startIndex) ?? pageText.startIndex
            let endIndex = pageText.index(range.upperBound, offsetBy: 20, limitedBy: pageText.endIndex) ?? pageText.endIndex
            let contextRange = startIndex..<endIndex
            return String(pageText[contextRange]).trimmingCharacters(in: .whitespaces)
        }

        return word
    }

    private func updateBookProgress() async {
        guard let book = currentBook else { return }

        // Only update the reading progress, not the entire book structure
        do {
            try await bookRepository.updateReadingProgress(bookId: book.id, pageIndex: currentPageIndex)
        } catch {
            // Log error but don't show to user for progress updates
            LoggingService.shared.reading("Failed to update book progress", level: .error)
        }
    }
}

// MARK: - Reading Errors

enum ReadingError: LocalizedError {
    case invalidPageIndex
    case bookNotLoaded
    case pageNotFound

    var errorDescription: String? {
        switch self {
        case .invalidPageIndex:
            return "Invalid page index"
        case .bookNotLoaded:
            return "Book not loaded"
        case .pageNotFound:
            return "Page not found"
        }
    }
}
