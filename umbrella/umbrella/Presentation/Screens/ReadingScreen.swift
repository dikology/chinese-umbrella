//
//  ReadingScreen.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import SwiftUI

/// Reading screen for displaying book pages with interactive word segmentation
struct ReadingScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: ReadingViewModel
    @State private var showingDictionaryPopup = false

    private let book: AppBook

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    init(book: AppBook) {
        self.book = book
        self.viewModel = DIContainer.makeReadingViewModel()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Main reading content
                VStack(spacing: 0) {
                    // Header with navigation controls
                    readingHeader

                    // Page content
                    ScrollView {
                        VStack(alignment: .center, spacing: 24) {
                            if viewModel.isLoading {
                                ProgressView("Loading page...")
                                    .padding()
                            } else if let page = viewModel.currentPage {
                                // Page title
                                Text("Page \(page.pageNumber)")
                                    .captionStyle()
                                    .padding(.bottom, 8)

                                // Segmented text content
                                segmentedTextView(for: page)

                                // Page separator
                                Divider()
                                    .background(colors.divider)
                                    .padding(.vertical, 16)

                                // Navigation hint
                                if !viewModel.isLastPage {
                                    Text("Scroll down for next page")
                                        .captionSmallStyle()
                                }
                            } else {
                                Text("No page loaded")
                                    .bodySecondaryStyle()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
                .background(colors.background)

                // Dictionary popup overlay
                if showingDictionaryPopup, let selectedWord = viewModel.selectedWord {
                    DictionaryPopupView(
                        wordSegment: selectedWord,
                        dictionaryEntry: viewModel.dictionaryEntry,
                        onMarkWord: {
                            Task {
                                await viewModel.markWordAsDifficult(selectedWord.word)
                            }
                        },
                        onClose: {
                            viewModel.deselectWord()
                            showingDictionaryPopup = false
                        }
                    )
                }
            }
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    progressIndicator
//                }
            }
        }
        .task {
            await viewModel.loadBook(book)
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
    }

    // MARK: - Subviews

    private var readingHeader: some View {
        HStack {
            Button(action: {
                Task { await viewModel.previousPage() }
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(viewModel.canGoPrevious ? colors.primary : colors.textSecondary)
            }
            .disabled(!viewModel.canGoPrevious)

            Spacer()

            VStack(spacing: 2) {
                Text("\(viewModel.currentPageIndex + 1) of \(viewModel.totalPages)")
                    .captionStyle()
                Text("Page \(viewModel.currentPageNumber)")
                    .bodySecondaryStyle()
                    .fontWeight(.medium)
            }

            Spacer()

            Button(action: {
                Task { await viewModel.nextPage() }
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(viewModel.canGoNext ? colors.primary : colors.textSecondary)
            }
            .disabled(!viewModel.canGoNext)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(colors.surface.opacity(0.9))
    }

    private var progressIndicator: some View {
        VStack(spacing: 2) {
            ProgressView(value: viewModel.readingProgress)
                .progressViewStyle(.linear)
                .frame(width: 60)
                .tint(colors.primary)
                .background(colors.progressTrack)
                .cornerRadius(2)
            Text("\(Int(viewModel.readingProgress * 100))%")
                .captionSmallStyle()
        }
    }

    private func segmentedTextView(for page: AppBookPage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Display segmented words in natural flowing text layout
            FlowingTextLayout {
                ForEach(viewModel.segmentedWords) { wordSegment in
                    WordButton(
                        wordSegment: wordSegment,
                        isSelected: viewModel.selectedWord?.id == wordSegment.id,
                        isMarked: viewModel.isWordMarked(wordSegment.word)
                    ) {
                        Task {
                            await viewModel.selectWord(wordSegment)
                            showingDictionaryPopup = true
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

}

// MARK: - Supporting Views

/// Custom layout that arranges word buttons in natural flowing text lines
struct FlowingTextLayout: Layout {
    let horizontalSpacing: CGFloat = 2 // Small spacing between words

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var currentLineWidth: CGFloat = 0
        var maxLineHeight: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let subviewSize = subview.sizeThatFits(.unspecified)
            let spacing = index > 0 ? horizontalSpacing : 0

            // If adding this view would exceed the line width, start a new line
            if currentLineWidth + spacing + subviewSize.width > containerWidth && currentLineWidth > 0 {
                height += maxLineHeight
                currentLineWidth = subviewSize.width
                maxLineHeight = subviewSize.height
            } else {
                currentLineWidth += spacing + subviewSize.width
                maxLineHeight = max(maxLineHeight, subviewSize.height)
            }
        }

        // Add the last line's height
        height += maxLineHeight

        return CGSize(width: containerWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
        let containerWidth = bounds.width

        for (index, subview) in subviews.enumerated() {
            let subviewSize = subview.sizeThatFits(.unspecified)
            let spacing = index > 0 ? horizontalSpacing : 0

            // If adding this view would exceed the line width, start a new line
            if currentX - bounds.minX + spacing + subviewSize.width > containerWidth && currentX > bounds.minX {
                currentY += lineHeight
                currentX = bounds.minX
                lineHeight = subviewSize.height
            }

            let xPosition = currentX + (index > 0 ? spacing : 0)
            subview.place(
                at: CGPoint(x: xPosition, y: currentY),
                proposal: ProposedViewSize(width: subviewSize.width, height: subviewSize.height)
            )

            currentX = xPosition + subviewSize.width
            lineHeight = max(lineHeight, subviewSize.height)
        }
    }
}

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

// MARK: - ViewModel Extensions

extension ReadingViewModel {
    var canGoPrevious: Bool {
        currentPageIndex > 0
    }

    var canGoNext: Bool {
        guard let book = currentBook else { return false }
        return currentPageIndex < book.totalPages - 1
    }

    var isLastPage: Bool {
        guard let book = currentBook else { return true }
        return currentPageIndex >= book.totalPages - 1
    }

    var totalPages: Int {
        currentBook?.totalPages ?? 0
    }

    var currentPageNumber: Int {
        currentPage?.pageNumber ?? 0
    }

    var readingProgress: Double {
        currentBook?.readingProgress ?? 0.0
    }
}

struct FlowingTextLayoutPreview: View {
    let sampleWords = ["你好", "世界", "学习", "中文", "这是", "一个", "测试", "句子", "。"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Before (Grid Layout - looks like columns):")
                .font(.headline)

            GridLayoutExample(words: sampleWords)

            Text("After (Flowing Text Layout - natural reading flow):")
                .font(.headline)

            FlowingLayoutExample(words: sampleWords)
        }
        .padding()
    }
}

struct GridLayoutExample: View {
    let words: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 28), spacing: 1)], spacing: 12) {
            ForEach(words, id: \.self) { word in
                Text(word)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .frame(height: 120)
    }
}

struct FlowingLayoutExample: View {
    let words: [String]

    var body: some View {
        FlowingTextLayout {
            ForEach(words, id: \.self) { word in
                Text(word)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .frame(height: 60)
    }
}

#Preview {
    // Create a mock book for preview
    let mockPage = AppBookPage(
        bookId: UUID(),
        pageNumber: 1,
        originalImagePath: "",
        extractedText: "你好，我是学生。",
        words: []
    )

    let mockBook = AppBook(
        title: "Sample Book",
        pages: [mockPage]
    )

    return ReadingScreen(book: mockBook)
}

#Preview("Flowing Text Layout") {
    FlowingTextLayoutPreview()
}
