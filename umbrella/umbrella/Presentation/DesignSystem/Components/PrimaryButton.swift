//
//  PrimaryButton.swift
//  umbrella
//
//  Created by Design System Team
//

import SwiftUI

/// Primary action button with adaptive styling
struct PrimaryButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let action: () -> Void
    let isLoading: Bool
    let isEnabled: Bool

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    init(
        title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minWidth: 44, minHeight: 44)
            .background(isEnabled ? colors.primary : colors.primary.opacity(0.4))
            .foregroundColor(.white)
            .cornerRadius(8)
            .shadow(color: colors.shadow, radius: 2, x: 0, y: 1)
        }
        .disabled(!isEnabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Upload Book") {}

        PrimaryButton(title: "Upload Book", isLoading: true) {}

        PrimaryButton(title: "Upload Book", isEnabled: false) {}
    }
    .padding()
}
