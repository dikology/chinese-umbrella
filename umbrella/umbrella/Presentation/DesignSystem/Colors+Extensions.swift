//
//  Colors+Extensions.swift
//  umbrella
//
//  Created by Design System Team
//

import SwiftUI

// MARK: - Design System Colors

extension Color {

    // MARK: - Light Mode Colors

    /// Primary page background - warm white with slight cream tint
    static let lightBackground = Color(red: 1.0, green: 0.988, blue: 0.976)

    /// Card, container background - elevated surfaces, modals
    static let lightSurface = Color(red: 1.0, green: 1.0, blue: 0.957)

    /// High contrast text for primary content
    static let lightTextPrimary = Color(red: 0.075, green: 0.259, blue: 0.322)

    /// Reduced emphasis text for labels and supporting content
    static let lightTextSecondary = Color(red: 0.388, green: 0.424, blue: 0.443)

    /// Subtle visual separation - 20% opacity
    static let lightDivider = Color(red: 0.369, green: 0.424, blue: 0.443).opacity(0.2)

    /// Primary action color
    static let lightPrimary = Color(red: 0.204, green: 0.502, blue: 0.553)

    /// Primary hover state
    static let lightPrimaryHover = Color(red: 0.192, green: 0.451, blue: 0.529)

    /// Primary active/pressed state
    static let lightPrimaryActive = Color(red: 0.165, green: 0.404, blue: 0.482)

    /// Success state color
    static let lightSuccess = Color(red: 0.133, green: 0.773, blue: 0.557)

    /// Error state color
    static let lightError = Color(red: 0.753, green: 0.082, blue: 0.184)

    /// Warning state color
    static let lightWarning = Color(red: 0.659, green: 0.506, blue: 0.294)

    /// Info state color
    static let lightInfo = Color(red: 0.388, green: 0.424, blue: 0.443)

    // MARK: - Dark Mode Colors

    /// Primary page background - deep charcoal
    static let darkBackground = Color(red: 0.122, green: 0.129, blue: 0.129)

    /// Card, container background - slightly elevated surface
    static let darkSurface = Color(red: 0.149, green: 0.157, blue: 0.157)

    /// High contrast white text for primary content
    static let darkTextPrimary = Color(red: 0.961, green: 0.961, blue: 0.961)

    /// Reduced emphasis gray text for labels
    static let darkTextSecondary = Color(red: 0.655, green: 0.663, blue: 0.663)

    /// Subtle visual separation - 30% opacity
    static let darkDivider = Color(red: 0.447, green: 0.463, blue: 0.463).opacity(0.3)

    /// Primary action color for dark mode
    static let darkPrimary = Color(red: 0.196, green: 0.722, blue: 0.776)

    /// Primary hover state for dark mode
    static let darkPrimaryHover = Color(red: 0.173, green: 0.659, blue: 0.710)

    /// Primary active/pressed state for dark mode
    static let darkPrimaryActive = Color(red: 0.149, green: 0.596, blue: 0.643)

    /// Success state color for dark mode (teal)
    static let darkSuccess = Color(red: 0.133, green: 0.722, blue: 0.776)

    /// Error state color for dark mode
    static let darkError = Color(red: 1.0, green: 0.329, blue: 0.349)

    /// Warning state color for dark mode
    static let darkWarning = Color(red: 0.902, green: 0.506, blue: 0.349)

    /// Info state color for dark mode
    static let darkInfo = Color(red: 0.655, green: 0.663, blue: 0.663)

    // MARK: - Semantic Color Properties (Adaptive)

    /// Adaptive background color that changes with color scheme
    static func adaptiveBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .darkBackground : .lightBackground
    }

    /// Adaptive surface color for cards and containers
    static func adaptiveSurface(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .darkSurface : .lightSurface
    }

    /// Adaptive primary text color
    static func adaptiveTextPrimary(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .darkTextPrimary : .lightTextPrimary
    }

    /// Adaptive secondary text color
    static func adaptiveTextSecondary(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .darkTextSecondary : .lightTextSecondary
    }

    /// Adaptive divider color
    static func adaptiveDivider(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .darkDivider : .lightDivider
    }

    /// Adaptive primary action color
    static func adaptivePrimary(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .darkPrimary : .lightPrimary
    }

    /// Adaptive primary hover color
    static func adaptivePrimaryHover(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .darkPrimaryHover : .lightPrimaryHover
    }

    /// Adaptive primary active color
    static func adaptivePrimaryActive(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .darkPrimaryActive : .lightPrimaryActive
    }

    /// Adaptive success color
    static func adaptiveSuccess(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .darkSuccess : .lightSuccess
    }

    /// Adaptive error color
    static func adaptiveError(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .darkError : .lightError
    }

    /// Adaptive warning color
    static func adaptiveWarning(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .darkWarning : .lightWarning
    }

    /// Adaptive info color
    static func adaptiveInfo(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .darkInfo : .lightInfo
    }

    // MARK: - Utility Colors

    /// Search bar background color
    static func adaptiveSearchBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)
    }

    /// Filter pill inactive background color
    static func adaptiveFilterInactive(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.gray.opacity(0.15) : Color.gray.opacity(0.1)
    }

    /// Progress track color
    static func adaptiveProgressTrack(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)
    }

    /// Shadow color for cards
    static func adaptiveShadow(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }

    // MARK: - Background Tint Colors (8% light mode, 15% dark mode)

    /// Blue background tint
    static func blueTint(_ colorScheme: ColorScheme) -> Color {
        let opacity = colorScheme == .dark ? 0.15 : 0.08
        return Color(red: 0.196, green: 0.447, blue: 1.0).opacity(opacity)
    }

    /// Green background tint
    static func greenTint(_ colorScheme: ColorScheme) -> Color {
        let opacity = colorScheme == .dark ? 0.15 : 0.08
        return Color(red: 0.133, green: 0.773, blue: 0.369).opacity(opacity)
    }

    /// Red background tint
    static func redTint(_ colorScheme: ColorScheme) -> Color {
        let opacity = colorScheme == .dark ? 0.15 : 0.08
        return Color(red: 0.929, green: 0.251, blue: 0.251).opacity(opacity)
    }

    /// Orange background tint
    static func orangeTint(_ colorScheme: ColorScheme) -> Color {
        let opacity = colorScheme == .dark ? 0.15 : 0.08
        return Color(red: 0.902, green: 0.506, blue: 0.294).opacity(opacity)
    }

    /// Purple background tint
    static func purpleTint(_ colorScheme: ColorScheme) -> Color {
        let opacity = colorScheme == .dark ? 0.15 : 0.08
        return Color(red: 0.584, green: 0.208, blue: 0.933).opacity(opacity)
    }
}

// MARK: - Adaptive Color Accessor

/// Struct that provides adaptive colors based on the current color scheme
struct AdaptiveColors {
    let colorScheme: ColorScheme

    // Semantic colors
    var background: Color { Color.adaptiveBackground(colorScheme) }
    var surface: Color { Color.adaptiveSurface(colorScheme) }
    var textPrimary: Color { Color.adaptiveTextPrimary(colorScheme) }
    var textSecondary: Color { Color.adaptiveTextSecondary(colorScheme) }
    var divider: Color { Color.adaptiveDivider(colorScheme) }
    var primary: Color { Color.adaptivePrimary(colorScheme) }
    var primaryHover: Color { Color.adaptivePrimaryHover(colorScheme) }
    var primaryActive: Color { Color.adaptivePrimaryActive(colorScheme) }
    var success: Color { Color.adaptiveSuccess(colorScheme) }
    var error: Color { Color.adaptiveError(colorScheme) }
    var warning: Color { Color.adaptiveWarning(colorScheme) }
    var info: Color { Color.adaptiveInfo(colorScheme) }

    // Utility colors
    var searchBackground: Color { Color.adaptiveSearchBackground(colorScheme) }
    var filterInactive: Color { Color.adaptiveFilterInactive(colorScheme) }
    var progressTrack: Color { Color.adaptiveProgressTrack(colorScheme) }
    var shadow: Color { Color.adaptiveShadow(colorScheme) }

    // Tint colors
    var blueTint: Color { Color.blueTint(colorScheme) }
    var greenTint: Color { Color.greenTint(colorScheme) }
    var redTint: Color { Color.redTint(colorScheme) }
    var orangeTint: Color { Color.orangeTint(colorScheme) }
    var purpleTint: Color { Color.purpleTint(colorScheme) }
}

// MARK: - Environment Integration

private struct AdaptiveColorsKey: EnvironmentKey {
    static let defaultValue = AdaptiveColors(colorScheme: .light)
}

extension EnvironmentValues {
    var adaptiveColors: AdaptiveColors {
        get { self[AdaptiveColorsKey.self] }
        set { self[AdaptiveColorsKey.self] = newValue }
    }
}

// MARK: - View Extension for Easy Access

extension View {
    /// Access adaptive colors based on the current environment
    func adaptiveColors(_ colorScheme: ColorScheme) -> AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }
}
