//
//  CardModifier.swift
//  umbrella
//
//  Created by Design System Team
//

import SwiftUI

/// Modifier for consistent card styling across the app
struct CardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    func body(content: Content) -> some View {
        content
            .background(colors.surface)
            .cornerRadius(.radiusL)
            .shadow(color: colors.shadow, radius: 2, x: 0, y: 1)
    }
}

/// Modifier for elevated card styling (more pronounced shadow)
struct ElevatedCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    func body(content: Content) -> some View {
        content
            .background(colors.surface)
            .cornerRadius(.radiusL)
            .shadow(color: colors.shadow, radius: 4, x: 0, y: 2)
    }
}

extension View {
    /// Apply standard card styling
    func cardStyle() -> some View {
        modifier(CardModifier())
    }

    /// Apply elevated card styling with stronger shadow
    func elevatedCardStyle() -> some View {
        modifier(ElevatedCardModifier())
    }
}
