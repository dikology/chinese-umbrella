//
//  PhotoPickerView.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import SwiftUI
import PhotosUI

/// A SwiftUI view that provides photo picker functionality for selecting existing photos
struct PhotoPickerView: View {
    @Binding var selectedImages: [UIImage]
    @State private var selectedItems: [PhotosPickerItem] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Select Photos")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Choose photos of book pages from your library")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Photo picker
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 50,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)

                        Text("Tap to select photos")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("You can select multiple pages at once")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Selected images preview
                if !selectedImages.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selected Photos (\(selectedImages.count))")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(selectedImages.indices, id: \.self) { index in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: selectedImages[index])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )

                                        // Remove button
                                        Button {
                                            removeImage(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .background(Color.black.opacity(0.6))
                                                .clipShape(Circle())
                                                .font(.system(size: 16))
                                        }
                                        .offset(x: 6, y: -6)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 16)
                }

                Spacer()

                // Bottom buttons
                VStack(spacing: 12) {
                    if !selectedImages.isEmpty {
                        Button {
                            dismiss()
                        } label: {
                            Text("Continue with \(selectedImages.count) photo\(selectedImages.count == 1 ? "" : "s")")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .onChange(of: selectedItems) { oldValue, newValue in
            loadSelectedImages()
        }
    }

    private func loadSelectedImages() {
        selectedImages.removeAll()

        let dispatchGroup = DispatchGroup()

        for item in selectedItems {
            dispatchGroup.enter()
            item.loadTransferable(type: Data.self) { result in
                switch result {
                case .success(let data):
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.selectedImages.append(image)
                        }
                    }
                case .failure(let error):
                    print("Error loading image: \(error)")
                }
                dispatchGroup.leave()
            }
        }

        // Sort images by selection order (approximate)
        dispatchGroup.notify(queue: .main) {
            // PhotosUI doesn't guarantee order, but we can try to maintain some order
            // For now, we'll just keep them as loaded
        }
    }

    private func removeImage(at index: Int) {
        selectedImages.remove(at: index)
        // Also remove from selectedItems if possible
        if index < selectedItems.count {
            selectedItems.remove(at: index)
        }
    }
}

#Preview {
    PhotoPickerView(selectedImages: .constant([]))
}
