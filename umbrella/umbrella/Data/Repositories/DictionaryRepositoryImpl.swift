//
//  DictionaryRepositoryImpl.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation

/// Dictionary repository implementation using CEDICT
/// Integrates with CEDICTDictionaryService for comprehensive Chinese-English dictionary lookups
class DictionaryRepositoryImpl: DictionaryRepository {
    private let dictionaryService: DictionaryService

    init(dictionaryService: DictionaryService = CEDICTDictionaryService()) {
        self.dictionaryService = dictionaryService
    }

    func lookup(character: String) async throws -> DictionaryEntry? {
        try await ensureDictionaryLoaded()
        return dictionaryService.lookup(word: character)
    }

    func lookup(word: String) async throws -> DictionaryEntry? {
        try await ensureDictionaryLoaded()
        return dictionaryService.lookup(word: word)
    }

    func getExamples(for word: String) async throws -> [String] {
        // Phase 1: Return empty examples - will be implemented in Phase 2
        // TODO: Integrate with example sentences database
        return []
    }

    func searchWords(prefix: String, limit: Int) async throws -> [DictionaryEntry] {
        // Phase 1: Basic prefix search implementation
        // TODO: Implement efficient prefix search in Phase 2
        // For now, this is a placeholder - would need to iterate through all entries
        // which is inefficient for large dictionaries like CEDICT
        throw DictionaryError.invalidQuery // Not implemented in Phase 1
    }

    func getWordsByHSKLevel(_ level: HSKLevel) async throws -> [DictionaryEntry] {
        // Phase 1: HSK level filtering not implemented
        // TODO: Integrate with HSK frequency database in Phase 2
        throw DictionaryError.invalidQuery // Not implemented in Phase 1
    }

    func preloadDictionary() async throws {
        do {
            try dictionaryService.preloadDictionary()
        } catch _ as DictionaryServiceError {
            throw DictionaryError.preloadFailed
        } catch {
            throw DictionaryError.unknown(error)
        }
    }

    func isDictionaryLoaded() async -> Bool {
        return dictionaryService.isLoaded
    }

    private func ensureDictionaryLoaded() async throws {
        if !(await isDictionaryLoaded()) {
            try await preloadDictionary()
        }
    }
}
