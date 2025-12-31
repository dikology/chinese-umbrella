//
//  BookUploadScreen.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import SwiftUI

/// Screen for uploading books with camera and photo picker options
struct BookUploadScreen: View {
    @State private var viewModel: BookUploadViewModel
    @Environment(\.dismiss) private var dismiss

    // Navigation state
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showPhotoReview = false

    init(bookUploadUseCase: BookUploadUseCase) {
        _viewModel = State(initialValue: BookUploadViewModel(bookUploadUseCase: bookUploadUseCase))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Upload Book")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Take photos of book pages or select from your library")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Book metadata input
                VStack(alignment: .leading, spacing: 16) {
                    Text("Book Information")
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

                // Upload options
                VStack(spacing: 16) {
                    Text("Choose Upload Method")
                        .font(.headline)
                        .padding(.top, 16)

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

                            Text("Capture new photos of book pages")
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

                            Text("Choose existing photos from your device")
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

                // Selected photos count
                if viewModel.selectedImages.count > 0 {
                    VStack(spacing: 8) {
                        Text("\(viewModel.selectedImages.count) photo\(viewModel.selectedImages.count == 1 ? "" : "s") selected")
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

                Spacer()

                // Upload button
                if !viewModel.selectedImages.isEmpty {
                    Button {
                        Task {
                            await viewModel.uploadBook()
                        }
                    } label: {
                        if viewModel.isUploading {
                            HStack {
                                ProgressView()
                                    .tint(.white)
                                Text("Processing...")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue.opacity(0.6))
                            .cornerRadius(12)
                        } else {
                            Text("Upload Book")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(viewModel.isUploading || viewModel.bookTitle.isEmpty)
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

/// ViewModel for BookUploadScreen
@Observable
final class BookUploadViewModel {
    private let bookUploadUseCase: BookUploadUseCase

    var bookTitle = ""
    var bookAuthor = ""
    var selectedImages: [UIImage] = []
    var isUploading = false
    var showError = false
    var errorMessage = ""
    var uploadComplete = false

    init(bookUploadUseCase: BookUploadUseCase) {
        self.bookUploadUseCase = bookUploadUseCase
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
                author: bookAuthor.isEmpty ? nil : bookAuthor
            )

            print("Successfully uploaded book: \(book.title)")
            uploadComplete = true

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
        func uploadBook(images: [UIImage], title: String, author: String?) async throws -> AppBook {
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

    return BookUploadScreen(bookUploadUseCase: MockBookUploadUseCase())
}
