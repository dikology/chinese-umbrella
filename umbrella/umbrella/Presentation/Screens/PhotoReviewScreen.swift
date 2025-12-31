//
//  PhotoReviewScreen.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import SwiftUI

/// Screen for reviewing and editing selected photos before processing
struct PhotoReviewScreen: View {
    @Binding var images: [UIImage]
    @Environment(\.dismiss) private var dismiss

    @State private var selectedIndices = Set<Int>()
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Review Photos")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Check and organize your selected photos")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Photo grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(images.indices, id: \.self) { index in
                            PhotoReviewItem(
                                image: images[index],
                                pageNumber: index + 1,
                                isSelected: selectedIndices.contains(index),
                                onTap: {
                                    toggleSelection(for: index)
                                },
                                onDelete: {
                                    deleteImage(at: index)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                // Selection controls
                if !selectedIndices.isEmpty {
                    VStack(spacing: 12) {
                        HStack {
                            Text("\(selectedIndices.count) selected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            Button {
                                selectedIndices.removeAll()
                            } label: {
                                Text("Clear Selection")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)

                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Selected")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 16)
                    .background(Color.gray.opacity(0.05))
                }

                // Bottom instructions
                VStack(spacing: 8) {
                    Text("Tap photos to select multiple")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Swipe left on individual photos to delete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)

                // Done button
                Button {
                    dismiss()
                } label: {
                    Text("Continue with \(images.count) photo\(images.count == 1 ? "" : "s")")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(images.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(images.isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Photos", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteSelectedImages()
                }
            } message: {
                Text("Are you sure you want to delete \(selectedIndices.count) selected photo\(selectedIndices.count == 1 ? "" : "s")?")
            }
        }
    }

    private func toggleSelection(for index: Int) {
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }

    private func deleteImage(at index: Int) {
        images.remove(at: index)
        // Adjust selected indices after removal
        selectedIndices = Set(selectedIndices.compactMap { selectedIndex in
            if selectedIndex < index {
                return selectedIndex
            } else if selectedIndex > index {
                return selectedIndex - 1
            } else {
                return nil
            }
        })
    }

    private func deleteSelectedImages() {
        // Sort indices in descending order to delete from end first
        let sortedIndices = selectedIndices.sorted(by: >)
        for index in sortedIndices {
            images.remove(at: index)
        }
        selectedIndices.removeAll()
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
    // Sample images for preview
    let sampleImages: [UIImage] = [
        UIImage(systemName: "photo")!,
        UIImage(systemName: "photo.fill")!,
        UIImage(systemName: "photo.artframe")!,
        UIImage(systemName: "photo.circle")!
    ]

    return PhotoReviewScreen(images: .constant(sampleImages))
}
