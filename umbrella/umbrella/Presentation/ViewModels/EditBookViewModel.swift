//
//  EditBookViewModel.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation
import UIKit
import SwiftUI

/// Represents an existing page in a book for editing
struct ExistingPageItem: Identifiable, Equatable {
    let id: UUID
    let pageNumber: Int
    let originalImagePath: String
    let extractedText: String
    var position: Int // For reordering

    static func == (lhs: ExistingPageItem, rhs: ExistingPageItem) -> Bool {
        lhs.id == rhs.id
    }
}

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

    // Existing page management
    var existingPageList: [ExistingPageItem] = []

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

        // Initialize existing pages for editing
        self.existingPageList = book.pages.enumerated().map { index, page in
            ExistingPageItem(
                id: page.id,
                pageNumber: page.pageNumber,
                originalImagePath: page.originalImagePath,
                extractedText: page.extractedText,
                position: index
            )
        }

        LoggingService.shared.debug("EditBookViewModel init complete: bookTitle=\(bookTitle), bookAuthor=\(bookAuthor), existingPageCount=\(existingPageCount), existingPageList.count=\(existingPageList.count)")
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

    @MainActor
    func reorderExistingPages(from source: IndexSet, to destination: Int) {
        LoggingService.shared.debug("EditBookViewModel: reorderExistingPages from \(source) to \(destination)")
        existingPageList.move(fromOffsets: source, toOffset: destination)
        // Update positions
        for (index, _) in existingPageList.enumerated() {
            existingPageList[index].position = index
        }
        LoggingService.shared.debug("EditBookViewModel: Reordered existing pages, new count: \(existingPageList.count)")
    }

    @MainActor
    func savePageReorder() async {
        LoggingService.shared.debug("EditBookViewModel: savePageReorder called")

        guard !existingPageList.isEmpty else {
            showError(message: "No pages to reorder")
            return
        }

        isEditing = true

        do {
            let newPageOrder = existingPageList.map { $0.id }
            LoggingService.shared.info("EditBookViewModel: Saving new page order with \(newPageOrder.count) pages")

            let updatedBook = try await editBookUseCase.reorderPages(book: existingBook, newPageOrder: newPageOrder)

            LoggingService.shared.info("EditBookViewModel: Successfully reordered pages in book '\(updatedBook.title)'")
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
