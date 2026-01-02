//
//  PinyinConverter.swift
//  umbrella
//
//  Created by Денис on 02.01.2026.
//

import Foundation

/// Utility for converting pinyin tone numbers to Unicode tone marks
struct PinyinConverter {
    /// Maps tone numbers to Unicode combining tone marks
    private static let toneMarks: [Character: String] = [
        "1": "\u{0304}", // macron (ā)
        "2": "\u{0301}", // acute (á)
        "3": "\u{030c}", // caron (ǎ)
        "4": "\u{0300}", // grave (à)
        "5": ""          // neutral tone (no mark)
    ]

    /// Vowels that can carry tone marks (in order of preference)
    private static let vowels = ["a", "e", "i", "o", "u", "ü", "A", "E", "I", "O", "U", "Ü"]

    /// Convert pinyin with tone numbers to pinyin with Unicode tone marks
    /// - Parameter pinyin: Pinyin string with tone numbers (e.g., "nǐ hǎo")
    /// - Returns: Pinyin string with Unicode tone marks (e.g., "nǐ hǎo")
    static func convertToneNumbersToMarks(_ pinyin: String) -> String {
        let syllables = pinyin.components(separatedBy: " ")
        let convertedSyllables = syllables.map { convertSyllable($0) }
        return convertedSyllables.joined(separator: " ")
    }

    /// Convert a single syllable from tone numbers to Unicode marks
    private static func convertSyllable(_ syllable: String) -> String {
        // Find the tone number at the end
        guard let lastChar = syllable.last,
              let toneMark = toneMarks[lastChar],
              lastChar.isNumber,
              let toneNumber = Int(String(lastChar)) else {
            // No tone number found, return as-is
            return syllable
        }

        // Remove the tone number
        var baseSyllable = String(syllable.dropLast())

        // If neutral tone (5), just return the base syllable
        if toneNumber == 5 {
            return baseSyllable
        }

        // Find the vowel to apply the tone mark to
        if let vowelIndex = findVowelForTone(baseSyllable) {
            // Insert the tone mark after the vowel
            let vowelChar = baseSyllable[vowelIndex]
            let markedVowel = String(vowelChar) + toneMark
            baseSyllable.replaceSubrange(vowelIndex...vowelIndex, with: markedVowel)
        }

        return baseSyllable
    }

    /// Find which vowel should receive the tone mark according to pinyin rules
    private static func findVowelForTone(_ syllable: String) -> String.Index? {
        let chars = Array(syllable.lowercased())

        // Rule 1: If there's an "a", it always gets the tone
        if let aIndex = chars.firstIndex(of: "a") {
            return syllable.index(syllable.startIndex, offsetBy: aIndex)
        }

        // Rule 2: If there's an "e", it gets the tone
        if let eIndex = chars.firstIndex(of: "e") {
            return syllable.index(syllable.startIndex, offsetBy: eIndex)
        }

        // Rule 3: If there's "ou", the "o" gets the tone
        if let oIndex = chars.firstIndex(of: "o"),
           oIndex + 1 < chars.count && chars[oIndex + 1] == "u" {
            return syllable.index(syllable.startIndex, offsetBy: oIndex)
        }

        // Rule 4: For all other cases, the last vowel gets the tone
        for i in (0..<chars.count).reversed() {
            if vowels.contains(String(chars[i])) {
                return syllable.index(syllable.startIndex, offsetBy: i)
            }
        }

        return nil
    }
}
