//
//  User.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation

/// Represents a user of the Chinese reading app
public struct AppUser: Identifiable, Codable, Hashable {
    public let id: UUID
    public let email: String
    public let displayName: String
    public var hskLevel: Int // 1-6
    public var vocabularyMasteryPct: Double // 0.0 - 100.0
    public let createdAt: Date
    public var updatedAt: Date

    // Optional password hash for local auth (Phase 1)
    public var passwordHash: String?

    init(
        id: UUID = UUID(),
        email: String,
        displayName: String,
        hskLevel: Int = 1,
        vocabularyMasteryPct: Double = 0.0,
        passwordHash: String? = nil
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.hskLevel = hskLevel
        self.vocabularyMasteryPct = vocabularyMasteryPct
        self.passwordHash = passwordHash
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Validation

    var isValid: Bool {
        !email.isEmpty &&
        email.contains("@") &&
        !displayName.isEmpty &&
        (1...6).contains(hskLevel) &&
        (0.0...100.0).contains(vocabularyMasteryPct)
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: AppUser, rhs: AppUser) -> Bool {
        lhs.id == rhs.id
    }
}
