//
//  BookUploadScreen.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import SwiftUI

// Design System Imports
import Foundation

/// Screen for uploading books with camera and photo picker options
struct BookUploadScreen: View {
    @State private var viewModel: BookUploadViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    // Navigation state
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showPhotoReview = false

    // Focus state for keyboard management
    @FocusState private var focusedField: FocusField?

    enum FocusField {
        case title, author
    }

    init(bookUploadUseCase: BookUploadUseCase, userId: UUID, onBookUploaded: (() -> Void)? = nil) {
        _viewModel = State(initialValue: BookUploadViewModel(
            bookUploadUseCase: bookUploadUseCase,
            userId: userId,
            onBookUploaded: onBookUploaded
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Header
                    VStack(spacing: 8) {
                        Text("Upload Book")
                            .titleStyle()
                        Text("Add pages and organize them")
                            .bodySecondaryStyle()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)

                    ScrollView {
                        VStack(spacing: 24) {
                            // MARK: - Metadata Section
                            CardContainer {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Book Information")
                                        .headingStyle()

                                    TextField("Book Title", text: $viewModel.bookTitle)
                                        .focused($focusedField, equals: .title)
                                        .textFieldStyle()

                                    TextField("Author (Optional)", text: $viewModel.bookAuthor)
                                        .focused($focusedField, equals: .author)
                                        .textFieldStyle()
                                }
                                .padding(.horizontal)
                            }
                            .padding(.horizontal)

                            // MARK: - Page Management Section
                            if !viewModel.pageList.isEmpty {
                                PageGridView(pages: $viewModel.pageList)
                            }

                            // MARK: - Upload Methods
                            if viewModel.pageList.count < 500 { // Reasonable limit
                                VStack(spacing: 16) {
                                    Text("Add Photos")
                                        .headingStyle()
                                        .padding(.top, 16)
                                        .padding(.horizontal)

                                    UploadMethodButtons(
                                        onCameraTap: openCamera,
                                        onLibraryTap: openPhotoPicker
                                    )
                                    .padding(.horizontal)
                                }
                            }

                            Spacer(minLength: 40)
                        }
                    }

                    // MARK: - Upload Button (Fixed at Bottom)
                    if !viewModel.pageList.isEmpty {
                        VStack(spacing: 12) {
                            PrimaryButton(
                                title: viewModel.isUploading ? "Processing..." : "Upload Book",
                                isLoading: viewModel.isUploading,
                                isEnabled: !viewModel.bookTitle.isEmpty
                            ) {
                                Task {
                                    await viewModel.uploadBook()
                                }
                            }

                            Text("\(viewModel.pageList.count) page(s) ready")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
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
            .alert("Error", isPresented: $viewModel.showError) {
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
            .onChange(of: viewModel.uploadComplete) { oldValue, newValue in
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

/// ViewModel for BookUploadScreen
@Observable
final class BookUploadViewModel {
    private let bookUploadUseCase: BookUploadUseCase
    private let userId: UUID
    private let onBookUploaded: (() -> Void)?

    var bookTitle = ""
    var bookAuthor = ""
    var selectedImages: [UIImage] = [] // Keep for backward compatibility
    var pageList: [PageItem] = [] // New page management
    var isUploading = false
    var showError = false
    var errorMessage = ""
    var uploadComplete = false

    init(bookUploadUseCase: BookUploadUseCase, userId: UUID, onBookUploaded: (() -> Void)? = nil) {
        self.bookUploadUseCase = bookUploadUseCase
        self.userId = userId
        self.onBookUploaded = onBookUploaded
    }

    @MainActor
    func uploadBook() async {
        guard !bookTitle.isEmpty else {
            showError(message: "Please enter a book title")
            return
        }

        guard !pageList.isEmpty else {
            showError(message: "Please add at least one photo")
            return
        }

        isUploading = true

        do {
            // Extract UIImages from PageItems for upload
            let images = pageList.map { $0.uiImage }

            let book = try await bookUploadUseCase.uploadBook(
                images: images,
                title: bookTitle,
                author: bookAuthor.isEmpty ? nil : bookAuthor,
                userId: userId
            )

            LoggingService.shared.info("Successfully uploaded book: \(book.title)")
            uploadComplete = true

            // Notify parent view that a book was uploaded
            onBookUploaded?()

        } catch {
            showError(message: error.localizedDescription)
        }

        isUploading = false
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

#Preview {
    // Mock use case for preview
    struct MockBookUploadUseCase: BookUploadUseCase {
        func uploadBook(images: [UIImage], title: String, author: String?, userId: UUID) async throws -> AppBook {
            // Mock implementation
            return AppBook(title: title, author: author, pages: [])
        }

        func validateImages(_ images: [UIImage]) -> [ImageValidationResult] {
            return images.map { _ in .valid }
        }

        func processImage(_ image: UIImage) async throws -> ProcessedImage {
            throw BookUploadError.networkError
        }

        func generateTitle(from text: String) -> String {
            return "Mock Title"
        }
    }

    return BookUploadScreen(bookUploadUseCase: MockBookUploadUseCase(), userId: UUID())
}
