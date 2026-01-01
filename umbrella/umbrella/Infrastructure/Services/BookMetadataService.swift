//
//  BookMetadataService.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation
import UIKit

/// Service for managing book metadata, statistics, and enhanced information
protocol BookMetadataService {
    /// Analyze book content and generate metadata
    func analyzeBookMetadata(images: [UIImage], title: String, author: String?) async throws -> BookMetadataAnalysis

    /// Update book metadata after processing
    func updateBookMetadata(book: AppBook, analysis: BookMetadataAnalysis) -> AppBook

    /// Detect language from text content
    func detectLanguage(from text: String) -> String?

    /// Estimate reading difficulty based on content
    func estimateReadingDifficulty(words: [AppWordSegment], language: String?) -> ReadingDifficulty?

    /// Calculate reading statistics for a book
    func calculateBookStatistics(book: AppBook) -> BookStatistics
}

/// Result of book metadata analysis
struct BookMetadataAnalysis {
    let detectedLanguage: String?
    let estimatedGenre: BookGenre?
    let totalWords: Int
    let estimatedReadingTimeMinutes: Int
    let suggestedDifficulty: ReadingDifficulty?
    let extractedDescription: String?
    let suggestedTags: [String]
}

/// Default implementation of BookMetadataService
class DefaultBookMetadataService: BookMetadataService {

    /// Analyze book content and generate comprehensive metadata
    func analyzeBookMetadata(images: [UIImage], title: String, author: String?) async throws -> BookMetadataAnalysis {
        // For now, implement basic analysis
        // In a real implementation, this could use ML models for genre detection, etc.

        var _ = ""
        var totalWords = 0

        // Analyze first few pages for metadata (don't process all images for performance)
        let pagesToAnalyze = min(images.count, 3)

        for i in 0..<pagesToAnalyze {
            // This is a simplified version - in reality you'd use OCR here
            // For now, we'll make assumptions based on title and content patterns
            totalWords += estimateWordsInImage(images[i])
        }

        let detectedLanguage = detectLanguageFromTitleAndAuthor(title, author)
        let estimatedGenre = estimateGenreFromTitle(title)
        let suggestedDifficulty = estimateReadingDifficulty(words: [], language: detectedLanguage) // Would need actual words
        let extractedDescription = generateDescription(title: title, author: author, genre: estimatedGenre)
        let suggestedTags = generateTags(title: title, genre: estimatedGenre, language: detectedLanguage)

        // Estimate reading time (200 words per minute average)
        let estimatedReadingTimeMinutes = max(1, totalWords / 200)

        return BookMetadataAnalysis(
            detectedLanguage: detectedLanguage,
            estimatedGenre: estimatedGenre,
            totalWords: totalWords,
            estimatedReadingTimeMinutes: estimatedReadingTimeMinutes,
            suggestedDifficulty: suggestedDifficulty,
            extractedDescription: extractedDescription,
            suggestedTags: suggestedTags
        )
    }

    /// Update book with analyzed metadata
    func updateBookMetadata(book: AppBook, analysis: BookMetadataAnalysis) -> AppBook {
        return AppBook(
            id: book.id,
            title: book.title,
            author: book.author,
            pages: book.pages,
            currentPageIndex: book.currentPageIndex,
            isLocal: book.isLocal,
            language: book.language ?? analysis.detectedLanguage,
            genre: book.genre ?? analysis.estimatedGenre,
            description: book.description ?? analysis.extractedDescription,
            totalWords: book.totalWords ?? analysis.totalWords,
            estimatedReadingTimeMinutes: book.estimatedReadingTimeMinutes ?? analysis.estimatedReadingTimeMinutes,
            difficulty: book.difficulty ?? analysis.suggestedDifficulty,
            tags: book.tags ?? analysis.suggestedTags
        )
    }

    /// Detect language from text content using basic heuristics
    func detectLanguage(from text: String) -> String? {
        // Check for Chinese characters
        let chineseCharacterSet = CharacterSet(charactersIn: "\u{4E00}"..."\u{9FFF}")
        let hasChinese = text.rangeOfCharacter(from: chineseCharacterSet) != nil

        if hasChinese {
            // Check for traditional vs simplified (basic heuristic)
            let traditionalChars = CharacterSet(charactersIn: "傳統繁體")
            let hasTraditional = text.rangeOfCharacter(from: traditionalChars) != nil
            return hasTraditional ? "zh-Hant" : "zh-Hans"
        }

        return "en" // Default to English
    }

    /// Estimate reading difficulty (simplified implementation)
    func estimateReadingDifficulty(words: [AppWordSegment], language: String?) -> ReadingDifficulty? {
        guard let language = language else { return .intermediate }

        if language.starts(with: "zh") {
            // For Chinese, base difficulty on word complexity
            // This is a simplified heuristic - real implementation would use HSK levels, etc.
            return .intermediate
        }

        return .intermediate // Default
    }

    /// Calculate comprehensive book statistics
    func calculateBookStatistics(book: AppBook) -> BookStatistics {
        return book.statistics
    }

    // MARK: - Private Helper Methods

    private func estimateWordsInImage(_ image: UIImage) -> Int {
        // Rough estimation based on image size
        // In a real implementation, this would use OCR to count actual words
        let imageArea = image.size.width * image.size.height
        let estimatedWordsPerPixel = 0.001 // Rough heuristic
        return max(50, Int(imageArea * estimatedWordsPerPixel))
    }

    private func detectLanguageFromTitleAndAuthor(_ title: String, _ author: String?) -> String? {
        let combinedText = title + (author ?? "")

        // Check for Chinese characters in title/author
        let chineseCharacterSet = CharacterSet(charactersIn: "\u{4E00}"..."\u{9FFF}")
        let hasChinese = combinedText.rangeOfCharacter(from: chineseCharacterSet) != nil

        if hasChinese {
            // Check for traditional Chinese indicators
            let traditionalIndicators = ["傳統", "繁體", "台灣", "香港", "澳門"]
            let hasTraditional = traditionalIndicators.contains { combinedText.contains($0) }
            return hasTraditional ? "zh-Hant" : "zh-Hans"
        }

        return "en"
    }

    private func estimateGenreFromTitle(_ title: String) -> BookGenre? {
        let lowerTitle = title.lowercased()

        // Simple keyword-based genre detection
        if lowerTitle.contains("历史") || lowerTitle.contains("history") {
            return .history
        } else if lowerTitle.contains("小说") || lowerTitle.contains("fiction") || lowerTitle.contains("故事") {
            return .fiction
        } else if lowerTitle.contains("科学") || lowerTitle.contains("science") {
            return .science
        } else if lowerTitle.contains("技术") || lowerTitle.contains("technology") {
            return .technology
        } else if lowerTitle.contains("教育") || lowerTitle.contains("education") {
            return .education
        } else if lowerTitle.contains("文学") || lowerTitle.contains("literature") {
            return .literature
        }

        return .other
    }

    private func generateDescription(title: String, author: String?, genre: BookGenre?) -> String? {
        var description = "\"\(title)\""

        if let author = author {
            description += " by \(author)"
        }

        if let genre = genre {
            description += " - A \(genre.rawValue) book"
        }

        return description
    }

    private func generateTags(title: String, genre: BookGenre?, language: String?) -> [String] {
        var tags: [String] = []

        if let genre = genre {
            tags.append(genre.rawValue)
        }

        if let language = language {
            if language.starts(with: "zh") {
                tags.append("chinese")
                if language == "zh-Hant" {
                    tags.append("traditional-chinese")
                } else {
                    tags.append("simplified-chinese")
                }
            } else {
                tags.append("english")
            }
        }

        // Add content-based tags from title
        let lowerTitle = title.lowercased()
        if lowerTitle.contains("学习") || lowerTitle.contains("learning") {
            tags.append("educational")
        }
        if lowerTitle.contains("小说") || lowerTitle.contains("fiction") {
            tags.append("story")
        }

        return tags
    }
}
