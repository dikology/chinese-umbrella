//
//  EmptyLibraryView.swift
//  umbrella
//
//  Created by Денис on 01.01.2026.
//

import SwiftUI

/// Empty state view for when library has no books
struct EmptyLibraryView: View {
    @Environment(\.colorScheme) private var colorScheme

    let message: String

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "books.vertical")
                .font(.system(size: 64))
                .foregroundColor(colors.textSecondary.opacity(0.5))

            Text("No Books Yet")
                .font(.heading)
                .foregroundColor(colors.textSecondary)

            Text(message)
                .bodySecondaryStyle()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}
