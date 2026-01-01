//
//  EditBookUseCase.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation
import UIKit

/// Protocol for book editing use case
protocol EditBookUseCase {
    /// Add new pages to an existing book
    func addPagesToBook(book: AppBook, newImages: [UIImage], updatedTitle: String?, updatedAuthor: String?) async throws -> AppBook
}

/// Implementation of EditBookUseCase
class DefaultEditBookUseCase: EditBookUseCase {
    private let ocrService: OCRService
    private let imageProcessingService: ImageProcessingService
    private let textSegmentationService: TextSegmentationService
    private let bookRepository: BookRepository

    init(
        ocrService: OCRService,
        imageProcessingService: ImageProcessingService,
        textSegmentationService: TextSegmentationService,
        bookRepository: BookRepository
    ) {
        self.ocrService = ocrService
        self.imageProcessingService = imageProcessingService
        self.textSegmentationService = textSegmentationService
        self.bookRepository = bookRepository
    }

    func addPagesToBook(book: AppBook, newImages: [UIImage], updatedTitle: String?, updatedAuthor: String?) async throws -> AppBook {
        // Validate images first
        let validationResults = validateImages(newImages)
        let validImages = zip(newImages, validationResults)
            .filter { $0.1.isValid }
            .map { $0.0 }

        guard !validImages.isEmpty else {
            throw EditBookError.noValidImages
        }

        if validImages.count < newImages.count {
            print("Warning: \(newImages.count - validImages.count) images were filtered out due to validation failures")
        }

        // Process images with OCR
        var processedImages: [ProcessedImage] = []
        for (index, image) in validImages.enumerated() {
            do {
                let processedImage = try await processImage(image)
                processedImages.append(processedImage)
                print("Processed new page \(index + 1)/\(validImages.count)")
            } catch {
                print("Failed to process new page \(index + 1): \(error)")
                throw EditBookError.ocrFailed(page: index + 1, error: error)
            }
        }

        // Create new book pages starting from the next page number
        var newPages: [AppBookPage] = []
        let startingPageNumber = book.totalPages + 1

        for (index, processedImage) in processedImages.enumerated() {
            // Segment the text for this page
            let segmentedWords = try await segmentText(processedImage.extractedText)

            let page = AppBookPage(
                bookId: book.id,
                pageNumber: startingPageNumber + index,
                originalImagePath: processedImage.filename,
                extractedText: processedImage.extractedText,
                words: segmentedWords,
                wordsMarked: []
            )
            newPages.append(page)
        }

        // Create updated book with new pages and metadata
        let allPages = book.pages + newPages
        let finalTitle = updatedTitle ?? book.title
        let finalAuthor = updatedAuthor ?? book.author
        let updatedBook = AppBook(
            id: book.id,
            title: finalTitle,
            author: finalAuthor,
            pages: allPages,
            currentPageIndex: book.currentPageIndex,
            isLocal: book.isLocal,
            language: book.language,
            genre: book.genre,
            description: book.description,
            totalWords: book.totalWords,
            estimatedReadingTimeMinutes: book.estimatedReadingTimeMinutes,
            difficulty: book.difficulty,
            tags: book.tags
        )

        // Update via repository
        let savedBook = try await bookRepository.updateBook(updatedBook)
        return savedBook
    }

    private func validateImages(_ images: [UIImage]) -> [ImageValidationResult] {
        return images.map { imageProcessingService.validateImageForOCR($0) }
    }

    private func processImage(_ image: UIImage) async throws -> ProcessedImage {
        // Process image for OCR
        let processedImage = imageProcessingService.processImageForOCR(image)

        // Validate processed image
        let validationResult = imageProcessingService.validateImageForOCR(processedImage)

        // Extract text
        let extractedText = try await ocrService.recognizeText(from: processedImage)

        // Get text blocks
        let textBlocks = try await ocrService.extractTextBlocks(from: processedImage)

        // Generate filename
        let filename = "\(UUID().uuidString).jpg"

        // Save processed image
        let _ = try imageProcessingService.saveImageToStorage(processedImage, filename: filename)

        return ProcessedImage(
            originalImage: image,
            processedImage: processedImage,
            extractedText: extractedText,
            textBlocks: textBlocks,
            validationResult: validationResult,
            filename: filename
        )
    }

    private func segmentText(_ text: String) async throws -> [AppWordSegment] {
        // Use the improved segmentation service that returns proper position information
        let segments = try await textSegmentationService.segmentWithPositions(text: text)
        return segments
    }
}

/// Errors that can occur during book editing
enum EditBookError: LocalizedError, Equatable {
    case noValidImages
    case ocrFailed(page: Int, error: Error)
    case updateFailed(error: Error)

    var errorDescription: String? {
        switch self {
        case .noValidImages:
            return "No valid images found. Please ensure your photos are clear and well-lit."
        case .ocrFailed(let page, let error):
            return "Failed to process page \(page): \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update book: \(error.localizedDescription)"
        }
    }

    // Equatable conformance for testing
    static func == (lhs: EditBookError, rhs: EditBookError) -> Bool {
        switch (lhs, rhs) {
        case (.noValidImages, .noValidImages):
            return true
        case (.ocrFailed(let lhsPage, _), .ocrFailed(let rhsPage, _)):
            return lhsPage == rhsPage
        case (.updateFailed, .updateFailed):
            return true // Don't compare the actual Error values
        default:
            return false
        }
    }
}
