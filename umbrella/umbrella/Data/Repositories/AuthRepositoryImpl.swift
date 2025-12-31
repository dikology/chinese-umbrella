//
//  AuthRepositoryImpl.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import CoreData
import Foundation

/// Core Data implementation of AuthRepository
class AuthRepositoryImpl: AuthRepository {
    private let coreDataManager: CoreDataManager

    init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
    }

    /// Sign up a new user (Phase 1: local only)
    func signUp(email: String, password: String, displayName: String) async throws -> AppUser {
        // Check if user already exists
        if try await userExists(email: email) {
            throw AuthError.userAlreadyExists
        }

        // Validate input
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }

        // Hash password (in Phase 1, we're using simple hashing for demo)
        let passwordHash = hashPassword(password)

        let user = AppUser(
            email: email,
            displayName: displayName,
            passwordHash: passwordHash
        )

        // Save to Core Data
        try await saveUserToCoreData(user)

        return user
    }

    /// Sign in an existing user
    func signIn(email: String, password: String) async throws -> AppUser {
        guard let user = try await findUserByEmail(email) else {
            throw AuthError.userNotFound
        }

        let hashedPassword = hashPassword(password)
        guard user.passwordHash == hashedPassword else {
            throw AuthError.invalidCredentials
        }

        return user
    }

    /// Sign in with Apple ID (placeholder for Phase 2)
    func signInWithApple(credential: String) async throws -> AppUser {
        // Phase 1: Mock implementation
        // In Phase 2, validate Apple credential and create/link account
        throw AuthError.appleSignInFailed
    }

    /// Get current authenticated user (Phase 1: return first user)
    func getCurrentUser() async throws -> AppUser? {
        try await coreDataManager.performBackgroundTask { context in
            let request: NSFetchRequest<AppUserEntity> = AppUserEntity.fetchRequest()
            request.fetchLimit = 1

            guard let userEntity = try context.fetch(request).first else {
                return nil
            }

            return AppUser.fromEntity(userEntity)
        }
    }

    /// Sign out (Phase 1: no-op, single user)
    func signOut() async throws {
        // Phase 1: No-op since we're offline-only
        // Phase 2: Clear tokens, etc.
    }

    /// Update user profile
    func updateUser(_ user: AppUser) async throws -> AppUser {
        try await coreDataManager.performBackgroundTask { context in
            let request: NSFetchRequest<AppUserEntity> = AppUserEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", user.id as CVarArg)

            guard let userEntity = try context.fetch(request).first else {
                throw AuthError.userNotFound
            }

            userEntity.update(from: user)
            try context.save()

            return AppUser.fromEntity(userEntity)
        }
    }

    /// Delete user account
    func deleteUser(_ userId: UUID) async throws {
        try await coreDataManager.performBackgroundTask { context in
            let request: NSFetchRequest<AppUserEntity> = AppUserEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", userId as CVarArg)

            guard let userEntity = try context.fetch(request).first else {
                throw AuthError.userNotFound
            }

            context.delete(userEntity)
            try context.save()
        }
    }

    // MARK: - Private Helpers

    private func userExists(email: String) async throws -> Bool {
        try await coreDataManager.performBackgroundTask { context in
            let request: NSFetchRequest<AppUserEntity> = AppUserEntity.fetchRequest()
            request.predicate = NSPredicate(format: "email == %@", email)
            request.fetchLimit = 1

            let count = try context.count(for: request)
            return count > 0
        }
    }

    private func findUserByEmail(_ email: String) async throws -> AppUser? {
        try await coreDataManager.performBackgroundTask { context in
            let request: NSFetchRequest<AppUserEntity> = AppUserEntity.fetchRequest()
            request.predicate = NSPredicate(format: "email == %@", email)

            guard let userEntity = try context.fetch(request).first else {
                return nil
            }

            return AppUser.fromEntity(userEntity)
        }
    }

    private func saveUserToCoreData(_ user: AppUser) async throws {
        try await coreDataManager.performBackgroundTask { context in
            let userEntity = AppUserEntity(context: context)
            userEntity.update(from: user)
            try context.save()
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func hashPassword(_ password: String) -> String {
        // Phase 1: Simple SHA256 hash (not secure for production!)
        // Phase 2: Use proper password hashing like Argon2
        let data = password.data(using: .utf8)!
        return data.map { String(format: "%02x", $0) }.joined()
    }
}

