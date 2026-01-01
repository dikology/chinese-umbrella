//
//  CircularProgressIndicator.swift
//  umbrella
//
//  Created by Design System Team
//

import SwiftUI

/// Circular progress indicator with adaptive styling
struct CircularProgressIndicator: View {
    @Environment(\.colorScheme) private var colorScheme

    let progress: Double
    let size: CGFloat

    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }

    init(progress: Double, size: CGFloat = 40) {
        self.progress = progress
        self.size = size
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(colors.progressTrack, lineWidth: 4)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(colors.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Progress text
            Text("\(Int(progress * 100))")
                .font(.captionSmall)
                .fontWeight(.bold)
                .foregroundColor(colors.textPrimary)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        CircularProgressIndicator(progress: 0.75)
        CircularProgressIndicator(progress: 0.25, size: 60)
        CircularProgressIndicator(progress: 1.0)
    }
    .padding()
}
