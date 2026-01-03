//
//  LoadingView.swift
//  umbrella
//
//  Created by Design System Team
//

import SwiftUI

/// Full-screen loading view displayed during app initialization
/// Shows while dictionary is preloaded and anonymous user is created
struct LoadingView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            // Background
            colors.background
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // App Logo/Icon Placeholder
                // TODO: Add app icon when available
                Circle()
                    .fill(colors.primary.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "book.fill")
                            .font(.system(size: 32))
                            .foregroundColor(colors.primary)
                    )

                // Loading Content
                VStack(spacing: 16) {
                    // Loading Spinner
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: colors.primary))

                    // Loading Text
                    VStack(spacing: 8) {
                        Text("Initializing Chinese Umbrella")
                            .font(.subheading)
                            .foregroundColor(colors.textPrimary)

                        Text("Preparing dictionary and content...")
                            .font(.bodySecondary)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                }

                // Loading Steps (Optional - can be enhanced later)
                VStack(spacing: 12) {
                    LoadingStepView(
                        title: "Loading dictionary",
                        isCompleted: false,
                        colors: colors
                    )
                    LoadingStepView(
                        title: "Setting up user",
                        isCompleted: false,
                        colors: colors
                    )
                }
                .padding(.horizontal, 32)
            }
        }
    }
}

// MARK: - Loading Step Component

/// Individual loading step indicator
private struct LoadingStepView: View {
    let title: String
    let isCompleted: Bool
    let colors: AdaptiveColors

    var body: some View {
        HStack(spacing: 12) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(isCompleted ? colors.success.opacity(0.1) : colors.surface)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(isCompleted ? colors.success : colors.textSecondary.opacity(0.3), lineWidth: 1)
                    )

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(colors.success)
                } else {
                    Circle()
                        .fill(colors.primary)
                        .frame(width: 8, height: 8)
                        .opacity(0.5)
                }
            }

            // Step Title
            Text(title)
                .font(.bodySecondary)
                .foregroundColor(isCompleted ? colors.textPrimary : colors.textSecondary)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview("Loading View - Light") {
    LoadingView()
        .preferredColorScheme(.light)
}

#Preview("Loading View - Dark") {
    LoadingView()
        .preferredColorScheme(.dark)
}

#Preview("Loading Steps") {
    VStack(spacing: 12) {
        LoadingStepView(
            title: "Loading dictionary",
            isCompleted: true,
            colors: AdaptiveColors(colorScheme: .light)
        )
        LoadingStepView(
            title: "Setting up user",
            isCompleted: false,
            colors: AdaptiveColors(colorScheme: .light)
        )
    }
    .padding()
    .background(Color.adaptiveBackground(.light))
}
