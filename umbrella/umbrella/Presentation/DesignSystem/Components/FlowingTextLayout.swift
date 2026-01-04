//
//  FlowingTextLayout.swift
//  umbrella
//
//  Created by Денис on 01.01.2026.
//

import SwiftUI

/// Custom layout that arranges word buttons in natural flowing text lines
struct FlowingTextLayout: Layout {
    let horizontalSpacing: CGFloat = 2 // Small spacing between words

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var currentLineWidth: CGFloat = 0
        var maxLineHeight: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let subviewSize = subview.sizeThatFits(.unspecified)
            let spacing = index > 0 ? horizontalSpacing : 0

            // If adding this view would exceed the line width, start a new line
            if currentLineWidth + spacing + subviewSize.width > containerWidth && currentLineWidth > 0 {
                height += maxLineHeight
                currentLineWidth = subviewSize.width
                maxLineHeight = subviewSize.height
            } else {
                currentLineWidth += spacing + subviewSize.width
                maxLineHeight = max(maxLineHeight, subviewSize.height)
            }
        }

        // Add the last line's height
        height += maxLineHeight

        return CGSize(width: containerWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
        let containerWidth = bounds.width

        for (index, subview) in subviews.enumerated() {
            let subviewSize = subview.sizeThatFits(.unspecified)
            let spacing = index > 0 ? horizontalSpacing : 0

            // If adding this view would exceed the line width, start a new line
            if currentX - bounds.minX + spacing + subviewSize.width > containerWidth && currentX > bounds.minX {
                currentY += lineHeight
                currentX = bounds.minX
                lineHeight = subviewSize.height
            }

            let xPosition = currentX + (index > 0 ? spacing : 0)
            subview.place(
                at: CGPoint(x: xPosition, y: currentY),
                proposal: ProposedViewSize(width: subviewSize.width, height: subviewSize.height)
            )

            currentX = xPosition + subviewSize.width
            lineHeight = max(lineHeight, subviewSize.height)
        }
    }
}
