//
//  DictionaryServiceTests.swift
//  umbrellaTests
//
//  Created by Денис on 02.01.2026.
//

import XCTest
@testable import umbrella

final class DictionaryServiceTests: XCTestCase {
    var dictionaryService: CEDICTDictionaryService!

    override func setUp() {
        super.setUp()
        dictionaryService = CEDICTDictionaryService()
    }

    override func tearDown() {
        dictionaryService = nil
        super.tearDown()
    }

    func testDictionaryPreloading() async throws {
        // Test that dictionary can be preloaded without errors
        XCTAssertFalse(dictionaryService.isLoaded, "Dictionary should not be loaded initially")

        do {
            try dictionaryService.preloadDictionary()
            XCTAssertTrue(dictionaryService.isLoaded, "Dictionary should be loaded after preloading")
        } catch {
            XCTFail("Dictionary preloading should not fail: \(error)")
        }
    }

    func testBasicWordLookup() async throws {
        // Preload dictionary
        try dictionaryService.preloadDictionary()

        // Test lookup of common words
        let helloEntry = dictionaryService.lookup(word: "你好")
        XCTAssertNotNil(helloEntry, "Should find entry for '你好'")
        XCTAssertEqual(helloEntry?.simplified, "你好", "Simplified form should be correct")

        let goodEntry = dictionaryService.lookup(word: "好")
        XCTAssertNotNil(goodEntry, "Should find entry for '好'")
        XCTAssertEqual(goodEntry?.simplified, "好", "Simplified form should be correct")
    }

    func testTraditionalToSimplifiedLookup() async throws {
        // Preload dictionary
        try dictionaryService.preloadDictionary()

        // Test lookup using traditional characters
        let traditionalEntry = dictionaryService.lookup(word: "愛")
        XCTAssertNotNil(traditionalEntry, "Should find entry for traditional character '愛'")
        XCTAssertEqual(traditionalEntry?.simplified, "爱", "Should map traditional to simplified")
    }

    func testPinyinParsing() async throws {
        // Preload dictionary
        try dictionaryService.preloadDictionary()

        // Test that pinyin is properly parsed
        let entry = dictionaryService.lookup(word: "你好")
        XCTAssertNotNil(entry?.pinyin, "Entry should have pinyin")
        XCTAssertFalse(entry!.pinyin.isEmpty, "Pinyin should not be empty")
    }

    func testEnglishDefinitions() async throws {
        // Preload dictionary
        try dictionaryService.preloadDictionary()

        // Test that English definitions are present
        let entry = dictionaryService.lookup(word: "你好")
        XCTAssertNotNil(entry?.englishDefinition, "Entry should have English definition")
        XCTAssertFalse(entry!.englishDefinition.isEmpty, "English definition should not be empty")
    }

    func testNonExistentWord() async throws {
        // Preload dictionary
        try dictionaryService.preloadDictionary()

        // Test lookup of non-existent word
        let nonExistentEntry = dictionaryService.lookup(word: "xyz123")
        XCTAssertNil(nonExistentEntry, "Should return nil for non-existent word")
    }

    func testDictionaryEntryStructure() async throws {
        // Preload dictionary
        try dictionaryService.preloadDictionary()

        // Test that entries have required fields
        let entry = dictionaryService.lookup(word: "我")
        XCTAssertNotNil(entry, "Should find entry for '我'")

        if let entry = entry {
            XCTAssertFalse(entry.simplified.isEmpty, "Simplified should not be empty")
            XCTAssertFalse(entry.traditional.isEmpty, "Traditional should not be empty")
            XCTAssertFalse(entry.pinyin.isEmpty, "Pinyin should not be empty")
            XCTAssertFalse(entry.englishDefinition.isEmpty, "English definition should not be empty")
            XCTAssertTrue(entry.isValid, "Entry should be valid")
        }
    }
}
