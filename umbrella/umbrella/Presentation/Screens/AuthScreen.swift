//
//  AuthScreen.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import SwiftUI
import AuthenticationServices

struct AuthScreen: View {
    @State private var viewModel: AuthViewModel
    @State private var showAppleSignIn = false

    init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "umbrella.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Chinese Umbrella")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text("Your Chinese reading companion")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)

                    // Auth Form Card
                    VStack(spacing: 20) {
                        // Mode Toggle
                        Picker("Mode", selection: $viewModel.isSignUpMode) {
                            Text("Sign In").tag(false)
                            Text("Sign Up").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        // Email Field
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Email")
                                .font(.headline)
                                .foregroundColor(.primary)

                            TextField("Enter your email", text: $viewModel.email)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }

                        // Password Field
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Password")
                                .font(.headline)
                                .foregroundColor(.primary)

                            SecureField("Enter your password", text: $viewModel.password)
                                .textFieldStyle(.roundedBorder)
                        }

                        // Display Name Field (Sign Up only)
                        if viewModel.isSignUpMode {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Display Name")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                TextField("Enter your display name", text: $viewModel.displayName)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.words)
                            }
                        }

                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Auth Button
                        Button(action: {
                            Task {
                                if viewModel.isSignUpMode {
                                    await viewModel.signUp()
                                } else {
                                    await viewModel.signIn()
                                }
                            }
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(viewModel.isSignUpMode ? "Sign Up" : "Sign In")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .disabled(viewModel.isLoading)
                        .padding(.horizontal)

                        // Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.3))
                            Text("or")
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.3))
                        }
                        .padding(.horizontal)

                        // Apple Sign In Button
                        SignInWithAppleButton(
                            .signIn,
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                Task {
                                    await handleAppleSignIn(result: result)
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .padding(30)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(radius: 5)
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .loadingOverlay(isPresented: viewModel.isLoading, message: "Signing in...")
        }
    }

    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                await viewModel.signInWithApple(credential: appleIDCredential)
            }
        case .failure(let error):
            await MainActor.run {
                viewModel.errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    AuthScreen(viewModel: AuthViewModel(authUseCase: AuthUseCase(repository: AuthRepositoryImpl(), keychainService: KeychainService())))
}
