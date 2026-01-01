//
//  LibraryViewModel.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation
import SwiftUI

/// ViewModel for the library screen managing book collections
@Observable
final class LibraryViewModel {
    private let bookRepository: BookRepository
    private let authViewModel: AuthViewModel

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

    init(bookRepository: BookRepository, authViewModel: AuthViewModel) {
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
