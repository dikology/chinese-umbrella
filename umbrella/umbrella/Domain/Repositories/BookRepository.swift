//
//  BookRepository.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation

/// Filters for advanced book search
public struct BookSearchFilters {
    public var genres: [BookGenre]?
    public var languages: [String]?
    public var difficulties: [ReadingDifficulty]?
    public var progressStatuses: [ReadingProgressStatus]?
    public var hasTags: [String]?
    public var minWordCount: Int?
    public var maxWordCount: Int?

    public init(
        genres: [BookGenre]? = nil,
        languages: [String]? = nil,
        difficulties: [ReadingDifficulty]? = nil,
        progressStatuses: [ReadingProgressStatus]? = nil,
        hasTags: [String]? = nil,
        minWordCount: Int? = nil,
        maxWordCount: Int? = nil
    ) {
        self.genres = genres
        self.languages = languages
        self.difficulties = difficulties
        self.progressStatuses = progressStatuses
        self.hasTags = hasTags
        self.minWordCount = minWordCount
        self.maxWordCount = maxWordCount
    }
}

/// Reading progress status categories
public enum ReadingProgressStatus: String {
    case notStarted = "not_started"     // 0% progress
    case inProgress = "in_progress"     // 1-99% progress
    case completed = "completed"        // 100% progress
}

/// Library statistics for user analytics
public struct LibraryStatistics {
    public let totalBooks: Int
    public let totalWords: Int
    public let totalReadingTimeMinutes: Int
    public let completedBooks: Int
    public let booksByGenre: [BookGenre: Int]
    public let booksByLanguage: [String: Int]
    public let averageReadingProgress: Double
}

/// Repository protocol for book management operations
protocol BookRepository {
    /// Save a new book to the library
    func saveBook(_ book: AppBook, userId: UUID) async throws -> AppBook

    /// Get a book by ID
    func getBook(by id: UUID) async throws -> AppBook?

    /// Get all books for a user
    func getBooks(for userId: UUID) async throws -> [AppBook]

    /// Update an existing book
    func updateBook(_ book: AppBook) async throws -> AppBook

    /// Delete a book
    func deleteBook(_ bookId: UUID) async throws

    /// Search books by title or author
    func searchBooks(query: String, userId: UUID) async throws -> [AppBook]

    /// Advanced search with filters
    func searchBooksWithFilters(query: String?, filters: BookSearchFilters, userId: UUID) async throws -> [AppBook]

    /// Get books by genre
    func getBooksByGenre(_ genre: BookGenre, userId: UUID) async throws -> [AppBook]

    /// Get books by language
    func getBooksByLanguage(_ language: String, userId: UUID) async throws -> [AppBook]

    /// Get books by reading progress status
    func getBooksByProgressStatus(_ status: ReadingProgressStatus, userId: UUID) async throws -> [AppBook]

    /// Get recently read books
    func getRecentBooks(for userId: UUID, limit: Int) async throws -> [AppBook]

    /// Get library statistics
    func getLibraryStatistics(userId: UUID) async throws -> LibraryStatistics

    /// Update reading progress for a book
    func updateReadingProgress(bookId: UUID, pageIndex: Int) async throws

    /// Reorder pages within a book
    func reorderPages(bookId: UUID, newPageOrder: [UUID]) async throws -> AppBook
}

/// Errors that can occur during book operations
enum BookRepositoryError: LocalizedError, Equatable {
    case bookNotFound
    case invalidBookData
    case saveFailed
    case deleteFailed
    case networkError
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .bookNotFound:
            return "Book not found"
        case .invalidBookData:
            return "Invalid book data"
        case .saveFailed:
            return "Failed to save book"
        case .deleteFailed:
            return "Failed to delete book"
        case .networkError:
            return "Network connection error"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }

    // Equatable conformance for testing
    static func == (lhs: BookRepositoryError, rhs: BookRepositoryError) -> Bool {
        switch (lhs, rhs) {
        case (.bookNotFound, .bookNotFound):
            return true
        case (.invalidBookData, .invalidBookData):
            return true
        case (.saveFailed, .saveFailed):
            return true
        case (.deleteFailed, .deleteFailed):
            return true
        case (.networkError, .networkError):
            return true
        case (.unknown, .unknown):
            return true // Don't compare the actual Error values
        default:
            return false
        }
    }
}
