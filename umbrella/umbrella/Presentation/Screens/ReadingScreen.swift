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
    private let userId: UUID

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    init(book: AppBook, userId: UUID, diContainer: DIContainer) {
        self.book = book
        self.viewModel = diContainer.makeReadingViewModel(userId: userId)
        self.userId = userId
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Main reading content
                VStack(spacing: 0) {
                    // Header with navigation controls
                    readingHeader

                    // Page content
                    PageContentView(viewModel: viewModel) {
                        showingDictionaryPopup = true
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
                Text("Page \(viewModel.currentPageIndex + 1) of \(viewModel.totalPages)")
                    .captionStyle()
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

}

// MARK: - Page Content View
private struct PageContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    let viewModel: ReadingViewModel
    let onWordSelected: () -> Void

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 24) {
                if viewModel.isLoading {
                    ProgressView("Loading page...")
                        .padding()
                } else if viewModel.currentPage != nil {
                    // Segmented text content
                    SegmentedTextView(viewModel: viewModel, onWordSelected: onWordSelected)

                    // Page separator
                    Divider()
                        .background(colors.divider)
                        .padding(.vertical, 16)

                    // Navigation hint
                    if !viewModel.isLastPage {
                        PageNavigationHint()
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
}

// MARK: - Segmented Text View
private struct SegmentedTextView: View {
    let viewModel: ReadingViewModel
    let onWordSelected: () -> Void

    var body: some View {
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
                            onWordSelected()
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}

// MARK: - Page Navigation Hint
private struct PageNavigationHint: View {
    var body: some View {
        Text("Scroll down for next page")
            .captionSmallStyle()
    }
}



// MARK: - Supporting Views


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

    ReadingScreen(book: mockBook, userId: UUID(), diContainer: DIContainer.preview)
        .environment(\.managedObjectContext, DIContainer.preview.coreDataManager.viewContext)
}
