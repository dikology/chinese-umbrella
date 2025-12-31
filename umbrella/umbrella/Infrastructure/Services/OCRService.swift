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
        return textBlocks.map { $0.text }.joined(separator: "\n")
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

                continuation.resume(returning: textBlocks)
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
