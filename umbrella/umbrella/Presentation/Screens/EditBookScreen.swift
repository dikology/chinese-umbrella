//
//  EditBookScreen.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import SwiftUI

/// Screen for editing books by adding pages or updating metadata
struct EditBookScreen: View {
    @State private var viewModel: EditBookViewModel
    @Environment(\.dismiss) private var dismiss

    // Navigation state
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showPhotoReview = false

    init(book: AppBook, editBookUseCase: EditBookUseCase, onBookEdited: (() -> Void)? = nil) {
        _viewModel = State(initialValue: EditBookViewModel(
            book: book,
            editBookUseCase: editBookUseCase,
            onBookEdited: onBookEdited
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Edit Book")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Update book information or add new pages")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 24) {

                        // Current book info
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Current Book Information")
                                .font(.headline)

                            VStack(spacing: 12) {
                                HStack {
                                    Text("Current pages:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(viewModel.existingPageCount)")
                                        .fontWeight(.semibold)
                                }

                                HStack {
                                    Text("Title:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(viewModel.existingBook.title)
                                        .lineLimit(1)
                                        .fontWeight(.semibold)
                                }

                                if let author = viewModel.existingBook.author {
                                    HStack {
                                        Text("Author:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(author)
                                            .lineLimit(1)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        // Book metadata editing
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Update Book Information")
                                .font(.headline)

                            TextField("Book Title", text: $viewModel.bookTitle)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal)

                            TextField("Author (Optional)", text: $viewModel.bookAuthor)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 16)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal)

                        // Add new pages section
                        VStack(spacing: 16) {
                            Text("Add New Pages")
                                .font(.headline)
                                .padding(.top, 16)

                            // Current status
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Existing pages:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(viewModel.existingPageCount)")
                                }

                                HStack {
                                    Text("New pages:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(viewModel.newPageCount)")
                                }

                                HStack {
                                    Text("Total after edit:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(viewModel.totalPageCount)")
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(12)
                            .padding(.horizontal)

                            // Upload options
                            VStack(spacing: 16) {
                                // Camera option
                                Button {
                                    showCamera = true
                                } label: {
                                    VStack(spacing: 12) {
                                        Image(systemName: "camera")
                                            .font(.system(size: 48))
                                            .foregroundColor(.blue)

                                        Text("Take Photos")
                                            .font(.title3)
                                            .fontWeight(.semibold)

                                        Text("Capture new photos of additional pages")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 24)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .padding(.horizontal)

                                // Photo picker option
                                Button {
                                    showPhotoPicker = true
                                } label: {
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.system(size: 48))
                                            .foregroundColor(.green)

                                        Text("Select from Library")
                                            .font(.title3)
                                            .fontWeight(.semibold)

                                        Text("Choose existing photos to add as new pages")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 24)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .padding(.horizontal)
                            }
                        }

                        // Selected photos count
                        if viewModel.selectedImages.count > 0 {
                            VStack(spacing: 8) {
                                Text("\(viewModel.selectedImages.count) new photo\(viewModel.selectedImages.count == 1 ? "" : "s") selected")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Button {
                                    showPhotoReview = true
                                } label: {
                                    Text("Review Photos")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.top, 8)
                        }

                        Spacer(minLength: 40)
                    }
                }

                // Edit button
                if !viewModel.selectedImages.isEmpty || viewModel.bookTitle != viewModel.existingBook.title || viewModel.bookAuthor != (viewModel.existingBook.author ?? "") {
                    Button {
                        Task {
                            await viewModel.editBook()
                        }
                    } label: {
                        if viewModel.isEditing {
                            HStack {
                                ProgressView()
                                    .tint(.white)
                                Text("Updating...")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue.opacity(0.6))
                            .cornerRadius(12)
                        } else {
                            Text("Update Book")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(viewModel.isEditing || viewModel.bookTitle.isEmpty)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
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
            .sheet(isPresented: $showCamera) {
                CameraView(capturedImages: $viewModel.selectedImages)
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPickerView(selectedImages: $viewModel.selectedImages)
            }
            .sheet(isPresented: $showPhotoReview) {
                PhotoReviewScreen(images: $viewModel.selectedImages)
            }
            .onChange(of: viewModel.editComplete) { oldValue, newValue in
                if newValue {
                    dismiss()
                }
            }
        }
    }
}
