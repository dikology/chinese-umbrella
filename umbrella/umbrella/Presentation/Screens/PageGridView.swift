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
    
    // Page number editing for existing pages
    @State private var editingPageNumber: ExistingPageItem?
    @State private var newPageNumber: String = ""
    @State private var showPageNumberEditor = false
    var onUpdatePageNumber: ((UUID, Int) -> Void)? = nil

    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 12)
    ]

    private var hasPages: Bool {
        if let existingPages = existingPages {
            return !existingPages.isEmpty
        } else {
            return !pages.isEmpty
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Debug logging for data changes
            let _ = {
                LoggingService.shared.debug("PageGridView: Rendering with \(existingPages?.count ?? 0) existing pages")
                if let pages = existingPages {
                    for (index, page) in pages.enumerated() {
                        LoggingService.shared.debug("PageGridView: Page \(index): ID=\(page.id), number=\(page.pageNumber)")
                    }
                }
            }()

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
                                    isEditing: isEditing,
                                    onTap: {
                                        if isEditing {
                                            LoggingService.shared.debug("PageGridView: Tapped page \(page.pageNumber) to edit number")
                                            editingPageNumber = page
                                            newPageNumber = "\(page.pageNumber)"
                                            showPageNumberEditor = true
                                        }
                                    }
                                )
                            }
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
                    Button(isEditing ? "Done" : "Edit Page Numbers") {
                        isEditing.toggle()
                        LoggingService.shared.debug("PageGridView: Edit mode toggled to \(isEditing)")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    
                    if isEditing && existingPages != nil {
                        Text("Tap any page to change its number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .alert("Edit Page Number", isPresented: $showPageNumberEditor) {
            TextField("Page Number", text: $newPageNumber)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) {
                LoggingService.shared.debug("PageGridView: Cancelled page number edit")
            }
            Button("Save") {
                if let page = editingPageNumber,
                   let number = Int(newPageNumber), number > 0 {
                    LoggingService.shared.info("PageGridView: Updating page \(page.id) from number \(page.pageNumber) to \(number)")
                    onUpdatePageNumber?(page.id, number)
                } else {
                    LoggingService.shared.warning("PageGridView: Invalid page number entered: \(newPageNumber)")
                }
            }
        } message: {
            if let page = editingPageNumber {
                Text("Current page number: \(page.pageNumber). Enter new page number. Pages will be reordered and renumbered sequentially after saving.")
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
    let onTap: (() -> Void)?
    
    @State private var loadedImage: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Try to load the actual page image, fallback to placeholder
            ZStack {
                if let loadedImage = loadedImage {
                    Image(uiImage: loadedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 160)
                        .clipped()
                        .cornerRadius(8)
                } else {
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
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isEditing ? Color.blue : Color.blue.opacity(0.3), lineWidth: isEditing ? 2 : 1)
            )
            
            // Page number badge - ALWAYS show the current page number
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 36, height: 36)
                
                Text("\(page.pageNumber)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
            .padding(8)
        }
        .onTapGesture {
            onTap?()
        }
        .task {
            // Load the image asynchronously
            if let image = await loadImage(from: page.originalImagePath) {
                loadedImage = image
            }
        }
    }
    
    private func loadImage(from path: String) async -> UIImage? {
        // Load image on background thread
        let fullImage = await Task.detached {
            return UIImage(contentsOfFile: path)
        }.value

        guard let fullImage = fullImage else {
            return nil
        }

        // Resize image on main thread (UIKit operations need main thread)
        return await MainActor.run {
            let targetSize = CGSize(width: 120, height: 160)
            return fullImage.resized(to: targetSize)
        }
    }
}

#Preview("Empty State") {
    PageGridView(pages: .constant([]))
        .padding()
}

#Preview("New Pages") {
    // Create mock images for preview
    let mockImage1 = createMockImage(color: .red, size: CGSize(width: 800, height: 600))
    let mockImage2 = createMockImage(color: .blue, size: CGSize(width: 800, height: 600))
    let mockImage3 = createMockImage(color: .green, size: CGSize(width: 800, height: 600))

    let mockPages = [
        PageItem(id: UUID(), uiImage: mockImage1, pageNumber: 1, position: 0),
        PageItem(id: UUID(), uiImage: mockImage2, pageNumber: 2, position: 1),
        PageItem(id: UUID(), uiImage: mockImage3, pageNumber: 3, position: 2)
    ]

    return PageGridView(pages: .constant(mockPages))
        .padding()
}

#Preview("Existing Pages - Edit Mode") {
    struct PreviewWrapper: View {
        @State private var mockExistingPages = [
            ExistingPageItem(
                id: UUID(uuidString: "9E3026A9-9EDD-47CB-8E2D-BAF6B671B198")!,
                pageNumber: 1,
                originalImagePath: "/mock/path/page1.jpg",
                extractedText: "This is the first page content",
                position: 0
            ),
            ExistingPageItem(
                id: UUID(uuidString: "E200C6ED-3E1D-4457-A7C8-CCA575DBEBE6")!,
                pageNumber: 2,
                originalImagePath: "/mock/path/page2.jpg",
                extractedText: "This is the second page content",
                position: 1
            ),
            ExistingPageItem(
                id: UUID(uuidString: "AA1AAF29-41D1-4647-9150-24433088E6FA")!,
                pageNumber: 3,
                originalImagePath: "/mock/path/page3.jpg",
                extractedText: "This is the third page content",
                position: 2
            )
        ]

        var body: some View {
            PageGridView(
                pages: .constant([]),
                existingPages: mockExistingPages,
                onUpdatePageNumber: { pageId, newNumber in
                    // Update the page number in our mock data to test UI updates
                    if let index = mockExistingPages.firstIndex(where: { $0.id == pageId }) {
                        mockExistingPages[index] = ExistingPageItem(
                            id: mockExistingPages[index].id,
                            pageNumber: newNumber,
                            originalImagePath: mockExistingPages[index].originalImagePath,
                            extractedText: mockExistingPages[index].extractedText,
                            position: mockExistingPages[index].position
                        )
                        LoggingService.shared.debug("Preview: Updated page \(pageId) to number \(newNumber)")
                    }
                }
            )
            .padding()
        }
    }

    return PreviewWrapper()
}

// MARK: - Helper Function
private func createMockImage(color: UIColor, size: CGSize) -> UIImage {
    UIGraphicsBeginImageContext(size)
    color.setFill()
    UIRectFill(CGRect(origin: .zero, size: size))

    // Add some text to make it more interesting
    let text = "Page"
    let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 40, weight: .bold),
        .foregroundColor: UIColor.white
    ]
    let textSize = text.size(withAttributes: attributes)
    let textRect = CGRect(
        x: (size.width - textSize.width) / 2,
        y: (size.height - textSize.height) / 2,
        width: textSize.width,
        height: textSize.height
    )
    text.draw(in: textRect, withAttributes: attributes)

    let image = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return image
}
