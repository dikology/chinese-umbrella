//
//  DictionaryEntry.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation

/// Represents a dictionary entry for a Chinese word/character
struct DictionaryEntry: Codable, Hashable {
    let simplified: String
    let traditional: String
    let pinyin: String
    let englishDefinition: String
    let frequency: HSKLevel?
    let examples: [String]

    init(
        simplified: String,
        traditional: String,
        pinyin: String,
        englishDefinition: String,
        frequency: HSKLevel? = nil,
        examples: [String] = []
    ) {
        self.simplified = simplified
        self.traditional = traditional
        self.pinyin = pinyin
        self.englishDefinition = englishDefinition
        self.frequency = frequency
        self.examples = examples
    }

    // MARK: - Computed Properties

    var primaryWord: String {
        simplified
    }

    var hasExamples: Bool {
        !examples.isEmpty
    }

    // MARK: - Validation

    var isValid: Bool {
        !simplified.isEmpty && !traditional.isEmpty && !pinyin.isEmpty && !englishDefinition.isEmpty
    }
}

/// HSK proficiency levels (1-6, plus beyond)
enum HSKLevel: Int, Codable, CaseIterable {
    case hsk1 = 1
    case hsk2 = 2
    case hsk3 = 3
    case hsk4 = 4
    case hsk5 = 5
    case hsk6 = 6

    var displayName: String {
        switch self {
        case .hsk1: return "HSK 1"
        case .hsk2: return "HSK 2"
        case .hsk3: return "HSK 3"
        case .hsk4: return "HSK 4"
        case .hsk5: return "HSK 5"
        case .hsk6: return "HSK 6"
        }
    }

    var description: String {
        switch self {
        case .hsk1: return "Beginner (150 words)"
        case .hsk2: return "Elementary (300 words)"
        case .hsk3: return "Intermediate (600 words)"
        case .hsk4: return "Upper Intermediate (1200 words)"
        case .hsk5: return "Advanced (2500 words)"
        case .hsk6: return "Proficient (5000+ words)"
        }
    }
}
