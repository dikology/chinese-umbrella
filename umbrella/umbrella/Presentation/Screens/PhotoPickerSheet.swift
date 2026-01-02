//
//  PhotoPickerSheet.swift
//  umbrella
//
//  Created by Assistant on 2025-01-02.
//

import SwiftUI

struct PhotoPickerSheet: View {
    @Binding var selectedPages: [PageItem]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        PhotoPickerView(selectedImages: .init(
            get: { [] },
            set: { images in
                let newPages = images.enumerated().map { index, image in
                    PageItem(
                        id: UUID(),
                        uiImage: image,
                        pageNumber: selectedPages.count + index + 1,
                        position: selectedPages.count + index
                    )
                }
                selectedPages.append(contentsOf: newPages)
                dismiss()
            }
        ))
    }
}
