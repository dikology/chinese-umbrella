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

/// Mock BookRepository for previews
private final class MockBookRepository: BookRepository {
    private var books: [AppBook] = []

    init() {
        // Create sample books for preview
        let _ = UUID()
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
