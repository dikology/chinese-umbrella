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
            LoggingService.shared.reading("❌ Invalid page index: \(index)", level: .error)
            throw ReadingError.invalidPageIndex
        }

        LoggingService.shared.reading("📖 Loading page \(index)", level: .info)
        currentPageIndex = index
        let page = book.pages[index]
        currentPage = page
        pageText = page.extractedText

        // Load or segment words for this page
        if page.words.isEmpty {
            LoggingService.shared.reading("✂️ Segmenting text for page \(index) (\(pageText.count) chars)", level: .debug)
            // If no pre-segmented words, perform segmentation
            segmentedWords = try await textSegmentationService.segmentWithPositions(text: pageText)
            LoggingService.shared.reading("✅ Segmented into \(segmentedWords.count) words", level: .debug)
        } else {
            segmentedWords = page.words
            LoggingService.shared.reading("✅ Using cached \(segmentedWords.count) words", level: .debug)
        }

        // Update marked words for this page
        updateMarkedWordsForCurrentPage()

        // Update book progress
        await updateBookProgress()
    }

    /// Navigate to a specific page (primary navigation method)
    /// This is the ONLY method that should change currentPageIndex
    func navigateToPage(_ index: Int) async {
        guard let book = currentBook else {
            LoggingService.shared.reading("⚠️ Cannot navigate: no book loaded", level: .debug)
            return
        }
        
        guard book.pages.indices.contains(index) else {
            LoggingService.shared.reading("⚠️ Cannot navigate to page \(index): out of bounds", level: .debug)
            return
        }
        
        // No-op if already at the target page
        guard index != currentPageIndex else {
            LoggingService.shared.reading("⏭️ Already at page \(index), skipping navigation", level: .debug)
            return
        }
        
        LoggingService.shared.reading("📍 Navigating from page \(currentPageIndex) to \(index)", level: .info)
        
        do {
            try await loadPage(index)
        } catch {
            LoggingService.shared.reading("❌ Failed to navigate to page \(index): \(error.localizedDescription)", level: .error)
            self.error = "Failed to load page: \(error.localizedDescription)"
        }
    }
    
    /// Navigate to next page
    func nextPage() async {
        let nextIndex = currentPageIndex + 1
        await navigateToPage(nextIndex)
    }

    /// Navigate to previous page
    func previousPage() async {
        let prevIndex = currentPageIndex - 1
        await navigateToPage(prevIndex)
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
    
    /// Update progress passively (from scroll position) without triggering navigation
    func updateProgressOnly(pageIndex: Int) async {
        guard let book = currentBook else { return }
        guard book.pages.indices.contains(pageIndex) else { return }
        guard pageIndex != currentPageIndex else { return }
        
        LoggingService.shared.reading("📊 Updating progress to page \(pageIndex) (scroll-based)", level: .info)
        
        // Update state
        currentPageIndex = pageIndex
        currentPage = book.pages[pageIndex]
        
        // Update progress in repository
        await updateBookProgress()
    }
    
    /// Prefetch a page for lazy loading
    func prefetchPage(_ index: Int) async {
        guard let book = currentBook, book.pages.indices.contains(index) else {
            LoggingService.shared.reading("⚠️ Cannot prefetch page \(index): out of bounds", level: .debug)
            return
        }
        
        let page = book.pages[index]
        
        // If page doesn't have segmented words, prefetch them
        if page.words.isEmpty {
            LoggingService.shared.reading("⏳ Prefetching segmentation for page \(index)", level: .debug)
            _ = try? await textSegmentationService.segmentWithPositions(text: page.extractedText)
            LoggingService.shared.reading("✅ Prefetch completed for page \(index)", level: .debug)
        } else {
            LoggingService.shared.reading("⏭️ Page \(index) already segmented, skipping prefetch", level: .debug)
        }
    }
    
    /// Get segmented words for a given text (used by multi-page view)
    func getSegmentedWords(for text: String) async -> [AppWordSegment] {
        do {
            let words = try await textSegmentationService.segmentWithPositions(text: text)
            LoggingService.shared.reading("✂️ Segmented text into \(words.count) words", level: .debug)
            return words
        } catch {
            LoggingService.shared.reading("❌ Failed to segment text: \(error)", level: .error)
            return []
        }
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
