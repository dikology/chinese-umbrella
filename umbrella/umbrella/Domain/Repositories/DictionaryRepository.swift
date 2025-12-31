//
//  DictionaryRepository.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation

/// Repository protocol for dictionary operations
protocol DictionaryRepository {
    /// Look up a single character
    func lookup(character: String) async throws -> DictionaryEntry?

    /// Look up a word (multiple characters)
    func lookup(word: String) async throws -> DictionaryEntry?

    /// Get example sentences for a word
    func getExamples(for word: String) async throws -> [String]

    /// Search for words matching a pattern
    func searchWords(prefix: String, limit: Int) async throws -> [DictionaryEntry]

    /// Get words by HSK level
    func getWordsByHSKLevel(_ level: HSKLevel) async throws -> [DictionaryEntry]

    /// Preload dictionary data (called on first app launch)
    func preloadDictionary() async throws

    /// Check if dictionary is loaded
    func isDictionaryLoaded() async -> Bool
}

/// Errors that can occur during dictionary operations
enum DictionaryError: LocalizedError {
    case wordNotFound
    case dictionaryNotLoaded
    case invalidQuery
    case preloadFailed
    case networkError
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .wordNotFound:
            return "Word not found in dictionary"
        case .dictionaryNotLoaded:
            return "Dictionary data not loaded"
        case .invalidQuery:
            return "Invalid search query"
        case .preloadFailed:
            return "Failed to load dictionary data"
        case .networkError:
            return "Network connection error"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
