//
//  LibraryScreen.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import SwiftUI
import AuthenticationServices

/// Main library screen showing user's book collection
struct LibraryScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    let viewModel: LibraryViewModel
    let diContainer: DIContainer
    @State private var showUploadSheet = false
    @State private var showEditSheet = false
    @State private var bookToEdit: AppBook?
    @State private var searchText = ""
    @State private var selectedBook: AppBook?

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    init(viewModel: LibraryViewModel, diContainer: DIContainer) {
        self.viewModel = viewModel
        self.diContainer = diContainer
    }

    // MARK: - Header Section
    private var headerSection: some View {
        LibraryHeader(
            onAddBook: { showUploadSheet = true },
            searchText: $searchText,
            selectedFilter: viewModel.selectedFilter,
            onFilterChange: viewModel.setFilter
        )
    }

    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: 0) {
            BookCountHeader(bookCountText: viewModel.bookCountText)

            if viewModel.hasBooks {
                BookListView(
                    books: viewModel.displayBooks,
                    onSelect: { selectedBook = $0 },
                    onEdit: { bookToEdit = $0; showEditSheet = true },
                    onDelete: viewModel.showDeleteConfirmation
                )
            } else {
                EmptyLibraryView(message: viewModel.emptyStateMessage)
            }

            Spacer()
        }
    }

    // MARK: - Sheet Content
    private var uploadSheetContent: some View {
        Group {
            if let userId = viewModel.currentUserId {
                BookUploadScreen(
                    bookUploadUseCase: diContainer.bookUploadUseCase,
                    userId: userId,
                    onBookUploaded: {
                        Task {
                            await viewModel.loadBooks()
                        }
                    }
                )
            } else {
                EmptyView()
            }
        }
    }

    private var editSheetContent: some View {
        Group {
            if let book = bookToEdit {
                EditBookScreen(
                    book: book,
                    editBookUseCase: diContainer.editBookUseCase,
                    onBookEdited: {
                        LoggingService.shared.debug("LibraryScreen: onBookEdited callback triggered")
                        Task {
                            await viewModel.loadBooks()
                            LoggingService.shared.debug("LibraryScreen: loadBooks completed after book edit")
                        }
                    }
                )
            } else {
                EmptyView()
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    headerSection
                    mainContent
                }
            }
            .loadingOverlay(isPresented: viewModel.isLoading, message: "Loading books...")
            .navigationBarHidden(true)
            .sheet(isPresented: $showUploadSheet) {
                uploadSheetContent
            }
            .sheet(isPresented: $showEditSheet) {
                editSheetContent
            }
            .onChange(of: showEditSheet) { oldValue, newValue in
                if newValue {
                    if bookToEdit != nil {
                        LoggingService.shared.debug("LibraryScreen: Presenting EditBookScreen for book: \(bookToEdit!.title)")
                    } else {
                        LoggingService.shared.warning("LibraryScreen: Attempting to show EditBookScreen but bookToEdit is nil")
                    }
                }
            }
            .alert("Delete Book", isPresented: Binding(
                get: { viewModel.showDeleteAlert },
                set: { viewModel.showDeleteAlert = $0 }
            )) {
                Button("Cancel", role: .cancel) {
                    viewModel.cancelDelete()
                }
                Button("Delete", role: .destructive) {
                    viewModel.confirmDelete()
                }
            } message: {
                Text(viewModel.bookToDelete.map { "Are you sure you want to delete '\($0.title)'? This action cannot be undone." } ?? "Are you sure you want to delete this book?")
            }
            .alert(item: Binding(
                get: { viewModel.errorAlert },
                set: { viewModel.errorAlert = $0 }
            )) { (error: ErrorAlert) in
                Alert(
                    title: Text(error.title),
                    message: Text(error.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                Task {
                    await viewModel.loadBooks()
                }
            }
            .navigationDestination(item: $selectedBook) { book in
                ReadingScreen(book: book, userId: viewModel.currentUserId ?? UUID(), diContainer: diContainer)
                    .environment(\.managedObjectContext, diContainer.coreDataManager.viewContext)
            }
        }
    }
}

/// Book count header component
private struct BookCountHeader: View {
    let bookCountText: String

    var body: some View {
        HStack {
            Text(bookCountText)
                .bodySecondaryStyle()
            Spacer()
        }
        .padding(.horizontal)
    }
}

/// Book list view component with swipe actions
private struct BookListView: View {
    @Environment(\.colorScheme) private var colorScheme

    let books: [AppBook]
    let onSelect: (AppBook) -> Void
    let onEdit: (AppBook) -> Void
    let onDelete: (AppBook) -> Void

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    var body: some View {
        List(books) { book in
            BookListRow(
                book: book,
                onSelect: {
                    LoggingService.shared.debug("LibraryScreen: Book selected: '\(book.title)' with \(book.totalPages) pages")
                    onSelect(book)
                }
            )
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .swipeActions(edge: .trailing) {
                Button(role: .destructive, action: {
                    onDelete(book)
                }) {
                    Label("Delete", systemImage: "trash")
                }
                Button(action: {
                    LoggingService.shared.debug("LibraryScreen: Setting bookToEdit to book with title: \(book.title), pages: \(book.totalPages)")
                    onEdit(book)
                }) {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(colors.primary)
            }
        }
        .listStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

/// Library header component containing title, add button, search, and filters
private struct LibraryHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    let onAddBook: () -> Void
    @Binding var searchText: String
    let selectedFilter: BookFilter
    let onFilterChange: (BookFilter) -> Void

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Title and upload button
            HStack {
                Text("Library")
                    .titleStyle()

                Spacer()

                Button(action: onAddBook) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(colors.primary)
                }
            }

            // Search bar (Phase 3+)
//            HStack {
//                Image(systemName: "magnifyingglass")
//                    .foregroundColor(colors.textSecondary)
//
//                TextField("Search books...", text: $searchText)
//                    .adaptiveTextFieldStyle()
//                    .onChange(of: searchText) { oldValue, newValue in
//                        Task {
//                            await viewModel.searchBooks(query: newValue)
//                        }
//                    }
//
//                if !searchText.isEmpty {
//                    Button {
//                        searchText = ""
//                        Task {
//                            await viewModel.searchBooks(query: "")
//                        }
//                    } label: {
//                        Image(systemName: "xmark.circle.fill")
//                            .foregroundColor(colors.textSecondary)
//                    }
//                }
//            }
//            .padding(12)
//            .background(colors.searchBackground)
//            .cornerRadius(8)

            // Filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BookFilter.allCases, id: \.self) { filter in
                        FilterPill(
                            filter: filter,
                            isSelected: selectedFilter == filter,
                            action: { onFilterChange(filter) }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
}





#Preview {
    LibraryScreen(viewModel: LibraryViewModel.preview, diContainer: DIContainer.preview)
        .environment(\.managedObjectContext, DIContainer.preview.coreDataManager.viewContext)
}

