//
//  BookInfoDisplay.swift
//  umbrella
//
//  Created by Assistant on 2025-01-02.
//

import SwiftUI

struct BookInfoDisplay: View {
    let book: AppBook

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Pages:")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(book.totalPages)")
                    .fontWeight(.semibold)
            }

            HStack {
                Text("Title:")
                    .foregroundColor(.secondary)
                Spacer()
                Text(book.title)
                    .lineLimit(1)
                    .fontWeight(.semibold)
            }

            if let author = book.author {
                HStack {
                    Text("Author:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(author)
                        .lineLimit(1)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
