//
//  OCRService.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import UIKit
import Vision

/// Protocol for OCR (Optical Character Recognition) operations
protocol OCRService {
    /// Recognize text from an image
    func recognizeText(from image: UIImage) async throws -> String

    /// Extract text blocks with position information
    func extractTextBlocks(from image: UIImage) async throws -> [TextBlock]
}

/// Represents a block of recognized text with position information
struct TextBlock {
    let text: String
    let boundingBox: CGRect
    let confidence: Float
}

/// Apple Vision API implementation of OCR service
class AppleVisionOCRService: OCRService {
    /// Recognize text from an image using Apple Vision
    /// - Parameter image: The image to process
    /// - Returns: Extracted text as a single string
    func recognizeText(from image: UIImage) async throws -> String {
        let textBlocks = try await extractTextBlocks(from: image)
        // Sort text blocks by reading order (top-to-bottom, left-to-right)
        let sortedBlocks = sortTextBlocksByReadingOrder(textBlocks)
        return sortedBlocks.map { $0.text }.joined(separator: "\n")
    }

    /// Extract text blocks with position information
    /// - Parameter image: The image to process
    /// - Returns: Array of text blocks with position and confidence data
    func extractTextBlocks(from image: UIImage) async throws -> [TextBlock] {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.visionError(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noResults)
                    return
                }

                let textBlocks = observations.compactMap { observation -> TextBlock? in
                    guard let topCandidate = observation.topCandidates(1).first else { return nil }

                    return TextBlock(
                        text: topCandidate.string,
                        boundingBox: observation.boundingBox,
                        confidence: topCandidate.confidence
                    )
                }

                // Sort text blocks by reading order before returning
                let sortedBlocks = self.sortTextBlocksByReadingOrder(textBlocks)
                continuation.resume(returning: sortedBlocks)
            }

            // Configure for Chinese text recognition
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en"]
            request.usesLanguageCorrection = true
            request.minimumTextHeight = 0.01 // Recognize smaller text
            request.revision = VNRecognizeTextRequestRevision3

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.visionError(error))
            }
        }
    }
    
    /// Sort text blocks by reading order (top-to-bottom, left-to-right)
    /// Vision API returns observations in arbitrary order, so we need to sort them
    /// based on their position. For Chinese text, we sort top-to-bottom first,
    /// then left-to-right within the same row.
    /// - Parameter textBlocks: Array of text blocks to sort
    /// - Returns: Sorted array of text blocks in reading order
    private func sortTextBlocksByReadingOrder(_ textBlocks: [TextBlock]) -> [TextBlock] {
        // Vision API uses normalized coordinates (0.0-1.0) with origin at bottom-left
        // We need to sort by:
        // 1. Top position (descending - higher Y = top of screen)
        // 2. Left position (ascending - lower X = left side)
        
        // Calculate the top Y coordinate for each block
        // boundingBox.origin.y is the bottom-left corner, so top = origin.y + height
        return textBlocks.sorted { block1, block2 in
            let top1 = block1.boundingBox.origin.y + block1.boundingBox.height
            let top2 = block2.boundingBox.origin.y + block2.boundingBox.height
            let left1 = block1.boundingBox.origin.x
            let left2 = block2.boundingBox.origin.x
            
            // Tolerance for considering blocks on the same "row" (within 5% of image height)
            let rowTolerance: CGFloat = 0.05
            
            // If blocks are on the same row (similar top Y), sort by left X
            if abs(top1 - top2) < rowTolerance {
                return left1 < left2
            }
            
            // Otherwise, sort by top Y (descending - higher Y first = top first)
            return top1 > top2
        }
    }
}

/// Errors that can occur during OCR operations
enum OCRError: LocalizedError {
    case invalidImage
    case visionError(Error)
    case noResults
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .visionError(let error):
            return "Vision API error: \(error.localizedDescription)"
        case .noResults:
            return "No text found in image"
        case .processingFailed:
            return "Text processing failed"
        }
    }
}
