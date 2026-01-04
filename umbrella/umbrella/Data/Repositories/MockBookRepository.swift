//
//  MockBookRepository.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation

/// Mock BookRepository for previews and testing with sample data
final class MockBookRepository: BookRepository {
    private var books: [AppBook] = []

    init() {
        // Create sample books for preview
        let bookId1 = UUID()
        let bookId2 = UUID()
        let bookId3 = UUID()

        books = [
            AppBook(
                id: bookId1,
                title: "Journey to the West",
                author: "Wu Cheng'en",
                pages: [
                    AppBookPage(
                        bookId: bookId1,
                        pageNumber: 1,
                        originalImagePath: "/preview/page1.jpg",
                        extractedText: "孙悟空大闹天宫",
                        words: [
                            AppWordSegment(word: "孙悟空", pinyin: "Sūn Wùkōng", startIndex: 0, endIndex: 3),
                            AppWordSegment(word: "大闹", pinyin: "dànào", startIndex: 4, endIndex: 6),
                            AppWordSegment(word: "天宫", pinyin: "tiāngōng", startIndex: 7, endIndex: 9)
                        ]
                    )
                ],
                currentPageIndex: 0,
                isLocal: true,
                language: "zh-Hans",
                genre: .literature,
                totalWords: 1250
            ),
            AppBook(
                id: bookId2,
                title: "Harry Potter and the Philosopher's Stone",
                author: "J.K. Rowling",
                pages: [
                    AppBookPage(
                        bookId: bookId2,
                        pageNumber: 1,
                        originalImagePath: "/preview/page1.jpg",
                        extractedText: "Mr. and Mrs. Dursley, of number four, Privet Drive...",
                        words: []
                    )
                ],
                currentPageIndex: 5,
                isLocal: false,
                language: "en",
                genre: .fiction,
                totalWords: 76944
            ),
            AppBook(
                id: bookId3,
                title: "Modern Chinese Grammar",
                author: "Various Authors",
                pages: [
                    AppBookPage(
                        bookId: bookId3,
                        pageNumber: 1,
                        originalImagePath: "/preview/page1.jpg",
                        extractedText: "学习中文语法",
                        words: [
                            AppWordSegment(word: "学习", pinyin: "xuéxí", startIndex: 0, endIndex: 2),
                            AppWordSegment(word: "中文", pinyin: "Zhōngwén", startIndex: 3, endIndex: 5),
                            AppWordSegment(word: "语法", pinyin: "yǔfǎ", startIndex: 6, endIndex: 8)
                        ]
                    )
                ],
                currentPageIndex: 15,
                isLocal: true,
                language: "zh-Hans",
                genre: .education,
                totalWords: 5200
            )
        ]
    }

    func saveBook(_ book: AppBook, userId: UUID) async throws -> AppBook {
        books.append(book)
        return book
    }

    func getBook(by id: UUID) async throws -> AppBook? {
        books.first { $0.id == id }
    }

    func getBooks(for userId: UUID) async throws -> [AppBook] {
        books
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
        books.filter { $0.title.lowercased().contains(query.lowercased()) }
    }

    func searchBooksWithFilters(query: String?, filters: BookSearchFilters, userId: UUID) async throws -> [AppBook] {
        var filteredBooks = books

        if let query = query, !query.isEmpty {
            filteredBooks = filteredBooks.filter { $0.title.lowercased().contains(query.lowercased()) }
        }

        return filteredBooks
    }

    func getBooksByGenre(_ genre: BookGenre, userId: UUID) async throws -> [AppBook] {
        books.filter { $0.genre == genre }
    }

    func getBooksByLanguage(_ language: String, userId: UUID) async throws -> [AppBook] {
        books.filter { $0.language == language }
    }

    func getBooksByProgressStatus(_ status: ReadingProgressStatus, userId: UUID) async throws -> [AppBook] {
        books.filter {
            switch status {
            case .notStarted: return $0.readingProgress == 0.0
            case .inProgress: return $0.readingProgress > 0.0 && $0.readingProgress < 1.0
            case .completed: return $0.readingProgress >= 1.0
            }
        }
    }

    func getRecentBooks(for userId: UUID, limit: Int) async throws -> [AppBook] {
        Array(books.sorted { $0.updatedDate > $1.updatedDate }.prefix(limit))
    }

    func getLibraryStatistics(userId: UUID) async throws -> LibraryStatistics {
        LibraryStatistics(
            totalBooks: books.count,
            totalWords: books.reduce(0) { $0 + ($1.totalWords ?? 0) },
            totalReadingTimeMinutes: books.reduce(0) { $0 + ($1.estimatedReadingTimeMinutes ?? 0) },
            completedBooks: books.filter { $0.isCompleted }.count,
            booksByGenre: [:], // Simplified for preview
            booksByLanguage: [:], // Simplified for preview
            averageReadingProgress: books.isEmpty ? 0.0 : books.reduce(0.0) { $0 + $1.readingProgress } / Double(books.count)
        )
    }

    func updateReadingProgress(bookId: UUID, pageIndex: Int) async throws {
        // No-op for preview
    }

    func reorderPages(bookId: UUID, newPageOrder: [UUID]) async throws -> AppBook {
        // For preview, just return the book unchanged
        guard let book = books.first(where: { $0.id == bookId }) else {
            throw BookRepositoryError.bookNotFound
        }
        return book
    }
}
