//
//  DictionaryPopupView.swift
//  umbrella
//
//  Created by Денис on 02.01.2026.
//

import SwiftUI

struct DictionaryPopupView: View {
    @Environment(\.colorScheme) private var colorScheme
    let wordSegment: AppWordSegment
    let dictionaryEntry: DictionaryEntry?
    let onMarkWord: () -> Void
    let onClose: () -> Void

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { onClose() }

            // Popup content
            VStack(spacing: 0) {
                Spacer()

                CardContainer(padding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)) {
                    VStack(spacing: 16) {
                        // Header with word and traditional form
                        wordHeader

                        // Pinyin with tone marks
                        pinyinSection

                        // Definitions
                        if let entry = dictionaryEntry {
                            definitionsSection(for: entry)
                        } else {
                            noDefinitionSection
                        }

                        // Action buttons
                        actionButtons
                    }
                }
                .cornerRadius(16)
                .shadow(color: colors.shadow, radius: 12, x: 0, y: 6)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)

                Spacer()
            }
        }
    }

    // MARK: - Subviews

    private var wordHeader: some View {
        VStack(spacing: 8) {
            // Main word (simplified)
            Text(wordSegment.word)
                .titleStyle()
                .fontWeight(.bold)

            // Traditional characters (if different)
            if let entry = dictionaryEntry, entry.hasTraditionalVariant {
                Text(entry.traditional)
                    .headingStyle()
                    .foregroundColor(colors.textSecondary)
                    .opacity(0.8)
            }
        }
    }

    private var pinyinSection: some View {
        Group {
            if let entry = dictionaryEntry {
                Text(entry.formattedPinyin)
                    .headingStyle()
                    .foregroundColor(colors.primary)
                    .fontWeight(.medium)
            } else {
                Text("Pinyin not available")
                    .headingStyle()
                    .foregroundColor(colors.textSecondary)
            }
        }
    }

    private func definitionsSection(for entry: DictionaryEntry) -> some View {
        VStack(spacing: 12) {
            if entry.hasMultipleDefinitions {
                // Multiple definitions - show as numbered list
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(entry.splitDefinitions.enumerated()), id: \.offset) { index, definition in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .captionStyle()
                                .foregroundColor(colors.textSecondary)
                                .frame(width: 20, alignment: .leading)

                            Text(definition)
                                .bodyStyle()
                                .foregroundColor(colors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Single definition - centered
                Text(entry.primaryDefinition)
                    .bodyStyle()
                    .multilineTextAlignment(.center)
                    .foregroundColor(colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // HSK level badge
            if let frequency = entry.frequency {
                Text("HSK Level \(frequency.rawValue)")
                    .captionStyle()
                    .foregroundColor(colors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colors.surface.opacity(0.6))
                    .cornerRadius(6)
            }
        }
    }

    private var noDefinitionSection: some View {
        Text("Definition not found")
            .bodyStyle()
            .foregroundColor(colors.textSecondary)
            .multilineTextAlignment(.center)
    }

    private var actionButtons: some View {
        HStack(spacing: 20) {
            // Mark/Star button
            Button(action: onMarkWord) {
                VStack(spacing: 4) {
                    Image(systemName: dictionaryEntry?.frequency != nil ? "star.fill" : "star")
                        .foregroundColor(dictionaryEntry?.frequency != nil ? .yellow : colors.textSecondary)
                        .font(.system(size: 20))
                    Text(dictionaryEntry?.frequency != nil ? "Marked" : "Mark")
                        .captionStyle()
                        .foregroundColor(colors.textPrimary)
                }
            }
            .buttonStyle(.plain)

            // Close button
            Button(action: onClose) {
                VStack(spacing: 4) {
                    Image(systemName: "xmark")
                        .foregroundColor(colors.textSecondary)
                        .font(.system(size: 20))
                    Text("Close")
                        .captionStyle()
                        .foregroundColor(colors.textPrimary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview {
    let mockEntry = DictionaryEntry(
        simplified: "你好",
        traditional: "你好",
        pinyin: "nǐ hǎo",
        englishDefinition: "hello; hi; how are you?; I am fine; how do you do",
        frequency: .hsk1
    )

    let mockSegment = AppWordSegment(
        id: UUID(),
        word: "你好",
        pinyin: "nǐ hǎo",
        startIndex: 0,
        endIndex: 2,
        isMarked: false,
        definition: mockEntry
    )

    DictionaryPopupView(
        wordSegment: mockSegment,
        dictionaryEntry: mockEntry,
        onMarkWord: {},
        onClose: {}
    )
}
