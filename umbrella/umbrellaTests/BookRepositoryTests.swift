//
//  BookRepositoryTests.swift
//  umbrellaTests
//
//  Created by Денис on 31.12.2025.
//

import Testing
import CoreData
@testable import umbrella

struct BookRepositoryTests {
    private let coreDataManager = CoreDataManager(inMemory: true)
    private var repository: BookRepositoryImpl!
    private var userId: UUID!

    init() {
        repository = BookRepositoryImpl(coreDataManager: coreDataManager)
        userId = UUID()
    }

    // MARK: - Setup Helpers

    private func createTestBook(
        title: String = "Test Book",
        author: String? = "Test Author",
        language: String? = "zh-Hans",
        genre: BookGenre? = .literature,
        totalWords: Int? = 1000
    ) -> AppBook {
        let pages = [
            AppBookPage(
                bookId: UUID(),
                pageNumber: 1,
                originalImagePath: "/path/to/image1.jpg",
                extractedText: "这是第一页的内容",
                words: [
                    AppWordSegment(word: "这是", startIndex: 0, endIndex: 2),
                    AppWordSegment(word: "第一页", startIndex: 3, endIndex: 6),
                    AppWordSegment(word: "的", startIndex: 6, endIndex: 7),
                    AppWordSegment(word: "内容", startIndex: 7, endIndex: 9)
                ]
            )
        ]

        return AppBook(
            title: title,
            author: author,
            pages: pages,
            language: language,
            genre: genre,
            totalWords: totalWords
        )
    }

    private func createTestUser() async throws -> UserEntity {
        let context = coreDataManager.viewContext
        let user = UserEntity(context: context)
        user.id = userId
        user.email = "test@example.com"
        user.createdDate = Date()
        try context.save()
        return user
    }

    // MARK: - CRUD Tests

    @Test func testSaveBook_successfullySavesBook() async throws {
        // Given
        let user = try await createTestUser()
        let book = createTestBook()

        // When
        let savedBook = try await repository.saveBook(book, userId: userId)

        // Then
        #expect(savedBook.title == book.title)
        #expect(savedBook.author == book.author)
        #expect(savedBook.language == book.language)
        #expect(savedBook.genre == book.genre)
        #expect(savedBook.totalWords == book.totalWords)
        #expect(savedBook.pages.count == book.pages.count)
    }

    @Test func testGetBook_byId_returnsCorrectBook() async throws {
        // Given
        let user = try await createTestUser()
        let book = createTestBook()
        let savedBook = try await repository.saveBook(book, userId: userId)

        // When
        let retrievedBook = try await repository.getBook(by: savedBook.id)

        // Then
        #expect(retrievedBook != nil)
        #expect(retrievedBook?.id == savedBook.id)
        #expect(retrievedBook?.title == savedBook.title)
    }

    @Test func testGetBooks_forUser_returnsUserBooksOnly() async throws {
        // Given
        let user1 = try await createTestUser()
        let user2Id = UUID()

        // Create user2
        let context = coreDataManager.viewContext
        let user2 = UserEntity(context: context)
        user2.id = user2Id
        user2.email = "user2@example.com"
        try context.save()

        let book1 = createTestBook(title: "User1 Book")
        let book2 = createTestBook(title: "User2 Book")

        _ = try await repository.saveBook(book1, userId: user1.id)
        _ = try await repository.saveBook(book2, userId: user2Id)

        // When
        let user1Books = try await repository.getBooks(for: user1.id)

        // Then
        #expect(user1Books.count == 1)
        #expect(user1Books.first?.title == "User1 Book")
    }

    @Test func testUpdateBook_modifiesExistingBook() async throws {
        // Given
        let user = try await createTestUser()
        let originalBook = createTestBook(title: "Original Title")
        let savedBook = try await repository.saveBook(originalBook, userId: userId)

        let updatedBook = AppBook(
            id: savedBook.id,
            title: "Updated Title",
            author: savedBook.author,
            pages: savedBook.pages,
            currentPageIndex: savedBook.currentPageIndex,
            isLocal: savedBook.isLocal,
            language: savedBook.language,
            genre: .fiction, // Changed genre
            description: "Updated description",
            totalWords: savedBook.totalWords,
            estimatedReadingTimeMinutes: savedBook.estimatedReadingTimeMinutes,
            difficulty: .advanced,
            tags: ["updated"]
        )

        // When
        let result = try await repository.updateBook(updatedBook)

        // Then
        #expect(result.title == "Updated Title")
        #expect(result.genre == .fiction)
        #expect(result.description == "Updated description")
        #expect(result.difficulty == .advanced)
        #expect(result.tags == ["updated"])
    }

    @Test func testDeleteBook_removesBookFromStorage() async throws {
        // Given
        let user = try await createTestUser()
        let book = createTestBook()
        let savedBook = try await repository.saveBook(book, userId: userId)

        // Verify book exists
        var retrievedBook = try await repository.getBook(by: savedBook.id)
        #expect(retrievedBook != nil)

        // When
        try await repository.deleteBook(savedBook.id)

        // Then
        retrievedBook = try await repository.getBook(by: savedBook.id)
        #expect(retrievedBook == nil)
    }

    // MARK: - Search and Filter Tests

    @Test func testSearchBooks_byTitle_returnsMatchingBooks() async throws {
        // Given
        let user = try await createTestUser()
        let book1 = createTestBook(title: "Chinese Literature")
        let book2 = createTestBook(title: "English Grammar")

        _ = try await repository.saveBook(book1, userId: userId)
        _ = try await repository.saveBook(book2, userId: userId)

        // When
        let results = try await repository.searchBooks(query: "Chinese", userId: userId)

        // Then
        #expect(results.count == 1)
        #expect(results.first?.title == "Chinese Literature")
    }

    @Test func testSearchBooksWithFilters_byGenre_returnsFilteredBooks() async throws {
        // Given
        let user = try await createTestUser()
        let book1 = createTestBook(title: "Literature Book", genre: .literature)
        let book2 = createTestBook(title: "Science Book", genre: .science)

        _ = try await repository.saveBook(book1, userId: userId)
        _ = try await repository.saveBook(book2, userId: userId)

        let filters = BookSearchFilters(genres: [.literature])

        // When
        let results = try await repository.searchBooksWithFilters(query: nil, filters: filters, userId: userId)

        // Then
        #expect(results.count == 1)
        #expect(results.first?.genre == .literature)
    }

    @Test func testSearchBooksWithFilters_byLanguage_returnsFilteredBooks() async throws {
        // Given
        let user = try await createTestUser()
        let book1 = createTestBook(title: "Chinese Book", language: "zh-Hans")
        let book2 = createTestBook(title: "English Book", language: "en")

        _ = try await repository.saveBook(book1, userId: userId)
        _ = try await repository.saveBook(book2, userId: userId)

        let filters = BookSearchFilters(languages: ["zh-Hans"])

        // When
        let results = try await repository.searchBooksWithFilters(query: nil, filters: filters, userId: userId)

        // Then
        #expect(results.count == 1)
        #expect(results.first?.language == "zh-Hans")
    }

    @Test func testGetBooksByGenre_returnsCorrectBooks() async throws {
        // Given
        let user = try await createTestUser()
        let book1 = createTestBook(title: "Lit Book 1", genre: .literature)
        let book2 = createTestBook(title: "Lit Book 2", genre: .literature)
        let book3 = createTestBook(title: "Sci Book", genre: .science)

        _ = try await repository.saveBook(book1, userId: userId)
        _ = try await repository.saveBook(book2, userId: userId)
        _ = try await repository.saveBook(book3, userId: userId)

        // When
        let results = try await repository.getBooksByGenre(.literature, userId: userId)

        // Then
        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.genre == .literature })
    }

    @Test func testGetBooksByLanguage_returnsCorrectBooks() async throws {
        // Given
        let user = try await createTestUser()
        let book1 = createTestBook(title: "Chinese Book 1", language: "zh-Hans")
        let book2 = createTestBook(title: "Chinese Book 2", language: "zh-Hans")
        let book3 = createTestBook(title: "English Book", language: "en")

        _ = try await repository.saveBook(book1, userId: userId)
        _ = try await repository.saveBook(book2, userId: userId)
        _ = try await repository.saveBook(book3, userId: userId)

        // When
        let results = try await repository.getBooksByLanguage("zh-Hans", userId: userId)

        // Then
        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.language == "zh-Hans" })
    }

    @Test func testGetBooksByProgressStatus_completedBooks() async throws {
        // Given
        let user = try await createTestUser()

        // Create a completed book (current page = total pages)
        let completedBook = AppBook(
            title: "Completed Book",
            author: "Author",
            pages: [AppBookPage(
                bookId: UUID(),
                pageNumber: 1,
                originalImagePath: "/path/image.jpg",
                extractedText: "Content",
                words: [AppWordSegment(word: "Content", startIndex: 0, endIndex: 7)]
            )],
            currentPageIndex: 0, // Last page
            isLocal: true
        )

        // Create an in-progress book
        let inProgressBook = AppBook(
            title: "In Progress Book",
            author: "Author",
            pages: [
                AppBookPage(bookId: UUID(), pageNumber: 1, originalImagePath: "/path/image1.jpg", extractedText: "Page 1", words: []),
                AppBookPage(bookId: UUID(), pageNumber: 2, originalImagePath: "/path/image2.jpg", extractedText: "Page 2", words: [])
            ],
            currentPageIndex: 0, // Not completed
            isLocal: true
        )

        _ = try await repository.saveBook(completedBook, userId: userId)
        _ = try await repository.saveBook(inProgressBook, userId: userId)

        // When
        let completedBooks = try await repository.getBooksByProgressStatus(.completed, userId: userId)

        // Then
        #expect(completedBooks.count == 1)
        #expect(completedBooks.first?.title == "Completed Book")
    }

    @Test func testGetRecentBooks_returnsMostRecentFirst() async throws {
        // Given
        let user = try await createTestUser()

        // Create books with different update dates
        var book1 = createTestBook(title: "Book 1")
        var book2 = createTestBook(title: "Book 2")
        var book3 = createTestBook(title: "Book 3")

        // Simulate different update times
        book1 = AppBook(
            id: book1.id,
            title: book1.title,
            author: book1.author,
            pages: book1.pages,
            currentPageIndex: book1.currentPageIndex,
            isLocal: book1.isLocal,
            updatedDate: Date().addingTimeInterval(-3600) // 1 hour ago
        )

        book2 = AppBook(
            id: book2.id,
            title: book2.title,
            author: book2.author,
            pages: book2.pages,
            currentPageIndex: book2.currentPageIndex,
            isLocal: book2.isLocal,
            updatedDate: Date().addingTimeInterval(-1800) // 30 min ago
        )

        book3 = AppBook(
            id: book3.id,
            title: book3.title,
            author: book3.author,
            pages: book3.pages,
            currentPageIndex: book3.currentPageIndex,
            isLocal: book3.isLocal,
            updatedDate: Date() // Now
        )

        _ = try await repository.saveBook(book1, userId: userId)
        _ = try await repository.saveBook(book2, userId: userId)
        _ = try await repository.saveBook(book3, userId: userId)

        // When
        let recentBooks = try await repository.getRecentBooks(for: userId, limit: 2)

        // Then
        #expect(recentBooks.count == 2)
        #expect(recentBooks.first?.title == "Book 3") // Most recent
        #expect(recentBooks.last?.title == "Book 2")  // Second most recent
    }

    @Test func testGetLibraryStatistics_calculatesCorrectStats() async throws {
        // Given
        let user = try await createTestUser()

        let book1 = createTestBook(title: "Book 1", genre: .literature, totalWords: 1000)
        let book2 = createTestBook(title: "Book 2", genre: .science, totalWords: 2000)

        _ = try await repository.saveBook(book1, userId: userId)
        _ = try await repository.saveBook(book2, userId: userId)

        // When
        let stats = try await repository.getLibraryStatistics(userId: userId)

        // Then
        #expect(stats.totalBooks == 2)
        #expect(stats.totalWords == 3000)
        #expect(stats.booksByGenre[.literature] == 1)
        #expect(stats.booksByGenre[.science] == 1)
    }

    @Test func testUpdateReadingProgress_updatesCurrentPageIndex() async throws {
        // Given
        let user = try await createTestUser()
        let book = createTestBook()
        let savedBook = try await repository.saveBook(book, userId: userId)

        // When
        try await repository.updateReadingProgress(bookId: savedBook.id, pageIndex: 2)

        // Then
        let updatedBook = try await repository.getBook(by: savedBook.id)
        #expect(updatedBook?.currentPageIndex == 2)
    }

    // MARK: - Error Handling Tests

    @Test func testGetBook_nonexistentId_returnsNil() async throws {
        // When
        let result = try await repository.getBook(by: UUID())

        // Then
        #expect(result == nil)
    }

    @Test func testUpdateBook_nonexistentBook_throwsError() async throws {
        // Given
        let nonexistentBook = createTestBook()

        // When/Then
        await #expect(throws: BookRepositoryError.bookNotFound) {
            try await repository.updateBook(nonexistentBook)
        }
    }

    @Test func testDeleteBook_nonexistentBook_doesNotThrow() async throws {
        // When/Then - Should not throw for nonexistent book
        try await repository.deleteBook(UUID())
    }
}
