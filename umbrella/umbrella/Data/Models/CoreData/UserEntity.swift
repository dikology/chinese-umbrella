//
//  UserEntity.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import CoreData
import Foundation

/// Core Data entity for User
@objc(UserEntity)
public class UserEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var email: String?
    @NSManaged public var displayName: String?
    @NSManaged public var passwordHash: String?
    @NSManaged public var appleUserId: String?
    @NSManaged public var hskLevel: Int16
    @NSManaged public var vocabularyMasteryPct: Double
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date

    // Relationships
    @NSManaged public var books: Set<CDBook>?
    @NSManaged public var markedWords: Set<CDMarkedWord>?
    @NSManaged public var userPreferences: UserPreferences?
}

extension UserEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        return NSFetchRequest<UserEntity>(entityName: "User")
    }

    // Conversion to domain model
    public func toDomain() -> AppUser {
        AppUser(
            id: id ?? UUID(),
            email: email ?? "",
            displayName: displayName ?? "",
            hskLevel: Int(hskLevel),
            vocabularyMasteryPct: vocabularyMasteryPct,
            passwordHash: passwordHash
        )
    }
}

// MARK: - Conversion Extensions

extension AppUser {
    /// Create AppUser from Core Data entity
    static func fromEntity(_ entity: UserEntity) -> AppUser {
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

extension UserEntity {
    /// Update entity from AppUser model
    public func update(from user: AppUser) {
        id = user.id
        email = user.email
        displayName = user.displayName
        hskLevel = Int16(user.hskLevel)
        vocabularyMasteryPct = user.vocabularyMasteryPct
        passwordHash = user.passwordHash
        // Note: createdAt and updatedAt are set during entity creation
        // and should not be updated from the domain model
    }
}
