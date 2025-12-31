//
//  ImageProcessingService.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import UIKit

/// Protocol for image processing operations
protocol ImageProcessingService {
    /// Compress and optimize an image for OCR processing
    func processImageForOCR(_ image: UIImage) -> UIImage

    /// Validate if an image is suitable for OCR processing
    func validateImageForOCR(_ image: UIImage) -> ImageValidationResult

    /// Save an image to local storage and return the file path
    func saveImageToStorage(_ image: UIImage, filename: String) throws -> String

    /// Load an image from local storage
    func loadImageFromStorage(filename: String) -> UIImage?

    /// Delete an image from local storage
    func deleteImageFromStorage(filename: String) throws

    /// Get the documents directory path for image storage
    func getImagesDirectory() -> URL
}

/// Result of image validation
struct ImageValidationResult {
    let isValid: Bool
    let warnings: [ImageValidationWarning]
    let recommendations: [String]

    static let valid = ImageValidationResult(isValid: true, warnings: [], recommendations: [])
}

/// Warnings for image validation
enum ImageValidationWarning {
    case lowResolution(width: Int, height: Int)
    case poorLighting
    case skewed
    case blurry
    case smallFileSize
    case largeFileSize(size: Int)

    var description: String {
        switch self {
        case .lowResolution(let width, let height):
            return "Image resolution is low (\(width)x\(height)). OCR may be less accurate."
        case .poorLighting:
            return "Image appears to have poor lighting. Ensure the page is well-lit."
        case .skewed:
            return "Image appears skewed. Try to position the camera straight above the page."
        case .blurry:
            return "Image appears blurry. Hold the camera steady when capturing."
        case .smallFileSize:
            return "Image file size is very small. This may indicate a low-quality image."
        case .largeFileSize(let size):
            return "Image file size is large (\(size)MB). This may affect processing speed."
        }
    }
}

/// Default implementation of ImageProcessingService
class DefaultImageProcessingService: ImageProcessingService {
    private let maxImageSize: CGFloat = 2048 // Max dimension for processing
    private let compressionQuality: CGFloat = 0.8
    private let minResolution: CGFloat = 1000 // Minimum pixels for decent OCR
    private let maxFileSizeMB: Int = 10 // Maximum file size in MB

    func processImageForOCR(_ image: UIImage) -> UIImage {
        // Fix orientation
        let orientedImage = fixOrientation(image)

        // Resize if too large
        let processedImage = resizeImageIfNeeded(orientedImage)

        // Enhance contrast for better OCR (basic enhancement)
        return enhanceImageForOCR(processedImage)
    }

    func validateImageForOCR(_ image: UIImage) -> ImageValidationResult {
        var warnings: [ImageValidationWarning] = []
        var recommendations: [String] = []

        // Check resolution
        let width = Int(image.size.width * image.scale)
        let height = Int(image.size.height * image.scale)
        if min(width, height) < Int(minResolution) {
            warnings.append(.lowResolution(width: width, height: height))
            recommendations.append("Try taking the photo closer to the page for better resolution.")
        }

        // Check file size (rough estimate)
        let fileSizeMB = estimateFileSize(image)
        if fileSizeMB < 0.1 {
            warnings.append(.smallFileSize)
            recommendations.append("Ensure the camera settings are not compressing the image too much.")
        } else if fileSizeMB > Double(maxFileSizeMB) {
            warnings.append(.largeFileSize(size: Int(fileSizeMB)))
            recommendations.append("Consider using a lower resolution camera setting if available.")
        }

        // Basic checks (in a real implementation, you'd use computer vision)
        // For now, we'll assume images are acceptable unless obviously wrong
        let isValid = warnings.filter { warning in
            // Only critical warnings make the image invalid
            switch warning {
            case .lowResolution, .smallFileSize:
                return true // These make it invalid
            default:
                return false // These are just warnings
            }
        }.isEmpty

        return ImageValidationResult(
            isValid: isValid,
            warnings: warnings,
            recommendations: recommendations
        )
    }

    func saveImageToStorage(_ image: UIImage, filename: String) throws -> String {
        let imagesDirectory = getImagesDirectory()
        try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)

        let fileURL = imagesDirectory.appendingPathComponent(filename)
        let data = image.jpegData(compressionQuality: compressionQuality)

        guard let data = data else {
            throw ImageProcessingError.compressionFailed
        }

        try data.write(to: fileURL)
        return fileURL.path
    }

    func loadImageFromStorage(filename: String) -> UIImage? {
        let fileURL = getImagesDirectory().appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        return UIImage(data: data)
    }

    func deleteImageFromStorage(filename: String) throws {
        let fileURL = getImagesDirectory().appendingPathComponent(filename)
        try FileManager.default.removeItem(at: fileURL)
    }

    func getImagesDirectory() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("BookImages", isDirectory: true)
    }

    // MARK: - Private Methods

    private func fixOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage ?? image
    }

    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let maxDimension = max(image.size.width, image.size.height)

        guard maxDimension > maxImageSize else { return image }

        let scale = maxImageSize / maxDimension
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }

    private func enhanceImageForOCR(_ image: UIImage) -> UIImage {
        // Basic enhancement: increase contrast and brightness
        // In a real implementation, you'd use Core Image filters for better results
        let ciImage = CIImage(image: image)
        guard let ciImage = ciImage else { return image }

        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(1.1, forKey: kCIInputContrastKey) // Slight contrast increase
        filter?.setValue(0.1, forKey: kCIInputBrightnessKey) // Slight brightness increase

        guard let outputImage = filter?.outputImage else { return image }

        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    private func estimateFileSize(_ image: UIImage) -> Double {
        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            return 0
        }
        return Double(data.count) / (1024 * 1024) // Size in MB
    }
}

/// Errors that can occur during image processing
enum ImageProcessingError: LocalizedError {
    case compressionFailed
    case saveFailed(Error)
    case loadFailed
    case deleteFailed(Error)

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .saveFailed(let error):
            return "Failed to save image: \(error.localizedDescription)"
        case .loadFailed:
            return "Failed to load image"
        case .deleteFailed(let error):
            return "Failed to delete image: \(error.localizedDescription)"
        }
    }
}
