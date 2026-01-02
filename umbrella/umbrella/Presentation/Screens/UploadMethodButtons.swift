//
//  UploadMethodButtons.swift
//  umbrella
//
//  Created by Assistant on 2025-01-02.
//

import SwiftUI

struct UploadMethodButtons: View {
    let onCameraTap: () -> Void
    let onLibraryTap: () -> Void
    @Environment(\.colorScheme) var colorScheme

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onCameraTap) {
                Label("Take Photos", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(colors.blueTint)
                    .foregroundColor(colors.primary)
                    .cornerRadius(12)
            }

            Button(action: onLibraryTap) {
                Label("Select from Library", systemImage: "photo.on.rectangle.angled")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(colors.greenTint)
                    .foregroundColor(colors.success)
                    .cornerRadius(12)
            }
        }
    }
}
