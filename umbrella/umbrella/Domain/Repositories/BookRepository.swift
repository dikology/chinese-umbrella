//
//  BookRepository.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation

/// Repository protocol for book management operations
protocol BookRepository {
    /// Save a new book to the library
    func saveBook(_ book: AppBook) async throws -> AppBook

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

    /// Get recently read books
    func getRecentBooks(for userId: UUID, limit: Int) async throws -> [AppBook]

    /// Update reading progress for a book
    func updateReadingProgress(bookId: UUID, pageIndex: Int) async throws
}

/// Errors that can occur during book operations
enum BookRepositoryError: LocalizedError {
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
}
