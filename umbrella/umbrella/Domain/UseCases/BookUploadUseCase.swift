//
//  BookUploadUseCase.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation
import UIKit

/// Protocol for book upload use case
protocol BookUploadUseCase {
    /// Upload and process images into a book
    func uploadBook(images: [UIImage], title: String, author: String?, userId: UUID) async throws -> AppBook

    /// Validate images before processing
    func validateImages(_ images: [UIImage]) -> [ImageValidationResult]

    /// Process a single image with OCR
    func processImage(_ image: UIImage) async throws -> ProcessedImage

    /// Generate a default title from the first page content
    func generateTitle(from text: String) -> String
}

/// Result of processing a single image
struct ProcessedImage {
    let originalImage: UIImage
    let processedImage: UIImage
    let extractedText: String
    let textBlocks: [TextBlock]
    let validationResult: ImageValidationResult
    let filename: String
}

/// Implementation of BookUploadUseCase
class DefaultBookUploadUseCase: BookUploadUseCase {
    private let ocrService: OCRService
    private let imageProcessingService: ImageProcessingService
    private let textSegmentationService: TextSegmentationService
    private let bookMetadataService: BookMetadataService
    private let bookRepository: BookRepository

    init(
        ocrService: OCRService,
        imageProcessingService: ImageProcessingService,
        textSegmentationService: TextSegmentationService,
        bookMetadataService: BookMetadataService,
        bookRepository: BookRepository
    ) {
        self.ocrService = ocrService
        self.imageProcessingService = imageProcessingService
        self.textSegmentationService = textSegmentationService
        self.bookMetadataService = bookMetadataService
        self.bookRepository = bookRepository
    }

    func uploadBook(images: [UIImage], title: String, author: String?, userId: UUID) async throws -> AppBook {
        // Validate images first
        let validationResults = validateImages(images)
        let validImages = zip(images, validationResults)
            .filter { $0.1.isValid }
            .map { $0.0 }

        guard !validImages.isEmpty else {
            throw BookUploadError.noValidImages
        }

        if validImages.count < images.count {
            print("Warning: \(images.count - validImages.count) images were filtered out due to validation failures")
        }

        // Process images with OCR
        var processedImages: [ProcessedImage] = []
        for (index, image) in validImages.enumerated() {
            do {
                let processedImage = try await processImage(image)
                processedImages.append(processedImage)
                print("Processed page \(index + 1)/\(validImages.count)")
            } catch {
                print("Failed to process page \(index + 1): \(error)")
                throw BookUploadError.ocrFailed(page: index + 1, error: error)
            }
        }

        // Segment text for the first page to get a better title if needed
        let actualTitle = title.isEmpty && !processedImages.isEmpty
            ? generateTitle(from: processedImages[0].extractedText)
            : title

        // Create book pages
        var pages: [AppBookPage] = []
        for (index, processedImage) in processedImages.enumerated() {
            // Segment the text for this page
            let segmentedWords = try await segmentText(processedImage.extractedText)

            let page = AppBookPage(
                bookId: UUID(), // Will be set when saving the book
                pageNumber: index + 1,
                originalImagePath: processedImage.filename,
                extractedText: processedImage.extractedText,
                words: segmentedWords,
                wordsMarked: []
            )
            pages.append(page)
        }

        // Analyze book metadata using the metadata service
        let metadataAnalysis = try await bookMetadataService.analyzeBookMetadata(
            images: images,
            title: actualTitle,
            author: author
        )

        // Create the book with enhanced metadata
        let book = AppBook(
            title: actualTitle,
            author: author,
            pages: pages,
            currentPageIndex: 0,
            isLocal: true
        )

        // Apply metadata analysis results
        let enhancedBook = bookMetadataService.updateBookMetadata(book: book, analysis: metadataAnalysis)

        // Save to repository
        let savedBook = try await bookRepository.saveBook(enhancedBook, userId: userId)
        return savedBook
    }

    func validateImages(_ images: [UIImage]) -> [ImageValidationResult] {
        return images.map { imageProcessingService.validateImageForOCR($0) }
    }

    func processImage(_ image: UIImage) async throws -> ProcessedImage {
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

    func generateTitle(from text: String) -> String {
        // Extract first meaningful line as title
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let firstLine = lines.first, firstLine.count > 3 && firstLine.count < 50 {
            return firstLine
        }

        // Fallback: extract first sentence
        let sentences = text.components(separatedBy: "。")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let firstSentence = sentences.first, firstSentence.count > 5 && firstSentence.count < 50 {
            return firstSentence + "。"
        }

        // Ultimate fallback
        return "Untitled Book"
    }

    // MARK: - Private Methods

    private func segmentText(_ text: String) async throws -> [AppWordSegment] {
        // Use the improved segmentation service that returns proper position information
        let segments = try await textSegmentationService.segmentWithPositions(text: text)
        return segments
    }
}

/// Errors that can occur during book upload
enum BookUploadError: LocalizedError {
    case noValidImages
    case ocrFailed(page: Int, error: Error)
    case saveFailed(error: Error)
    case invalidTitle
    case networkError

    var errorDescription: String? {
        switch self {
        case .noValidImages:
            return "No valid images found. Please ensure your photos are clear and well-lit."
        case .ocrFailed(let page, let error):
            return "Failed to process page \(page): \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save book: \(error.localizedDescription)"
        case .invalidTitle:
            return "Book title is required"
        case .networkError:
            return "Network connection required for text processing"
        }
    }
}
