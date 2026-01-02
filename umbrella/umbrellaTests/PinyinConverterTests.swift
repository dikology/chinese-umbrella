//
//  PinyinConverterTests.swift
//  umbrellaTests
//
//  Created by Денис on 02.01.2026.
//

import Testing
@testable import umbrella

@Suite("Pinyin Converter Tests")
struct PinyinConverterTests {

    @Test("Tone number to Unicode mark conversion")
    func testToneNumberToMarkConversion() {
        // Test basic tone conversions
        #expect(PinyinConverter.convertToneNumbersToMarks("ni3") == "nǐ")
        #expect(PinyinConverter.convertToneNumbersToMarks("hao3") == "hǎo")
        #expect(PinyinConverter.convertToneNumbersToMarks("ma1") == "mā")
        #expect(PinyinConverter.convertToneNumbersToMarks("ma2") == "má")
        #expect(PinyinConverter.convertToneNumbersToMarks("ma4") == "mà")
        #expect(PinyinConverter.convertToneNumbersToMarks("ma5") == "ma")
    }

    @Test("Multi-syllable word conversion")
    func testMultiSyllableWords() {
        // Test multi-syllable words
        #expect(PinyinConverter.convertToneNumbersToMarks("ni3 hao3") == "nǐ hǎo")
        #expect(PinyinConverter.convertToneNumbersToMarks("zai4 jian4") == "zài jiàn")
        #expect(PinyinConverter.convertToneNumbersToMarks("xie1 xie5") == "xiē xiè")
    }

    @Test("Vowel precedence rules")
    func testVowelPrecedenceRules() {
        // Test vowel precedence (a > e > o > others)
        #expect(PinyinConverter.convertToneNumbersToMarks("liang2") == "liáng") // a gets tone
        #expect(PinyinConverter.convertToneNumbersToMarks("hen3") == "hěn") // e gets tone
        #expect(PinyinConverter.convertToneNumbersToMarks("gou3") == "gǒu") // o gets tone
        #expect(PinyinConverter.convertToneNumbersToMarks("shi4") == "shì") // i gets tone
        #expect(PinyinConverter.convertToneNumbersToMarks("lü3") == "lǚ") // ü gets tone
    }

    @Test("Strings without tone numbers")
    func testNoToneNumbers() {
        // Test strings without tone numbers
        #expect(PinyinConverter.convertToneNumbersToMarks("hello") == "hello")
        #expect(PinyinConverter.convertToneNumbersToMarks("ni hao") == "ni hao")
    }

    @Test("Empty and invalid input")
    func testEmptyAndInvalidInput() {
        // Test edge cases
        #expect(PinyinConverter.convertToneNumbersToMarks("") == "")
        #expect(PinyinConverter.convertToneNumbersToMarks("a0") == "a0") // Invalid tone number
        #expect(PinyinConverter.convertToneNumbersToMarks("a6") == "a6") // Invalid tone number
    }

    @Test("Complex real-world examples")
    func testComplexExamples() {
        // Test real examples from CEDICT
        #expect(PinyinConverter.convertToneNumbersToMarks("zhong1 guo2") == "zhōng guó")
        #expect(PinyinConverter.convertToneNumbersToMarks("xue2 xi2") == "xué xí")
        #expect(PinyinConverter.convertToneNumbersToMarks("fa1 zhan3") == "fā zhǎn")
    }
}
