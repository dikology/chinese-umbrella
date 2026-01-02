//
//  DictionaryService.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation

/// Protocol for dictionary lookup operations
protocol DictionaryService {
    /// Look up a word in the dictionary
    func lookup(word: String) -> DictionaryEntry?

    /// Preload dictionary data
    func preloadDictionary() throws

    /// Check if dictionary is loaded
    var isLoaded: Bool { get }
}

/// CEDICT (Chinese-English Dictionary) implementation
class CEDICTDictionaryService: DictionaryService {
    private var dictionary: [String: DictionaryEntry] = [:]
    private var traditionalToSimplified: [String: String] = [:]
    private(set) var isLoaded = false

    /// Look up a word in the CEDICT dictionary
    func lookup(word: String) -> DictionaryEntry? {
        // Try simplified first
        if let entry = dictionary[word] {
            return entry
        }

        // Try traditional if simplified lookup failed
        if let simplified = traditionalToSimplified[word] {
            return dictionary[simplified]
        }

        return nil
    }

    /// Preload CEDICT data from bundled file
    func preloadDictionary() throws {
        guard let url = Bundle.main.url(forResource: "cedict_ts", withExtension: "u8") else {
            throw DictionaryServiceError.fileNotFound
        }

        let content = try String(contentsOf: url, encoding: .utf8)
        try parseCEDICT(content)
        isLoaded = true
    }

    /// Parse CEDICT formatted text
    private func parseCEDICT(_ content: String) throws {
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            // Skip comments and empty lines
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty && !trimmed.hasPrefix("#") else { continue }

            // CEDICT format: Traditional Simplified [pinyin] /definition1/definition2/
            let components = trimmed.components(separatedBy: " ")

            guard components.count >= 3 else { continue }

            let traditional = components[0]
            let simplified = components[1]

            // Find pinyin (between brackets)
            guard let pinyinStart = trimmed.range(of: "["),
                  let pinyinEnd = trimmed.range(of: "]", range: pinyinStart.upperBound..<trimmed.endIndex) else {
                continue
            }

            let pinyin = String(trimmed[pinyinStart.upperBound..<pinyinEnd.lowerBound])
                .trimmingCharacters(in: .whitespaces)

            // Find definitions (between slashes)
            guard let definitionStart = trimmed.range(of: "/", range: pinyinEnd.upperBound..<trimmed.endIndex),
                  let definitionEnd = trimmed.range(of: "/", options: .backwards, range: definitionStart.upperBound..<trimmed.endIndex) else {
                continue
            }

            let definitionsText = String(trimmed[definitionStart.upperBound..<definitionEnd.lowerBound])
            let definitions = definitionsText.components(separatedBy: "/").filter { !$0.isEmpty }

            guard !definitions.isEmpty else { continue }

            // Create dictionary entry
            let entry = DictionaryEntry(
                simplified: simplified,
                traditional: traditional,
                pinyin: pinyin,
                englishDefinition: definitions.joined(separator: "; "),
                frequency: estimateHSKLevel(simplified),
                examples: [] // Examples would be in a separate file
            )

            // Store by simplified form
            dictionary[simplified] = entry

            // Map traditional to simplified for lookups
            if traditional != simplified {
                traditionalToSimplified[traditional] = simplified
            }
        }
    }

    /// Estimate HSK level based on word (simplified approach)
    private func estimateHSKLevel(_ word: String) -> HSKLevel? {
        // This is a placeholder implementation
        // In a real app, this would use pre-computed HSK frequency data

        // For now, assign levels based on character count and common patterns
        switch word.count {
        case 1:
            return .hsk1 // Most single characters are HSK 1-2
        case 2:
            return .hsk2 // Common two-character words
        case 3:
            return .hsk3 // Longer words tend to be higher levels
        default:
            return .hsk4 // Very long words are typically advanced
        }
    }
}

/// Errors that can occur during dictionary operations
enum DictionaryServiceError: LocalizedError {
    case fileNotFound
    case parsingError
    case loadError
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Dictionary file not found"
        case .parsingError:
            return "Error parsing dictionary data"
        case .loadError:
            return "Failed to load dictionary"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
