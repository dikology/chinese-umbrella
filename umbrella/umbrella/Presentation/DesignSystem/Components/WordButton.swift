//
//  WordButton.swift
//  umbrella
//
//  Created by Денис on 01.01.2026.
//

import SwiftUI

/// Interactive word button for reading screen with selection and marking states
struct WordButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let wordSegment: AppWordSegment
    let isSelected: Bool
    let isMarked: Bool
    let action: () -> Void

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            Text(wordSegment.word)
                .font(.body)
                .foregroundColor(textColor)
                .padding(.horizontal, 3)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(selectionColor, lineWidth: isSelected ? 2 : 0)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if isMarked {
            return colors.warning
        } else {
            return colors.textPrimary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return colors.primary
        } else if isMarked {
            return colors.orangeTint
        } else {
            return .clear
        }
    }

    private var selectionColor: Color {
        isSelected ? colors.primary : .clear
    }
}
