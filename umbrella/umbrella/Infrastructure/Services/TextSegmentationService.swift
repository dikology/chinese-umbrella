//
//  TextSegmentationService.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation

/// Protocol for Chinese text segmentation (word breaking)
protocol TextSegmentationService {
    /// Segment text into individual words
    func segment(text: String) async throws -> [String]

    /// Segment text with position information
    func segmentWithPositions(text: String) async throws -> [AppWordSegment]
}

/// HTTP-based segmentation service (Phase 1 implementation)
/// In Phase 2, this will be replaced with embedded HanLP
class HanLPSegmentationService: TextSegmentationService {
    private let baseURL = URL(string: "https://api.hanlp.com")! // Placeholder - will need real endpoint
    private let apiKey: String

    init(apiKey: String = "placeholder_key") {
        self.apiKey = apiKey
    }

    /// Segment text into words using HanLP service
    func segment(text: String) async throws -> [String] {
        let segments = try await segmentWithPositions(text: text)
        return segments.map { $0.word }
    }

    /// Segment text with position information
    func segmentWithPositions(text: String) async throws -> [AppWordSegment] {
        // For Phase 1 MVP, implement basic character-by-character segmentation
        // This will be replaced with proper HanLP integration in Phase 2

        var segments: [AppWordSegment] = []
        var currentIndex = 0

        // Simple segmentation: split by spaces, or character-by-character for Chinese
        let words = basicSegmentation(text)

        for word in words {
            if let range = text.range(of: word, range: text.index(text.startIndex, offsetBy: currentIndex)..<text.endIndex) {
                let startOffset = text.distance(from: text.startIndex, to: range.lowerBound)
                let endOffset = text.distance(from: text.startIndex, to: range.upperBound)

                segments.append(AppWordSegment(
                    word: word,
                    pinyin: nil, // Will be looked up separately
                    startIndex: startOffset,
                    endIndex: endOffset
                ))

                currentIndex = endOffset
            }
        }

        return segments
    }

    /// Basic segmentation fallback for Phase 1
    /// This is a temporary implementation until proper HanLP integration
    private func basicSegmentation(_ text: String) -> [String] {
        // For Chinese text without spaces, split into individual characters
        // This is not ideal but provides basic functionality for the MVP

        // Check if text contains Chinese characters
        let chineseCharacterSet = CharacterSet(charactersIn: "\u{4E00}"..."\u{9FFF}")
        let hasChinese = text.rangeOfCharacter(from: chineseCharacterSet) != nil

        if hasChinese {
            // For Chinese text, split by characters (temporary)
            return text.map { String($0) }
        } else {
            // For other text, split by spaces
            return text.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
        }
    }

    /// Future method for proper HanLP integration
    private func callHanLPAPI(text: String) async throws -> [String] {
        // This will be implemented in Phase 2 with real HanLP service
        let requestBody = ["text": text, "language": "zh"]
        let data = try JSONSerialization.data(withJSONObject: requestBody)

        var request = URLRequest(url: baseURL.appendingPathComponent("/segment"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = data

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SegmentationError.apiError
        }

        guard let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let words = json["words"] as? [String] else {
            throw SegmentationError.invalidResponse
        }

        return words
    }
}

/// Errors that can occur during text segmentation
enum SegmentationError: LocalizedError {
    case apiError
    case invalidResponse
    case networkError
    case textTooLong
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .apiError:
            return "Segmentation API error"
        case .invalidResponse:
            return "Invalid API response"
        case .networkError:
            return "Network connection error"
        case .textTooLong:
            return "Text is too long for processing"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
