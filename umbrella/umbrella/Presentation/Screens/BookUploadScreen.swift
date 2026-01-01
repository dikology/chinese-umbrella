//
//  BookUploadScreen.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import SwiftUI

// Design System Imports

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
                colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Upload Book")
                        .titleStyle()

                    Text("Take photos of book pages or select from your library")
                        .bodySecondaryStyle()
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Book metadata input
                CardContainer {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Book Information")
                            .headingStyle()

                        TextField("Book Title", text: $viewModel.bookTitle)
                            .textFieldStyle()

                        TextField("Author (Optional)", text: $viewModel.bookAuthor)
                            .textFieldStyle()
                    }
                }
                .padding(.horizontal)

                // Upload options
                VStack(spacing: 16) {
                    Text("Choose Upload Method")
                        .headingStyle()
                        .padding(.top, 16)

                    // Camera option
                    Button {
                        showCamera = true
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "camera")
                                .font(.system(size: 48))
                                .foregroundColor(colors.primary)

                            Text("Take Photos")
                                .subheadingStyle()

                            Text("Capture new photos of book pages")
                                .bodySecondaryStyle()
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(colors.blueTint)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(colors.primary.opacity(0.3), lineWidth: 1)
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
                                .foregroundColor(colors.success)

                            Text("Select from Library")
                                .subheadingStyle()

                            Text("Choose existing photos from your device")
                                .bodySecondaryStyle()
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(colors.greenTint)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(colors.success.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                }

                // Selected photos count
                if viewModel.selectedImages.count > 0 {
                    VStack(spacing: 8) {
                        Text("\(viewModel.selectedImages.count) photo\(viewModel.selectedImages.count == 1 ? "" : "s") selected")
                            .bodySecondaryStyle()

                        Button {
                            showPhotoReview = true
                        } label: {
                            Text("Review Photos")
                                .bodySecondaryStyle()
                                .foregroundColor(colors.primary)
                        }
                    }
                    .padding(.top, 8)
                }

                Spacer()

                // Upload button
                if !viewModel.selectedImages.isEmpty {
                    PrimaryButton(
                        title: viewModel.isUploading ? "Processing..." : "Upload Book",
                        isLoading: viewModel.isUploading,
                        isEnabled: !viewModel.bookTitle.isEmpty
                    ) {
                        Task {
                            await viewModel.uploadBook()
                        }
                    }
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
            .alert("Upload Error", isPresented: $viewModel.showError) {
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
            .onChange(of: viewModel.uploadComplete) { oldValue, newValue in
                if newValue {
                    dismiss()
                }
                }
            }
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
    var selectedImages: [UIImage] = []
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

        guard !selectedImages.isEmpty else {
            showError(message: "Please select at least one photo")
            return
        }

        isUploading = true

        do {
            let book = try await bookUploadUseCase.uploadBook(
                images: selectedImages,
                title: bookTitle,
                author: bookAuthor.isEmpty ? nil : bookAuthor,
                userId: userId
            )

            print("Successfully uploaded book: \(book.title)")
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
