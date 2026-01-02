//
//  DictionaryRepositoryTests.swift
//  umbrellaTests
//
//  Created by Денис on 02.01.2026.
//

import Testing
@testable import umbrella

@Suite("Dictionary Repository Tests")
struct DictionaryRepositoryTests {

    // Mock service for testing
    private final class MockDictionaryService: DictionaryService {
        var mockEntry: DictionaryEntry?
        var preloadCalled = false
        var isLoaded = false

        func lookup(word: String) -> DictionaryEntry? {
            return mockEntry
        }

        func preloadDictionary() throws {
            preloadCalled = true
            isLoaded = true
        }
    }

    @Test("Character lookup functionality")
    func testLookupCharacter() async throws {
        // Setup
        let mockService = MockDictionaryService()
        let repository = DictionaryRepositoryImpl(dictionaryService: mockService)

        let expectedEntry = DictionaryEntry(
            simplified: "你",
            traditional: "你",
            pinyin: "nǐ",
            englishDefinition: "you"
        )
        mockService.mockEntry = expectedEntry

        // Test lookup
        let entry = try await repository.lookup(character: "你")
        #expect(entry != nil, "Should return entry")
        #expect(entry?.simplified == "你", "Should return correct entry")
    }

    @Test("Word lookup functionality")
    func testLookupWord() async throws {
        // Setup
        let mockService = MockDictionaryService()
        let repository = DictionaryRepositoryImpl(dictionaryService: mockService)

        let expectedEntry = DictionaryEntry(
            simplified: "你好",
            traditional: "你好",
            pinyin: "nǐ hǎo",
            englishDefinition: "hello"
        )
        mockService.mockEntry = expectedEntry

        // Test lookup
        let entry = try await repository.lookup(word: "你好")
        #expect(entry != nil, "Should return entry")
        #expect(entry?.simplified == "你好", "Should return correct entry")
    }

    @Test("Dictionary preloading")
    func testDictionaryPreloading() async throws {
        // Setup
        let mockService = MockDictionaryService()
        let repository = DictionaryRepositoryImpl(dictionaryService: mockService)

        // Test preloading
        try await repository.preloadDictionary()

        // Verify service was called
        #expect(mockService.preloadCalled, "Service preload should be called")
    }

    @Test("Dictionary loaded state")
    func testIsDictionaryLoaded() async {
        // Setup
        let mockService = MockDictionaryService()
        let repository = DictionaryRepositoryImpl(dictionaryService: mockService)

        // Initially should not be loaded
        mockService.isLoaded = false
        var loaded = await repository.isDictionaryLoaded()
        #expect(!loaded, "Should not be loaded initially")

        // After setting loaded
        mockService.isLoaded = true
        loaded = await repository.isDictionaryLoaded()
        #expect(loaded, "Should be loaded after setting")
    }

    @Test("Examples retrieval")
    func testGetExamples() async throws {
        // Setup
        let mockService = MockDictionaryService()
        let repository = DictionaryRepositoryImpl(dictionaryService: mockService)

        // Test examples (currently returns empty array)
        let examples = try await repository.getExamples(for: "你好")
        #expect(examples.isEmpty, "Examples should be empty in Phase 1")
    }
}
