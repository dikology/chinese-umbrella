//
//  PhotoReviewScreen.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import SwiftUI

/// Screen for reviewing and editing selected photos before processing
struct PhotoReviewScreen: View {
    @Binding var pages: [PageItem]
    @Environment(\.dismiss) private var dismiss
    @State private var currentPageIndex = 0
    @State private var showPageNumberEditor = false
    @State private var pageNumberInput = ""

    var currentPage: PageItem {
        pages[currentPageIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Full page image viewer
                VStack(spacing: 0) {
                    // Navigation bar
                    HStack {
                        Button("← Back") { dismiss() }
                        Spacer()
                        Text("Page \(currentPageIndex + 1) of \(pages.count)")
                            .font(.headline)
                        Spacer()
                        Button("Edit") {
                            pageNumberInput = String(currentPage.pageNumber ?? 0)
                            showPageNumberEditor = true
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))

                    // Image viewer
                    Image(uiImage: currentPage.uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Navigation controls
                    HStack {
                        Button(action: previousPage) {
                            Image(systemName: "chevron.left")
                                .frame(width: 44, height: 44)
                        }
                        .disabled(currentPageIndex == 0)

                        Spacer()

                        Button(action: nextPage) {
                            Image(systemName: "chevron.right")
                                .frame(width: 44, height: 44)
                        }
                        .disabled(currentPageIndex == pages.count - 1)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPageNumberEditor) {
                PageNumberEditorSheet(
                    pageIndex: currentPageIndex,
                    pages: $pages,
                    input: $pageNumberInput,
                    isPresented: $showPageNumberEditor
                )
            }
        }
    }

    private func previousPage() {
        if currentPageIndex > 0 {
            currentPageIndex -= 1
        }
    }

    private func nextPage() {
        if currentPageIndex < pages.count - 1 {
            currentPageIndex += 1
        }
    }
}

/// Individual photo item in the review grid
struct PhotoReviewItem: View {
    let image: UIImage
    let pageNumber: Int
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Photo
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                )
                .onTapGesture {
                    onTap()
                }

            // Page number badge
            Text("\(pageNumber)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.7))
                .clipShape(Capsule())
                .offset(x: -8, y: 8)

            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .background(Color.white.clipShape(Circle()))
                    .font(.system(size: 24))
                    .offset(x: 6, y: -6)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    // Sample pages for preview
    let samplePages: [PageItem] = [
        PageItem(id: UUID(), uiImage: UIImage(systemName: "photo")!, pageNumber: 1, position: 0),
        PageItem(id: UUID(), uiImage: UIImage(systemName: "photo.fill")!, pageNumber: 2, position: 1),
        PageItem(id: UUID(), uiImage: UIImage(systemName: "photo.artframe")!, pageNumber: 3, position: 2),
        PageItem(id: UUID(), uiImage: UIImage(systemName: "photo.circle")!, pageNumber: 4, position: 3)
    ]

    PhotoReviewScreen(pages: .constant(samplePages))
}
