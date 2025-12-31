//
//  AppUserEntity+Extensions.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import CoreData
import Foundation

// MARK: - Conversion Extensions

extension AppUser {
    /// Create AppUser from Core Data entity
    static func fromEntity(_ entity: AppUserEntity) -> AppUser {
        AppUser(
            id: entity.id ?? UUID(),
            email: entity.email ?? "",
            displayName: entity.displayName ?? "",
            hskLevel: Int(entity.hskLevel),
            vocabularyMasteryPct: entity.vocabularyMasteryPct,
            passwordHash: entity.passwordHash
        )
    }
}

extension AppUserEntity {
    /// Update entity from AppUser model
    func update(from user: AppUser) {
        id = user.id
        email = user.email
        displayName = user.displayName
        hskLevel = Int16(user.hskLevel)
        vocabularyMasteryPct = user.vocabularyMasteryPct
        passwordHash = user.passwordHash
        createdAt = user.createdAt
        updatedAt = user.updatedAt
    }
}
