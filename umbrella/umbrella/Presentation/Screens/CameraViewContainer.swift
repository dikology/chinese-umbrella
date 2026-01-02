//
//  CameraViewContainer.swift
//  umbrella
//
//  Created by Assistant on 2025-01-02.
//

import SwiftUI

struct CameraViewContainer: View {
    @Binding var pageList: [PageItem]
    @Binding var isPresented: Bool
    @State private var capturedImages: [UIImage] = []

    var body: some View {
        ZStack(alignment: .topLeading) {
            CameraView(capturedImages: $capturedImages)
                .onChange(of: capturedImages) { oldValue, newValue in
                    // Convert captured images to PageItems and add to pageList
                    if newValue.count > oldValue.count {
                        let newImages = newValue.suffix(newValue.count - oldValue.count)
                        let newPages = newImages.enumerated().map { index, image in
                            PageItem(
                                id: UUID(),
                                uiImage: image,
                                pageNumber: pageList.count + index + 1,
                                position: pageList.count + index
                            )
                        }
                        pageList.append(contentsOf: newPages)
                        isPresented = false
                    }
                }

            // Close button
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
                    .padding()
            }
        }
        .ignoresSafeArea()
    }
}
