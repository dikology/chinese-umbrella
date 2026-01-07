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
    @State private var scrollViewID = UUID()

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
                        scrollViewID: scrollViewID,
                        onWordSelected: {
                            showingDictionaryPopup = true
                        },
                        onPageChange: { newPageIndex in
                            Task {
                                await viewModel.updateCurrentPageIndex(newPageIndex)
                            }
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
            Button(action: {
                Task { 
                    await viewModel.previousPage()
                    scrollViewID = UUID() // Force scroll to top
                }
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
                Task { 
                    await viewModel.nextPage()
                    scrollViewID = UUID() // Force scroll to top
                }
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

// MARK: - Multi-Page Content View with Lazy Loading
private struct MultiPageContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let viewModel: ReadingViewModel
    let scrollViewID: UUID
    let onWordSelected: () -> Void
    let onPageChange: (Int) -> Void
    
    @State private var visiblePageIndices: Set<Int> = []
    @State private var currentVisiblePage: Int = 0
    @State private var isProgrammaticScroll: Bool = false
    @State private var pageChangeTask: Task<Void, Never>?
    
    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }
    
    // Determine how many pages to prefetch based on device
    private var prefetchRange: Int {
        // On iPad, show more pages at once
        horizontalSizeClass == .regular ? 3 : 2
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.isLoading {
                        ProgressView("Loading book...")
                            .padding()
                    } else if let book = viewModel.currentBook {
                        // Display pages starting from current page, with prefetching
                        ForEach(Array(visiblePageRange(book: book).enumerated()), id: \.element) { _, pageIndex in
                            SinglePageContentView(
                                pageIndex: pageIndex,
                                viewModel: viewModel,
                                onWordSelected: onWordSelected
                            )
                            .id(pageIndex)
                            .onAppear {
                                LoggingService.shared.reading("📄 Page \(pageIndex) appeared. isProgrammatic: \(isProgrammaticScroll), currentVisible: \(currentVisiblePage)", level: .debug)
                                
                                visiblePageIndices.insert(pageIndex)
                                
                                // Only update current page if this is a user scroll (not programmatic)
                                if !isProgrammaticScroll {
                                    // Debounce page changes to avoid rapid updates
                                    pageChangeTask?.cancel()
                                    pageChangeTask = Task {
                                        // Wait a bit to see if user is still scrolling
                                        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                                        
                                        guard !Task.isCancelled else { return }
                                        
                                        // Update current page when it becomes visible via user scroll
                                        if pageIndex != currentVisiblePage {
                                            LoggingService.shared.reading("📍 Updating current page from \(currentVisiblePage) to \(pageIndex) (user scroll)", level: .info)
                                            currentVisiblePage = pageIndex
                                            onPageChange(pageIndex)
                                        }
                                    }
                                }
                                
                                // Prefetch next page if we're at the end of visible range
                                if pageIndex == visiblePageRange(book: book).last,
                                   pageIndex < book.totalPages - 1 {
                                    LoggingService.shared.reading("⏳ Prefetching page \(pageIndex + 1)", level: .debug)
                                    Task {
                                        await viewModel.prefetchPage(pageIndex + 1)
                                    }
                                }
                            }
                            .onDisappear {
                                LoggingService.shared.reading("👋 Page \(pageIndex) disappeared", level: .debug)
                                visiblePageIndices.remove(pageIndex)
                            }
                            
                            // Page separator
                            if pageIndex < book.totalPages - 1 {
                                PageSeparatorView(pageNumber: pageIndex + 1)
                                    .padding(.vertical, 24)
                            }
                        }
                        
                        // End of book indicator
                        if visiblePageRange(book: book).contains(book.totalPages - 1) {
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
            .id(scrollViewID)
            .onChange(of: viewModel.currentPageIndex) { oldIndex, newIndex in
                // Only scroll programmatically if we're not already at that page
                // This prevents feedback loops from scroll-based navigation
                if oldIndex != newIndex && currentVisiblePage != newIndex {
                    LoggingService.shared.reading("🔄 ViewModel page index changed: \(oldIndex) -> \(newIndex), triggering programmatic scroll", level: .info)
                    isProgrammaticScroll = true
                    currentVisiblePage = newIndex
                    
                    withAnimation {
                        proxy.scrollTo(newIndex, anchor: .top)
                    }
                    
                    // Reset programmatic scroll flag after animation completes
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        isProgrammaticScroll = false
                        LoggingService.shared.reading("✅ Programmatic scroll completed", level: .debug)
                    }
                } else if currentVisiblePage == newIndex {
                    LoggingService.shared.reading("⏭️ Skipping scroll: already at page \(newIndex)", level: .debug)
                }
            }
            .onAppear {
                // Initialize current visible page
                currentVisiblePage = viewModel.currentPageIndex
                LoggingService.shared.reading("🚀 MultiPageContentView appeared, starting at page \(currentVisiblePage)", level: .info)
            }
        }
    }
    
    // Calculate the range of pages to display
    private func visiblePageRange(book: AppBook) -> Range<Int> {
        let startIndex = max(0, viewModel.currentPageIndex - 1)
        let endIndex = min(book.totalPages, viewModel.currentPageIndex + prefetchRange)
        return startIndex..<endIndex
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
