//
//  CardContainer.swift
//  umbrella
//
//  Created by Design System Team
//

import SwiftUI

/// Container view with adaptive card styling
struct CardContainer<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let content: Content
    let padding: EdgeInsets

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    init(
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background(colors.surface)
            .cornerRadius(12)
            .shadow(color: colors.shadow, radius: 2, x: 0, y: 1)
    }
}

/// Convenience initializer with default padding
extension CardContainer where Content: View {
    init(@ViewBuilder content: () -> Content) {
        self.init(padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16), content: content)
    }
}

#Preview {
    VStack(spacing: 16) {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Book Title")
                    .titleStyle()

                Text("Author Name")
                    .bodySecondaryStyle()

                HStack {
                    Text("100 pages")
                        .captionStyle()
                    Spacer()
                    Text("50% read")
                        .captionStyle()
                }
            }
        }

        CardContainer(padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)) {
            Text("Compact card content")
                .bodyStyle()
        }
    }
    .padding()
}
