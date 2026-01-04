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
        // Compare all properties that affect UI display
        lhs.id == rhs.id &&
        lhs.pageNumber == rhs.pageNumber &&
        lhs.originalImagePath == rhs.originalImagePath &&
        lhs.extractedText == rhs.extractedText &&
        lhs.position == rhs.position
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
    var isLoadingExistingPages = false

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
    func loadExistingPages() async {
        guard !isLoadingExistingPages && existingPageList.isEmpty else { return }

        isLoadingExistingPages = true

        LoggingService.shared.debug("EditBookViewModel: Loading existing pages for book '\(existingBook.title)' with \(existingBook.totalPages) pages")

        let pages = await Task.detached {
            self.existingBook.pages.enumerated().map { index, page in
                ExistingPageItem(
                    id: page.id,
                    pageNumber: page.pageNumber,
                    originalImagePath: page.originalImagePath,
                    extractedText: page.extractedText,
                    position: index
                )
            }
        }.value

        self.existingPageList = pages

        LoggingService.shared.debug("EditBookViewModel: Successfully loaded \(pages.count) existing pages")

        isLoadingExistingPages = false
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
    func updatePageNumber(pageId: UUID, newNumber: Int) {
        LoggingService.shared.debug("EditBookViewModel: Updating page \(pageId) to number \(newNumber)")

        // Find the page and update its number
        if let index = existingPageList.firstIndex(where: { $0.id == pageId }) {
            let oldNumber = existingPageList[index].pageNumber

            // Create a new array with the updated page to ensure SwiftUI detects the change
            var updatedPages = existingPageList
            updatedPages[index] = ExistingPageItem(
                id: existingPageList[index].id,
                pageNumber: newNumber,
                originalImagePath: existingPageList[index].originalImagePath,
                extractedText: existingPageList[index].extractedText,
                position: existingPageList[index].position
            )

            // Replace the entire array to trigger SwiftUI update
            existingPageList = updatedPages

            LoggingService.shared.info("EditBookViewModel: Updated page at index \(index) from number \(oldNumber) to \(newNumber), UI should now reflect change")
        } else {
            LoggingService.shared.warning("EditBookViewModel: Could not find page with ID \(pageId) to update")
        }
    }

    @MainActor
    func savePageNumbers() async {
        LoggingService.shared.debug("EditBookViewModel: savePageNumbers called")

        guard !existingPageList.isEmpty else {
            showError(message: "No pages to save")
            return
        }

        isEditing = true

        do {
            // Sort pages by their page number to get the new order
            let sortedPages = existingPageList.sorted { $0.pageNumber < $1.pageNumber }
            let newPageOrder = sortedPages.map { $0.id }
            
            LoggingService.shared.info("EditBookViewModel: Saving new page order with \(newPageOrder.count) pages. New order: \(sortedPages.map { $0.pageNumber })")

            let updatedBook = try await editBookUseCase.reorderPages(book: existingBook, newPageOrder: newPageOrder)

            LoggingService.shared.info("EditBookViewModel: Successfully saved page numbers for book '\(updatedBook.title)'")
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
