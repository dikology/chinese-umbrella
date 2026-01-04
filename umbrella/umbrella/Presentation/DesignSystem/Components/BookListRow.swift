//
//  BookListRow.swift
//  umbrella
//
//  Created by Денис on 01.01.2026.
//

import SwiftUI

/// Book list row component for displaying book information in lists
struct BookListRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let book: AppBook
    let onSelect: () -> Void

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    var body: some View {
        Button(action: onSelect) {
            CardContainer {
                HStack(spacing: 16) {
                    // Book cover placeholder
//                    ZStack {
//                        RoundedRectangle(cornerRadius: 8)
//                            .fill(colors.filterInactive)
//                            .frame(width: 60, height: 80)
//
//                        Image(systemName: book.isLocal ? "camera" : "globe")
//                            .font(.title2)
//                            .foregroundColor(colors.textSecondary)
//                    }

                    // Book info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title)
                            .font(.subheading)
                            .lineLimit(1)
                            .foregroundColor(colors.textPrimary)

                        if let author = book.author {
                            Text(author)
                                .bodySecondaryStyle()
                                .lineLimit(1)
                        }

                        HStack(spacing: 12) {
                            Text("\(book.totalPages) pages")
                                .captionStyle()

//                            if book.isCompleted {
//                                Image(systemName: "checkmark.circle.fill")
//                                    .foregroundColor(colors.success)
//                                    .font(.caption)
//                            } else {
//                                Text("\(Int(book.readingProgress * 100))% read")
//                                    .captionStyle()
//                            }
                        }
                    }

                    Spacer()

                    // Progress indicator
//                    VStack {
//                        Spacer()
//                        CircularProgressIndicator(progress: book.readingProgress, size: 40)
//                        Spacer()
//                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
