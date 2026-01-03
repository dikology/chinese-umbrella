//
//  AuthRepository.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation
import AuthenticationServices

/// Repository protocol for authentication operations
protocol AuthRepository {
    /// Sign up a new user
    func signUp(email: String, password: String, displayName: String) async throws -> AppUser

    /// Sign in an existing user
    func signIn(email: String, password: String) async throws -> AppUser

    /// Sign in with Apple ID
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> AppUser

    /// Get current authenticated user
    func getCurrentUser() async throws -> AppUser?

    /// Sign out current user
    func signOut() async throws

    /// Update user profile
    func updateUser(_ user: AppUser) async throws -> AppUser

    /// Delete user account
    func deleteUser(_ userId: UUID) async throws

    /// Get user by ID
    func getUserById(_ userId: UUID) async throws -> AppUser?
}

/// Errors that can occur during authentication
enum AuthError: LocalizedError {
    case invalidCredentials
    case userNotFound
    case userAlreadyExists
    case weakPassword
    case invalidEmail
    case emptyDisplayName
    case networkError
    case appleSignInFailed
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User not found"
        case .userAlreadyExists:
            return "An account with this email already exists"
        case .weakPassword:
            return "Password is too weak"
        case .invalidEmail:
            return "Invalid email address"
        case .emptyDisplayName:
            return "Display name is required"
        case .networkError:
            return "Network connection error"
        case .appleSignInFailed:
            return "Apple Sign-In failed"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
