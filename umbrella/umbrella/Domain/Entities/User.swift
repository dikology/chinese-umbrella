//
//  User.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation

/// Represents a user of the Chinese reading app
struct AppUser: Identifiable, Codable, Hashable {
    let id: UUID
    let email: String
    let displayName: String
    var hskLevel: Int // 1-6
    var vocabularyMasteryPct: Double // 0.0 - 100.0
    let createdAt: Date
    var updatedAt: Date

    // Optional password hash for local auth (Phase 1)
    var passwordHash: String?

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

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AppUser, rhs: AppUser) -> Bool {
        lhs.id == rhs.id
    }
}
