//
//  ReadingViewModelTests.swift
//  umbrellaTests
//
//  Created by Cursor on 07.01.2026.
//

import Testing
import Foundation
@testable import umbrella

struct ReadingViewModelTests {
    private var mockBookRepository: ReadingMockBookRepository!
    private var mockDictionaryRepository: MockDictionaryRepository!
    private var mockWordMarkerRepository: MockWordMarkerRepository!
    private var mockTextSegmentationService: ReadingMockTextSegmentationService!
    private var testUserId: UUID!
    
    init() {
        mockBookRepository = ReadingMockBookRepository()
        mockDictionaryRepository = MockDictionaryRepository()
        mockWordMarkerRepository = MockWordMarkerRepository()
        mockTextSegmentationService = ReadingMockTextSegmentationService()
        testUserId = UUID()
    }
    
    // MARK: - Helper Methods
    
    private func createViewModel() -> ReadingViewModel {
        return ReadingViewModel(
            userId: testUserId,
            bookRepository: mockBookRepository,
            dictionaryRepository: mockDictionaryRepository,
            wordMarkerRepository: mockWordMarkerRepository,
            textSegmentationService: mockTextSegmentationService
        )
    }
    
    private func createTestBook(pageCount: Int = 5) -> AppBook {
        let pages = (0..<pageCount).map { index in
            AppBookPage(
                bookId: UUID(),
                pageNumber: index + 1,
                originalImagePath: "/path/to/page\(index + 1).jpg",
                extractedText: "这是第\(index + 1)页的内容。",
                words: createTestWords(for: index),
                wordsMarked: []
            )
        }
        
        return AppBook(
            title: "Test Book",
            author: "Test Author",
            pages: pages,
            currentPageIndex: 0
        )
    }
    
    private func createTestWords(for pageIndex: Int) -> [AppWordSegment] {
        return [
            AppWordSegment(word: "这是", startIndex: 0, endIndex: 2, isMarked: false),
            AppWordSegment(word: "第\(pageIndex + 1)页", startIndex: 2, endIndex: 6, isMarked: false),
            AppWordSegment(word: "的", startIndex: 6, endIndex: 7, isMarked: false),
            AppWordSegment(word: "内容", startIndex: 7, endIndex: 9, isMarked: false)
        ]
    }
    
    // MARK: - Initialization Tests
    
    @Test("ReadingViewModel initializes with correct default values")
    func testInitialization() {
        // When
        let viewModel = createViewModel()
        
        // Then
        #expect(viewModel.currentBook == nil)
        #expect(viewModel.currentPage == nil)
        #expect(viewModel.currentPageIndex == 0)
        #expect(viewModel.pageText == "")
        #expect(viewModel.segmentedWords.isEmpty)
        #expect(viewModel.selectedWord == nil)
        #expect(viewModel.dictionaryEntry == nil)
        #expect(viewModel.markedWordsThisSession.isEmpty)
        #expect(!viewModel.isLoading)
        #expect(viewModel.error == nil)
    }
    
    // MARK: - Book Loading Tests
    
    @Test("Load book sets current book and page correctly")
    func testLoadBook() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 3)
        
        // When
        await viewModel.loadBook(book)
        
        // Then
        #expect(viewModel.currentBook?.id == book.id)
        #expect(viewModel.currentPageIndex == 0)
        #expect(viewModel.currentPage?.pageNumber == 1)
        #expect(!viewModel.isLoading)
    }
    
    @Test("Load book with custom starting page index")
    func testLoadBookWithCustomStartIndex() async {
        // Given
        let viewModel = createViewModel()
        var book = createTestBook(pageCount: 5)
        book.currentPageIndex = 2 // Start at page 3
        
        // When
        await viewModel.loadBook(book)
        
        // Then
        #expect(viewModel.currentPageIndex == 2)
        #expect(viewModel.currentPage?.pageNumber == 3)
    }
    
    // MARK: - Page Navigation Tests
    
    @Test("Navigate to next page updates index correctly")
    func testNextPage() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 5)
        await viewModel.loadBook(book)
        
        // When
        await viewModel.nextPage()
        
        // Then
        #expect(viewModel.currentPageIndex == 1)
        #expect(viewModel.currentPage?.pageNumber == 2)
    }
    
    @Test("Navigate to previous page updates index correctly")
    func testPreviousPage() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 5)
        await viewModel.loadBook(book)
        await viewModel.nextPage()
        await viewModel.nextPage()
        
        // When
        await viewModel.previousPage()
        
        // Then
        #expect(viewModel.currentPageIndex == 1)
        #expect(viewModel.currentPage?.pageNumber == 2)
    }
    
    @Test("Cannot navigate to next page when at last page")
    func testCannotGoNextAtLastPage() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 3)
        await viewModel.loadBook(book)
        await viewModel.nextPage()
        await viewModel.nextPage()
        
        #expect(viewModel.currentPageIndex == 2) // At last page
        
        // When
        await viewModel.nextPage()
        
        // Then - should stay at last page
        #expect(viewModel.currentPageIndex == 2)
    }
    
    @Test("Cannot navigate to previous page when at first page")
    func testCannotGoPreviousAtFirstPage() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 3)
        await viewModel.loadBook(book)
        
        #expect(viewModel.currentPageIndex == 0) // At first page
        
        // When
        await viewModel.previousPage()
        
        // Then - should stay at first page
        #expect(viewModel.currentPageIndex == 0)
    }
    
    // MARK: - Prefetch Tests
    
    @Test("Prefetch page loads segmentation for unsegmented pages")
    func testPrefetchPageWithUnsegmentedText() async {
        // Given
        let viewModel = createViewModel()
        let pages = [
            AppBookPage(
                bookId: UUID(),
                pageNumber: 1,
                originalImagePath: "/path/page1.jpg",
                extractedText: "未分词的文本",
                words: [], // No pre-segmented words
                wordsMarked: []
            ),
            AppBookPage(
                bookId: UUID(),
                pageNumber: 2,
                originalImagePath: "/path/page2.jpg",
                extractedText: "另一段文本",
                words: [], // No pre-segmented words
                wordsMarked: []
            )
        ]
        let book = AppBook(title: "Test", pages: pages)
        await viewModel.loadBook(book)
        
        let initialCallCount = mockTextSegmentationService.segmentCallCount
        
        // When
        await viewModel.prefetchPage(1)
        
        // Then - should call segmentation service
        #expect(mockTextSegmentationService.segmentCallCount == initialCallCount + 1)
    }
    
    @Test("Prefetch page skips already segmented pages")
    func testPrefetchPageWithAlreadySegmentedText() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 3)
        await viewModel.loadBook(book)
        
        let initialCallCount = mockTextSegmentationService.segmentCallCount
        
        // When - prefetch page that already has words
        await viewModel.prefetchPage(1)
        
        // Then - should not call segmentation service
        #expect(mockTextSegmentationService.segmentCallCount == initialCallCount)
    }
    
    @Test("Prefetch invalid page index is handled gracefully")
    func testPrefetchInvalidPageIndex() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 3)
        await viewModel.loadBook(book)
        
        // When - prefetch invalid index
        await viewModel.prefetchPage(10)
        
        // Then - should not crash and state should remain unchanged
        #expect(viewModel.currentPageIndex == 0)
    }
    
    // MARK: - Get Segmented Words Tests
    
    @Test("Get segmented words returns words successfully")
    func testGetSegmentedWords() async {
        // Given
        let viewModel = createViewModel()
        mockTextSegmentationService.mockWords = [
            AppWordSegment(word: "测试", startIndex: 0, endIndex: 2, isMarked: false),
            AppWordSegment(word: "文本", startIndex: 2, endIndex: 4, isMarked: false)
        ]
        
        // When
        let words = await viewModel.getSegmentedWords(for: "测试文本")
        
        // Then
        #expect(words.count == 2)
        #expect(words[0].word == "测试")
        #expect(words[1].word == "文本")
    }
    
    @Test("Get segmented words handles errors gracefully")
    func testGetSegmentedWordsWithError() async {
        // Given
        let viewModel = createViewModel()
        mockTextSegmentationService.shouldThrowError = true
        
        // When
        let words = await viewModel.getSegmentedWords(for: "测试文本")
        
        // Then - should return empty array
        #expect(words.isEmpty)
    }
    
    // MARK: - Computed Properties Tests
    
    @Test("canGoPrevious returns correct values")
    func testCanGoPrevious() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 3)
        await viewModel.loadBook(book)
        
        // At first page
        #expect(!viewModel.canGoPrevious)
        
        // Move to second page
        await viewModel.nextPage()
        #expect(viewModel.canGoPrevious)
    }
    
    @Test("canGoNext returns correct values")
    func testCanGoNext() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 3)
        await viewModel.loadBook(book)
        
        // At first page
        #expect(viewModel.canGoNext)
        
        // Move to last page
        await viewModel.nextPage()
        await viewModel.nextPage()
        #expect(!viewModel.canGoNext)
    }
    
    @Test("isLastPage returns correct values")
    func testIsLastPage() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 3)
        await viewModel.loadBook(book)
        
        // At first page
        #expect(!viewModel.isLastPage)
        
        // Move to last page
        await viewModel.nextPage()
        await viewModel.nextPage()
        #expect(viewModel.isLastPage)
    }
    
    @Test("totalPages returns correct count")
    func testTotalPages() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 7)
        await viewModel.loadBook(book)
        
        // Then
        #expect(viewModel.totalPages == 7)
    }
    
    // MARK: - Navigation Edge Cases Tests (Catches Scrolling Bugs)
    
    @Test("Navigating to same page is a no-op")
    func testNavigateToSamePageIsNoOp() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 5)
        await viewModel.loadBook(book)
        await viewModel.navigateToPage(2)
        
        let updateCountBefore = mockBookRepository.updateProgressCallCount
        
        // When - navigate to same page
        await viewModel.navigateToPage(2)
        
        // Then - should not trigger repository update
        #expect(viewModel.currentPageIndex == 2)
        #expect(mockBookRepository.updateProgressCallCount == updateCountBefore)
    }
    
    @Test("Rapid consecutive navigation calls handle correctly")
    func testRapidConsecutiveNavigation() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 10)
        await viewModel.loadBook(book)
        
        // When - rapid navigation (simulates rapid button taps)
        await viewModel.navigateToPage(1)
        await viewModel.navigateToPage(2)
        await viewModel.navigateToPage(3)
        await viewModel.navigateToPage(4)
        
        // Then - should end up at page 4 with all updates applied
        #expect(viewModel.currentPageIndex == 4)
        #expect(viewModel.currentPage?.pageNumber == 5)
    }
    
    @Test("Interleaved forward and backward navigation")
    func testInterleavedNavigation() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 10)
        await viewModel.loadBook(book)
        
        // When - mix forward and backward navigation
        await viewModel.nextPage() // 0 -> 1
        await viewModel.previousPage() // 1 -> 0
        await viewModel.nextPage() // 0 -> 1
        await viewModel.nextPage() // 1 -> 2
        await viewModel.previousPage() // 2 -> 1
        
        // Then - should be at page 1
        #expect(viewModel.currentPageIndex == 1)
        #expect(viewModel.currentPage?.pageNumber == 2)
    }
    
    @Test("Navigation with duplicate calls (catches race conditions)")
    func testNavigationWithDuplicateCalls() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 10)
        await viewModel.loadBook(book)
        
        // When - navigate with duplicates
        await viewModel.navigateToPage(3)
        await viewModel.navigateToPage(3) // Duplicate
        await viewModel.navigateToPage(3) // Duplicate
        await viewModel.navigateToPage(5)
        await viewModel.navigateToPage(5) // Duplicate
        
        // Then - should be at page 5
        #expect(viewModel.currentPageIndex == 5)
        
        // Should only have 2 unique navigations (0->3, 3->5) plus initial load
        // Duplicates should be no-ops
        #expect(mockBookRepository.updateProgressCallCount == 3) // Load + 2 navigations
    }
    
    @Test("Navigate to invalid page index is rejected")
    func testNavigateToInvalidIndex() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 5)
        await viewModel.loadBook(book)
        
        // When - try to navigate to invalid indices
        await viewModel.navigateToPage(-1) // Below bounds
        #expect(viewModel.currentPageIndex == 0)
        
        await viewModel.navigateToPage(10) // Above bounds
        #expect(viewModel.currentPageIndex == 0)
        
        await viewModel.navigateToPage(100) // Way above bounds
        #expect(viewModel.currentPageIndex == 0)
    }
    
    @Test("Navigate without loaded book is rejected")
    func testNavigateWithoutBook() async {
        // Given
        let viewModel = createViewModel()
        // No book loaded
        
        // When - try to navigate
        await viewModel.navigateToPage(5)
        
        // Then - should remain at default state
        #expect(viewModel.currentPageIndex == 0)
        #expect(viewModel.currentBook == nil)
    }
    
    @Test("Rapid button tapping (catches stuck flag issue)")
    func testRapidButtonTapping() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 20)
        await viewModel.loadBook(book)
        
        // When - simulate rapid next button tapping
        for _ in 0..<10 {
            await viewModel.nextPage()
        }
        
        // Then - should be at page 10, not stuck
        #expect(viewModel.currentPageIndex == 10)
        #expect(viewModel.canGoNext) // Should still be able to go next
        #expect(viewModel.canGoPrevious) // Should be able to go previous
    }
    
    @Test("Navigation to boundaries handles correctly")
    func testNavigationToBoundaries() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 5)
        await viewModel.loadBook(book)
        
        // When - navigate to last page
        await viewModel.navigateToPage(4)
        #expect(viewModel.currentPageIndex == 4)
        #expect(viewModel.isLastPage)
        
        // Try to go next (should be no-op)
        await viewModel.nextPage()
        #expect(viewModel.currentPageIndex == 4) // Still at last page
        
        // Navigate to first page
        await viewModel.navigateToPage(0)
        #expect(viewModel.currentPageIndex == 0)
        
        // Try to go previous (should be no-op)
        await viewModel.previousPage()
        #expect(viewModel.currentPageIndex == 0) // Still at first page
    }
    
    @Test("Large jumps in page navigation work correctly")
    func testLargePageJumps() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 100)
        await viewModel.loadBook(book)
        
        // When - make large jumps
        await viewModel.navigateToPage(50)
        #expect(viewModel.currentPageIndex == 50)
        
        await viewModel.navigateToPage(10)
        #expect(viewModel.currentPageIndex == 10)
        
        await viewModel.navigateToPage(90)
        #expect(viewModel.currentPageIndex == 90)
        
        await viewModel.navigateToPage(0)
        #expect(viewModel.currentPageIndex == 0)
    }
    
    @Test("Sequential page navigation maintains state correctly")
    func testSequentialPageNavigation() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 10)
        await viewModel.loadBook(book)
        
        // When - navigate sequentially through all pages
        for pageIndex in 0..<10 {
            await viewModel.navigateToPage(pageIndex)
            #expect(viewModel.currentPageIndex == pageIndex)
            #expect(viewModel.currentPage?.pageNumber == pageIndex + 1)
        }
        
        // Then - should be at last page
        #expect(viewModel.isLastPage)
    }
    
    @Test("Mixed navigation methods produce consistent results")
    func testMixedNavigationMethods() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 15)
        await viewModel.loadBook(book)
        
        // When - mix different navigation methods
        await viewModel.nextPage() // 0 -> 1
        #expect(viewModel.currentPageIndex == 1)
        
        await viewModel.navigateToPage(5) // 1 -> 5
        #expect(viewModel.currentPageIndex == 5)
        
        await viewModel.previousPage() // 5 -> 4
        #expect(viewModel.currentPageIndex == 4)
        
        await viewModel.nextPage() // 4 -> 5
        #expect(viewModel.currentPageIndex == 5)
        
        await viewModel.navigateToPage(10) // 5 -> 10
        #expect(viewModel.currentPageIndex == 10)
        
        // All transitions should have succeeded
        #expect(viewModel.currentPage?.pageNumber == 11)
    }
    
    @Test("Progress updates are called for each unique navigation")
    func testProgressUpdatesForUniqueNavigations() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 10)
        await viewModel.loadBook(book)
        
        let initialCount = mockBookRepository.updateProgressCallCount
        
        // When - perform unique navigations
        await viewModel.navigateToPage(2)
        await viewModel.navigateToPage(2) // Duplicate - should not update
        await viewModel.navigateToPage(5)
        await viewModel.navigateToPage(5) // Duplicate - should not update
        await viewModel.navigateToPage(8)
        
        // Then - should have 3 unique updates (2, 5, 8)
        #expect(mockBookRepository.updateProgressCallCount == initialCount + 3)
    }
    
    // MARK: - Scroll-Based Progress Tests
    
    @Test("Update progress only updates without full navigation")
    func testUpdateProgressOnly() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 10)
        await viewModel.loadBook(book)
        
        #expect(viewModel.currentPageIndex == 0)
        
        // When - simulate scroll-based update
        await viewModel.updateProgressOnly(pageIndex: 3)
        
        // Then - page index should update
        #expect(viewModel.currentPageIndex == 3)
        #expect(viewModel.currentPage?.pageNumber == 4)
    }
    
    @Test("Update progress only ignores same page")
    func testUpdateProgressOnlySamePage() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 10)
        await viewModel.loadBook(book)
        await viewModel.updateProgressOnly(pageIndex: 3)
        
        let updateCountBefore = mockBookRepository.updateProgressCallCount
        
        // When - update to same page
        await viewModel.updateProgressOnly(pageIndex: 3)
        
        // Then - should not trigger repository update
        #expect(viewModel.currentPageIndex == 3)
        #expect(mockBookRepository.updateProgressCallCount == updateCountBefore)
    }
    
    @Test("Update progress only allows any distance")
    func testUpdateProgressOnlyAllowsAnyDistance() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 20)
        await viewModel.loadBook(book)
        
        #expect(viewModel.currentPageIndex == 0)
        
        // When - jump to far page (simulates fast scrolling)
        await viewModel.updateProgressOnly(pageIndex: 10)
        
        // Then - should allow the jump
        #expect(viewModel.currentPageIndex == 10)
        
        // When - jump back
        await viewModel.updateProgressOnly(pageIndex: 2)
        
        // Then - should allow backward jump too
        #expect(viewModel.currentPageIndex == 2)
    }
    
    @Test("Update progress only rejects invalid indices")
    func testUpdateProgressOnlyInvalidIndex() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 5)
        await viewModel.loadBook(book)
        
        // When - try invalid indices
        await viewModel.updateProgressOnly(pageIndex: -1)
        #expect(viewModel.currentPageIndex == 0)
        
        await viewModel.updateProgressOnly(pageIndex: 10)
        #expect(viewModel.currentPageIndex == 0)
    }
    
    @Test("Update progress only handles no book")
    func testUpdateProgressOnlyNoBook() async {
        // Given
        let viewModel = createViewModel()
        // No book loaded
        
        // When - try to update progress
        await viewModel.updateProgressOnly(pageIndex: 5)
        
        // Then - should remain at default state
        #expect(viewModel.currentPageIndex == 0)
        #expect(viewModel.currentBook == nil)
    }
}


// MARK: - Mock Implementations

class ReadingMockBookRepository: BookRepository {
    var updateProgressCallCount = 0
    var lastUpdatedBookId: UUID?
    var lastUpdatedPageIndex: Int?

    func saveBook(_ book: AppBook, userId: UUID) async throws -> AppBook {
        return book
    }

    func getBook(by id: UUID) async throws -> AppBook? {
        return nil
    }

    func getBooks(for userId: UUID) async throws -> [AppBook] {
        return []
    }

    func updateBook(_ book: AppBook) async throws -> AppBook {
        return book
    }

    func deleteBook(_ bookId: UUID) async throws {
        // No-op
    }

    func searchBooks(query: String, userId: UUID) async throws -> [AppBook] {
        return []
    }

    func searchBooksWithFilters(query: String?, filters: BookSearchFilters, userId: UUID) async throws -> [AppBook] {
        return []
    }

    func getBooksByGenre(_ genre: BookGenre, userId: UUID) async throws -> [AppBook] {
        return []
    }

    func getBooksByLanguage(_ language: String, userId: UUID) async throws -> [AppBook] {
        return []
    }

    func getBooksByProgressStatus(_ status: ReadingProgressStatus, userId: UUID) async throws -> [AppBook] {
        return []
    }

    func getRecentBooks(for userId: UUID, limit: Int) async throws -> [AppBook] {
        return []
    }

    func getLibraryStatistics(userId: UUID) async throws -> LibraryStatistics {
        return LibraryStatistics(
            totalBooks: 0,
            totalWords: 0,
            totalReadingTimeMinutes: 0,
            completedBooks: 0,
            booksByGenre: [:],
            booksByLanguage: [:],
            averageReadingProgress: 0.0
        )
    }

    func updateReadingProgress(bookId: UUID, pageIndex: Int) async throws {
        updateProgressCallCount += 1
        lastUpdatedBookId = bookId
        lastUpdatedPageIndex = pageIndex
    }

    func reorderPages(bookId: UUID, newPageOrder: [UUID]) async throws -> AppBook {
        throw BookRepositoryError.bookNotFound
    }
}

class MockDictionaryRepository: DictionaryRepository {
    func lookup(character: String) async throws -> DictionaryEntry? {
        return nil
    }

    func lookup(word: String) async throws -> DictionaryEntry? {
        return nil
    }

    func getExamples(for word: String) async throws -> [String] {
        return []
    }

    func searchWords(prefix: String, limit: Int) async throws -> [DictionaryEntry] {
        return []
    }

    func getWordsByHSKLevel(_ level: HSKLevel) async throws -> [DictionaryEntry] {
        return []
    }

    func preloadDictionary() async throws {
        // Mock implementation - do nothing
    }

    func isDictionaryLoaded() async -> Bool {
        return true
    }
}

class MockWordMarkerRepository: WordMarkerRepository {
    func markWord(_ word: AppMarkedWord) async throws -> AppMarkedWord {
        return word
    }

    func unmarkWord(word: String, userId: UUID) async throws {
        // No-op
    }

    func getMarkedWords(for userId: UUID) async throws -> [AppMarkedWord] {
        return []
    }

    func getMarkedWords(for bookId: UUID, userId: UUID) async throws -> [AppMarkedWord] {
        return []
    }

    func isWordMarked(_ word: String, userId: UUID) async throws -> Bool {
        return false
    }

    func getRecentMarkedWords(for userId: UUID, limit: Int) async throws -> [AppMarkedWord] {
        return []
    }

    func incrementMarkCount(word: String, userId: UUID) async throws {
        // No-op
    }

    func getMarkStatistics(for userId: UUID) async throws -> WordMarkStatistics {
        return WordMarkStatistics(
            totalMarkedWords: 0,
            recentlyMarkedWords: 0,
            frequentlyMarkedWords: 0,
            averageMarksPerSession: 0.0,
            mostMarkedWords: []
        )
    }
}

class ReadingMockTextSegmentationService: TextSegmentationService {
    var segmentCallCount = 0
    var shouldThrowError = false
    var mockWords: [AppWordSegment] = []
    var mockSegments: [String] = []

    func segment(text: String) async throws -> [String] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: -1, userInfo: nil)
        }

        if !mockSegments.isEmpty {
            return mockSegments
        }

        // Default segmentation - return the text as a single segment
        return [text]
    }

    func segmentWithPositions(text: String) async throws -> [AppWordSegment] {
        segmentCallCount += 1

        if shouldThrowError {
            throw NSError(domain: "TestError", code: -1, userInfo: nil)
        }

        if !mockWords.isEmpty {
            return mockWords
        }

        // Default segmentation
        return [
            AppWordSegment(word: text, startIndex: 0, endIndex: text.count, isMarked: false)
        ]
    }
}

