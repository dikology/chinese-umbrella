//
//  PageGridView.swift
//  umbrella
//
//  Created by Assistant on 2025-01-02.
//

import SwiftUI

struct PageGridView: View {
    @Binding var pages: [PageItem]
    @State private var editingPage: PageItem?
    @State private var isEditing = false

    // Optional existing pages for editing existing books
    var existingPages: [ExistingPageItem]? = nil
    var onReorderExistingPages: ((IndexSet, Int) -> Void)? = nil

    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 12)
    ]

    private var displayTitle: String {
        if let existingPages = existingPages {
            return "Existing Pages (\(existingPages.count))"
        } else {
            return "Pages (\(pages.count))"
        }
    }

    private var hasPages: Bool {
        if let existingPages = existingPages {
            return !existingPages.isEmpty
        } else {
            return !pages.isEmpty
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(displayTitle)
                    .font(.headline)

                Spacer()

                if hasPages {
                    Menu {
                        Button("Renumber from 1", action: renumberPages)
                        Button("Sort by number", action: sortByNumber)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)

            if !hasPages {
                ContentUnavailableView(
                    "No Pages Yet",
                    systemImage: "photo.stack",
                    description: Text("Add photos to get started")
                )
                .frame(height: 200)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        // Show existing pages if available
                        if let existingPages = existingPages {
                            ForEach(Array(existingPages.enumerated()), id: \.element.id) { index, page in
                                ExistingPageThumbnailCard(
                                    page: page,
                                    isEditing: isEditing
                                )
                            }
                            .onMove(perform: onReorderExistingPages)
                        } else {
                            // Show new pages
                            ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                                PageThumbnailCard(
                                    page: page,
                                    onEdit: { editingPage = page },
                                    onDelete: { pages.remove(at: index) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
                }

                // Reorder mode toggle
                if hasPages {
                    Button(isEditing ? "Done" : "Reorder") {
                        isEditing.toggle()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                }
            }
        }
    }

    private func renumberPages() {
        for (index, _) in pages.enumerated() {
            pages[index].pageNumber = index + 1
        }
    }

    private func sortByNumber() {
        pages.sort { ($0.pageNumber ?? 0) < ($1.pageNumber ?? 0) }
    }
}

// MARK: - Page Thumbnail Card
struct PageThumbnailCard: View {
    let page: PageItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.editMode) var editMode

    var isInEditMode: Bool {
        editMode?.wrappedValue == .active
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Thumbnail
            if let thumbnail = page.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 160)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            }

            // Page number badge
            if let pageNumber = page.pageNumber {
                Text("\(pageNumber)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .padding(8)
            }

            // Delete button (edit mode)
            if isInEditMode {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .padding(4)
                }
            }
        }
        .onTapGesture {
            if !isInEditMode {
                onEdit()
            }
        }
    }
}

// MARK: - Existing Page Thumbnail Card
struct ExistingPageThumbnailCard: View {
    let page: ExistingPageItem
    let isEditing: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Thumbnail placeholder (we don't have actual thumbnails for existing pages yet)
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 160)

                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)

                    Text("Page \(page.pageNumber)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )

            // Reorder handle (shown in edit mode)
            if isEditing {
                Image(systemName: "line.horizontal.3")
                    .foregroundColor(.blue)
                    .padding(4)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
                    .padding(8)
            }
        }
    }
}
