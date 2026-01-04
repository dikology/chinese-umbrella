//
//  InputModifier.swift
//  umbrella
//
//  Created by Design System Team
//

import SwiftUI

/// Modifier for text field styling
struct TextFieldModifier: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    func body(content: Content) -> some View {
        content
            .padding(.spacingM)
            .background(colors.surface)
            .foregroundColor(colors.textPrimary)
            .font(.body)
            .cornerRadius(.radiusM)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusM)
                    .stroke(colors.divider, lineWidth: 1)
            )
    }
}

/// Modifier for search field styling
struct SearchFieldModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    func body(content: Content) -> some View {
        content
            .padding(.spacingM)
            .background(colors.searchBackground)
            .foregroundColor(colors.textPrimary)
            .font(.body)
            .cornerRadius(.radiusM)
    }
}

extension View {
    /// Apply text field styling
    func textFieldStyle() -> some View {
        modifier(TextFieldModifier())
    }

    /// Apply search field styling
    func searchFieldStyle() -> some View {
        modifier(SearchFieldModifier())
    }
}
