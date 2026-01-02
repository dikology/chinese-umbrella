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
            onBookEdited: onBookEdited
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

                        // Existing pages display
                        if viewModel.existingPageCount > 0 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Existing Pages: \(viewModel.existingPageCount)")
                                    .font(.headline)
                                // Show thumbnail grid of existing pages
                            }
                            .padding()
                        }

                        // Add new pages
                        PageGridView(pages: $viewModel.pageList)

                        // Upload buttons
                        UploadMethodButtons(
                            onCameraTap: openCamera,
                            onLibraryTap: openPhotoPicker
                        )

                        Spacer(minLength: 40)
                    }
                }

                // Fixed button at bottom
                if !viewModel.pageList.isEmpty ||
                   viewModel.bookTitle != viewModel.existingBook.title {
                    PrimaryButton(
                        title: viewModel.isEditing ? "Updating..." : "Update Book",
                        isLoading: viewModel.isEditing,
                        isEnabled: !viewModel.bookTitle.isEmpty
                    ) {
                        Task { await viewModel.editBook() }
                    }
                    .padding()
                }
            }
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
