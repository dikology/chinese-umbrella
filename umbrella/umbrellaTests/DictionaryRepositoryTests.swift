//
//  DictionaryRepositoryTests.swift
//  umbrellaTests
//
//  Created by Денис on 02.01.2026.
//

import XCTest
@testable import umbrella

final class DictionaryRepositoryTests: XCTestCase {
    var repository: DictionaryRepositoryImpl!
    var mockService: MockDictionaryService!

    override func setUp() {
        super.setUp()
        mockService = MockDictionaryService()
        repository = DictionaryRepositoryImpl(dictionaryService: mockService)
    }

    override func tearDown() {
        repository = nil
        mockService = nil
        super.tearDown()
    }

    func testLookupCharacter() async throws {
        // Setup mock
        let expectedEntry = DictionaryEntry(
            simplified: "你",
            traditional: "你",
            pinyin: "nǐ",
            englishDefinition: "you"
        )
        mockService.mockEntry = expectedEntry

        // Test lookup
        let entry = try await repository.lookup(character: "你")
        XCTAssertNotNil(entry, "Should return entry")
        XCTAssertEqual(entry?.simplified, "你", "Should return correct entry")
    }

    func testLookupWord() async throws {
        // Setup mock
        let expectedEntry = DictionaryEntry(
            simplified: "你好",
            traditional: "你好",
            pinyin: "nǐ hǎo",
            englishDefinition: "hello"
        )
        mockService.mockEntry = expectedEntry

        // Test lookup
        let entry = try await repository.lookup(word: "你好")
        XCTAssertNotNil(entry, "Should return entry")
        XCTAssertEqual(entry?.simplified, "你好", "Should return correct entry")
    }

    func testDictionaryPreloading() async throws {
        // Test preloading
        try await repository.preloadDictionary()

        // Verify service was called
        XCTAssertTrue(mockService.preloadCalled, "Service preload should be called")
    }

    func testIsDictionaryLoaded() async {
        // Initially should not be loaded
        mockService.isLoaded = false
        var loaded = await repository.isDictionaryLoaded()
        XCTAssertFalse(loaded, "Should not be loaded initially")

        // After setting loaded
        mockService.isLoaded = true
        loaded = await repository.isDictionaryLoaded()
        XCTAssertTrue(loaded, "Should be loaded after setting")
    }

    func testGetExamples() async throws {
        // Test examples (currently returns empty array)
        let examples = try await repository.getExamples(for: "你好")
        XCTAssertTrue(examples.isEmpty, "Examples should be empty in Phase 1")
    }
}

// Mock service for testing
class MockDictionaryService: DictionaryService {
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
