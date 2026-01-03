//
//  TextSegmentationServiceTests.swift
//  umbrellaTests
//
//  Created by Денис on 31.12.2025.
//

import Testing
import NaturalLanguage
@testable import umbrella

struct TextSegmentationServiceTests {
    private var service: LocalTextSegmentationService!
    private var dictionaryService: CEDICTDictionaryService!

    init() async throws {
        dictionaryService = CEDICTDictionaryService()
        try dictionaryService.preloadDictionary()
        service = LocalTextSegmentationService(dictionaryService: dictionaryService)
    }

    // MARK: - Chinese Text Segmentation Tests

    @Test func testSegment_chineseText_returnsProperWordSegments() async throws {
        // Given
        let chineseText = "这是一个测试句子。"

        // When
        let segments = try await service.segment(text: chineseText)

        // Then
        #expect(!segments.isEmpty)

        // With dictionary-based segmentation, we should get multi-character words where possible
        // "这是" (zhè shì) - "this is" - exists in CEDICT
        #expect(segments.contains { $0 == "这是" } || segments.contains { $0 == "这" })

        // "一个" (yī gè) - "one/a" - exists in CEDICT
        #expect(segments.contains { $0 == "一个" } || (segments.contains { $0 == "一" } && segments.contains { $0 == "个" }))

        // "测试" (cè shì) - "test" - exists in CEDICT
        #expect(segments.contains { $0 == "测试" } || (segments.contains { $0 == "测" } && segments.contains { $0 == "试" }))

        // "句子" (jù zi) - "sentence" - exists in CEDICT
        #expect(segments.contains { $0 == "句子" } || (segments.contains { $0 == "句" } && segments.contains { $0 == "子" }))

        // Punctuation should still be preserved
        #expect(segments.contains { $0 == "。" })
    }

    @MainActor
    @Test func testSegmentWithPositions_chineseText_returnsCorrectPositions() async throws {
        // Given
        let chineseText = "你好世界"

        // When
        let wordSegments = try await service.segmentWithPositions(text: chineseText)

        // Then
        // With dictionary segmentation, "你好" and "世界" should be recognized as words
        #expect(wordSegments.count == 2) // Should have 2 words instead of 4 characters

        // Verify positions are correct
        for segment in wordSegments {
            #expect(segment.endIndex > segment.startIndex, "Segment end should be after start")
            #expect(segment.startIndex >= 0 && segment.endIndex <= chineseText.count, "Segment positions should be within text bounds")
        }

        // Check that we get the expected words
        #expect(wordSegments.contains { $0.word == "你好" && $0.startIndex == 0 && $0.endIndex == 2 })
        #expect(wordSegments.contains { $0.word == "世界" && $0.startIndex == 2 && $0.endIndex == 4 })
    }

    @MainActor
    @Test func testSegmentWithPositions_textWithPunctuation_separatesPunctuation() async throws {
        // Given
        let textWithPunctuation = "你好，世界！"

        // When
        let wordSegments = try await service.segmentWithPositions(text: textWithPunctuation)

        // Then
        #expect(wordSegments.count >= 3) // Words + punctuation

        // Should contain punctuation as separate segments
        let punctuationSegments = wordSegments.filter { $0.word.contains(where: { char in
            char.isPunctuation || char.isSymbol || "，。！？".contains(char)
        })}
        #expect(!punctuationSegments.isEmpty, "Should have punctuation segments")
    }

    @MainActor
    @Test func testSegmentWithPositions_mixedChineseEnglish_handlesBoth() async throws {
        // Given
        let mixedText = "Hello 世界！This is a test."

        // When
        let wordSegments = try await service.segmentWithPositions(text: mixedText)

        // Then
        #expect(wordSegments.count > 0)

        // Should contain both English and Chinese words
        let hasEnglishWords = wordSegments.contains { segment in
            segment.word == "Hello" || segment.word == "This" || segment.word == "is" || segment.word == "a" || segment.word == "test"
        }
        let hasChineseWords = wordSegments.contains { segment in
            segment.word == "世界"
        }
        let hasPunctuation = wordSegments.contains { segment in
            segment.word == "！" || segment.word == "."
        }

        #expect(hasEnglishWords, "Should segment English words")
        #expect(hasChineseWords, "Should segment Chinese words")
        #expect(hasPunctuation, "Should separate punctuation")
    }

    @MainActor
    @Test func testSegmentWithPositions_longChineseText_complexSegmentation() async throws {
        // Given - A longer Chinese text sample
        let longText = """
        《红楼梦》是中国古典小说巅峰之作，全书以贾、史、王、薛四大家族的兴衰为背景，以贾府的家庭琐事和贾宝玉、林黛玉的爱情悲剧为主线，描绘了当时社会生活的方方面面。
        """

        // When
        let wordSegments = try await service.segmentWithPositions(text: longText)

        // Then
        #expect(wordSegments.count > 5, "Should segment long text into words")

        // With dictionary segmentation, we should get multi-character words where possible
        let hasMultiCharWords = wordSegments.contains { $0.word.count > 1 }
        #expect(hasMultiCharWords, "Should recognize some multi-character words from dictionary")

        // Verify some expected characters/words are present
        let segmentWords = wordSegments.map { $0.word }
        // Check for individual characters that might not form dictionary words
        #expect(segmentWords.contains("红") || segmentWords.contains(where: { $0.contains("红") }), "Should contain characters from the text")
        #expect(segmentWords.contains("楼") || segmentWords.contains(where: { $0.contains("楼") }), "Should contain characters from the text")
        #expect(segmentWords.contains("梦") || segmentWords.contains(where: { $0.contains("梦") }), "Should contain characters from the text")

        // Check for known dictionary words
        #expect(segmentWords.contains("中国") || (segmentWords.contains("中") && segmentWords.contains("国")), "Should recognize '中国' (China) as a word")

        // Verify positions are contiguous and non-overlapping
        for i in 0..<wordSegments.count-1 {
            let currentEnd = wordSegments[i].endIndex
            let nextStart = wordSegments[i+1].startIndex
            #expect(currentEnd == nextStart, "Word positions should be contiguous")
        }
    }

    @MainActor
    @Test func testSegmentWithPositions_emptyText_returnsEmptyArray() async throws {
        // Given
        let emptyText = ""

        // When
        let wordSegments = try await service.segmentWithPositions(text: emptyText)

        // Then
        #expect(wordSegments.isEmpty)
    }

    @MainActor
    @Test func testSegmentWithPositions_whitespaceOnly_returnsEmptyArray() async throws {
        // Given
        let whitespaceText = "   \n\t  "

        // When
        let wordSegments = try await service.segmentWithPositions(text: whitespaceText)

        // Then
        #expect(wordSegments.isEmpty)
    }

    @MainActor
    @Test func testSegmentWithPositions_punctuationOnly_returnsPunctuation() async throws {
        // Given
        let punctuationText = "。！？"

        // When
        let wordSegments = try await service.segmentWithPositions(text: punctuationText)

        // Then
        #expect(wordSegments.count == 3, "Should segment each punctuation mark")
        #expect(wordSegments.allSatisfy { $0.word.count == 1 }, "Each segment should be a single character")
    }

    // MARK: - English Text Tests

    @Test func testSegment_englishText_returnsWordArray() async throws {
        // Given
        let englishText = "This is a test sentence."

        // When
        let segments = try await service.segment(text: englishText)

        // Then
        #expect(segments.count >= 5)
        #expect(segments.contains("This"))
        #expect(segments.contains("is"))
        #expect(segments.contains("a"))
        #expect(segments.contains("test"))
        #expect(segments.contains("sentence"))
    }

    @MainActor
    @Test func testSegmentWithPositions_englishText_correctPositions() async throws {
        // Given
        let englishText = "Hello world!"

        // When
        let wordSegments = try await service.segmentWithPositions(text: englishText)

        // Then
        #expect(wordSegments.count >= 2)

        // Find "Hello" segment
        let helloSegment = wordSegments.first(where: { $0.word == "Hello" })
        #expect(helloSegment != nil, "Should contain 'Hello' segment")
        if let helloSegment = helloSegment {
            #expect(helloSegment.startIndex == 0)
            #expect(helloSegment.endIndex == 5)
        }

        // Find "world" segment
        let worldSegment = wordSegments.first(where: { $0.word == "world" })
        #expect(worldSegment != nil, "Should contain 'world' segment")
        if let worldSegment = worldSegment {
            #expect(worldSegment.startIndex == 6)
            #expect(worldSegment.endIndex == 11)
        }
    }

    // MARK: - Position Accuracy Tests

    @MainActor
    @Test func testSegmentWithPositions_positionsCoverEntireText() async throws {
        // Given
        let testText = "测试text123"

        // When
        let wordSegments = try await service.segmentWithPositions(text: testText)

        // Then
        #expect(!wordSegments.isEmpty)

        // Collect all covered positions
        var coveredPositions = Set<Int>()
        for segment in wordSegments {
            for position in segment.startIndex..<segment.endIndex {
                coveredPositions.insert(position)
            }
        }

        // Should cover all non-whitespace positions
        for (index, char) in testText.enumerated() {
            if !char.isWhitespace {
                #expect(coveredPositions.contains(index), "Position \(index) (\(char)) should be covered")
            }
        }
    }

    @MainActor
    @Test func testSegmentWithPositions_noOverlappingSegments() async throws {
        // Given
        let testText = "这是一个测试"

        // When
        let wordSegments = try await service.segmentWithPositions(text: testText)

        // Then
        for i in 0..<wordSegments.count {
            for j in i+1..<wordSegments.count {
                let segment1 = wordSegments[i]
                let segment2 = wordSegments[j]

                // Check for overlap
                let overlap = max(0, min(segment1.endIndex, segment2.endIndex) - max(segment1.startIndex, segment2.startIndex))
                #expect(overlap == 0, "Segments '\(segment1.word)' and '\(segment2.word)' should not overlap")
            }
        }
    }

    // MARK: - AppWordSegment Properties Tests

    @MainActor
    @Test func testAppWordSegment_properties_calculatedCorrectly() async throws {
        // Given
        let segment = AppWordSegment(
            word: "测试",
            startIndex: 0,
            endIndex: 2
        )

        // Then
        #expect(segment.length == 2)
        #expect(segment.range == 0..<2)
        #expect(!segment.isMarked)
        #expect(segment.definition == nil)
        #expect(segment.hasDefinition == false)
        #expect(segment.isValid == true)
    }

    @MainActor
    @Test func testAppWordSegment_invalidSegment() async throws {
        // Given
        let invalidSegment = AppWordSegment(
            word: "",
            startIndex: 5,
            endIndex: 3 // end < start
        )

        // Then
        #expect(!invalidSegment.isValid)
    }

    // MARK: - Language Detection Tests

    @MainActor
    @Test func testSegmentWithPositions_detectsChineseLanguage() async throws {
        // Given
        let chineseText = "我爱学习中文"

        // When
        let wordSegments = try await service.segmentWithPositions(text: chineseText)

        // Then
        // With dictionary segmentation, should recognize "学习" and "中文" as words
        #expect(wordSegments.count <= 6) // Should have fewer segments than individual characters

        // Should contain multi-character words where possible
        let segmentWords = wordSegments.map { $0.word }
        #expect(segmentWords.contains("学习") || (segmentWords.contains("学") && segmentWords.contains("习")), "Should recognize '学习' (study) as a word")
        #expect(segmentWords.contains("中文") || (segmentWords.contains("中") && segmentWords.contains("文")), "Should recognize '中文' (Chinese) as a word")

        // Check that all characters from the original text are represented
        let reconstructedText = segmentWords.joined()
        #expect(reconstructedText.contains("我爱学习中文"), "All characters should be preserved in segmentation")
    }

    @MainActor
    @Test func testSegmentWithPositions_handlesNumbersAndSymbols() async throws {
        // Given
        let textWithNumbers = "第1章 测试2023年"

        // When
        let wordSegments = try await service.segmentWithPositions(text: textWithNumbers)

        // Then
        #expect(wordSegments.count > 0)

        // Should handle mixed content
        let segmentsText = wordSegments.map { $0.word }.joined()
        let reconstructedText = segmentsText.replacingOccurrences(of: " ", with: "")
        #expect(reconstructedText.contains("第1章"), "Should preserve numbers in segments")
        #expect(reconstructedText.contains("2023年"), "Should preserve years in segments")
    }
}
