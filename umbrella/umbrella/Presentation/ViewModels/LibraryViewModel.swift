//
//  LibraryViewModel.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation
import SwiftUI
import AuthenticationServices

/// Protocol for auth view model interface
protocol AuthViewModelProtocol {
    var currentUser: AppUser? { get }
}

/// ViewModel for the library screen managing book collections
/// Represents the current state of the library view
enum LibraryViewState {
    case loading
    case loaded([AppBook])
    case error(String)
}

@Observable
final class LibraryViewModel {
    private let bookRepository: BookRepository
    private let userId: UUID
    private let logger: Logger

    // Data
    var selectedBook: AppBook?

    // State
    var viewState: LibraryViewState = .loading
    var selectedFilter: BookFilter = .all

    // UI State
    var showUploadSheet = false
    var showDeleteAlert = false
    var bookToDelete: AppBook?
    var errorAlert: ErrorAlert?

    // Computed properties for UI access
    var currentUserId: UUID? {
        userId
    }

    init(bookRepository: BookRepository, userId: UUID, logger: Logger = LoggingService.shared) {
        self.bookRepository = bookRepository
        self.userId = userId
        self.logger = logger
    }

    // MARK: - Data Loading

    @MainActor
    func loadBooks() async {
        logger.debug("LibraryViewModel: loadBooks called")
        viewState = .loading

        do {
            let loadedBooks = try await bookRepository.getBooks(for: userId)
            logger.debug("LibraryViewModel: Loaded \(loadedBooks.count) books")
            for (index, book) in loadedBooks.enumerated() {
                logger.debug("LibraryViewModel: Book \(index): '\(book.title)' has \(book.totalPages) pages")
            }
            let filteredBooks = applyFiltering(to: loadedBooks, filter: selectedFilter)
            viewState = .loaded(filteredBooks)
            logger.debug("LibraryViewModel: Books loaded and filtered, displayBooks count: \(displayBooks.count)")
            for (index, book) in displayBooks.enumerated() {
                logger.debug("LibraryViewModel: Display book \(index): '\(book.title)' has \(book.totalPages) pages")
            }
        } catch {
            logger.error("LibraryViewModel: Failed to load books", error: error)
            viewState = .error("Could not load your book library. Please check your connection and try again.")
            errorAlert = ErrorAlert(
                title: "Failed to Load Books",
                message: "Could not load your book library. Please check your connection and try again."
            )
        }
    }


    // MARK: - Book Management

    @MainActor
    func deleteBook(_ book: AppBook) async {
        do {
            try await bookRepository.deleteBook(book.id)

            // Update the state by removing the book and reapplying filter
            if case .loaded(let books) = viewState {
                let updatedBooks = books.filter { $0.id != book.id }
                let filteredBooks = applyFiltering(to: updatedBooks, filter: selectedFilter)
                viewState = .loaded(filteredBooks)
            }
        } catch {
            logger.error("LibraryViewModel: Failed to delete book", error: error)
            errorAlert = ErrorAlert(
                title: "Delete Failed",
                message: "Could not delete '\(book.title)'. Please try again."
            )
        }
    }

    func selectBook(_ book: AppBook) {
        selectedBook = book
    }

    func clearSelection() {
        selectedBook = nil
    }

    // MARK: - Filtering

    func setFilter(_ filter: BookFilter) {
        selectedFilter = filter

        // Reapply filter to current books if loaded
        if case .loaded(let books) = viewState {
            let filteredBooks = applyFiltering(to: books, filter: filter)
            viewState = .loaded(filteredBooks)
        }
    }

    private func applyFiltering(to books: [AppBook], filter: BookFilter) -> [AppBook] {
        switch filter {
        case .all:
            return books
        case .local:
            return books.filter { $0.isLocal }
        case .groupLibrary:
            return books.filter { !$0.isLocal }
        }
    }

    // MARK: - Computed Properties

    var displayBooks: [AppBook] {
        switch viewState {
        case .loaded(let books):
            return books
        case .loading, .error:
            return []
        }
    }

    var isLoading: Bool {
        if case .loading = viewState { return true }
        return false
    }

    var bookCountText: String {
        let count = displayBooks.count
        return "\(count) book\(count == 1 ? "" : "s")"
    }

    var hasBooks: Bool {
        !displayBooks.isEmpty
    }

    var emptyStateMessage: String {
        switch viewState {
        case .error(let message):
            return message
        case .loaded(let books):
            if books.isEmpty {
                switch selectedFilter {
                case .all:
                    return "No books yet. Upload your first book to get started!"
                case .local:
                    return "No uploaded books yet. Use the camera or photo library to add books."
                case .groupLibrary:
                    return "No group library books available yet."
                }
            } else {
                return ""
            }
        case .loading:
            return "Loading your books..."
        }
    }

    // MARK: - UI Actions

    func showDeleteConfirmation(for book: AppBook) {
        bookToDelete = book
        showDeleteAlert = true
    }

    func confirmDelete() {
        guard let book = bookToDelete else { return }
        Task {
            await deleteBook(book)
        }
        bookToDelete = nil
        showDeleteAlert = false
    }

    func cancelDelete() {
        bookToDelete = nil
        showDeleteAlert = false
    }
}

/// Filter options for the library
enum BookFilter: String, CaseIterable {
    case all = "All Books"
    case local = "My Books"
    case groupLibrary = "Group Library"

    var icon: String {
        switch self {
        case .all: return "books.vertical"
        case .local: return "camera"
        case .groupLibrary: return "globe"
        }
    }
}

/// Error alert for user feedback
struct ErrorAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

/// Book list item view model
struct BookListItem {
    let book: AppBook

    var title: String { book.title }
    var author: String { book.author ?? "Unknown Author" }
    var pageCount: String { "\(book.totalPages) pages" }
    var progressText: String { "\(Int(book.readingProgress * 100))% read" }
    var isCompleted: Bool { book.isCompleted }
    var lastReadDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: book.updatedDate, relativeTo: Date())
    }
}

// MARK: - Preview Support

// MARK: - Preview Instance

extension LibraryViewModel {
    /// Preview instance with mock data for SwiftUI previews
    static var preview: LibraryViewModel {
        let viewModel = LibraryViewModel(
            bookRepository: MockBookRepository(),
            userId: UUID()
        )
        // Load the mock books
        Task {
            await viewModel.loadBooks()
        }
        return viewModel
    }
}
