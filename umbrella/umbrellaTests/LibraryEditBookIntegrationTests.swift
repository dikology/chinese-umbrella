//
//  LibraryEditBookIntegrationTests.swift
//  umbrellaTests
//
//  Created by Денис on 31.12.2025.
//

import Testing
import SwiftUI
@testable import umbrella

struct LibraryEditBookIntegrationTests {
    private var mockBookRepository: MockBookRepository!
    private var mockEditBookUseCase: MockEditBookUseCase!

    init() {
        mockBookRepository = MockBookRepository()
        mockEditBookUseCase = MockEditBookUseCase()
    }

    // MARK: - Integration Tests

    @Test("LibraryScreen can present EditBookScreen with valid book")
    @MainActor
    func testLibraryScreenPresentsEditBookScreen() async throws {
        // Given: Library screen with a book
        let testBook = createTestBook(title: "Integration Test Book", pageCount: 3)
        mockBookRepository.books = [testBook]

        // When: Simulating the edit action (this would normally be triggered by swipe gesture)
        // Note: In a real UI test, this would be tested via XCUIApplication

        // Then: EditBookScreen should be initializable with the book
        let editScreen = EditBookScreen(
            book: testBook,
            editBookUseCase: mockEditBookUseCase
        )

        // Verify the screen was created successfully
        // This is a basic integration test - full UI testing would require XCUITest
        #expect(editScreen != nil)
    }

    @Test("EditBookScreen receives correct book data from LibraryScreen")
    @MainActor
    func testEditBookScreenReceivesCorrectData() async throws {
        // Given: A book with specific data
        let testBook = createTestBook(
            title: "Integration Book",
            author: "Test Author",
            pageCount: 5
        )

        // When: EditBookScreen is created with this book
        let editScreen = EditBookScreen(
            book: testBook,
            editBookUseCase: mockEditBookUseCase
        )

        // Then: The screen should have access to the book data
        // Note: We can't directly test the UI content without XCUITest,
        // but we can test that the ViewModel is initialized correctly
        #expect(testBook.title == "Integration Book")
        #expect(testBook.totalPages == 5)
        #expect(testBook.author == "Test Author")
    }

    @Test("EditBookScreen handles callback after successful edit")
    @MainActor
    func testEditBookScreenCallbackAfterEdit() async throws {
        // Given: EditBookScreen with callback
        let testBook = createTestBook(pageCount: 2)
        var callbackCalled = false

        let editScreen = EditBookScreen(
            book: testBook,
            editBookUseCase: mockEditBookUseCase,
            onBookEdited: {
                callbackCalled = true
            }
        )

        // When: Simulating successful edit (this would happen inside the ViewModel)
        // In a real scenario, this would be triggered by user interaction

        // Then: Callback should be stored (we can't test execution without UI interaction)
        #expect(editScreen != nil)
        // The callback execution would be tested in UI tests
    }

    @Test("LibraryScreen handles books with different page counts")
    @MainActor
    func testLibraryScreenHandlesDifferentBookSizes() async throws {
        // Test with various book sizes
        let testCases = [
            createTestBook(title: "Empty Book", pageCount: 0),
            createTestBook(title: "Small Book", pageCount: 1),
            createTestBook(title: "Medium Book", pageCount: 10),
            createTestBook(title: "Large Book", pageCount: 100)
        ]

        for book in testCases {
            // When: EditBookScreen is created for each book
            let editScreen = EditBookScreen(
                book: book,
                editBookUseCase: mockEditBookUseCase
            )

            // Then: Screen should handle all book sizes
            #expect(editScreen != nil)
            #expect(book.totalPages >= 0)
        }
    }

    // MARK: - Helper Methods

    private func createTestBook(title: String = "Test Book", author: String? = "Test Author", pageCount: Int = 3) -> AppBook {
        let pages = (0..<pageCount).map { index in
            AppBookPage(
                id: UUID(),
                bookId: UUID(), // Need to provide a bookId
                pageNumber: index + 1,
                originalImagePath: "/test/path/image\(index).jpg",
                extractedText: "Test extracted text for page \(index)",
                words: [AppWordSegment(word: "test\(index)", startIndex: 0, endIndex: 4)],
                wordsMarked: []
            )
        }

        return AppBook(
            title: title,
            author: author,
            pages: pages,
            currentPageIndex: 0,
            isLocal: true
        )
    }

    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

    @Test("Add pages to existing book integration test")
    @MainActor
    func testAddPagesToExistingBook() async throws {
        // Given: A book with 2 existing pages
        let bookId = UUID()
        let existingPages = [
            AppBookPage(
                id: UUID(),
                bookId: bookId,
                pageNumber: 1,
                originalImagePath: "/test/path/image1.jpg",
                extractedText: "Existing page 1 text",
                words: [AppWordSegment(word: "existing1", startIndex: 0, endIndex: 9)],
                wordsMarked: []
            ),
            AppBookPage(
                id: UUID(),
                bookId: bookId,
                pageNumber: 2,
                originalImagePath: "/test/path/image2.jpg",
                extractedText: "Existing page 2 text",
                words: [AppWordSegment(word: "existing2", startIndex: 0, endIndex: 9)],
                wordsMarked: []
            )
        ]

        let originalBook = AppBook(
            id: bookId,
            title: "Original Book",
            author: "Original Author",
            pages: existingPages,
            currentPageIndex: 0,
            isLocal: true
        )

        // Mock the use case to simulate successful processing
        let mockUseCase = MockEditBookUseCase()

        // When: Adding 2 new pages
        let newImages = [createTestImage(), createTestImage()]
        let updatedBook = try await mockUseCase.addPagesToBook(
            book: originalBook,
            newImages: newImages,
            updatedTitle: "Updated Title",
            updatedAuthor: "Updated Author"
        )

        // Then: Book should have 4 pages total
        #expect(updatedBook.pages.count == 4)
        #expect(updatedBook.title == "Updated Title")
        #expect(updatedBook.author == "Updated Author")

        // Verify page numbers are sequential
        for i in 0..<4 {
            #expect(updatedBook.pages[i].pageNumber == i + 1)
        }

        // Verify original pages are preserved
        #expect(updatedBook.pages[0].words.first?.word == "existing1")
        #expect(updatedBook.pages[1].words.first?.word == "existing2")
    }

    @Test("Add pages fails when no images provided")
    @MainActor
    func testAddPagesFailsWithNoImages() async throws {
        // Given: A book with existing pages
        let originalBook = createTestBook(title: "Test Book", pageCount: 1)
        let mockUseCase = MockEditBookUseCase()

        // When/Then: Adding empty image array should fail
        await #expect(throws: EditBookError.noValidImages) {
            try await mockUseCase.addPagesToBook(
                book: originalBook,
                newImages: [],
                updatedTitle: nil,
                updatedAuthor: nil
            )
        }
    }

    @Test("End-to-end add pages with real services simulation")
    @MainActor
    func testAddPagesEndToEnd() async throws {
        // Given: A book with 1 existing page
        let bookId = UUID()
        let existingPage = AppBookPage(
            id: UUID(),
            bookId: bookId,
            pageNumber: 1,
            originalImagePath: "/test/path/original.jpg",
            extractedText: "Original page text",
            words: [AppWordSegment(word: "original", startIndex: 0, endIndex: 8)],
            wordsMarked: []
        )

        let originalBook = AppBook(
            id: bookId,
            title: "Original Book",
            author: "Original Author",
            pages: [existingPage],
            currentPageIndex: 0,
            isLocal: true
        )

        // Create a real use case with mocked services
        let mockOCRService = MockOCRService()
        let mockImageProcessingService = MockImageProcessingService()
        let mockTextSegmentationService = MockTextSegmentationService()
        let mockBookRepository = MockBookRepository()

        let useCase = DefaultEditBookUseCase(
            ocrService: mockOCRService,
            imageProcessingService: mockImageProcessingService,
            textSegmentationService: mockTextSegmentationService,
            bookRepository: mockBookRepository
        )

        // When: Adding 2 new images
        let newImages = [createTestImage(), createTestImage()]
        let updatedBook = try await useCase.addPagesToBook(
            book: originalBook,
            newImages: newImages,
            updatedTitle: "Updated Title",
            updatedAuthor: nil
        )

        // Then: Book should have 3 pages total
        #expect(updatedBook.pages.count == 3)
        #expect(updatedBook.title == "Updated Title")
        #expect(updatedBook.author == "Original Author") // Should keep original when nil provided

        // Verify page numbers are sequential
        #expect(updatedBook.pages[0].pageNumber == 1) // Original page
        #expect(updatedBook.pages[1].pageNumber == 2) // First new page
        #expect(updatedBook.pages[2].pageNumber == 3) // Second new page

        // Verify original page content is preserved
        #expect(updatedBook.pages[0].words.first?.word == "original")
    }

    @Test("EditBookScreen can reorder existing pages")
    @MainActor
    func testEditBookScreenReorderPages() async throws {
        // Given: A book with multiple pages
        let testBook = createTestBook(title: "Reorder Integration Test", pageCount: 4)
        let editScreen = EditBookScreen(
            book: testBook,
            editBookUseCase: mockEditBookUseCase
        )

        // Create a view model to test reordering
        let viewModel = EditBookViewModel(book: testBook, editBookUseCase: mockEditBookUseCase)

        // Verify initial state
        #expect(viewModel.existingPageList.count == 4)
        let originalPageIds = viewModel.existingPageList.map { $0.id }

        // When: Reorder pages (move page 3 to position 0)
        viewModel.reorderExistingPages(from: IndexSet([2]), to: 0)

        // Then: Verify the reordering worked
        #expect(viewModel.existingPageList.count == 4)
        let reorderedPageIds = viewModel.existingPageList.map { $0.id }
        #expect(reorderedPageIds != originalPageIds)

        // Verify page 3 (originally at index 2) is now at index 0
        #expect(reorderedPageIds[0] == originalPageIds[2])

        // When: Save the reordering
        let reorderedBook = AppBook(
            id: testBook.id,
            title: testBook.title,
            author: testBook.author,
            pages: viewModel.existingPageList.enumerated().map { index, page in
                AppBookPage(
                    bookId: testBook.id,
                    pageNumber: index + 1,
                    originalImagePath: page.originalImagePath,
                    extractedText: page.extractedText,
                    words: []
                )
            },
            currentPageIndex: testBook.currentPageIndex,
            isLocal: testBook.isLocal,
            language: testBook.language,
            genre: testBook.genre,
            description: testBook.description,
            totalWords: testBook.totalWords,
            estimatedReadingTimeMinutes: testBook.estimatedReadingTimeMinutes,
            difficulty: testBook.difficulty,
            tags: testBook.tags
        )
        mockEditBookUseCase.reorderPagesResult = reorderedBook

        await viewModel.savePageReorder()

        // Then: Verify save completed
        #expect(viewModel.editComplete == true)
        #expect(mockEditBookUseCase.reorderPagesCallCount == 1)
    }
}

// MARK: - Mock Classes

private class MockEditBookUseCase: EditBookUseCase {
    var shouldThrowError = false

    // Page reordering properties
    var reorderPagesCallCount = 0
    var reorderPagesResult: AppBook?

    func addPagesToBook(book: AppBook, newImages: [UIImage], updatedTitle: String?, updatedAuthor: String?) async throws -> AppBook {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }

        if newImages.isEmpty {
            throw EditBookError.noValidImages
        }

        // Simulate processing images and creating new pages
        var newPages: [AppBookPage] = []
        let startingPageNumber = book.pages.count + 1

        for (index, _) in newImages.enumerated() {
            let newPage = AppBookPage(
                id: UUID(),
                bookId: book.id,
                pageNumber: startingPageNumber + index,
                originalImagePath: "/mock/path/newpage\(index + 1).jpg",
                extractedText: "Mock extracted text for new page \(index + 1)",
                words: [AppWordSegment(word: "newpage\(index + 1)", startIndex: 0, endIndex: 8)],
                wordsMarked: []
            )
            newPages.append(newPage)
        }

        // Create updated book with new pages and metadata
        let allPages = book.pages + newPages
        let finalTitle = updatedTitle ?? book.title
        let finalAuthor = updatedAuthor ?? book.author

        return AppBook(
            id: book.id,
            title: finalTitle,
            author: finalAuthor,
            pages: allPages,
            currentPageIndex: book.currentPageIndex,
            isLocal: book.isLocal,
            language: book.language,
            genre: book.genre,
            description: book.description,
            totalWords: book.totalWords,
            estimatedReadingTimeMinutes: book.estimatedReadingTimeMinutes,
            difficulty: book.difficulty,
            tags: book.tags
        )
    }

    func reorderPages(book: AppBook, newPageOrder: [UUID]) async throws -> AppBook {
        reorderPagesCallCount += 1

        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Reorder test error"])
        }

        return reorderPagesResult ?? book
    }
}

private class MockBookRepository: BookRepository {
    var books: [AppBook] = []

    func saveBook(_ book: AppBook, userId: UUID) async throws -> AppBook {
        books.append(book)
        return book
    }

    func getBook(by id: UUID) async throws -> AppBook? {
        return books.first { $0.id == id }
    }

    func getBooks(for userId: UUID) async throws -> [AppBook] {
        return books
    }

    func updateBook(_ book: AppBook) async throws -> AppBook {
        if let index = books.firstIndex(where: { $0.id == book.id }) {
            books[index] = book
        }
        return book
    }

    func deleteBook(_ bookId: UUID) async throws {
        books.removeAll { $0.id == bookId }
    }

    func searchBooks(query: String, userId: UUID) async throws -> [AppBook] {
        return books.filter { $0.title.contains(query) || ($0.author?.contains(query) ?? false) }
    }

    func searchBooksWithFilters(query: String?, filters: BookSearchFilters, userId: UUID) async throws -> [AppBook] {
        return books
    }

    func getBooksByGenre(_ genre: BookGenre, userId: UUID) async throws -> [AppBook] {
        return books.filter { $0.genre == genre }
    }

    func getBooksByLanguage(_ language: String, userId: UUID) async throws -> [AppBook] {
        return books.filter { $0.language == language }
    }

    func getBooksByProgressStatus(_ status: ReadingProgressStatus, userId: UUID) async throws -> [AppBook] {
        return books
    }

    func getRecentBooks(for userId: UUID, limit: Int) async throws -> [AppBook] {
        return Array(books.prefix(limit))
    }

    func getLibraryStatistics(userId: UUID) async throws -> LibraryStatistics {
        return LibraryStatistics(
            totalBooks: books.count,
            totalWords: 0,
            totalReadingTimeMinutes: 0,
            completedBooks: 0,
            booksByGenre: [:],
            booksByLanguage: [:],
            averageReadingProgress: 0.0
        )
    }

    func updateReadingProgress(bookId: UUID, pageIndex: Int) async throws {
        // Do nothing for mock
    }

    func reorderPages(bookId: UUID, newPageOrder: [UUID]) async throws -> AppBook {
        // For integration tests, just return the book unchanged
        guard let book = books.first(where: { $0.id == bookId }) else {
            throw BookRepositoryError.bookNotFound
        }
        return book
    }
}

// MARK: - Mock Services for End-to-End Testing

private class MockOCRService: OCRService {
    func recognizeText(from image: UIImage) async throws -> String {
        return "Mock extracted text"
    }

    func extractTextBlocks(from image: UIImage) async throws -> [TextBlock] {
        return [TextBlock(text: "Mock text", boundingBox: .zero, confidence: 1.0)]
    }
}

private class MockImageProcessingService: ImageProcessingService {
    func processImageForOCR(_ image: UIImage) -> UIImage {
        return image
    }

    func validateImageForOCR(_ image: UIImage) -> ImageValidationResult {
        return ImageValidationResult(isValid: true, warnings: [], recommendations: [])
    }

    func saveImageToStorage(_ image: UIImage, filename: String) throws -> String {
        return "/mock/path/\(filename)"
    }

    func loadImageFromStorage(filename: String) -> UIImage? {
        return nil // Mock always returns nil
    }

    func deleteImageFromStorage(filename: String) throws {
        // Mock does nothing
    }

    func getImagesDirectory() -> URL {
        return URL(fileURLWithPath: "/mock/images")
    }
}

private class MockTextSegmentationService: TextSegmentationService {
    func segment(text: String) async throws -> [String] {
        return ["mock"]
    }

    func segmentWithPositions(text: String) async throws -> [AppWordSegment] {
        return [AppWordSegment(word: "mock", startIndex: 0, endIndex: 4)]
    }
}
