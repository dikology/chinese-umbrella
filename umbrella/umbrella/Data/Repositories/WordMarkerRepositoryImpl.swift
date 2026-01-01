//
//  WordMarkerRepositoryImpl.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation

/// Basic word marker repository implementation
/// Phase 1: In-memory storage - will be enhanced with Core Data persistence in Phase 2
class WordMarkerRepositoryImpl: WordMarkerRepository {
    private var markedWords: [UUID: [AppMarkedWord]] = [:] // userId -> marked words
    private let queue = DispatchQueue(label: "com.umbrella.wordmarker", attributes: .concurrent)

    func markWord(_ markedWord: AppMarkedWord) async throws -> AppMarkedWord {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }

                var userWords = self.markedWords[markedWord.userId] ?? []

                // Check if word is already marked
                if let existingIndex = userWords.firstIndex(where: { $0.word == markedWord.word }) {
                    let existingWord = userWords[existingIndex]
                    // Create new instance with updated count and timestamp
                    let updatedWord = AppMarkedWord(
                        id: existingWord.id,
                        userId: existingWord.userId,
                        word: existingWord.word,
                        readingDate: Date(), // Update timestamp
                        contextSnippet: existingWord.contextSnippet,
                        textId: existingWord.textId,
                        pageNumber: existingWord.pageNumber,
                        markedCount: existingWord.markedCount + 1 // Increment count
                    )
                    userWords[existingIndex] = updatedWord
                    self.markedWords[markedWord.userId] = userWords
                    continuation.resume(returning: updatedWord)
                } else {
                    // Add new marked word
                    userWords.append(markedWord)
                    self.markedWords[markedWord.userId] = userWords
                    continuation.resume(returning: markedWord)
                }
            }
        }
    }

    func unmarkWord(word: String, userId: UUID) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }

                var userWords = self.markedWords[userId] ?? []
                userWords.removeAll { $0.word == word }
                self.markedWords[userId] = userWords
                continuation.resume()
            }
        }
    }

    func getMarkedWords(for userId: UUID) async throws -> [AppMarkedWord] {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                let words = self?.markedWords[userId] ?? []
                continuation.resume(returning: words)
            }
        }
    }

    func getMarkedWords(for bookId: UUID, userId: UUID) async throws -> [AppMarkedWord] {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                let userWords = self?.markedWords[userId] ?? []
                let bookWords = userWords.filter { $0.textId == bookId }
                continuation.resume(returning: bookWords)
            }
        }
    }

    func isWordMarked(_ word: String, userId: UUID) async throws -> Bool {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                let userWords = self?.markedWords[userId] ?? []
                let isMarked = userWords.contains { $0.word == word }
                continuation.resume(returning: isMarked)
            }
        }
    }

    func getRecentMarkedWords(for userId: UUID, limit: Int) async throws -> [AppMarkedWord] {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                let userWords = self?.markedWords[userId] ?? []
                let recentWords = userWords
                    .filter { $0.isRecentlyMarked }
                    .sorted { $0.readingDate > $1.readingDate }
                    .prefix(limit)
                continuation.resume(returning: Array(recentWords))
            }
        }
    }

    func incrementMarkCount(word: String, userId: UUID) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }

                var userWords = self.markedWords[userId] ?? []
                if let index = userWords.firstIndex(where: { $0.word == word }) {
                    let existingWord = userWords[index]
                    // Create new instance with incremented count
                    let updatedWord = AppMarkedWord(
                        id: existingWord.id,
                        userId: existingWord.userId,
                        word: existingWord.word,
                        readingDate: existingWord.readingDate,
                        contextSnippet: existingWord.contextSnippet,
                        textId: existingWord.textId,
                        pageNumber: existingWord.pageNumber,
                        markedCount: existingWord.markedCount + 1
                    )
                    userWords[index] = updatedWord
                    self.markedWords[userId] = userWords
                }
                continuation.resume()
            }
        }
    }

    func getMarkStatistics(for userId: UUID) async throws -> WordMarkStatistics {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                let userWords = self?.markedWords[userId] ?? []

                let totalMarkedWords = userWords.count
                let recentlyMarkedWords = userWords.filter { $0.isRecentlyMarked }.count
                let frequentlyMarkedWords = userWords.filter { $0.isFrequentlyMarked }.count

                // Calculate average marks per session (simplified for Phase 1)
                let averageMarksPerSession = totalMarkedWords > 0 ? Double(totalMarkedWords) / 10.0 : 0.0

                // Get most marked words
                let mostMarkedWords = userWords
                    .sorted { $0.markedCount > $1.markedCount }
                    .prefix(10)
                    .map { $0.word }

                let statistics = WordMarkStatistics(
                    totalMarkedWords: totalMarkedWords,
                    recentlyMarkedWords: recentlyMarkedWords,
                    frequentlyMarkedWords: frequentlyMarkedWords,
                    averageMarksPerSession: averageMarksPerSession,
                    mostMarkedWords: mostMarkedWords
                )

                continuation.resume(returning: statistics)
            }
        }
    }

    // MARK: - Helper Methods
}
