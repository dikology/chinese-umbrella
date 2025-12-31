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
    @State private var viewModel: LibraryViewModel
    @State private var showUploadSheet = false
    @State private var searchText = ""

    init(viewModel: LibraryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with search and filter
                VStack(spacing: 16) {
                    // Title and upload button
                    HStack {
                        Text("My Library")
                            .font(.title)
                            .fontWeight(.bold)

                        Spacer()

                        Button {
                            showUploadSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }

                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)

                        TextField("Search books...", text: $searchText)
                            .textFieldStyle(.plain)
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
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
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
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)

                // Book list or empty state
                if viewModel.hasBooks {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.displayBooks) { book in
                                BookListRow(
                                    book: book,
                                    onSelect: {
                                        viewModel.selectBook(book)
                                    },
                                    onDelete: {
                                        viewModel.showDeleteConfirmation(for: book)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                } else {
                    EmptyLibraryView(message: viewModel.emptyStateMessage)
                }

                Spacer()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showUploadSheet) {
                BookUploadScreen(bookUploadUseCase: DIContainer.bookUploadUseCase)
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
        }
    }
}

/// Filter pill component
struct FilterPill: View {
    let filter: BookFilter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                Text(filter.rawValue)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

/// Book list row component
struct BookListRow: View {
    let book: AppBook
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Book cover placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 80)

                    Image(systemName: book.isLocal ? "camera" : "globe")
                        .font(.title2)
                        .foregroundColor(.gray)
                }

                // Book info
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(1)

                    if let author = book.author {
                        Text(author)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 12) {
                        Text("\(book.totalPages) pages")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if book.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        } else {
                            Text("\(Int(book.readingProgress * 100))% read")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Progress indicator
                VStack {
                    Spacer()
                    CircularProgressView(progress: book.readingProgress)
                        .frame(width: 40, height: 40)
                    Spacer()
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

/// Circular progress indicator
struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))")
                .font(.caption2)
                .fontWeight(.bold)
        }
    }
}

/// Empty library state
struct EmptyLibraryView: View {
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "books.vertical")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Books Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}

// #Preview {  // Commented out for now - complex preview causing issues
//     LibraryScreen(viewModel: LibraryViewModel.preview)
// }

/// Protocol for AuthViewModel (needed for mocking)
protocol AuthViewModelProtocol {
    var isAuthenticated: Bool { get }
    var currentUser: AppUser? { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }

    func signUp(email: String, password: String) async
    func signIn(email: String, password: String) async
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async
    func logout()
}
