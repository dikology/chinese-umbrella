//
//  BookUploadViewModel+PageManagement.swift
//  umbrella
//
//  Created by Assistant on 2025-01-02.
//

import SwiftUI
import Foundation

// MARK: - Page Item Data Model
struct PageItem: Identifiable, Equatable {
    let id: UUID
    let uiImage: UIImage
    var pageNumber: Int?
    var notes: String = ""
    var position: Int // For reordering

    /// Generate thumbnail for grid display
    var thumbnail: UIImage? {
        let targetSize = CGSize(width: 120, height: 160)
        return uiImage.resized(to: targetSize)
    }

    static func == (lhs: PageItem, rhs: PageItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - View Model Extension
extension BookUploadViewModel {
    @MainActor
    func addPages(_ images: [UIImage]) {
        let newPages = images.enumerated().map { index, image in
            PageItem(
                id: UUID(),
                uiImage: image,
                pageNumber: pageList.count + index + 1,
                position: pageList.count + index
            )
        }
        pageList.append(contentsOf: newPages)
    }

    @MainActor
    func removePage(at index: Int) {
        guard index >= 0 && index < pageList.count else { return }
        pageList.remove(at: index)
        // Recalculate positions
        for (idx, _) in pageList.enumerated() {
            pageList[idx].position = idx
        }
    }

    @MainActor
    func reorderPages(from source: IndexSet, to destination: Int) {
        pageList.move(fromOffsets: source, toOffset: destination)
        // Recalculate positions
        for (idx, _) in pageList.enumerated() {
            pageList[idx].position = idx
        }
    }

    @MainActor
    func updatePageNumber(for page: PageItem, number: Int) {
        if let index = pageList.firstIndex(where: { $0.id == page.id }) {
            pageList[index].pageNumber = number
        }
    }
}
