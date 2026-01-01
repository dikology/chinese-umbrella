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

    // New images to add
    var selectedImages: [UIImage] = []

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
        selectedImages.count
    }

    var totalPageCount: Int {
        existingPageCount + newPageCount
    }

    var canEdit: Bool {
        !bookTitle.isEmpty && !selectedImages.isEmpty
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

        guard !selectedImages.isEmpty else {
            showError(message: "Please select at least one photo to add")
            return
        }

        isEditing = true

        do {
            // Add new pages with updated metadata
            let editedBook = try await editBookUseCase.addPagesToBook(
                book: existingBook,
                newImages: selectedImages,
                updatedTitle: bookTitle,
                updatedAuthor: bookAuthor.isEmpty ? nil : bookAuthor
            )

            LoggingService.shared.info("Successfully edited book: \(editedBook.title) (added \(selectedImages.count) pages)")
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
