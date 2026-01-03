import Foundation
import CoreData

final class AnonymousUserService {
    private let keychainService: KeychainService
    private let authRepository: AuthRepository
    private let coreDataManager: CoreDataManager

    private let anonymousUserIdKey = "anonymousUserId"

    init(keychainService: KeychainService, authRepository: AuthRepository, coreDataManager: CoreDataManager = .shared) {
        self.keychainService = keychainService
        self.authRepository = authRepository
        self.coreDataManager = coreDataManager
    }
    
    /// Get or create the anonymous user for this device
    func getOrCreateAnonymousUser() async throws -> AppUser {
        // Check if we already have an anonymous user ID
        if let existingId = try? keychainService.retrieve(key: anonymousUserIdKey),
           let userId = UUID(uuidString: existingId),
           let user = try? await authRepository.getUserById(userId) {
            return user
        }
        
        // Create new anonymous user
        let anonymousUser = AppUser(
            email: "anonymous@local.device",
            displayName: "Local User",
            hskLevel: 1,
            vocabularyMasteryPct: 0.0
        )
        
        // Save to Core Data
        let savedUser = try await saveAnonymousUser(anonymousUser)
        
        // Store ID for future launches
        try keychainService.store(key: anonymousUserIdKey, value: savedUser.id.uuidString)
        
        return savedUser
    }
    
    private func saveAnonymousUser(_ user: AppUser) async throws -> AppUser {
        // Direct Core Data save bypassing auth repository's validation
        // (since anonymous user doesn't have real email/password)
        let context = coreDataManager.backgroundContext

        return try await context.perform {
            let userEntity = UserEntity(context: context)
            userEntity.id = user.id
            userEntity.email = user.email
            userEntity.displayName = user.displayName
            userEntity.hskLevel = Int16(user.hskLevel)
            userEntity.vocabularyMasteryPct = user.vocabularyMasteryPct
            userEntity.createdAt = user.createdAt
            userEntity.updatedAt = user.updatedAt

            try context.save()
            return user
        }
    }
}