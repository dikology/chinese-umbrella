//
//  Book.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation

/// Represents a book in the user's library
public struct AppBook: Identifiable, Codable, Hashable {
    public let id: UUID
    public let title: String
    public let author: String?
    public let pages: [AppBookPage]
    public let createdDate: Date
    public var updatedDate: Date
    public var currentPageIndex: Int
    public var isLocal: Bool // true for user-uploaded, false for public library

    init(
        id: UUID = UUID(),
        title: String,
        author: String? = nil,
        pages: [AppBookPage] = [],
        currentPageIndex: Int = 0,
        isLocal: Bool = true
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.pages = pages
        self.currentPageIndex = currentPageIndex
        self.isLocal = isLocal
        self.createdDate = Date()
        self.updatedDate = Date()
    }

    // MARK: - Computed Properties

    var currentPage: AppBookPage? {
        guard pages.indices.contains(currentPageIndex) else { return nil }
        return pages[currentPageIndex]
    }

    var totalPages: Int {
        pages.count
    }

    var readingProgress: Double {
        guard totalPages > 0 else { return 0.0 }
        return Double(currentPageIndex + 1) / Double(totalPages)
    }

    var isCompleted: Bool {
        currentPageIndex >= totalPages - 1
    }

    // MARK: - Validation

    var isValid: Bool {
        !title.isEmpty && totalPages >= 0 && currentPageIndex >= 0
    }

    // MARK: - Navigation Methods

    mutating func nextPage() -> Bool {
        guard currentPageIndex < totalPages - 1 else { return false }
        currentPageIndex += 1
        updatedDate = Date()
        return true
    }

    mutating func previousPage() -> Bool {
        guard currentPageIndex > 0 else { return false }
        currentPageIndex -= 1
        updatedDate = Date()
        return true
    }

    mutating func goToPage(_ index: Int) -> Bool {
        guard pages.indices.contains(index) else { return false }
        currentPageIndex = index
        updatedDate = Date()
        return true
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: AppBook, rhs: AppBook) -> Bool {
        lhs.id == rhs.id
    }
}
