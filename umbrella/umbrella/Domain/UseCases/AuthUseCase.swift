//
//  AuthUseCase.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation
import AuthenticationServices

/// Use case for authentication operations
/// Orchestrates authentication business logic and coordinates between repository and presentation layers
final class AuthUseCase {
    private let repository: AuthRepository
    private let keychainService: KeychainService

    init(repository: AuthRepository, keychainService: KeychainService) {
        self.repository = repository
        self.keychainService = keychainService
    }

    /// Sign up a new user
    func signUp(email: String, password: String, displayName: String) async throws -> AppUser {
        let user = try await repository.signUp(email: email, password: password, displayName: displayName)

        // Store user session (Phase 1: just mark as authenticated)
        try keychainService.store(key: "currentUserId", value: user.id.uuidString)
        try keychainService.store(key: "isAuthenticated", value: "true")

        return user
    }

    /// Sign in an existing user
    func signIn(email: String, password: String) async throws -> AppUser {
        let user = try await repository.signIn(email: email, password: password)

        // Store user session
        try keychainService.store(key: "currentUserId", value: user.id.uuidString)
        try keychainService.store(key: "isAuthenticated", value: "true")

        return user
    }

    /// Sign in with Apple ID
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> AppUser {
        let user = try await repository.signInWithApple(credential: credential)

        // Store user session
        try keychainService.store(key: "currentUserId", value: user.id.uuidString)
        try keychainService.store(key: "isAuthenticated", value: "true")

        return user
    }

    /// Get current authenticated user
    func getCurrentUser() async throws -> AppUser? {
        // Check if user is authenticated
        guard let isAuthenticated = try keychainService.retrieve(key: "isAuthenticated"),
              isAuthenticated == "true",
              let userIdString = try keychainService.retrieve(key: "currentUserId"),
              let _ = UUID(uuidString: userIdString) else {
            return nil
        }

        return try await repository.getCurrentUser()
    }

    /// Check if user is currently authenticated
    func isAuthenticated() -> Bool {
        do {
            guard let isAuthenticated = try keychainService.retrieve(key: "isAuthenticated") else {
                return false
            }
            return isAuthenticated == "true"
        } catch {
            return false
        }
    }

    /// Sign out current user
    func signOut() async throws {
        try await repository.signOut()

        // Clear session data
        try keychainService.delete(key: "currentUserId")
        try keychainService.delete(key: "isAuthenticated")
        try keychainService.delete(key: "authToken") // For future API token storage
    }

    /// Update user profile
    func updateUser(_ user: AppUser) async throws -> AppUser {
        try await repository.updateUser(user)
    }

    /// Delete user account
    func deleteUser(_ userId: UUID) async throws {
        try await repository.deleteUser(userId)

        // Clear session data
        try keychainService.delete(key: "currentUserId")
        try keychainService.delete(key: "isAuthenticated")
        try keychainService.delete(key: "authToken")
    }
}
