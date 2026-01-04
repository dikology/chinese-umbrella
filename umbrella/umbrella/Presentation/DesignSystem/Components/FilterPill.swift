//
//  FilterPill.swift
//  umbrella
//
//  Created by Денис on 01.01.2026.
//

import SwiftUI

/// Reusable filter pill component for category selection
struct FilterPill: View {
    @Environment(\.colorScheme) private var colorScheme

    let filter: BookFilter
    let isSelected: Bool
    let action: () -> Void

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                Text(filter.rawValue)
                    .font(.bodySecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? colors.primary : colors.filterInactive)
            .foregroundColor(isSelected ? .white : colors.textPrimary)
            .cornerRadius(20)
        }
    }
}
