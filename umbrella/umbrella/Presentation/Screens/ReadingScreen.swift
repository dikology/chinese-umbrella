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

                    // Multi-page scrollable content
                    MultiPageContentView(
                        viewModel: viewModel,
                        onWordSelected: {
                            showingDictionaryPopup = true
                        }
                    )
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
            Spacer()

            VStack(spacing: 2) {
                Text("Page \(viewModel.currentPageIndex + 1) of \(viewModel.totalPages)")
                    .captionStyle()
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(colors.surface.opacity(0.9))
    }

}

// MARK: - Multi-Page Content View with Pure Continuous Scroll
private struct MultiPageContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let viewModel: ReadingViewModel
    let onWordSelected: () -> Void
    
    @State private var progressUpdateTask: Task<Void, Never>?
    @State private var pageWindowCenter: Int = 0
    @State private var windowUpdateTask: Task<Void, Never>?
    
    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }
    
    // Stable page range based on local state (updates throttled to prevent feedback loops)
    private func stablePageRange(for book: AppBook) -> Range<Int> {
        // Show large window: 3 before + current + 5 after = 9 pages total
        let start = max(0, pageWindowCenter - 3)
        let end = min(book.totalPages, pageWindowCenter + 6)
        return start..<end
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView("Loading book...")
                        .padding()
                } else if let book = viewModel.currentBook {
                    // Display stable page range
                    ForEach(Array(stablePageRange(for: book)), id: \.self) { pageIndex in
                        SinglePageContentView(
                            pageIndex: pageIndex,
                            viewModel: viewModel,
                            onWordSelected: onWordSelected
                        )
                        .id(pageIndex)
                        .background(
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: PageVisibilityPreferenceKey.self,
                                    value: [PageVisibility(
                                        index: pageIndex,
                                        frame: geometry.frame(in: .named("scroll"))
                                    )]
                                )
                            }
                        )
                        .onAppear {
                            // Prefetch pages at edges of window
                            if pageIndex == stablePageRange(for: book).upperBound - 1,
                               pageIndex < book.totalPages - 1 {
                                Task {
                                    await viewModel.prefetchPage(pageIndex + 1)
                                }
                            }
                        }
                        
                        // Page separator
                        if pageIndex < book.totalPages - 1 {
                            PageSeparatorView(pageNumber: pageIndex + 1)
                                .padding(.vertical, 24)
                        }
                    }
                    
                    // End of book indicator
                    if stablePageRange(for: book).contains(book.totalPages - 1) {
                        EndOfBookView()
                            .padding(.vertical, 32)
                    }
                } else {
                    Text("No book loaded")
                        .bodySecondaryStyle()
                        .padding()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(PageVisibilityPreferenceKey.self) { pageVisibilities in
            // Filter to only significantly visible pages
            let significantlyVisible = pageVisibilities.filter { $0.visibleHeight > 0 }
            
            // Find the page with maximum visibility
            guard let mostVisible = significantlyVisible.max(by: { $0.visibleHeight < $1.visibleHeight }) else {
                return
            }
            
            // Update page window center if needed (throttled to next frame)
            if abs(mostVisible.index - pageWindowCenter) > 2 {
                windowUpdateTask?.cancel()
                windowUpdateTask = Task { @MainActor in
                    // Wait for next frame
                    try? await Task.sleep(nanoseconds: 16_000_000) // ~1 frame at 60fps
                    guard !Task.isCancelled else { return }
                    pageWindowCenter = mostVisible.index
                }
            }
            
            // Only update progress if it's a different page
            guard mostVisible.index != viewModel.currentPageIndex else { return }
            
            // Cancel any pending update
            progressUpdateTask?.cancel()
            
            // Debounce to ensure user has settled on this page
            let targetPage = mostVisible.index
            progressUpdateTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                guard !Task.isCancelled else { return }
                
                // Passive update - no navigation, just track progress
                await viewModel.updateProgressOnly(pageIndex: targetPage)
            }
        }
        .onAppear {
            pageWindowCenter = viewModel.currentPageIndex
        }
    }
}

// MARK: - Page Visibility Tracking
private struct PageVisibility: Equatable {
    let index: Int
    let frame: CGRect
    
    var visibleHeight: CGFloat {
        // Calculate visible portion within screen bounds
        let screenHeight = UIScreen.main.bounds.height
        
        // If page is completely off-screen, return 0
        guard frame.maxY > 0 && frame.minY < screenHeight else {
            return 0
        }
        
        // Calculate the visible portion
        let visibleTop = max(frame.minY, 0)
        let visibleBottom = min(frame.maxY, screenHeight)
        let visible = visibleBottom - visibleTop
        
        // Return 0 if less than 20% of screen height is visible
        // This filters out pages that are barely in view
        return visible > screenHeight * 0.2 ? visible : 0
    }
}

private struct PageVisibilityPreferenceKey: PreferenceKey {
    static var defaultValue: [PageVisibility] = []
    
    static func reduce(value: inout [PageVisibility], nextValue: () -> [PageVisibility]) {
        value.append(contentsOf: nextValue())
    }
}

// MARK: - Single Page Content View
private struct SinglePageContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let pageIndex: Int
    let viewModel: ReadingViewModel
    let onWordSelected: () -> Void
    
    @State private var pageContent: PageContent?
    @State private var isLoading = false
    @State private var hasLoaded = false
    
    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Page number indicator
            HStack {
                Text("Page \(pageIndex + 1)")
                    .captionStyle()
                    .foregroundColor(colors.textSecondary)
                Spacer()
            }
            
            // Page content
            if isLoading {
                ProgressView("Loading page...")
                    .padding()
            } else if let content = pageContent {
                SegmentedTextView(
                    segmentedWords: content.words,
                    markedWords: content.markedWords,
                    selectedWord: viewModel.selectedWord,
                    viewModel: viewModel,
                    onWordSelected: onWordSelected
                )
            } else {
                Text("Failed to load page")
                    .bodySecondaryStyle()
                    .padding()
            }
        }
        .task {
            // Only load if not already loaded
            if !hasLoaded {
                await loadPage()
            }
        }
    }
    
    private func loadPage() async {
        guard let book = viewModel.currentBook,
              book.pages.indices.contains(pageIndex) else {
            LoggingService.shared.reading("⚠️ Cannot load page \(pageIndex): book not loaded or index out of bounds", level: .default)
            return
        }
        
        LoggingService.shared.reading("🔄 SinglePageContentView loading page \(pageIndex)", level: .debug)
        isLoading = true
        defer { 
            isLoading = false
            hasLoaded = true
        }
        
        let page = book.pages[pageIndex]
        
        // Load or use cached segmented words
        let words: [AppWordSegment]
        if page.words.isEmpty {
            // Segment on demand
            LoggingService.shared.reading("✂️ Segmenting page \(pageIndex) on demand", level: .debug)
            words = await viewModel.getSegmentedWords(for: page.extractedText)
        } else {
            LoggingService.shared.reading("✅ Using cached words for page \(pageIndex)", level: .debug)
            words = page.words
        }
        
        pageContent = PageContent(
            words: words,
            markedWords: page.wordsMarked
        )
        LoggingService.shared.reading("✅ Page \(pageIndex) loaded with \(words.count) words", level: .debug)
    }
}

// MARK: - Page Content Model
private struct PageContent {
    let words: [AppWordSegment]
    let markedWords: Set<String>
}

// MARK: - Segmented Text View
private struct SegmentedTextView: View {
    let segmentedWords: [AppWordSegment]
    let markedWords: Set<String>
    let selectedWord: AppWordSegment?
    let viewModel: ReadingViewModel
    let onWordSelected: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Display segmented words in natural flowing text layout
            FlowingTextLayout {
                ForEach(segmentedWords) { wordSegment in
                    WordButton(
                        wordSegment: wordSegment,
                        isSelected: selectedWord?.id == wordSegment.id,
                        isMarked: markedWords.contains(wordSegment.word)
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

// MARK: - Page Separator View
private struct PageSeparatorView: View {
    @Environment(\.colorScheme) private var colorScheme
    let pageNumber: Int
    
    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Divider()
                .background(colors.divider)
            
            HStack {
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(colors.textSecondary)
                Text("Continue to page \(pageNumber + 1)")
                    .captionSmallStyle()
                    .foregroundColor(colors.textSecondary)
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(colors.textSecondary)
            }
            
            Divider()
                .background(colors.divider)
        }
    }
}

// MARK: - End of Book View
private struct EndOfBookView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(colors.success)
            
            Text("End of Book")
                .headingStyle()
            
            Text("You've reached the last page")
                .bodySecondaryStyle()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
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
