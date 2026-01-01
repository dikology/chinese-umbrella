//
//  DictionaryRepositoryImpl.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation

/// Basic dictionary repository implementation
/// Phase 1: In-memory dictionary with basic Chinese-English mappings
/// In future phases, this will integrate with CEDICT or other dictionary APIs
class DictionaryRepositoryImpl: DictionaryRepository {
    private var isLoaded = false
    private var dictionaryData: [String: DictionaryEntry] = [:]

    // Basic dictionary data for Phase 1 - will be expanded
    private let basicDictionary: [String: DictionaryEntry] = [
        "你": DictionaryEntry(
            simplified: "你",
            traditional: "你",
            pinyin: "nǐ",
            englishDefinition: "you (singular)",
            frequency: .hsk1
        ),
        "好": DictionaryEntry(
            simplified: "好",
            traditional: "好",
            pinyin: "hǎo",
            englishDefinition: "good; well; proper; good to; easy to; very; so; (suffix indicating completion or readiness)",
            frequency: .hsk1
        ),
        "我": DictionaryEntry(
            simplified: "我",
            traditional: "我",
            pinyin: "wǒ",
            englishDefinition: "I; me; my",
            frequency: .hsk1
        ),
        "是": DictionaryEntry(
            simplified: "是",
            traditional: "是",
            pinyin: "shì",
            englishDefinition: "is; are; am; yes; to be",
            frequency: .hsk1
        ),
        "的": DictionaryEntry(
            simplified: "的",
            traditional: "的",
            pinyin: "de",
            englishDefinition: "(possessive particle); of",
            frequency: .hsk1
        ),
        "了": DictionaryEntry(
            simplified: "了",
            traditional: "了",
            pinyin: "le",
            englishDefinition: "(modal particle intensifying preceding clause); (completed action marker)",
            frequency: .hsk1
        ),
        "不": DictionaryEntry(
            simplified: "不",
            traditional: "不",
            pinyin: "bù",
            englishDefinition: "(negative prefix); not; no",
            frequency: .hsk1
        ),
        "在": DictionaryEntry(
            simplified: "在",
            traditional: "在",
            pinyin: "zài",
            englishDefinition: "(located) at; (to be) in; to exist; in the middle of doing something",
            frequency: .hsk1
        )
    ]

    func lookup(character: String) async throws -> DictionaryEntry? {
        try await ensureDictionaryLoaded()
        return dictionaryData[character]
    }

    func lookup(word: String) async throws -> DictionaryEntry? {
        try await ensureDictionaryLoaded()
        return dictionaryData[word]
    }

    func getExamples(for word: String) async throws -> [String] {
        // Phase 1: Return empty examples - will be implemented in Phase 2
        return []
    }

    func searchWords(prefix: String, limit: Int) async throws -> [DictionaryEntry] {
        try await ensureDictionaryLoaded()

        let filtered = dictionaryData.values.filter { entry in
            entry.simplified.hasPrefix(prefix) || entry.traditional.hasPrefix(prefix)
        }

        return Array(filtered.prefix(limit))
    }

    func getWordsByHSKLevel(_ level: HSKLevel) async throws -> [DictionaryEntry] {
        try await ensureDictionaryLoaded()

        return dictionaryData.values.filter { $0.frequency == level }
    }

    func preloadDictionary() async throws {
        // Simulate loading time
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        dictionaryData = basicDictionary
        isLoaded = true
    }

    func isDictionaryLoaded() async -> Bool {
        return isLoaded
    }

    private func ensureDictionaryLoaded() async throws {
        if !isLoaded {
            try await preloadDictionary()
        }
    }
}
