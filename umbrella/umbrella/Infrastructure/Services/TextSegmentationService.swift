//
 //  TextSegmentationService.swift
 //  umbrella
 //
 //  Created by Денис on 31.12.2025.
 //

 import Foundation
 import NaturalLanguage

/// Protocol for Chinese text segmentation (word breaking)
protocol TextSegmentationService {
    /// Segment text into individual words
    func segment(text: String) async throws -> [String]

    /// Segment text with position information
    func segmentWithPositions(text: String) async throws -> [AppWordSegment]
}

/// Local segmentation service using Apple's NaturalLanguage framework
/// Phase 1 implementation - provides accurate Chinese word segmentation locally
/// In Phase 2, this can be enhanced with HanLP for even better accuracy
class LocalTextSegmentationService: TextSegmentationService {
    // Chinese and common punctuation that should be preserved as separate tokens
    private let punctuationSet: CharacterSet = {
        var set = CharacterSet.punctuationCharacters
        set.formUnion(.symbols)
        // Add Chinese-specific punctuation
        set.insert(charactersIn: "。，、；：？！\"\"''（）【】《》〈〉「」『』…—～·")
        return set
    }()

    /// Segment text into words using NLTokenizer
    func segment(text: String) async throws -> [String] {
        let segments = try await segmentWithPositions(text: text)
        return segments.map { $0.word }
    }

    /// Segment text with position information using NLTokenizer
    func segmentWithPositions(text: String) async throws -> [AppWordSegment] {
        // Handle edge cases first
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty {
            return []
        }

        // For punctuation-only text, segment each character
        if isPunctuationOnly(text) {
            return segmentPunctuationOnly(text)
        }

        // For Chinese text, use character-based segmentation for language learning
        if containsChineseCharacters(text) {
            return segmentChineseText(text)
        }

        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        var segments: [AppWordSegment] = []
        var lastEndIndex = text.startIndex

        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            // Add any intermediate tokens (punctuation, whitespace, newlines) between words
            if lastEndIndex < tokenRange.lowerBound {
                let intermediateRange = lastEndIndex..<tokenRange.lowerBound
                let intermediateText = String(text[intermediateRange])

                // Process intermediate text into separate tokens
                addIntermediateSegments(
                    from: intermediateText,
                    startIndex: lastEndIndex,
                    in: text,
                    to: &segments
                )
            }

            // Add the word token
            let word = String(text[tokenRange])
            let startOffset = text.distance(from: text.startIndex, to: tokenRange.lowerBound)
            let endOffset = text.distance(from: text.startIndex, to: tokenRange.upperBound)

            segments.append(AppWordSegment(
                word: word,
                pinyin: nil, // Will be looked up separately by dictionary service
                startIndex: startOffset,
                endIndex: endOffset,
                isMarked: false
            ))

            lastEndIndex = tokenRange.upperBound
            return true
        }

        // Add any remaining intermediate tokens after the last word
        if lastEndIndex < text.endIndex {
            let remainingRange = lastEndIndex..<text.endIndex
            let remainingText = String(text[remainingRange])
            addIntermediateSegments(
                from: remainingText,
                startIndex: lastEndIndex,
                in: text,
                to: &segments
            )
        }

        return segments
    }

    /// Check if text contains Chinese characters
    private func containsChineseCharacters(_ text: String) -> Bool {
        let chineseCharacterSet = CharacterSet(charactersIn: "\u{4E00}"..."\u{9FFF}")
        return text.rangeOfCharacter(from: chineseCharacterSet) != nil
    }

    /// Check if text contains only punctuation
    private func isPunctuationOnly(_ text: String) -> Bool {
        return text.allSatisfy { char in
            char.unicodeScalars.allSatisfy { punctuationSet.contains($0) } || char.isWhitespace || char.isNewline
        }
    }

    /// Segment punctuation-only text into individual characters
    private func segmentPunctuationOnly(_ text: String) -> [AppWordSegment] {
        var segments: [AppWordSegment] = []
        var currentIndex = 0

        for char in text {
            if !char.isWhitespace && !char.isNewline {
                segments.append(AppWordSegment(
                    word: String(char),
                    pinyin: nil,
                    startIndex: currentIndex,
                    endIndex: currentIndex + 1,
                    isMarked: false
                ))
            }
            currentIndex += 1
        }

        return segments
    }

    /// Segment Chinese text into individual characters for language learning
    private func segmentChineseText(_ text: String) -> [AppWordSegment] {
        var segments: [AppWordSegment] = []
        var currentIndex = 0

        for char in text {
            if char.isWhitespace || char.isNewline {
                // Skip whitespace for Chinese text (unlike punctuation which we want to preserve)
                currentIndex += 1
                continue
            }

            // Check if this is punctuation
            if char.unicodeScalars.allSatisfy({ punctuationSet.contains($0) }) {
                segments.append(AppWordSegment(
                    word: String(char),
                    pinyin: nil,
                    startIndex: currentIndex,
                    endIndex: currentIndex + 1,
                    isMarked: false
                ))
            } else {
                // Chinese character
                segments.append(AppWordSegment(
                    word: String(char),
                    pinyin: nil,
                    startIndex: currentIndex,
                    endIndex: currentIndex + 1,
                    isMarked: false
                ))
            }
            currentIndex += 1
        }

        return segments
    }

    /// Process intermediate text (between words) into individual segments
    /// Handles punctuation, newlines, and whitespace as separate tokens
    private func addIntermediateSegments(
        from intermediateText: String,
        startIndex: String.Index,
        in fullText: String,
        to segments: inout [AppWordSegment],
        includeNewlines: Bool = true
    ) {
        var currentIndex = startIndex
        var currentGroup = ""
        var currentGroupStart = currentIndex
        var currentGroupType: IntermediateTokenType = .whitespace

        for char in intermediateText {
            let charType = intermediateTokenType(for: char)

            if charType == currentGroupType && charType != .newline {
                // Continue grouping same type (except newlines which are always individual)
                currentGroup.append(char)
            } else {
                // Flush current group if not empty
                if !currentGroup.isEmpty {
                    let endIndex = fullText.index(currentGroupStart, offsetBy: currentGroup.count)
                    let range = currentGroupStart..<endIndex
                    let startOffset = fullText.distance(from: fullText.startIndex, to: range.lowerBound)
                    let endOffset = fullText.distance(from: fullText.startIndex, to: range.upperBound)

                    // Only add punctuation tokens, skip whitespace
                    if currentGroupType == .punctuation {
                        segments.append(AppWordSegment(
                            word: currentGroup,
                            pinyin: nil,
                            startIndex: startOffset,
                            endIndex: endOffset,
                            isMarked: false
                        ))
                    }

                    currentGroupStart = endIndex
                }

                // Start new group
                currentGroup = String(char)
                currentGroupType = charType

                // Newlines are individual tokens only if includeNewlines is true
                if charType == .newline && includeNewlines {
                    let endIndex = fullText.index(currentGroupStart, offsetBy: 1)
                    let range = currentGroupStart..<endIndex
                    let startOffset = fullText.distance(from: fullText.startIndex, to: range.lowerBound)
                    let endOffset = fullText.distance(from: fullText.startIndex, to: range.upperBound)

                    segments.append(AppWordSegment(
                        word: currentGroup,
                        pinyin: nil,
                        startIndex: startOffset,
                        endIndex: endOffset,
                        isMarked: false
                    ))
                    currentGroupStart = endIndex
                    currentGroup = ""
                    currentGroupType = .whitespace
                }
            }
            currentIndex = fullText.index(after: currentIndex)
        }

        // Flush remaining group
        if !currentGroup.isEmpty && currentGroupType == .punctuation {
            let endIndex = fullText.index(currentGroupStart, offsetBy: currentGroup.count)
            let range = currentGroupStart..<endIndex
            let startOffset = fullText.distance(from: fullText.startIndex, to: range.lowerBound)
            let endOffset = fullText.distance(from: fullText.startIndex, to: range.upperBound)

            segments.append(AppWordSegment(
                word: currentGroup,
                pinyin: nil,
                startIndex: startOffset,
                endIndex: endOffset,
                isMarked: false
            ))
        }
    }

    private enum IntermediateTokenType {
        case punctuation
        case newline
        case whitespace
    }

    private func intermediateTokenType(for char: Character) -> IntermediateTokenType {
        if char.isNewline {
            return .newline
        } else if char.unicodeScalars.allSatisfy({ punctuationSet.contains($0) }) {
            return .punctuation
        } else {
            return .whitespace
        }
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
