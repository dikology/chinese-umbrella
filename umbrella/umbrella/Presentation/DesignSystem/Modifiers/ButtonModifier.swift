//
//  ButtonModifier.swift
//  umbrella
//
//  Created by Design System Team
//

import SwiftUI

/// Modifier for primary button styling
struct PrimaryButtonModifier: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, .spacingL)
            .padding(.vertical, .spacingM)
            .background(isEnabled ? colors.primary : colors.primary.opacity(0.4))
            .foregroundColor(.white)
            .font(.caption)
            .cornerRadius(.radiusM)
            .shadow(color: colors.shadow, radius: 2, x: 0, y: 1)
    }
}

/// Modifier for secondary button styling
struct SecondaryButtonModifier: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, .spacingL)
            .padding(.vertical, .spacingM)
            .background(Color.clear)
            .foregroundColor(colors.textPrimary)
            .font(.caption)
            .cornerRadius(.radiusM)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusM)
                    .stroke(colors.divider, lineWidth: 1)
            )
    }
}

/// Modifier for destructive button styling
struct DestructiveButtonModifier: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, .spacingL)
            .padding(.vertical, .spacingM)
            .background(isEnabled ? colors.error : colors.error.opacity(0.4))
            .foregroundColor(.white)
            .font(.caption)
            .cornerRadius(.radiusM)
            .shadow(color: colors.shadow, radius: 2, x: 0, y: 1)
    }
}

extension View {
    /// Apply primary button styling
    func primaryButtonStyle() -> some View {
        modifier(PrimaryButtonModifier())
    }

    /// Apply secondary button styling
    func secondaryButtonStyle() -> some View {
        modifier(SecondaryButtonModifier())
    }

    /// Apply destructive button styling
    func destructiveButtonStyle() -> some View {
        modifier(DestructiveButtonModifier())
    }
}
