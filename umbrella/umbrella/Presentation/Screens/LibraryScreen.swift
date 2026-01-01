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
    @State private var viewModel: LibraryViewModel
    @State private var showUploadSheet = false
    @State private var showEditSheet = false
    @State private var bookToEdit: AppBook?
    @State private var searchText = ""
    @State private var selectedBook: AppBook?

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    init(viewModel: LibraryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with search and filter
                    VStack(spacing: 16) {
                        // Title and upload button
                        HStack {
                            Text("My Library")
                                .titleStyle()

                            Spacer()

                            Button {
                                showUploadSheet = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(colors.primary)
                            }
                        }

                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(colors.textSecondary)

                        TextField("Search books...", text: $searchText)
                            .adaptiveTextFieldStyle()
                            .onChange(of: searchText) { oldValue, newValue in
                                Task {
                                    await viewModel.searchBooks(query: newValue)
                                }
                            }

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                Task {
                                    await viewModel.searchBooks(query: "")
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(colors.textSecondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(colors.searchBackground)
                    .cornerRadius(8)

                    // Filter pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(BookFilter.allCases, id: \.self) { filter in
                                FilterPill(
                                    filter: filter,
                                    isSelected: viewModel.selectedFilter == filter,
                                    action: {
                                        viewModel.setFilter(filter)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Book count
                HStack {
                    Text(viewModel.bookCountText)
                        .bodySecondaryStyle()
                    Spacer()
                }
                .padding(.horizontal)

                // Book list or empty state
                if viewModel.hasBooks {
                    List(viewModel.displayBooks) { book in
                        BookListRow(
                            book: book,
                            onSelect: {
                                selectedBook = book
                            }
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .leading) {
                            Button(action: {
                                LoggingService.shared.debug("LibraryScreen: Setting bookToEdit to book with title: \(book.title), pages: \(book.totalPages)")
                                bookToEdit = book
                                showEditSheet = true
                            }) {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(colors.primary)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive, action: {
                                viewModel.showDeleteConfirmation(for: book)
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .listStyle(.plain)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                } else {
                    EmptyLibraryView(message: viewModel.emptyStateMessage)
                }

                Spacer()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showUploadSheet) {
                if let userId = viewModel.currentUserId {
                    BookUploadScreen(
                        bookUploadUseCase: DIContainer.bookUploadUseCase,
                        userId: userId,
                        onBookUploaded: {
                            Task {
                                await viewModel.loadBooks()
                            }
                        }
                    )
                }
            }
            .sheet(isPresented: $showEditSheet) {
                if let book = bookToEdit {
                    EditBookScreen(
                        book: book,
                        editBookUseCase: DIContainer.editBookUseCase,
                        onBookEdited: {
                            Task {
                                await viewModel.loadBooks()
                            }
                        }
                    )
                } else {
                    EmptyView()
                }
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
            }
            .alert("Delete Book", isPresented: $viewModel.showDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    viewModel.cancelDelete()
                }
                Button("Delete", role: .destructive) {
                    viewModel.confirmDelete()
                }
            } message: {
                if let book = viewModel.bookToDelete {
                    Text("Are you sure you want to delete '\(book.title)'? This action cannot be undone.")
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadBooks()
                }
            }
            .navigationDestination(item: $selectedBook) { book in
                ReadingScreen(book: book)
            }
        }
    }
}

/// Filter pill component
struct FilterPill: View {
    @Environment(\.colorScheme) private var colorScheme

    let filter: BookFilter
    let isSelected: Bool
    let action: () -> Void

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                Text(filter.rawValue)
                    .font(.bodySecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? colors.primary : colors.filterInactive)
            .foregroundColor(isSelected ? .white : colors.textPrimary)
            .cornerRadius(20)
        }
    }
}

/// Book list row component
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
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colors.filterInactive)
                            .frame(width: 60, height: 80)

                        Image(systemName: book.isLocal ? "camera" : "globe")
                            .font(.title2)
                            .foregroundColor(colors.textSecondary)
                    }

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

                            if book.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(colors.success)
                                    .font(.caption)
                            } else {
                                Text("\(Int(book.readingProgress * 100))% read")
                                    .captionStyle()
                            }
                        }
                    }

                    Spacer()

                    // Progress indicator
                    VStack {
                        Spacer()
                        CircularProgressIndicator(progress: book.readingProgress, size: 40)
                        Spacer()
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}


/// Empty library state
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

#Preview {
    LibraryScreen(viewModel: LibraryViewModel.preview)
}

