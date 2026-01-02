//
//  EditBookViewModel.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation
import UIKit

/// ViewModel for editing books (adding pages)
@Observable
final class EditBookViewModel {
    private let editBookUseCase: EditBookUseCase
    private let onBookEdited: (() -> Void)?

    // Book being edited
    let existingBook: AppBook

    // Editable fields
    var bookTitle = ""
    var bookAuthor = ""

    // New images to add (maintained for backward compatibility)
    var selectedImages: [UIImage] = []

    // New page management
    var pageList: [PageItem] = []

    // UI state
    var isEditing = false
    var showError = false
    var errorMessage = ""
    var editComplete = false

    // Computed properties
    var existingPageCount: Int {
        existingBook.totalPages
    }

    var newPageCount: Int {
        pageList.count
    }

    var totalPageCount: Int {
        existingPageCount + newPageCount
    }

    var canEdit: Bool {
        !bookTitle.isEmpty && !pageList.isEmpty
    }

    init(
        book: AppBook,
        editBookUseCase: EditBookUseCase,
        onBookEdited: (() -> Void)? = nil
    ) {
        LoggingService.shared.debug("EditBookViewModel init: book.title=\(book.title), book.totalPages=\(book.totalPages), book.author=\(book.author ?? "nil")")
        self.existingBook = book
        self.editBookUseCase = editBookUseCase
        self.onBookEdited = onBookEdited

        // Pre-populate with existing book data
        self.bookTitle = book.title
        self.bookAuthor = book.author ?? ""

        LoggingService.shared.debug("EditBookViewModel init complete: bookTitle=\(bookTitle), bookAuthor=\(bookAuthor), existingPageCount=\(existingPageCount)")
    }

    @MainActor
    func editBook() async {
        guard canEdit else {
            showError(message: "Please enter a title and select at least one photo")
            return
        }

        guard !pageList.isEmpty else {
            showError(message: "Please add at least one photo")
            return
        }

        isEditing = true

        do {
            LoggingService.shared.info("EditBookViewModel: Starting edit with \(pageList.count) pages to add to book '\(existingBook.title)'")

            // Extract UIImages from PageItems for upload
            let images = pageList.map { $0.uiImage }
            LoggingService.shared.debug("EditBookViewModel: Extracted \(images.count) images from pageList")

            // Add new pages with updated metadata
            let editedBook = try await editBookUseCase.addPagesToBook(
                book: existingBook,
                newImages: images,
                updatedTitle: bookTitle,
                updatedAuthor: bookAuthor.isEmpty ? nil : bookAuthor
            )

            LoggingService.shared.info("EditBookViewModel: Successfully edited book: \(editedBook.title) (added \(pageList.count) pages, final total: \(editedBook.totalPages))")
            editComplete = true

            // Notify parent view that a book was edited
            onBookEdited?()

        } catch {
            showError(message: error.localizedDescription)
        }

        isEditing = false
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
