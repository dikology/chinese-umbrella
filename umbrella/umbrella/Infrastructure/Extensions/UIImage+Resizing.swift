//
//  UIImage+Resizing.swift
//  umbrella
//
//  Created by Assistant on 2025-01-02.
//

import UIKit

extension UIImage {
    /// Resize the image to fit within the specified size while maintaining aspect ratio
    func resized(to targetSize: CGSize) -> UIImage? {
        let size = self.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Use the smaller ratio to ensure the image fits within the target size
        let scaleFactor = min(widthRatio, heightRatio)

        let scaledSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        UIGraphicsBeginImageContextWithOptions(scaledSize, false, scale)
        draw(in: CGRect(origin: .zero, size: scaledSize))

        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }
}
