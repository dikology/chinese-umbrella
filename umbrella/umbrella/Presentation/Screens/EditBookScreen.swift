//
//  EditBookScreen.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import SwiftUI

// Import for logging
import class Foundation.Bundle

/// Screen for editing books by adding pages or updating metadata
struct EditBookScreen: View {
    @State private var viewModel: EditBookViewModel
    @Environment(\.dismiss) private var dismiss

    // Navigation state
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showPhotoReview = false

    // Focus state for keyboard management
    @FocusState private var focusedField: FocusField?

    enum FocusField { case title, author }

    init(book: AppBook, editBookUseCase: EditBookUseCase, onBookEdited: (() -> Void)? = nil) {
        LoggingService.shared.debug("EditBookScreen init called with book: \(book.title), pages: \(book.totalPages), author: \(book.author ?? "nil")")
        _viewModel = State(initialValue: EditBookViewModel(
            book: book,
            editBookUseCase: editBookUseCase,
            onBookEdited: onBookEdited,
            logger: LoggingService.shared
        ))
        LoggingService.shared.debug("EditBookViewModel created with existingPageCount: \(_viewModel.wrappedValue.existingPageCount)")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Book info (read-only display)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Current Book")
                                .font(.headline)
                            BookInfoDisplay(book: viewModel.existingBook)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)

                        // Editable metadata
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Update Information")
                                .font(.headline)
                            TextField("Title", text: $viewModel.bookTitle)
                                .focused($focusedField, equals: .title)
                            TextField("Author", text: $viewModel.bookAuthor)
                                .focused($focusedField, equals: .author)
                        }
                        .padding()

                        // Existing pages display and editing
                        if !viewModel.existingPageList.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Existing Pages")
                                    .font(.headline)

                                PageGridView(
                                    pages: $viewModel.pageList,
                                    existingPages: viewModel.existingPageList,
                                    onUpdatePageNumber: { pageId, newNumber in
                                        viewModel.updatePageNumber(pageId: pageId, newNumber: newNumber)
                                    }
                                )
                            }
                            .padding()
                        }

                        // Add new pages
                        if viewModel.existingPageList.isEmpty {
                            PageGridView(pages: $viewModel.pageList)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Add New Pages")
                                    .font(.headline)
                                PageGridView(pages: $viewModel.pageList)
                            }
                            .padding()
                        }

                        // Upload buttons
                        UploadMethodButtons(
                            onCameraTap: openCamera,
                            onLibraryTap: openPhotoPicker
                        )

                        Spacer(minLength: 40)
                    }
                }

                // Fixed button at bottom
                VStack(spacing: 12) {
                    // Save page numbers button (only show if there are existing pages)
                    if !viewModel.existingPageList.isEmpty {
                        PrimaryButton(
                            title: viewModel.isEditing ? "Saving..." : "Save Page Numbers",
                            isLoading: viewModel.isEditing,
                            isEnabled: true
                        ) {
                            Task { await viewModel.savePageNumbers() }
                        }
                    }

                    // Update book button (for adding pages or changing metadata)
                    if !viewModel.pageList.isEmpty ||
                       viewModel.bookTitle != viewModel.existingBook.title ||
                       viewModel.bookAuthor != (viewModel.existingBook.author ?? "") {
                        PrimaryButton(
                            title: viewModel.isEditing ? "Updating..." : "Update Book",
                            isLoading: viewModel.isEditing,
                            isEnabled: !viewModel.bookTitle.isEmpty
                        ) {
                            Task { await viewModel.editBook() }
                        }
                    }
                }
                .padding()
            }
            .loadingOverlay(isPresented: viewModel.isLoadingExistingPages, message: "Loading existing pages...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Edit Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage)
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraViewContainer(
                    pageList: $viewModel.pageList,
                    isPresented: $showCamera
                )
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPickerSheet(selectedPages: $viewModel.pageList)
            }
            .sheet(isPresented: $showPhotoReview) {
                PhotoReviewScreen(pages: $viewModel.pageList)
            }
            .onChange(of: viewModel.editComplete) { oldValue, newValue in
                if newValue {
                    dismiss()
                }
            }
            .task {
                await viewModel.loadExistingPages()
            }
        }
    }

    private func openCamera() {
        focusedField = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showCamera = true
        }
    }

    private func openPhotoPicker() {
        focusedField = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showPhotoPicker = true
        }
    }
}

#Preview {
    // Mock use case for preview
    struct MockEditBookUseCase: EditBookUseCase {
        func addPagesToBook(book: AppBook, newImages: [UIImage], updatedTitle: String?, updatedAuthor: String?) async throws -> AppBook {
            // Mock implementation - return book with one additional page
            var updatedPages = book.pages
            let newPage = AppBookPage(
                id: UUID(),
                bookId: book.id,
                pageNumber: book.totalPages + 1,
                originalImagePath: "/mock/path/new_page.jpg",
                extractedText: "This is mock extracted text for the new page.",
                words: [
                    AppWordSegment(word: "This", startIndex: 0, endIndex: 4),
                    AppWordSegment(word: "is", startIndex: 5, endIndex: 7),
                    AppWordSegment(word: "mock", startIndex: 8, endIndex: 12)
                ]
            )
            updatedPages.append(newPage)

            return AppBook(
                id: book.id,
                title: updatedTitle ?? book.title,
                author: updatedAuthor ?? book.author,
                pages: updatedPages,
                currentPageIndex: book.currentPageIndex,
                isLocal: book.isLocal
            )
        }

        func reorderPages(book: AppBook, newPageOrder: [UUID]) async throws -> AppBook {
            // Mock implementation - just return the book as-is
            return book
        }
    }

    // Create consistent book ID for all pages
    let bookId = UUID()

    // Create mock book with existing pages
    let mockPages = [
        AppBookPage(
            id: UUID(),
            bookId: bookId,
            pageNumber: 1,
            originalImagePath: "/mock/path/page1.jpg",
            extractedText: "This is the first page of the book with some Chinese text.",
            words: [
                AppWordSegment(word: "This", startIndex: 0, endIndex: 4),
                AppWordSegment(word: "is", startIndex: 5, endIndex: 7),
                AppWordSegment(word: "the", startIndex: 8, endIndex: 11),
                AppWordSegment(word: "first", startIndex: 12, endIndex: 17)
            ]
        ),
        AppBookPage(
            id: UUID(),
            bookId: bookId,
            pageNumber: 2,
            originalImagePath: "/mock/path/page2.jpg",
            extractedText: "This is the second page with more content.",
            words: [
                AppWordSegment(word: "This", startIndex: 0, endIndex: 4),
                AppWordSegment(word: "is", startIndex: 5, endIndex: 7),
                AppWordSegment(word: "the", startIndex: 8, endIndex: 11),
                AppWordSegment(word: "second", startIndex: 12, endIndex: 18)
            ]
        ),
        AppBookPage(
            id: UUID(),
            bookId: bookId,
            pageNumber: 3,
            originalImagePath: "/mock/path/page3.jpg",
            extractedText: "This is the third and final page.",
            words: [
                AppWordSegment(word: "This", startIndex: 0, endIndex: 4),
                AppWordSegment(word: "is", startIndex: 5, endIndex: 7),
                AppWordSegment(word: "the", startIndex: 8, endIndex: 11),
                AppWordSegment(word: "third", startIndex: 12, endIndex: 17)
            ]
        )
    ]

    let mockBook = AppBook(
        id: bookId,
        title: "Sample Chinese Book",
        author: "Test Author",
        pages: mockPages,
        currentPageIndex: 0,
        isLocal: true,
        language: "zh-Hans",
        genre: .literature,
        description: "A sample book for testing the edit functionality"
    )

    return EditBookScreen(
        book: mockBook,
        editBookUseCase: MockEditBookUseCase(),
        onBookEdited: {
            LoggingService.shared.debug("Book edited callback triggered")
        }
    )
}
