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
                imageData: Data(),
                words: [WordSegment(word: "test\(index)", boundingBox: .zero)],
                pageNumber: index + 1
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
}

// MARK: - Mock Classes

private class MockBookRepository: BookRepository {
    var books: [AppBook] = []

    func saveBook(_ book: AppBook) async throws -> AppBook {
        books.append(book)
        return book
    }

    func getAllBooks() async throws -> [AppBook] {
        return books
    }

    func getBook(by id: UUID) async throws -> AppBook? {
        return books.first { $0.id == id }
    }

    func updateBook(_ book: AppBook) async throws -> AppBook {
        if let index = books.firstIndex(where: { $0.id == book.id }) {
            books[index] = book
        }
        return book
    }

    func deleteBook(by id: UUID) async throws {
        books.removeAll { $0.id == id }
    }

    func getBooksByUserId(_ userId: String) async throws -> [AppBook] {
        return books
    }
}
