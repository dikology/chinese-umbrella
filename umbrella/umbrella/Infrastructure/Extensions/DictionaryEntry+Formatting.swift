//
//  DictionaryEntry+Formatting.swift
//  umbrella
//
//  Created by Денис on 02.01.2026.
//

import Foundation

extension DictionaryEntry {
    /// Pinyin with Unicode tone marks instead of numbers
    var formattedPinyin: String {
        PinyinConverter.convertToneNumbersToMarks(pinyin)
    }

    /// Individual definitions split by semicolon and cleaned
    var splitDefinitions: [String] {
        englishDefinition
            .components(separatedBy: "; ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Whether this entry has multiple definitions
    var hasMultipleDefinitions: Bool {
        splitDefinitions.count > 1
    }

    /// Primary definition (first one)
    var primaryDefinition: String {
        splitDefinitions.first ?? englishDefinition
    }

    /// Secondary definitions (all except the first)
    var secondaryDefinitions: [String] {
        let defs = splitDefinitions
        return defs.count > 1 ? Array(defs.dropFirst()) : []
    }
}
