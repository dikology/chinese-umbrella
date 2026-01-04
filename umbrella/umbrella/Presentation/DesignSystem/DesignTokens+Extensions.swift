//
//  DesignTokens+Extensions.swift
//  umbrella
//
//  Created by Design System Team
//

import SwiftUI

// MARK: - Design System Tokens

extension CGFloat {
    // MARK: - Spacing

    /// Extra small spacing - 4pt - Tight spacing, small gaps
    static let spacingXS: CGFloat = 4

    /// Small spacing - 8pt - Component internal spacing
    static let spacingS: CGFloat = 8

    /// Medium spacing - 12pt - Standard component padding
    static let spacingM: CGFloat = 12

    /// Large spacing - 16pt - Section spacing, larger gaps
    static let spacingL: CGFloat = 16

    /// Extra large spacing - 24pt - Major section breaks, margins
    static let spacingXL: CGFloat = 24

    // MARK: - Corner Radius

    /// Small corner radius - 4pt - Subtle rounding
    static let radiusS: CGFloat = 4

    /// Medium corner radius - 8pt - Standard card rounding
    static let radiusM: CGFloat = 8

    /// Large corner radius - 12pt - Modal/dialog rounding
    static let radiusL: CGFloat = 12

    /// Extra large corner radius - 16pt - Special accent rounding
    static let radiusXL: CGFloat = 16

    // MARK: - Component Sizes

    /// Standard book cover width - 60pt
    static let bookCoverWidth: CGFloat = 60

    /// Standard book cover height - 80pt
    static let bookCoverHeight: CGFloat = 80

    /// Progress indicator size - 40pt
    static let progressIndicatorSize: CGFloat = 40

    /// Minimum touch target size - 44pt (Apple HIG)
    static let minTouchTarget: CGFloat = 44

    /// Icon button size - 32pt
    static let iconButtonSize: CGFloat = 32

    /// Standard button height - 44pt
    static let buttonHeight: CGFloat = 44
}

// MARK: - Spacing Convenience Extensions

extension EdgeInsets {
    /// Standard padding using medium spacing
    static let standard = EdgeInsets(
        top: .spacingM,
        leading: .spacingM,
        bottom: .spacingM,
        trailing: .spacingM
    )

    /// Compact padding using small spacing
    static let compact = EdgeInsets(
        top: .spacingS,
        leading: .spacingS,
        bottom: .spacingS,
        trailing: .spacingS
    )

    /// Loose padding using large spacing
    static let loose = EdgeInsets(
        top: .spacingL,
        leading: .spacingL,
        bottom: .spacingL,
        trailing: .spacingL
    )
}

// MARK: - View Extensions for Design Tokens

extension View {
    /// Apply standard padding using design tokens
    func standardPadding() -> some View {
        self.padding(.standard)
    }

    /// Apply compact padding using design tokens
    func compactPadding() -> some View {
        self.padding(.compact)
    }

    /// Apply loose padding using design tokens
    func loosePadding() -> some View {
        self.padding(.loose)
    }

    /// Apply standard corner radius using design tokens
    func standardCornerRadius() -> some View {
        self.cornerRadius(.radiusM)
    }
}
