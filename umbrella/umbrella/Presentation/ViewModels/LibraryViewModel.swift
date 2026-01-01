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
@Observable
final class LibraryViewModel {
    private let bookRepository: BookRepository
    private let authViewModel: AuthViewModelProtocol

    // Data
    var books: [AppBook] = []
    var filteredBooks: [AppBook] = []
    var selectedBook: AppBook?

    // State
    var isLoading = false
    var isSearching = false
    var searchQuery = ""
    var selectedFilter: BookFilter = .all

    // UI State
    var showUploadSheet = false
    var showDeleteAlert = false
    var bookToDelete: AppBook?

    // Computed properties for UI access
    var currentUserId: UUID? {
        authViewModel.currentUser?.id
    }

    init(bookRepository: BookRepository, authViewModel: AuthViewModelProtocol) {
        self.bookRepository = bookRepository
        self.authViewModel = authViewModel
    }

    // MARK: - Data Loading

    @MainActor
    func loadBooks() async {
        guard let userId = authViewModel.currentUser?.id else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            books = try await bookRepository.getBooks(for: userId)
            applyFiltering()
        } catch {
            print("Failed to load books: \(error)")
            // TODO: Show error to user
        }
    }

    @MainActor
    func searchBooks(query: String) async {
        searchQuery = query
        isSearching = !query.isEmpty

        if query.isEmpty {
            applyFiltering()
            return
        }

        do {
            guard let userId = authViewModel.currentUser?.id else { return }
            filteredBooks = try await bookRepository.searchBooks(query: query, userId: userId)
        } catch {
            print("Failed to search books: \(error)")
            filteredBooks = []
        }
    }

    // MARK: - Book Management

    @MainActor
    func deleteBook(_ book: AppBook) async {
        do {
            try await bookRepository.deleteBook(book.id)
            books.removeAll { $0.id == book.id }
            applyFiltering()
        } catch {
            print("Failed to delete book: \(error)")
            // TODO: Show error to user
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
        applyFiltering()
    }

    private func applyFiltering() {
        if isSearching { return } // Don't filter when searching

        switch selectedFilter {
        case .all:
            filteredBooks = books
        case .local:
            filteredBooks = books.filter { $0.isLocal }
        case .publicLibrary:
            filteredBooks = books.filter { !$0.isLocal }
        case .recent:
            // Get books read in the last 7 days
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            filteredBooks = books.filter { $0.updatedDate > sevenDaysAgo }
                .sorted { $0.updatedDate > $1.updatedDate }
        case .completed:
            filteredBooks = books.filter { $0.isCompleted }
        }
    }

    // MARK: - Computed Properties

    var displayBooks: [AppBook] {
        isSearching ? filteredBooks : books
    }

    var bookCountText: String {
        let count = displayBooks.count
        return "\(count) book\(count == 1 ? "" : "s")"
    }

    var hasBooks: Bool {
        !displayBooks.isEmpty
    }

    var emptyStateMessage: String {
        if isSearching {
            return "No books found matching '\(searchQuery)'"
        } else {
            switch selectedFilter {
            case .all:
                return "No books yet. Upload your first book to get started!"
            case .local:
                return "No uploaded books yet. Use the camera or photo library to add books."
            case .publicLibrary:
                return "No public library books available yet."
            case .recent:
                return "No recently read books."
            case .completed:
                return "No completed books yet."
            }
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
    case publicLibrary = "Public Library"
    case recent = "Recent"
    case completed = "Completed"

    var icon: String {
        switch self {
        case .all: return "books.vertical"
        case .local: return "camera"
        case .publicLibrary: return "globe"
        case .recent: return "clock"
        case .completed: return "checkmark.circle"
        }
    }
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
        let userId = UUID()
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
}


// MARK: - Preview Instance

/// Mock AuthViewModel for previews
private final class MockAuthViewModel: AuthViewModelProtocol {
    private let mockUser = AppUser(
        id: UUID(),
        email: "preview@example.com",
        displayName: "Preview User",
        hskLevel: 3,
        vocabularyMasteryPct: 25.0
    )

    init() {}

    var isAuthenticated: Bool { true }
    var currentUser: AppUser? { mockUser }
    var isLoading: Bool { false }
    var errorMessage: String? { nil }

    func signUp() async {}
    func signIn() async {}
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {}
    func logout() async {}
}

extension LibraryViewModel {
    /// Preview instance with mock data for SwiftUI previews
    static var preview: LibraryViewModel {
        let viewModel = LibraryViewModel(
            bookRepository: MockBookRepository(),
            authViewModel: MockAuthViewModel()
        )
        // Load the mock books
        Task {
            await viewModel.loadBooks()
        }
        return viewModel
    }
}
