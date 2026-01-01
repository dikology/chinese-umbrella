//
//  ReadingScreen.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import SwiftUI

/// Reading screen for displaying book pages with interactive word segmentation
struct ReadingScreen: View {
    @State private var viewModel: ReadingViewModel
    @State private var showingDictionaryPopup = false

    private let book: AppBook

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
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 8)

                                // Segmented text content
                                segmentedTextView(for: page)

                                // Page separator
                                Divider()
                                    .padding(.vertical, 16)

                                // Navigation hint
                                if !viewModel.isLastPage {
                                    Text("Scroll down for next page")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            } else {
                                Text("No page loaded")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }

                // Dictionary popup overlay
                if showingDictionaryPopup, let selectedWord = viewModel.selectedWord {
                    dictionaryPopup(for: selectedWord)
                }
            }
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    progressIndicator
                }
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
                    .foregroundColor(viewModel.canGoPrevious ? .primary : .gray)
            }
            .disabled(!viewModel.canGoPrevious)

            Spacer()

            VStack(spacing: 2) {
                Text("\(viewModel.currentPageIndex + 1) of \(viewModel.totalPages)")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("Page \(viewModel.currentPageNumber)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()

            Button(action: {
                Task { await viewModel.nextPage() }
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(viewModel.canGoNext ? .primary : .gray)
            }
            .disabled(!viewModel.canGoNext)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground).opacity(0.9))
    }

    private var progressIndicator: some View {
        VStack(spacing: 2) {
            ProgressView(value: viewModel.readingProgress)
                .progressViewStyle(.linear)
                .frame(width: 60)
            Text("\(Int(viewModel.readingProgress * 100))%")
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }

    private func segmentedTextView(for page: AppBookPage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Display segmented words as interactive buttons
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40), spacing: 2)], spacing: 8) {
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

    private func dictionaryPopup(for wordSegment: AppWordSegment) -> some View {
        Color.black.opacity(0.4)
            .edgesIgnoringSafeArea(.all)
            .overlay(
                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 16) {
                        // Word display
                        VStack(spacing: 8) {
                            Text(wordSegment.word)
                                .font(.title)
                                .fontWeight(.bold)

                            if let pinyin = wordSegment.pinyin {
                                Text(pinyin)
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Dictionary entry
                        if let entry = viewModel.dictionaryEntry {
                            VStack(spacing: 12) {
                                Text(entry.englishDefinition)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)

                                if let frequency = entry.frequency {
                                    Text("HSK Level \(frequency.rawValue)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Text("Definition not found")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        // Action buttons
                        HStack(spacing: 20) {
                            Button(action: {
                                Task {
                                    await viewModel.markWordAsDifficult(wordSegment.word)
                                    showingDictionaryPopup = false
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: viewModel.isWordMarked(wordSegment.word) ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                    Text("Mark")
                                        .font(.caption)
                                }
                            }

                            Button(action: {
                                viewModel.deselectWord()
                                showingDictionaryPopup = false
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.gray)
                                    Text("Close")
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 8)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)

                    Spacer()
                }
            )
            .onTapGesture {
                viewModel.deselectWord()
                showingDictionaryPopup = false
            }
    }
}

// MARK: - Supporting Views

struct WordButton: View {
    let wordSegment: AppWordSegment
    let isSelected: Bool
    let isMarked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(wordSegment.word)
                .font(.system(size: 16))
                .foregroundColor(textColor)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
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
            return .orange
        } else {
            return .primary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isMarked {
            return .orange.opacity(0.1)
        } else {
            return .clear
        }
    }

    private var selectionColor: Color {
        isSelected ? .blue : .clear
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
