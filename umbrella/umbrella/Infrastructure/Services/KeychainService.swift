//
//  KeychainService.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation
import Security

/// Service for secure storage of sensitive data using iOS Keychain
final class KeychainService {
    enum KeychainError: LocalizedError {
        case itemNotFound
        case duplicateItem
        case invalidItemFormat
        case unexpectedStatus(OSStatus)

        var errorDescription: String? {
            switch self {
            case .itemNotFound:
                return "Item not found in keychain"
            case .duplicateItem:
                return "Item already exists in keychain"
            case .invalidItemFormat:
                return "Invalid item format"
            case .unexpectedStatus(let status):
                return "Keychain operation failed with status: \(status)"
            }
        }
    }

    private let service: String

    init(service: String = "com.chineseumbrella.app") {
        self.service = service
    }

    /// Store a string value securely in the keychain
    func store(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidItemFormat
        }

        // Delete existing item if it exists
        try? delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            if status == errSecDuplicateItem {
                throw KeychainError.duplicateItem
            }
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Retrieve a string value from the keychain
    func retrieve(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.unexpectedStatus(status)
        }

        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidItemFormat
        }

        return string
    }

    /// Delete a value from the keychain
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Check if a key exists in the keychain
    func exists(key: String) -> Bool {
        do {
            return try retrieve(key: key) != nil
        } catch {
            return false
        }
    }
}
