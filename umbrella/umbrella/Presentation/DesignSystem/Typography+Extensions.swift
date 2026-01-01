//
//  Typography+Extensions.swift
//  umbrella
//
//  Created by Design System Team
//

import SwiftUI

// MARK: - Design System Typography

extension Font {

    // MARK: - Display & Title Fonts

    /// Display font - 34pt, 700 Bold - Main screen titles
    static let display = Font.system(size: 34, weight: .bold, design: .default)

    /// Title font - 28pt, 700 Bold - Section headers
    static let title = Font.system(size: 28, weight: .bold, design: .default)

    /// Heading font - 24pt, 600 Semibold - Subsection headers
    static let heading = Font.system(size: 24, weight: .semibold, design: .default)

    /// Subheading font - 20pt, 600 Semibold - Component headings
    static let subheading = Font.system(size: 20, weight: .semibold, design: .default)

    // MARK: - Body & Content Fonts

    /// Body font - 16pt, 400 Regular - Primary content text
    static let body = Font.system(size: 16, weight: .regular, design: .default)

    /// Body secondary font - 14pt, 400 Regular - Secondary content
    static let bodySecondary = Font.system(size: 14, weight: .regular, design: .default)

    /// Caption font - 12pt, 500 Medium - Labels, hints, metadata
    static let caption = Font.system(size: 12, weight: .medium, design: .default)

    /// Caption small font - 11pt, 400 Regular - Fine print, timestamps
    static let captionSmall = Font.system(size: 11, weight: .regular, design: .default)

    // MARK: - Monospace Font

    /// Monospace font - SF Mono - For code snippets (if needed)
    static let monospace = Font.system(size: 14, weight: .regular, design: .monospaced)
}

// MARK: - Text Style Extensions

extension View where Self == Text {

    /// Apply display style with adaptive color
    func displayStyle() -> some View {
        self.modifier(TextStyleModifier(style: .display))
    }

    /// Apply title style with adaptive color
    func titleStyle() -> some View {
        self.modifier(TextStyleModifier(style: .title))
    }

    /// Apply heading style with adaptive color
    func headingStyle() -> some View {
        self.modifier(TextStyleModifier(style: .heading))
    }

    /// Apply subheading style with adaptive color
    func subheadingStyle() -> some View {
        self.modifier(TextStyleModifier(style: .subheading))
    }

    /// Apply body style with adaptive color
    func bodyStyle() -> some View {
        self.modifier(TextStyleModifier(style: .body))
    }

    /// Apply body secondary style with adaptive color
    func bodySecondaryStyle() -> some View {
        self.modifier(TextStyleModifier(style: .bodySecondary))
    }

    /// Apply caption style with adaptive color
    func captionStyle() -> some View {
        self.modifier(TextStyleModifier(style: .caption))
    }

    /// Apply caption small style with adaptive color
    func captionSmallStyle() -> some View {
        self.modifier(TextStyleModifier(style: .captionSmall))
    }

    /// Apply success color styling
    func successStyle() -> some View {
        self.modifier(ColorStyleModifier(color: .success))
    }

    /// Apply error color styling
    func errorStyle() -> some View {
        self.modifier(ColorStyleModifier(color: .error))
    }

    /// Apply warning color styling
    func warningStyle() -> some View {
        self.modifier(ColorStyleModifier(color: .warning))
    }

    /// Apply info color styling
    func infoStyle() -> some View {
        self.modifier(ColorStyleModifier(color: .info))
    }
}

// MARK: - TextField Style Extensions

extension TextField {

    /// Apply adaptive text field styling
    func adaptiveTextFieldStyle() -> some View {
        self.modifier(TextFieldStyleModifier())
    }
}

// MARK: - TextEditor Style Extensions

extension TextEditor {

    /// Apply adaptive text editor styling
    func adaptiveTextEditorStyle() -> some View {
        self.modifier(TextEditorStyleModifier())
    }
}

// MARK: - Text Style Modifiers

/// Text style types for typography
enum TextStyle {
    case display, title, heading, subheading, body, bodySecondary, caption, captionSmall
}

/// Color style types for semantic colors
enum ColorStyle {
    case success, error, warning, info
}

/// Modifier for applying text styles with adaptive colors
struct TextStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let style: TextStyle

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    func body(content: Content) -> some View {
        content
            .font(font(for: style))
            .foregroundColor(textColor(for: style))
    }

    private func font(for style: TextStyle) -> Font {
        switch style {
        case .display: return .display
        case .title: return .title
        case .heading: return .heading
        case .subheading: return .subheading
        case .body: return .body
        case .bodySecondary: return .bodySecondary
        case .caption: return .caption
        case .captionSmall: return .captionSmall
        }
    }

    private func textColor(for style: TextStyle) -> Color {
        switch style {
        case .display, .title, .heading, .subheading, .body:
            return colors.textPrimary
        case .bodySecondary, .caption, .captionSmall:
            return colors.textSecondary
        }
    }
}

/// Modifier for applying semantic color styles
struct ColorStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let color: ColorStyle

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    func body(content: Content) -> some View {
        content
            .foregroundColor(semanticColor(for: color))
    }

    private func semanticColor(for color: ColorStyle) -> Color {
        switch color {
        case .success: return colors.success
        case .error: return colors.error
        case .warning: return colors.warning
        case .info: return colors.info
        }
    }
}

/// Modifier for text field styling
struct TextFieldStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(colors.textPrimary)
            .textFieldStyle(.plain)
    }
}

/// Modifier for text editor styling
struct TextEditorStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(colors.textPrimary)
    }
}
