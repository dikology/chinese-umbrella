//
//  SecondaryButton.swift
//  umbrella
//
//  Created by Design System Team
//

import SwiftUI

/// Secondary action button with adaptive styling
struct SecondaryButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let action: () -> Void
    let isEnabled: Bool

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    init(
        title: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, .spacingL)
                .padding(.vertical, .spacingM)
                .frame(minWidth: .minTouchTarget, minHeight: .minTouchTarget)
                .background(Color.clear)
                .foregroundColor(colors.textPrimary)
                .cornerRadius(.radiusM)
                .overlay(
                    RoundedRectangle(cornerRadius: .radiusM)
                        .stroke(colors.divider, lineWidth: 1)
                )
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    VStack(spacing: 16) {
        SecondaryButton(title: "Cancel") {}

        SecondaryButton(title: "Cancel", isEnabled: false) {}
    }
    .padding()
}
