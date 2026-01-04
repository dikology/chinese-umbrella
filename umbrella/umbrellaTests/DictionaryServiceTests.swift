//
//  DictionaryServiceTests.swift
//  umbrellaTests
//
//  Created by Денис on 02.01.2026.
//

import Testing
@testable import umbrella

struct DictionaryServiceTests {
    private var dictionaryService: CEDICTDictionaryService!

    init() {
        dictionaryService = CEDICTDictionaryService()
    }

    @Test("Dictionary can be preloaded without errors")
    @MainActor
    func testDictionaryPreloading() async {
        // Test that dictionary can be preloaded without errors
        #expect(!dictionaryService.isLoaded, "Dictionary should not be loaded initially")

        do {
            try dictionaryService.preloadDictionary()
            #expect(dictionaryService.isLoaded, "Dictionary should be loaded after preloading")
        } catch {
            Issue.record("Dictionary preloading should not fail: \(error)")
        }
    }

    @Test("Basic word lookup works for common words")
    @MainActor
    func testBasicWordLookup() async {
        // Preload dictionary
        try? dictionaryService.preloadDictionary()

        // Test lookup of common words
        let helloEntry = dictionaryService.lookup(word: "你好")
        #expect(helloEntry != nil, "Should find entry for '你好'")
        #expect(helloEntry?.simplified == "你好", "Simplified form should be correct")

        let goodEntry = dictionaryService.lookup(word: "好")
        #expect(goodEntry != nil, "Should find entry for '好'")
        #expect(goodEntry?.simplified == "好", "Simplified form should be correct")
    }

    @Test("Traditional to simplified character lookup works")
    @MainActor
    func testTraditionalToSimplifiedLookup() async {
        // Preload dictionary
        try? dictionaryService.preloadDictionary()

        // Test lookup using traditional characters
        let traditionalEntry = dictionaryService.lookup(word: "愛")
        #expect(traditionalEntry != nil, "Should find entry for traditional character '愛'")
        #expect(traditionalEntry?.simplified == "爱", "Should map traditional to simplified")
    }

    @Test("Pinyin is properly parsed from dictionary")
    @MainActor
    func testPinyinParsing() async {
        // Preload dictionary
        try? dictionaryService.preloadDictionary()

        // Test that pinyin is properly parsed
        let entry = dictionaryService.lookup(word: "你好")
        #expect(entry?.pinyin != nil, "Entry should have pinyin")
        #expect(!entry!.pinyin.isEmpty, "Pinyin should not be empty")
    }

    @Test("English definitions are present in dictionary entries")
    @MainActor
    func testEnglishDefinitions() async {
        // Preload dictionary
        try? dictionaryService.preloadDictionary()

        // Test that English definitions are present
        let entry = dictionaryService.lookup(word: "你好")
        #expect(entry?.englishDefinition != nil, "Entry should have English definition")
        #expect(!entry!.englishDefinition.isEmpty, "English definition should not be empty")
    }

    @Test("Non-existent words return nil")
    @MainActor
    func testNonExistentWord() async {
        // Preload dictionary
        try? dictionaryService.preloadDictionary()

        // Test lookup of non-existent word
        let nonExistentEntry = dictionaryService.lookup(word: "xyz123")
        #expect(nonExistentEntry == nil, "Should return nil for non-existent word")
    }

    @Test("Dictionary entries have all required fields")
    @MainActor
    func testDictionaryEntryStructure() async {
        // Preload dictionary
        try? dictionaryService.preloadDictionary()

        // Test that entries have required fields
        let entry = dictionaryService.lookup(word: "我")
        #expect(entry != nil, "Should find entry for '我'")

        if let entry = entry {
            #expect(!entry.simplified.isEmpty, "Simplified should not be empty")
            #expect(!entry.traditional.isEmpty, "Traditional should not be empty")
            #expect(!entry.pinyin.isEmpty, "Pinyin should not be empty")
            #expect(!entry.englishDefinition.isEmpty, "English definition should not be empty")
            #expect(entry.isValid, "Entry should be valid")
        }
    }
}
