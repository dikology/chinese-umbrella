//
//  OCRProgressScreen.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import SwiftUI

/// Screen showing OCR processing progress for book pages
struct OCRProgressScreen: View {
    @State var viewModel: OCRProgressViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Processing Book")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Extracting text from \(viewModel.totalPages) page\(viewModel.totalPages == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                // Overall progress
                VStack(spacing: 12) {
                    ProgressView(value: viewModel.overallProgress, total: 1.0)
                        .progressViewStyle(.linear)
                        .tint(.blue)

                    HStack {
                        Text("\(Int(viewModel.overallProgress * 100))% complete")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(viewModel.completedPages)/\(viewModel.totalPages) pages")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // Current page being processed
                if let currentPage = viewModel.currentPageInfo {
                    VStack(spacing: 16) {
                        Text("Processing Page \(currentPage.pageNumber)")
                            .font(.headline)

                        // Page image preview
                        ZStack {
                            Image(uiImage: currentPage.image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )

                            // Processing overlay
                            if currentPage.status == .processing {
                                ZStack {
                                    Color.black.opacity(0.3)
                                    VStack(spacing: 8) {
                                        ProgressView()
                                            .tint(.white)
                                        Text("Extracting text...")
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                    }
                                }
                                .cornerRadius(8)
                            }

                            // Status indicator
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    StatusIndicator(status: currentPage.status)
                                        .padding(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Page list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.pageProgress) { page in
                            PageProgressRow(page: page)
                        }
                    }
                    .padding(.horizontal)
                }

                // Processing status messages
                if let statusMessage = viewModel.statusMessage {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.isError ? "exclamationmark.triangle" : "info.circle")
                            .foregroundColor(viewModel.isError ? .red : .blue)

                        Text(statusMessage)
                            .font(.subheadline)
                            .foregroundColor(viewModel.isError ? .red : .secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(viewModel.isError ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }

                Spacer()

                // Bottom buttons
                VStack(spacing: 12) {
                    if viewModel.isComplete {
                        Button {
                            dismiss()
                        } label: {
                            Text("View Book")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    } else if viewModel.canCancel {
                        Button {
                            viewModel.cancelProcessing()
                        } label: {
                            Text("Cancel Processing")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }

                    if viewModel.isComplete {
                        Text("Book processing complete!")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true) // Prevent going back during processing
            .onAppear {
                viewModel.startProcessing()
            }
            .alert("Processing Error", isPresented: $viewModel.showErrorAlert) {
                Button("Retry") {
                    viewModel.retryProcessing()
                }
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

/// Status indicator for page processing
struct StatusIndicator: View {
    let status: PageProcessingStatus

    var body: some View {
        ZStack {
            Circle()
                .fill(status.color.opacity(0.9))
                .frame(width: 24, height: 24)

            Image(systemName: status.icon)
                .foregroundColor(.white)
                .font(.system(size: 12))
        }
    }
}

/// Progress row for individual pages
struct PageProgressRow: View {
    let page: PageProgressInfo

    var body: some View {
        HStack(spacing: 12) {
            // Page number
            Text("\(page.pageNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .center)

            // Status indicator
            StatusIndicator(status: page.status)

            // Page title or status
            VStack(alignment: .leading, spacing: 2) {
                Text(page.title)
                    .font(.subheadline)
                    .lineLimit(1)

                if let subtitle = page.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Progress indicator
            if page.status == .processing {
                ProgressView()
                    .scaleEffect(0.7)
            } else if page.status == .completed {
                Image(systemName: "checkmark")
                    .foregroundColor(.green)
                    .font(.system(size: 14))
            } else if page.status == .failed {
                Image(systemName: "xmark")
                    .foregroundColor(.red)
                    .font(.system(size: 14))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

/// ViewModel for OCR progress screen
@Observable
final class OCRProgressViewModel {
    private let bookUploadUseCase: BookUploadUseCase
    private let images: [UIImage]
    private let bookTitle: String
    private let bookAuthor: String?

    var totalPages: Int
    var completedPages = 0
    var overallProgress: Double = 0.0
    var pageProgress: [PageProgressInfo] = []
    var currentPageInfo: PageProgressInfo?
    var statusMessage: String?
    var isError = false
    var isComplete = false
    var canCancel = true
    var showErrorAlert = false
    var errorMessage = ""

    private var processingTask: Task<Void, Never>?

    init(bookUploadUseCase: BookUploadUseCase, images: [UIImage], bookTitle: String, bookAuthor: String?) {
        self.bookUploadUseCase = bookUploadUseCase
        self.images = images
        self.bookTitle = bookTitle
        self.bookAuthor = bookAuthor
        self.totalPages = images.count

        // Initialize page progress
        self.pageProgress = images.enumerated().map { index, image in
            PageProgressInfo(
                id: UUID(),
                pageNumber: index + 1,
                title: "Page \(index + 1)",
                subtitle: nil,
                status: .pending,
                image: image
            )
        }
    }

    func startProcessing() {
        processingTask = Task {
            await processBook()
        }
    }

    func cancelProcessing() {
        processingTask?.cancel()
        canCancel = false
        statusMessage = "Cancelling..."
    }

    func retryProcessing() {
        showErrorAlert = false
        errorMessage = ""
        startProcessing()
    }

    @MainActor
    private func processBook() async {
        do {
            statusMessage = "Starting book processing..."
            isError = false

            // Update first page to processing
            if let firstPage = pageProgress.first {
                updatePageStatus(pageId: firstPage.id, status: .processing)
                currentPageInfo = pageProgress[0]
            }

            // Process the book
            let book = try await bookUploadUseCase.uploadBook(
                images: images,
                title: bookTitle,
                author: bookAuthor
            )

            // Update progress for each page
            for (index, page) in book.pages.enumerated() {
                try await Task.sleep(for: .milliseconds(500)) // Simulate processing time

                let pageId = pageProgress[index].id
                updatePageStatus(pageId: pageId, status: .completed, subtitle: "\(page.extractedText.prefix(50))...")
                completedPages = index + 1
                overallProgress = Double(completedPages) / Double(totalPages)

                // Update current page info
                if index + 1 < pageProgress.count {
                    updatePageStatus(pageId: pageProgress[index + 1].id, status: .processing)
                    currentPageInfo = pageProgress[index + 1]
                }
            }

            // Complete processing
            statusMessage = "Book processing complete!"
            isComplete = true
            canCancel = false
            currentPageInfo = nil

        } catch {
            isError = true
            canCancel = false
            statusMessage = "Processing failed: \(error.localizedDescription)"
            errorMessage = error.localizedDescription
            showErrorAlert = true

            // Mark failed pages
            for page in pageProgress where page.status == .processing {
                updatePageStatus(pageId: page.id, status: .failed)
            }
        }
    }

    private func updatePageStatus(pageId: UUID, status: PageProcessingStatus, subtitle: String? = nil) {
        if let index = pageProgress.firstIndex(where: { $0.id == pageId }) {
            pageProgress[index].status = status
            if let subtitle = subtitle {
                pageProgress[index].subtitle = subtitle
            }
        }
    }
}

/// Information about page processing progress
struct PageProgressInfo: Identifiable {
    let id: UUID
    let pageNumber: Int
    var title: String
    var subtitle: String?
    var status: PageProcessingStatus
    let image: UIImage
}

/// Status of page processing
enum PageProcessingStatus {
    case pending
    case processing
    case completed
    case failed

    var color: Color {
        switch self {
        case .pending: return .gray
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }

    var icon: String {
        switch self {
        case .pending: return "circle"
        case .processing: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle"
        case .failed: return "xmark.circle"
        }
    }
}

#Preview {
    let sampleImages = [
        UIImage(systemName: "photo")!,
        UIImage(systemName: "photo.fill")!,
        UIImage(systemName: "photo.artframe")!
    ]

    let viewModel = OCRProgressViewModel(
        bookUploadUseCase: MockBookUploadUseCase(),
        images: sampleImages,
        bookTitle: "Sample Book",
        bookAuthor: "Sample Author"
    )

    return OCRProgressScreen(viewModel: viewModel)
}

/// Mock use case for preview
private struct MockBookUploadUseCase: BookUploadUseCase {
    func uploadBook(images: [UIImage], title: String, author: String?) async throws -> AppBook {
        try await Task.sleep(for: .seconds(2))
        return AppBook(title: title, author: author, pages: [])
    }

    func validateImages(_ images: [UIImage]) -> [ImageValidationResult] {
        return images.map { _ in .valid }
    }

    func processImage(_ image: UIImage) async throws -> ProcessedImage {
        try await Task.sleep(for: .milliseconds(500))
        return ProcessedImage(
            originalImage: image,
            processedImage: image,
            extractedText: "Sample extracted text",
            textBlocks: [],
            validationResult: .valid,
            filename: "sample.jpg"
        )
    }

    func generateTitle(from text: String) -> String {
        return "Mock Title"
    }
}
