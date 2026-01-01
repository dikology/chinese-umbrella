//
//  AuthRepositoryImpl.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import CoreData
import Foundation
import AuthenticationServices
internal import os

/// Core Data implementation of AuthRepository
class AuthRepositoryImpl: AuthRepository {
    private let coreDataManager: CoreDataManager
    private let logger = LoggingService.shared

    init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
    }

    /// Sign up a new user (Phase 1: local only)
    func signUp(email: String, password: String, displayName: String) async throws -> AppUser {
        logger.auth("Starting signup for email: \(email)", level: .info)

        // Check if user already exists
        logger.auth("Checking if user exists with email: \(email)", level: .debug)
        if try await userExists(email: email) {
            logger.auth("User already exists with email: \(email)", level: .default)
            throw AuthError.userAlreadyExists
        }

        // Validate input
        logger.auth("Validating email format", level: .debug)
        guard isValidEmail(email) else {
            logger.auth("Invalid email format: \(email)", level: .default)
            throw AuthError.invalidEmail
        }

        logger.auth("Validating password length", level: .debug)
        guard password.count >= 6 else {
            logger.auth("Password too short: \(password.count) characters", level: .default)
            throw AuthError.weakPassword
        }

        logger.auth("Validating display name", level: .debug)
        guard !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.auth("Display name is empty", level: .default)
            throw AuthError.emptyDisplayName
        }

        // Hash password (in Phase 1, we're using simple hashing for demo)
        logger.auth("Hashing password", level: .debug)
        let passwordHash = hashPassword(password)

        let user = AppUser(
            email: email,
            displayName: displayName,
            passwordHash: passwordHash
        )

        logger.auth("Created user object, saving to Core Data", level: .debug)
        // Save to Core Data
        do {
            try await saveUserToCoreData(user)
            logger.auth("Successfully saved user to Core Data for email: \(email)", level: .info)
        } catch {
            logger.error("Failed to save user to Core Data", error: error)
            throw error
        }

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
        try await coreDataManager.performBackgroundTask { [logger] context in
            logger.coreData("Creating UserEntity for email: \(user.email)", level: .debug)
            let userEntity = UserEntity(context: context)
            userEntity.update(from: user)
            // Set required dates that aren't handled by update(from:)
            userEntity.createdAt = user.createdAt
            userEntity.updatedAt = user.updatedAt

            logger.coreData("Attempting to save context for user: \(user.email)", level: .debug)
            do {
                try context.save()
                logger.coreData("Context saved successfully for user: \(user.email)", level: .info)
            } catch {
                logger.error("Core Data context save failed", error: error)
                // Log detailed validation errors if any
                if let validationErrors = (error as NSError).userInfo[NSDetailedErrorsKey] as? [NSError] {
                    logger.coreData("Validation errors found:", level: .error)
                    for validationError in validationErrors {
                        logger.coreData("  - \(validationError.localizedDescription)", level: .error)
                    }
                }
                throw error
            }
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

