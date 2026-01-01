//
//  AuthViewModel.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation
import AuthenticationServices

@Observable
final class AuthViewModel: AuthViewModelProtocol {
    // MARK: - Published Properties
    var isAuthenticated = false
    var currentUser: AppUser?
    var isLoading = false
    var errorMessage: String?

    // MARK: - Form Properties
    var email = ""
    var password = ""
    var displayName = ""
    var isSignUpMode = false

    // MARK: - Private Properties
    private let authUseCase: AuthUseCase

    init(authUseCase: AuthUseCase) {
        self.authUseCase = authUseCase
        checkAuthenticationStatus()
    }

    // MARK: - Public Methods

    func signUp() async {
        guard validateForm() else { return }

        await performAuthAction {
            let user = try await self.authUseCase.signUp(
                email: self.email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: self.password,
                displayName: self.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.clearForm()
            }
        }
    }

    func signIn() async {
        guard validateSignInForm() else { return }

        await performAuthAction {
            let user = try await self.authUseCase.signIn(
                email: self.email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: self.password
            )
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.clearForm()
            }
        }
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        await performAuthAction {
            let user = try await self.authUseCase.signInWithApple(credential: credential)
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
        }
    }

    func logout() async {
        await performAuthAction {
            try await self.authUseCase.signOut()
            await MainActor.run {
                self.isAuthenticated = false
                self.currentUser = nil
                self.clearForm()
            }
        }
    }

    func toggleAuthMode() {
        isSignUpMode.toggle()
        errorMessage = nil
        clearForm()
    }

    // MARK: - Private Methods

    private func checkAuthenticationStatus() {
        Task {
            do {
                if let user = try await self.authUseCase.getCurrentUser() {
                    await MainActor.run {
                        self.currentUser = user
                        self.isAuthenticated = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.isAuthenticated = false
                    self.currentUser = nil
                }
            }
        }
    }

    private func performAuthAction(_ action: @escaping () async throws -> Void) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            try await action()
        } catch let authError as AuthError {
            await MainActor.run {
                errorMessage = authError.errorDescription ?? "An authentication error occurred"
            }
        } catch {
            await MainActor.run {
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    private func validateForm() -> Bool {
        errorMessage = nil

        guard !email.isEmpty else {
            errorMessage = "Email is required"
            return false
        }

        guard email.contains("@") else {
            errorMessage = "Please enter a valid email address"
            return false
        }

        guard !password.isEmpty else {
            errorMessage = "Password is required"
            return false
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return false
        }

        guard !displayName.isEmpty else {
            errorMessage = "Display name is required"
            return false
        }

        return true
    }

    private func validateSignInForm() -> Bool {
        errorMessage = nil

        guard !email.isEmpty else {
            errorMessage = "Email is required"
            return false
        }

        guard email.contains("@") else {
            errorMessage = "Please enter a valid email address"
            return false
        }

        guard !password.isEmpty else {
            errorMessage = "Password is required"
            return false
        }

        return true
    }

    private func clearForm() {
        email = ""
        password = ""
        displayName = ""
        errorMessage = nil
    }
}
