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

    init() {
        service = LocalTextSegmentationService()
    }

    // MARK: - Chinese Text Segmentation Tests

    @Test func testSegment_chineseText_returnsProperWordSegments() async throws {
        // Given
        let chineseText = "这是一个测试句子。"

        // When
        let segments = try await service.segment(text: chineseText)

        // Then
        #expect(!segments.isEmpty)
        // Chinese text is segmented into individual characters for language learning
        #expect(segments.contains { $0 == "这" })
        #expect(segments.contains { $0 == "是" })
        #expect(segments.contains { $0 == "一" })
        #expect(segments.contains { $0 == "个" })
        #expect(segments.contains { $0 == "测" })
        #expect(segments.contains { $0 == "试" })
        #expect(segments.contains { $0 == "句" })
        #expect(segments.contains { $0 == "子" })
        #expect(segments.contains { $0 == "。" })
    }

    @Test func testSegmentWithPositions_chineseText_returnsCorrectPositions() async throws {
        // Given
        let chineseText = "你好世界"

        // When
        let wordSegments = try await service.segmentWithPositions(text: chineseText)

        // Then
        #expect(wordSegments.count == 4) // Should have 4 individual characters

        // Verify positions are correct
        for segment in wordSegments {
            let expectedSubstring = String(chineseText[chineseText.index(chineseText.startIndex, offsetBy: segment.startIndex)..<chineseText.index(chineseText.startIndex, offsetBy: segment.endIndex)])
            #expect(segment.word == expectedSubstring, "Word '\(segment.word)' doesn't match text at positions \(segment.startIndex)-\(segment.endIndex)")
        }

        // Check specific characters
        #expect(wordSegments.contains { $0.word == "你" && $0.startIndex == 0 && $0.endIndex == 1 })
        #expect(wordSegments.contains { $0.word == "好" && $0.startIndex == 1 && $0.endIndex == 2 })
        #expect(wordSegments.contains { $0.word == "世" && $0.startIndex == 2 && $0.endIndex == 3 })
        #expect(wordSegments.contains { $0.word == "界" && $0.startIndex == 3 && $0.endIndex == 4 })
    }

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
            segment.word == "世" || segment.word == "界"
        }
        let hasPunctuation = wordSegments.contains { segment in
            segment.word == "！" || segment.word == "."
        }

        #expect(hasEnglishWords, "Should segment English words")
        #expect(hasChineseWords, "Should segment Chinese words")
        #expect(hasPunctuation, "Should separate punctuation")
    }

    @Test func testSegmentWithPositions_longChineseText_complexSegmentation() async throws {
        // Given - A longer Chinese text sample
        let longText = """
        《红楼梦》是中国古典小说巅峰之作，全书以贾、史、王、薛四大家族的兴衰为背景，以贾府的家庭琐事和贾宝玉、林黛玉的爱情悲剧为主线，描绘了当时社会生活的方方面面。
        """

        // When
        let wordSegments = try await service.segmentWithPositions(text: longText)

        // Then
        #expect(wordSegments.count > 10, "Should segment long text into individual characters")

        // For language learning, Chinese text is segmented into individual characters
        let allSingleChars = wordSegments.allSatisfy { $0.word.count == 1 }
        #expect(allSingleChars, "Should segment Chinese text into individual characters")

        // Verify some expected characters are present
        let segmentWords = wordSegments.map { $0.word }
        #expect(segmentWords.contains("红"), "Should contain individual characters")
        #expect(segmentWords.contains("楼"), "Should contain individual characters")
        #expect(segmentWords.contains("梦"), "Should contain individual characters")
        #expect(segmentWords.contains("中"), "Should contain individual characters")
        #expect(segmentWords.contains("国"), "Should contain individual characters")

        // Verify positions are contiguous and non-overlapping
        for i in 0..<wordSegments.count-1 {
            let currentEnd = wordSegments[i].endIndex
            let nextStart = wordSegments[i+1].startIndex
            #expect(currentEnd == nextStart, "Character positions should be contiguous")
        }
    }

    @Test func testSegmentWithPositions_emptyText_returnsEmptyArray() async throws {
        // Given
        let emptyText = ""

        // When
        let wordSegments = try await service.segmentWithPositions(text: emptyText)

        // Then
        #expect(wordSegments.isEmpty)
    }

    @Test func testSegmentWithPositions_whitespaceOnly_returnsEmptyArray() async throws {
        // Given
        let whitespaceText = "   \n\t  "

        // When
        let wordSegments = try await service.segmentWithPositions(text: whitespaceText)

        // Then
        #expect(wordSegments.isEmpty)
    }

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

    @Test func testSegmentWithPositions_englishText_correctPositions() async throws {
        // Given
        let englishText = "Hello world!"

        // When
        let wordSegments = try await service.segmentWithPositions(text: englishText)

        // Then
        #expect(wordSegments.count >= 2)

        // Find "Hello" segment
        if let helloSegment = wordSegments.first(where: { $0.word == "Hello" }) {
            #expect(helloSegment.startIndex == 0)
            #expect(helloSegment.endIndex == 5)
        } else {
            #expect(false, "Should contain 'Hello' segment")
        }

        // Find "world" segment
        if let worldSegment = wordSegments.first(where: { $0.word == "world" }) {
            #expect(worldSegment.startIndex == 6)
            #expect(worldSegment.endIndex == 11)
        } else {
            #expect(false, "Should contain 'world' segment")
        }
    }

    // MARK: - Position Accuracy Tests

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

    @Test func testSegmentWithPositions_detectsChineseLanguage() async throws {
        // Given
        let chineseText = "我爱学习中文"

        // When
        let wordSegments = try await service.segmentWithPositions(text: chineseText)

        // Then
        #expect(wordSegments.count == 6) // Should have 6 individual characters

        // For language learning, Chinese text is segmented into individual characters
        let allSingleChars = wordSegments.allSatisfy { $0.word.count == 1 }
        #expect(allSingleChars, "Should segment Chinese into individual characters for language learning")

        // Check specific characters are present
        #expect(wordSegments.contains { $0.word == "我" })
        #expect(wordSegments.contains { $0.word == "爱" })
        #expect(wordSegments.contains { $0.word == "学" })
        #expect(wordSegments.contains { $0.word == "习" })
        #expect(wordSegments.contains { $0.word == "中" })
        #expect(wordSegments.contains { $0.word == "文" })
    }

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
