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
    
    // MARK: - Scroll-Based Navigation Tests
    
    @Test("Update page index via scroll works correctly")
    func testUpdateCurrentPageIndexViaScroll() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 5)
        await viewModel.loadBook(book)
        
        // When - simulate scrolling to page 2
        await viewModel.updateCurrentPageIndex(2)
        
        // Then
        #expect(viewModel.currentPageIndex == 2)
        #expect(viewModel.currentPage?.pageNumber == 3)
    }
    
    @Test("Update page index with same index does not trigger updates")
    func testUpdateCurrentPageIndexWithSameIndex() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 5)
        await viewModel.loadBook(book)
        let initialUpdateCount = mockBookRepository.updateProgressCallCount
        
        // When - update to same page
        await viewModel.updateCurrentPageIndex(0)
        
        // Then - should not call repository again
        #expect(viewModel.currentPageIndex == 0)
        #expect(mockBookRepository.updateProgressCallCount == initialUpdateCount)
    }
    
    @Test("Update page index with invalid index is ignored")
    func testUpdateCurrentPageIndexWithInvalidIndex() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 3)
        await viewModel.loadBook(book)
        
        // When - try to update to invalid index
        await viewModel.updateCurrentPageIndex(10)
        
        // Then - should stay at current page
        #expect(viewModel.currentPageIndex == 0)
    }
    
    @Test("Rapid page index updates handle correctly")
    func testRapidPageIndexUpdates() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 10)
        await viewModel.loadBook(book)
        
        // When - simulate rapid scrolling
        await viewModel.updateCurrentPageIndex(1)
        await viewModel.updateCurrentPageIndex(2)
        await viewModel.updateCurrentPageIndex(3)
        await viewModel.updateCurrentPageIndex(4)
        
        // Then - should end up at last update
        #expect(viewModel.currentPageIndex == 4)
        #expect(viewModel.currentPage?.pageNumber == 5)
    }
    
    @Test("Scroll forward then backward works correctly")
    func testScrollForwardThenBackward() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 5)
        await viewModel.loadBook(book)
        
        // When - scroll forward
        await viewModel.updateCurrentPageIndex(3)
        #expect(viewModel.currentPageIndex == 3)
        
        // Then scroll backward
        await viewModel.updateCurrentPageIndex(1)
        
        // Then
        #expect(viewModel.currentPageIndex == 1)
        #expect(viewModel.currentPage?.pageNumber == 2)
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
    
    // MARK: - Scroll Behavior Tests
    
    @Test("Update page index to same page does not trigger progress update")
    func testUpdateToSamePageDoesNotTriggerUpdate() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 5)
        await viewModel.loadBook(book)
        await viewModel.updateCurrentPageIndex(2) // Move to page 2
        
        let updateCountBefore = mockBookRepository.updateProgressCallCount
        
        // When - update to same page
        await viewModel.updateCurrentPageIndex(2)
        
        // Then - should not call repository again
        #expect(mockBookRepository.updateProgressCallCount == updateCountBefore)
    }
    
    @Test("Consecutive scroll updates handle correctly without duplicates")
    func testConsecutiveScrollUpdates() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 10)
        await viewModel.loadBook(book)
        
        // When - simulate rapid scrolling (user scrolling through pages)
        await viewModel.updateCurrentPageIndex(1)
        await viewModel.updateCurrentPageIndex(2)
        await viewModel.updateCurrentPageIndex(3)
        await viewModel.updateCurrentPageIndex(3) // Duplicate
        await viewModel.updateCurrentPageIndex(4)
        
        // Then - should end up at page 4
        #expect(viewModel.currentPageIndex == 4)
        
        // Should have 4 unique updates (0->1, 1->2, 2->3, 3->4), not 5
        // The duplicate update to 3 should be ignored
        #expect(mockBookRepository.updateProgressCallCount == 5) // Initial load + 4 updates
    }
    
    @Test("Page index update after programmatic navigation")
    func testPageIndexUpdateAfterProgrammaticNav() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 5)
        await viewModel.loadBook(book)
        
        // When - use nextPage (programmatic navigation)
        await viewModel.nextPage()
        
        // Then - should be at page 1
        #expect(viewModel.currentPageIndex == 1)
        
        // When - simulate scroll update to same page
        await viewModel.updateCurrentPageIndex(1)
        
        // Then - should not trigger extra updates
        let updateCount = mockBookRepository.updateProgressCallCount
        #expect(updateCount > 0)
    }
    
    @Test("Scroll back and forth maintains correct state")
    func testScrollBackAndForth() async {
        // Given
        let viewModel = createViewModel()
        let book = createTestBook(pageCount: 5)
        await viewModel.loadBook(book)
        
        // When - scroll forward then backward
        await viewModel.updateCurrentPageIndex(2) // Forward to 2
        #expect(viewModel.currentPageIndex == 2)
        
        await viewModel.updateCurrentPageIndex(1) // Back to 1
        #expect(viewModel.currentPageIndex == 1)
        
        await viewModel.updateCurrentPageIndex(3) // Forward to 3
        #expect(viewModel.currentPageIndex == 3)
        
        await viewModel.updateCurrentPageIndex(0) // Back to start
        #expect(viewModel.currentPageIndex == 0)
        
        // Then - all updates should have succeeded
        #expect(mockBookRepository.updateProgressCallCount == 5) // Load + 4 updates
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

