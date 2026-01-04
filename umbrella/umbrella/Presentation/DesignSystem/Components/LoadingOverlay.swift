//
//  LoadingOverlay.swift
//  umbrella
//
//  Created by Design System Team
//

import SwiftUI

/// A reusable overlay component for displaying loading states over existing content.
/// Provides a non-blocking loading indicator with customizable message.
struct LoadingOverlay: View {
    @Environment(\.colorScheme) private var colorScheme

    let message: String

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            // Semi-transparent background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            // Loading content container
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(colors.primary)

                Text(message)
                    .captionStyle()
            }
            .padding(24)
            .background(colors.surface)
            .cornerRadius(12)
            .shadow(color: colors.shadow, radius: 8, x: 0, y: 4)
        }
        .ignoresSafeArea()
    }
}

// MARK: - View Extension for Easy Usage

extension View {
    /// Adds a loading overlay when the condition is true
    /// - Parameters:
    ///   - isPresented: Whether to show the loading overlay
    ///   - message: The message to display below the loading indicator
    /// - Returns: The view with optional loading overlay
    func loadingOverlay(isPresented: Bool, message: String = "Loading...") -> some View {
        self.overlay {
            if isPresented {
                LoadingOverlay(message: message)
            }
        }
    }
}

// MARK: - Preview

#Preview("Loading Overlay - Light") {
    ZStack {
        Color.blue
            .ignoresSafeArea()
        Text("Content behind overlay")
            .foregroundColor(.white)
            .font(.title)
    }
    .loadingOverlay(isPresented: true, message: "Loading books...")
    .preferredColorScheme(.light)
}

#Preview("Loading Overlay - Dark") {
    ZStack {
        Color.blue
            .ignoresSafeArea()
        Text("Content behind overlay")
            .foregroundColor(.white)
            .font(.title)
    }
    .loadingOverlay(isPresented: true, message: "Loading books...")
    .preferredColorScheme(.dark)
}

#Preview("No Overlay") {
    ZStack {
        Color.blue
            .ignoresSafeArea()
        Text("Content without overlay")
            .foregroundColor(.white)
            .font(.title)
    }
    .loadingOverlay(isPresented: false, message: "Loading books...")
}
