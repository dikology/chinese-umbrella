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
        guard !textBlocks.isEmpty else { return [] }
        
        // Vision API uses normalized coordinates (0.0-1.0) with origin at bottom-left
        // Calculate the center Y coordinate for each block for better line grouping
        struct BlockWithPosition {
            let block: TextBlock
            let centerY: CGFloat
            let centerX: CGFloat
            let top: CGFloat
        }
        
        let blocksWithPositions = textBlocks.map { block in
            let centerY = block.boundingBox.origin.y + (block.boundingBox.height / 2)
            let centerX = block.boundingBox.origin.x + (block.boundingBox.width / 2)
            let top = block.boundingBox.origin.y + block.boundingBox.height
            return BlockWithPosition(block: block, centerY: centerY, centerX: centerX, top: top)
        }
        
        // Calculate average block height for dynamic tolerance
        let avgHeight = textBlocks.reduce(0.0) { $0 + $1.boundingBox.height } / CGFloat(textBlocks.count)
        // Use half the average height as tolerance for same-line detection
        let rowTolerance = avgHeight * 0.5
        
        // Group blocks into lines using a more sophisticated clustering approach
        var lines: [[BlockWithPosition]] = []
        var remainingBlocks = blocksWithPositions.sorted { $0.top > $1.top }
        
        while !remainingBlocks.isEmpty {
            let firstBlock = remainingBlocks.removeFirst()
            var currentLine = [firstBlock]
            
            // Find all blocks that belong to the same line
            // A block belongs to the same line if its centerY is within tolerance of the line's centerY
            remainingBlocks.removeAll { candidate in
                let yDiff = abs(candidate.centerY - firstBlock.centerY)
                if yDiff < rowTolerance {
                    currentLine.append(candidate)
                    return true
                }
                return false
            }
            
            // Sort blocks within the line from left to right
            currentLine.sort { $0.centerX < $1.centerX }
            lines.append(currentLine)
        }
        
        // Lines are already sorted top-to-bottom, now flatten them
        return lines.flatMap { $0.map { $0.block } }
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
