//
//  WordMarkerRepository.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation

/// Repository protocol for word marking operations
protocol WordMarkerRepository {
    /// Mark a word as difficult
    func markWord(_ markedWord: AppMarkedWord) async throws -> AppMarkedWord

    /// Unmark a word (remove from difficult words)
    func unmarkWord(word: String, userId: UUID) async throws

    /// Get all marked words for a user
    func getMarkedWords(for userId: UUID) async throws -> [AppMarkedWord]

    /// Get marked words for a specific book
    func getMarkedWords(for bookId: UUID, userId: UUID) async throws -> [AppMarkedWord]

    /// Check if a word is marked as difficult
    func isWordMarked(_ word: String, userId: UUID) async throws -> Bool

    /// Get recently marked words
    func getRecentMarkedWords(for userId: UUID, limit: Int) async throws -> [AppMarkedWord]

    /// Update mark count for a word
    func incrementMarkCount(word: String, userId: UUID) async throws

    /// Get mark statistics for analytics
    func getMarkStatistics(for userId: UUID) async throws -> WordMarkStatistics
}

/// Statistics about word marking patterns
struct WordMarkStatistics {
    let totalMarkedWords: Int
    let recentlyMarkedWords: Int // Last 7 days
    let frequentlyMarkedWords: Int // Marked 3+ times
    let averageMarksPerSession: Double
    let mostMarkedWords: [String] // Top 10 most marked words
}

/// Errors that can occur during word marking operations
enum WordMarkerError: LocalizedError {
    case wordAlreadyMarked
    case wordNotMarked
    case invalidData
    case saveFailed
    case networkError
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .wordAlreadyMarked:
            return "Word is already marked"
        case .wordNotMarked:
            return "Word is not marked"
        case .invalidData:
            return "Invalid marking data"
        case .saveFailed:
            return "Failed to save marking"
        case .networkError:
            return "Network connection error"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
