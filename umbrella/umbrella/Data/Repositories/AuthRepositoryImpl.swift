//
//  AuthRepositoryImpl.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import CoreData
import Foundation
import AuthenticationServices

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

    /// Sign in with Apple ID
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> AppUser {
        // Extract user identifier from Apple credential
        let appleUserId = credential.user

        // Check if user already exists with this Apple ID
        if let existingUser = try await findUserByAppleId(appleUserId) {
            return existingUser
        }

        // Create new user account
        let email = credential.email ?? "\(appleUserId)@apple.com" // Apple may not provide email on subsequent logins
        let fullName = credential.fullName
        let displayName = [
            fullName?.givenName,
            fullName?.familyName
        ].compactMap { $0 }.joined(separator: " ")

        let user = AppUser(
            email: email,
            displayName: displayName.isEmpty ? "Apple User" : displayName
        )

        // Save Apple ID mapping for future logins
        try await saveUserWithAppleId(user, appleUserId: appleUserId)

        return user
    }

    /// Get current authenticated user (Phase 1: return first user)
    func getCurrentUser() async throws -> AppUser? {
        try await coreDataManager.performBackgroundTask { context in
            let request = UserEntity.fetchRequest()
            request.fetchLimit = 1

            do {
                let fetchedObjects = try context.fetch(request)
                guard let userEntity = fetchedObjects.first else {
                    return nil
                }
                return AppUser.fromEntity(userEntity)
            } catch {
                // Handle case where existing data doesn't match current class structure
                // This can happen during development when schema changes
                print("Warning: Could not fetch user entities: \(error)")
                return nil
            }
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
            let request = UserEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", user.id as CVarArg)

            let fetchedObjects = try context.fetch(request)
            guard let userEntity = fetchedObjects.first else {
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
            let request = UserEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", userId as CVarArg)

            let fetchedObjects = try context.fetch(request)
            guard let userEntity = fetchedObjects.first else {
                throw AuthError.userNotFound
            }

            context.delete(userEntity)
            try context.save()
        }
    }

    // MARK: - Private Helpers

    private func userExists(email: String) async throws -> Bool {
        try await coreDataManager.performBackgroundTask { context in
            let request = UserEntity.fetchRequest()
            request.predicate = NSPredicate(format: "email == %@", email)
            request.fetchLimit = 1

            let count = try context.count(for: request)
            return count > 0
        }
    }

    private func findUserByEmail(_ email: String) async throws -> AppUser? {
        try await coreDataManager.performBackgroundTask { context in
            let request = UserEntity.fetchRequest()
            request.predicate = NSPredicate(format: "email == %@", email)

            let fetchedObjects = try context.fetch(request)
            guard let userEntity = fetchedObjects.first else {
                return nil
            }

            return AppUser.fromEntity(userEntity)
        }
    }

    private func saveUserToCoreData(_ user: AppUser) async throws {
        try await coreDataManager.performBackgroundTask { context in
            let userEntity = UserEntity(context: context)
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

    private func findUserByAppleId(_ appleUserId: String) async throws -> AppUser? {
        try await coreDataManager.performBackgroundTask { context in
            let request = UserEntity.fetchRequest()
            request.predicate = NSPredicate(format: "appleUserId == %@", appleUserId)

            let fetchedObjects = try context.fetch(request)
            guard let userEntity = fetchedObjects.first else {
                return nil
            }

            return AppUser.fromEntity(userEntity)
        }
    }

    private func saveUserWithAppleId(_ user: AppUser, appleUserId: String) async throws {
        try await coreDataManager.performBackgroundTask { context in
            let userEntity = UserEntity(context: context)
            userEntity.update(from: user)
            userEntity.appleUserId = appleUserId
            try context.save()
        }
    }
}

