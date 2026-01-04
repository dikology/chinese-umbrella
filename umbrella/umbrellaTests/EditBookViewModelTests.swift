//
//  EditBookViewModelTests.swift
//  umbrellaTests
//
//  Created by Денис on 31.12.2025.
//

import Testing
import UIKit
@testable import umbrella

struct EditBookViewModelTests {
    private var mockUseCase: MockEditBookUseCase!
    private var testBook: AppBook!

    init() {
        mockUseCase = MockEditBookUseCase()
        testBook = createTestBook()
    }

    // MARK: - Initialization Tests

    @Test("ViewModel initializes correctly with valid book")
    func testInitializationWithValidBook() {
        // Given
        let book = createTestBook(title: "Test Book", author: "Test Author", pageCount: 5)

        // When
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)

        // Then
        #expect(viewModel.existingBook.id == book.id)
        #expect(viewModel.bookTitle == "Test Book")
        #expect(viewModel.bookAuthor == "Test Author")
        #expect(viewModel.existingPageCount == 5)
        #expect(viewModel.newPageCount == 0)
        #expect(viewModel.totalPageCount == 5)
        #expect(!viewModel.canEdit) // No images selected yet
    }

    @Test("ViewModel initializes correctly with book having no author")
    func testInitializationWithBookWithoutAuthor() {
        // Given
        let book = createTestBook(title: "Test Book", author: nil, pageCount: 3)

        // When
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)

        // Then
        #expect(viewModel.bookTitle == "Test Book")
        #expect(viewModel.bookAuthor == "")
        #expect(viewModel.existingPageCount == 3)
    }

    @Test("ViewModel initializes correctly with book having no pages")
    func testInitializationWithEmptyBook() {
        // Given
        let book = createTestBook(title: "Empty Book", pageCount: 0)

        // When
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)

        // Then
        #expect(viewModel.existingPageCount == 0)
        #expect(viewModel.totalPageCount == 0)
        #expect(viewModel.bookTitle == "Empty Book")
    }

    // MARK: - Computed Properties Tests

    @Test("Computed properties update correctly when images are added")
    func testComputedPropertiesWithImages() {
        // Given
        let book = createTestBook(pageCount: 2)
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)

        // When
        let pageItems = [
            PageItem(id: UUID(), uiImage: createTestImage(), position: 0),
            PageItem(id: UUID(), uiImage: createTestImage(), position: 1),
            PageItem(id: UUID(), uiImage: createTestImage(), position: 2)
        ]
        viewModel.pageList = pageItems

        // Then
        #expect(viewModel.existingPageCount == 2)
        #expect(viewModel.newPageCount == 3)
        #expect(viewModel.totalPageCount == 5)
        #expect(viewModel.canEdit) // Has title and images
    }

    @Test("canEdit returns false when no images selected")
    func testCanEditWithoutImages() {
        // Given
        let book = createTestBook(pageCount: 1)
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)

        // Then
        #expect(!viewModel.canEdit)
    }

    @Test("canEdit returns false when title is empty")
    func testCanEditWithEmptyTitle() {
        // Given
        let book = createTestBook(pageCount: 1)
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)

        // When
        viewModel.bookTitle = ""
        viewModel.pageList = [PageItem(id: UUID(), uiImage: createTestImage(), position: 0)]

        // Then
        #expect(!viewModel.canEdit)
    }

    // MARK: - Edit Book Tests

    @Test("editBook succeeds with valid data")
    func testEditBookSuccess() async {
        // Given
        let book = createTestBook(pageCount: 2)
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)
        viewModel.pageList = [
            PageItem(id: UUID(), uiImage: createTestImage(), position: 0),
            PageItem(id: UUID(), uiImage: createTestImage(), position: 1)
        ]
        viewModel.bookTitle = "Updated Title"
        viewModel.bookAuthor = "Updated Author"

        // When
        await viewModel.editBook()

        // Then
        #expect(viewModel.editComplete)
        #expect(!viewModel.isEditing)
        #expect(!viewModel.showError)
    }

    @Test("editBook fails when no images selected")
    func testEditBookFailsWithoutImages() async {
        // Given
        let book = createTestBook(pageCount: 2)
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)

        // When
        await viewModel.editBook()

        // Then
        #expect(!viewModel.editComplete)
        #expect(!viewModel.isEditing)
        #expect(viewModel.showError)
        #expect(viewModel.errorMessage.contains("select at least one photo"))
    }

    @Test("editBook fails when title is empty")
    func testEditBookFailsWithEmptyTitle() async {
        // Given
        let book = createTestBook(pageCount: 2)
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)
        viewModel.bookTitle = ""
        viewModel.pageList = [PageItem(id: UUID(), uiImage: createTestImage(), position: 0)]

        // When
        await viewModel.editBook()

        // Then
        #expect(!viewModel.editComplete)
        #expect(viewModel.showError)
        #expect(viewModel.errorMessage.contains("enter a title"))
    }

    @Test("editBook handles use case error")
    func testEditBookHandlesUseCaseError() async {
        // Given
        let book = createTestBook(pageCount: 2)
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)
        viewModel.pageList = [PageItem(id: UUID(), uiImage: createTestImage(), position: 0)]

        mockUseCase.shouldThrowError = true

        // When
        await viewModel.editBook()

        // Then
        #expect(!viewModel.editComplete)
        #expect(!viewModel.isEditing)
        #expect(viewModel.showError)
        #expect(viewModel.errorMessage == "Test error")
    }

    // MARK: - Edge Cases

    @Test("ViewModel handles book with very long title")
    func testLongTitleHandling() {
        // Given
        let longTitle = String(repeating: "A", count: 1000)
        let book = createTestBook(title: longTitle, pageCount: 1)
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)

        // Then
        #expect(viewModel.bookTitle == longTitle)
        #expect(viewModel.existingPageCount == 1)
    }

    @Test("ViewModel handles book with empty title")
    func testEmptyTitleHandling() {
        // Given
        let book = createTestBook(title: "", pageCount: 1)
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)

        // Then
        #expect(viewModel.bookTitle == "")
        #expect(!viewModel.canEdit) // Cannot edit without title
    }

    @Test("ViewModel handles book with nil author")
    func testNilAuthorHandling() {
        // Given
        let book = createTestBook(title: "Test Book", author: nil, pageCount: 1)
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)

        // Then
        #expect(viewModel.bookAuthor == "")
        #expect(viewModel.existingBook.author == nil)
    }

    @Test("ViewModel handles book with special characters in title")
    func testSpecialCharactersInTitle() {
        // Given
        let specialTitle = "书名: 测试 (Test) - 123 !@#$%^&*()"
        let book = createTestBook(title: specialTitle, pageCount: 1)
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)

        // Then
        #expect(viewModel.bookTitle == specialTitle)
    }

    @Test("ViewModel handles rapid image additions")
    func testRapidImageAdditions() {
        // Given
        let book = createTestBook(pageCount: 2)
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)

        // When: Adding images rapidly
        for i in 0..<10 {
            let pageItem = PageItem(id: UUID(), uiImage: createTestImage(), position: i)
            viewModel.pageList.append(pageItem)
            // Then: Counts should update correctly
            #expect(viewModel.newPageCount == i + 1)
            #expect(viewModel.totalPageCount == 2 + i + 1)
        }
    }

    @Test("ViewModel handles image removal")
    func testImageRemoval() {
        // Given
        let book = createTestBook(pageCount: 2)
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)
        let pageItems = [
            PageItem(id: UUID(), uiImage: createTestImage(), position: 0),
            PageItem(id: UUID(), uiImage: createTestImage(), position: 1),
            PageItem(id: UUID(), uiImage: createTestImage(), position: 2)
        ]
        viewModel.pageList = pageItems

        // When: Removing an image
        viewModel.pageList.remove(at: 1)

        // Then: Counts should update
        #expect(viewModel.newPageCount == 2)
        #expect(viewModel.totalPageCount == 4)
    }

    // MARK: - Helper Methods

    private func createTestBook(
        title: String = "Test Book",
        author: String? = "Test Author",
        pageCount: Int = 3
    ) -> AppBook {
        let bookId = UUID()
        let pages = (0..<pageCount).map { index in
            AppBookPage(
                id: UUID(),
                bookId: bookId,
                pageNumber: index + 1,
                originalImagePath: "/test/path/image\(index).jpg",
                extractedText: "Test extracted text for page \(index)",
                words: [AppWordSegment(word: "test\(index)", startIndex: 0, endIndex: 4)],
                wordsMarked: []
            )
        }

        return AppBook(
            id: bookId,
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
}

// MARK: - Mock Classes

private class MockEditBookUseCase: EditBookUseCase {
    var shouldThrowError = false

    // Page reordering properties
    var reorderPagesCallCount = 0
    var reorderPagesBookId: UUID?
    var reorderPagesOrder: [UUID]?
    var reorderPagesResult: AppBook?
    var reorderPagesError: Error?

    func addPagesToBook(book: AppBook, newImages: [UIImage], updatedTitle: String?, updatedAuthor: String?) async throws -> AppBook {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }

        // Return a modified book
        var modifiedBook = book
        if let updatedTitle = updatedTitle {
            // Note: Since AppBook is a struct with let properties, we can't modify it directly
            // In a real implementation, this would return a new book instance
            modifiedBook = AppBook(
                id: book.id,
                title: updatedTitle,
                author: updatedAuthor,
                pages: book.pages,
                currentPageIndex: book.currentPageIndex,
                isLocal: book.isLocal
            )
        }

        return modifiedBook
    }

    func reorderPages(book: AppBook, newPageOrder: [UUID]) async throws -> AppBook {
        reorderPagesCallCount += 1
        reorderPagesBookId = book.id
        reorderPagesOrder = newPageOrder

        if let error = reorderPagesError {
            throw error
        }

        return reorderPagesResult ?? book
    }
}

// MARK: - Page Reordering Tests

extension EditBookViewModelTests {

    @Test("ViewModel loads existing pages correctly")
    func testLoadExistingPages() async {
        // Given
        let book = createTestBook(title: "Reorder Test Book", pageCount: 3)
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)

        // When
        await viewModel.loadExistingPages()

        // Then
        #expect(viewModel.existingPageList.count == 3)
        #expect(viewModel.existingPageList[0].pageNumber == 1)
        #expect(viewModel.existingPageList[1].pageNumber == 2)
        #expect(viewModel.existingPageList[2].pageNumber == 3)
        #expect(viewModel.existingPageList[0].position == 0)
        #expect(viewModel.existingPageList[1].position == 1)
        #expect(viewModel.existingPageList[2].position == 2)
    }

    @Test("updatePageNumber correctly updates page number")
    @MainActor
    func testUpdatePageNumber_updatesPageNumber() async {
        // Given
        let book = createTestBook(title: "Update Number Test Book", pageCount: 3)
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)

        await viewModel.loadExistingPages()

        let firstPageId = viewModel.existingPageList[0].id
        let originalPageNumber = viewModel.existingPageList[0].pageNumber

        // When - Update first page to number 5
        viewModel.updatePageNumber(pageId: firstPageId, newNumber: 5)

        // Then
        #expect(viewModel.existingPageList.count == 3)
        #expect(viewModel.existingPageList[0].pageNumber == 5)
        #expect(viewModel.existingPageList[0].id == firstPageId)
        
        // Other pages should remain unchanged
        #expect(viewModel.existingPageList[1].pageNumber == 2)
        #expect(viewModel.existingPageList[2].pageNumber == 3)
    }

    @Test("savePageNumbers successfully saves page numbers")
    @MainActor
    func testSavePageNumbers_successfullySaves() async {
        // Given
        let book = createTestBook(title: "Save Numbers Test", pageCount: 3)
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)

        await viewModel.loadExistingPages()

        // Update page numbers (reverse order: 3, 2, 1)
        let pageIds = viewModel.existingPageList.map { $0.id }
        viewModel.updatePageNumber(pageId: pageIds[0], newNumber: 3)
        viewModel.updatePageNumber(pageId: pageIds[1], newNumber: 2)
        viewModel.updatePageNumber(pageId: pageIds[2], newNumber: 1)

        // Set up mock to return reordered book
        let reorderedBook = AppBook(
            id: book.id,
            title: book.title,
            author: book.author,
            pages: book.pages.reversed(),
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
        mockUseCase.reorderPagesResult = reorderedBook

        // When
        await viewModel.savePageNumbers()

        // Then
        #expect(viewModel.editComplete == true)
        #expect(viewModel.isEditing == false)

        // Verify the use case was called
        #expect(mockUseCase.reorderPagesCallCount == 1)
        #expect(mockUseCase.reorderPagesBookId == book.id)
        
        // Verify the order is sorted by page number (1, 2, 3 -> which is pageIds[2], pageIds[1], pageIds[0])
        let expectedOrder = [pageIds[2], pageIds[1], pageIds[0]]
        #expect(mockUseCase.reorderPagesOrder == expectedOrder)
    }

    @Test("savePageNumbers handles errors correctly")
    func testSavePageNumbers_handlesErrors() async {
        // Given
        let book = createTestBook(title: "Error Numbers Test", pageCount: 2)
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)

        await viewModel.loadExistingPages()

        // Set up mock to throw error
        mockUseCase.reorderPagesError = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])

        // When
        await viewModel.savePageNumbers()

        // Then
        #expect(viewModel.editComplete == false)
        #expect(viewModel.isEditing == false)
        #expect(viewModel.showError == true)
        #expect(viewModel.errorMessage == "Test error")
    }
    
    @Test("updatePageNumber handles invalid page ID")
    @MainActor
    func testUpdatePageNumber_handlesInvalidPageId() async {
        // Given
        let book = createTestBook(title: "Invalid ID Test", pageCount: 2)
        let viewModel = EditBookViewModel(book: book, editBookUseCase: mockUseCase)

        await viewModel.loadExistingPages()

        let originalPageNumbers = viewModel.existingPageList.map { $0.pageNumber }

        // When - Try to update a non-existent page
        viewModel.updatePageNumber(pageId: UUID(), newNumber: 99)

        // Then - Nothing should change
        let newPageNumbers = viewModel.existingPageList.map { $0.pageNumber }
        #expect(originalPageNumbers == newPageNumbers)
    }
}
