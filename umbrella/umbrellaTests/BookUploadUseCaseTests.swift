//
//  BookUploadUseCaseTests.swift
//  umbrellaTests
//
//  Created by Денис on 31.12.2025.
//

import Testing
import UIKit
@testable import umbrella

struct BookUploadUseCaseTests {
    private let coreDataManager = CoreDataManager(inMemory: true)

    // MARK: - Setup

    private func createTestImage(width: CGFloat = 100, height: CGFloat = 100) -> UIImage {
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContext(size)
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }

    private func createMockServices() -> (
        ocrService: MockOCRService,
        imageProcessingService: MockImageProcessingService,
        textSegmentationService: MockTextSegmentationService,
        bookMetadataService: MockBookMetadataService,
        bookRepository: MockBookRepository
    ) {
        let ocrService = MockOCRService()
        let imageProcessingService = MockImageProcessingService()
        let textSegmentationService = MockTextSegmentationService()
        let bookMetadataService = MockBookMetadataService()
        let bookRepository = MockBookRepository()

        return (ocrService, imageProcessingService, textSegmentationService, bookMetadataService, bookRepository)
    }

    // MARK: - Tests

    @MainActor
    @Test func testValidateImages_withValidImages_returnsAllValid() async throws {
        // Given
        let (ocrService, imageProcessingService, textSegmentationService, bookMetadataService, bookRepository) = createMockServices()
        let useCase = DefaultBookUploadUseCase(
            ocrService: ocrService,
            imageProcessingService: imageProcessingService,
            textSegmentationService: textSegmentationService,
            bookMetadataService: bookMetadataService,
            bookRepository: bookRepository
        )

        let images = [createTestImage(), createTestImage()]

        // Mock valid image validation results
        imageProcessingService.validateResult = ImageValidationResult(
            isValid: true,
            warnings: [],
            recommendations: []
        )

        // When
        let results = useCase.validateImages(images)

        // Then
        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.isValid })
    }

    @MainActor
    @Test func testValidateImages_withInvalidImages_filtersThemOut() async throws {
        // Given
        let (ocrService, imageProcessingService, textSegmentationService, bookMetadataService, bookRepository) = createMockServices()
        let useCase = DefaultBookUploadUseCase(
            ocrService: ocrService,
            imageProcessingService: imageProcessingService,
            textSegmentationService: textSegmentationService,
            bookMetadataService: bookMetadataService,
            bookRepository: bookRepository
        )

        let images = [createTestImage(), createTestImage()]

        // Mock one valid, one invalid
        imageProcessingService.validateResults = [
            ImageValidationResult(isValid: true, warnings: [], recommendations: []),
            ImageValidationResult(isValid: false, warnings: [.lowResolution(width: 100, height: 100)], recommendations: [])
        ]

        // When
        let results = useCase.validateImages(images)

        // Then
        #expect(results.count == 2)
        #expect(results[0].isValid)
        #expect(!results[1].isValid)
    }

    @MainActor
    @Test func testProcessImage_successfulProcessing_returnsProcessedImage() async throws {
        // Given
        let (ocrService, imageProcessingService, textSegmentationService, bookMetadataService, bookRepository) = createMockServices()
        let useCase = DefaultBookUploadUseCase(
            ocrService: ocrService,
            imageProcessingService: imageProcessingService,
            textSegmentationService: textSegmentationService,
            bookMetadataService: bookMetadataService,
            bookRepository: bookRepository
        )

        let originalImage = createTestImage()
        let processedImage = createTestImage(width: 200, height: 200)

        // Mock services
        imageProcessingService.processResult = processedImage
        imageProcessingService.validateResult = ImageValidationResult(isValid: true, warnings: [], recommendations: [])
        ocrService.recognizeResult = "Sample extracted text"
        ocrService.extractTextBlocksResult = [
            TextBlock(text: "Sample", boundingBox: .zero, confidence: 0.9)
        ]
        imageProcessingService.saveResult = "/path/to/saved/image.jpg"

        // When
        let result = try await useCase.processImage(originalImage)

        // Then
        #expect(result.originalImage === originalImage)
        #expect(result.processedImage === processedImage)
        #expect(result.extractedText == "Sample extracted text")
        #expect(result.textBlocks.count == 1)
        // The filename should be a UUID string ending with .jpg
        #expect(result.filename.hasSuffix(".jpg"))
        #expect(UUID(uuidString: String(result.filename.dropLast(4))) != nil)
    }

    @MainActor
    @Test func testGenerateTitle_withEmptyTitle_extractsFromText() async throws {
        // Given
        let (ocrService, imageProcessingService, textSegmentationService, bookMetadataService, bookRepository) = createMockServices()
        let useCase = DefaultBookUploadUseCase(
            ocrService: ocrService,
            imageProcessingService: imageProcessingService,
            textSegmentationService: textSegmentationService,
            bookMetadataService: bookMetadataService,
            bookRepository: bookRepository
        )

        let textWithTitle = """
        第 一 章

        红楼梦

        作者：曹雪芹

        这是一个著名的中国古典小说...
        """

        // When
        let title = useCase.generateTitle(from: textWithTitle)

        // Then
        #expect(title == "红楼梦")
    }

    @MainActor
    @Test func testGenerateTitle_withExistingTitle_returnsExisting() async throws {
        // Given
        let (ocrService, imageProcessingService, textSegmentationService, bookMetadataService, bookRepository) = createMockServices()
        let useCase = DefaultBookUploadUseCase(
            ocrService: ocrService,
            imageProcessingService: imageProcessingService,
            textSegmentationService: textSegmentationService,
            bookMetadataService: bookMetadataService,
            bookRepository: bookRepository
        )

        // When
        let title = useCase.generateTitle(from: "Some text content")

        // Then
        #expect(title == "Some text content")
    }

    @MainActor
    @Test func testUploadBook_successfulUpload_returnsSavedBook() async throws {
        // Given
        let (ocrService, imageProcessingService, textSegmentationService, bookMetadataService, bookRepository) = createMockServices()
        let useCase = DefaultBookUploadUseCase(
            ocrService: ocrService,
            imageProcessingService: imageProcessingService,
            textSegmentationService: textSegmentationService,
            bookMetadataService: bookMetadataService,
            bookRepository: bookRepository
        )

        let images = [createTestImage(), createTestImage()]
        let userId = UUID()

        // Mock all dependencies
        imageProcessingService.validateResult = ImageValidationResult(isValid: true, warnings: [], recommendations: [])
        imageProcessingService.processResult = createTestImage(width: 200, height: 200)
        ocrService.recognizeResult = "Sample Chinese text 这是中文"
        ocrService.extractTextBlocksResult = [TextBlock(text: "Sample", boundingBox: .zero, confidence: 0.9)]
        imageProcessingService.saveResult = "/path/to/image.jpg"

        textSegmentationService.segmentResult = ["Sample", "Chinese", "text"]
        textSegmentationService.segmentWithPositionsResult = [
            AppWordSegment(word: "Sample", startIndex: 0, endIndex: 6),
            AppWordSegment(word: "Chinese", startIndex: 7, endIndex: 14),
            AppWordSegment(word: "text", startIndex: 15, endIndex: 19)
        ]

        bookMetadataService.analyzeResult = BookMetadataAnalysis(
            detectedLanguage: "zh-Hans",
            estimatedGenre: .literature,
            totalWords: 100,
            estimatedReadingTimeMinutes: 5,
            suggestedDifficulty: .intermediate,
            extractedDescription: "A sample book",
            suggestedTags: ["chinese", "literature"]
        )

        let expectedBook = AppBook(
            title: "Test Book",
            author: "Test Author",
            pages: [],
            language: "zh-Hans",
            genre: .literature,
            description: "A sample book",
            totalWords: 100,
            estimatedReadingTimeMinutes: 5,
            difficulty: .intermediate,
            tags: ["chinese", "literature"]
        )
        bookRepository.saveResult = expectedBook

        // When
        let result = try await useCase.uploadBook(images: images, title: "Test Book", author: "Test Author", userId: userId)

        // Then
        #expect(result.title == "Test Book")
        #expect(result.author == "Test Author")
        #expect(result.language == "zh-Hans")
        #expect(result.genre == .literature)
        #expect(result.totalWords == 100)
    }

    @MainActor
    @Test func testUploadBook_withNoValidImages_throwsError() async throws {
        // Given
        let (ocrService, imageProcessingService, textSegmentationService, bookMetadataService, bookRepository) = createMockServices()
        let useCase = DefaultBookUploadUseCase(
            ocrService: ocrService,
            imageProcessingService: imageProcessingService,
            textSegmentationService: textSegmentationService,
            bookMetadataService: bookMetadataService,
            bookRepository: bookRepository
        )

        let images = [createTestImage()]
        let userId = UUID()

        // Mock invalid image
        imageProcessingService.validateResult = ImageValidationResult(isValid: false, warnings: [.lowResolution(width: 100, height: 100)], recommendations: [])

        // When/Then
        await #expect(throws: BookUploadError.noValidImages) {
            try await useCase.uploadBook(images: images, title: "Test", author: nil, userId: userId)
        }
    }

    @MainActor
    @Test func testUploadBook_ocrFailure_throwsError() async throws {
        // Given
        let (ocrService, imageProcessingService, textSegmentationService, bookMetadataService, bookRepository) = createMockServices()
        let useCase = DefaultBookUploadUseCase(
            ocrService: ocrService,
            imageProcessingService: imageProcessingService,
            textSegmentationService: textSegmentationService,
            bookMetadataService: bookMetadataService,
            bookRepository: bookRepository
        )

        let images = [createTestImage()]
        let userId = UUID()

        // Mock valid image but OCR failure
        imageProcessingService.validateResult = ImageValidationResult(isValid: true, warnings: [], recommendations: [])
        imageProcessingService.processResult = createTestImage(width: 200, height: 200)
        ocrService.recognizeError = OCRError.visionError(NSError(domain: "test", code: 1))

        // When/Then
        await #expect(throws: BookUploadError.ocrFailed(page: 1, error: OCRError.visionError(NSError(domain: "test", code: 1)))) {
            try await useCase.uploadBook(images: images, title: "Test", author: nil, userId: userId)
        }
    }
}

// MARK: - Mock Services

private class MockOCRService: OCRService {
    var recognizeResult: String = ""
    var recognizeError: Error?
    var extractTextBlocksResult: [TextBlock] = []
    var extractTextBlocksError: Error?

    func recognizeText(from image: UIImage) async throws -> String {
        if let error = recognizeError {
            throw error
        }
        return recognizeResult
    }

    func extractTextBlocks(from image: UIImage) async throws -> [TextBlock] {
        if let error = extractTextBlocksError {
            throw error
        }
        return extractTextBlocksResult
    }
}

private class MockImageProcessingService: ImageProcessingService {
    var validateResult: ImageValidationResult = .init(isValid: true, warnings: [], recommendations: [])
    var validateResults: [ImageValidationResult] = []
    var processResult: UIImage?
    var saveResult: String = ""
    var loadResult: UIImage?
    var getImagesDirectoryResult: URL = URL(fileURLWithPath: "/mock/images")

    func validateImageForOCR(_ image: UIImage) -> ImageValidationResult {
        if !validateResults.isEmpty {
            return validateResults.removeFirst()
        }
        return validateResult
    }

    func processImageForOCR(_ image: UIImage) -> UIImage {
        return processResult ?? image
    }

    func saveImageToStorage(_ image: UIImage, filename: String) throws -> String {
        return saveResult.isEmpty ? filename : saveResult
    }

    func loadImageFromStorage(filename: String) -> UIImage? {
        return loadResult
    }

    func deleteImageFromStorage(filename: String) throws {
        // Mock implementation - do nothing
    }

    func getImagesDirectory() -> URL {
        return getImagesDirectoryResult
    }
}

private class MockTextSegmentationService: TextSegmentationService {
    var segmentResult: [String] = []
    var segmentError: Error?
    var segmentWithPositionsResult: [AppWordSegment] = []
    var segmentWithPositionsError: Error?

    func segment(text: String) async throws -> [String] {
        if let error = segmentError {
            throw error
        }
        return segmentResult
    }

    func segmentWithPositions(text: String) async throws -> [AppWordSegment] {
        if let error = segmentWithPositionsError {
            throw error
        }
        return segmentWithPositionsResult
    }
}

private class MockBookMetadataService: BookMetadataService {
    var analyzeResult: BookMetadataAnalysis = .init(
        detectedLanguage: nil,
        estimatedGenre: nil,
        totalWords: 0,
        estimatedReadingTimeMinutes: 0,
        suggestedDifficulty: nil,
        extractedDescription: nil,
        suggestedTags: []
    )
    var analyzeError: Error?

    func analyzeBookMetadata(images: [UIImage], title: String, author: String?) async throws -> BookMetadataAnalysis {
        if let error = analyzeError {
            throw error
        }
        return analyzeResult
    }

    func updateBookMetadata(book: AppBook, analysis: BookMetadataAnalysis) -> AppBook {
        return AppBook(
            id: book.id,
            title: book.title,
            author: book.author,
            pages: book.pages,
            currentPageIndex: book.currentPageIndex,
            isLocal: book.isLocal,
            language: book.language ?? analysis.detectedLanguage,
            genre: book.genre ?? analysis.estimatedGenre,
            description: book.description ?? analysis.extractedDescription,
            totalWords: book.totalWords ?? analysis.totalWords,
            estimatedReadingTimeMinutes: book.estimatedReadingTimeMinutes ?? analysis.estimatedReadingTimeMinutes,
            difficulty: book.difficulty ?? analysis.suggestedDifficulty,
            tags: book.tags ?? analysis.suggestedTags
        )
    }

    func detectLanguage(from text: String) -> String? {
        return "zh-Hans"
    }

    func estimateReadingDifficulty(words: [AppWordSegment], language: String?) -> ReadingDifficulty? {
        return .intermediate
    }

    func calculateBookStatistics(book: AppBook) -> BookStatistics {
        return book.statistics
    }
}

private class MockBookRepository: BookRepository {
    var saveResult: AppBook?
    var saveError: Error?
    var getResult: AppBook?
    var getError: Error?
    var getBooksResult: [AppBook] = []
    var getBooksError: Error?

    func saveBook(_ book: AppBook, userId: UUID) async throws -> AppBook {
        if let error = saveError {
            throw error
        }
        return saveResult ?? book
    }

    func getBook(by id: UUID) async throws -> AppBook? {
        if let error = getError {
            throw error
        }
        return getResult
    }

    func getBooks(for userId: UUID) async throws -> [AppBook] {
        if let error = getBooksError {
            throw error
        }
        return getBooksResult
    }

    func updateBook(_ book: AppBook) async throws -> AppBook {
        return book
    }

    func deleteBook(_ bookId: UUID) async throws {
        // Mock implementation
    }

    func searchBooks(query: String, userId: UUID) async throws -> [AppBook] {
        return []
    }

    func searchBooksWithFilters(query: String?, filters: BookSearchFilters, userId: UUID) async throws -> [AppBook] {
        return []
    }

    func getBooksByGenre(_ genre: BookGenre, userId: UUID) async throws -> [AppBook] {
        return []
    }

    func getBooksByLanguage(_ language: String, userId: UUID) async throws -> [AppBook] {
        return []
    }

    func getBooksByProgressStatus(_ status: ReadingProgressStatus, userId: UUID) async throws -> [AppBook] {
        return []
    }

    func getRecentBooks(for userId: UUID, limit: Int) async throws -> [AppBook] {
        return []
    }

    func getLibraryStatistics(userId: UUID) async throws -> LibraryStatistics {
        return LibraryStatistics(
            totalBooks: 0,
            totalWords: 0,
            totalReadingTimeMinutes: 0,
            completedBooks: 0,
            booksByGenre: [:],
            booksByLanguage: [:],
            averageReadingProgress: 0.0
        )
    }

    func updateReadingProgress(bookId: UUID, pageIndex: Int) async throws {
        // Mock implementation
    }

    func reorderPages(bookId: UUID, newPageOrder: [UUID]) async throws -> AppBook {
        // Mock implementation - return a dummy book
        return AppBook(
            title: "Mock Book",
            author: "Mock Author",
            pages: [],
            currentPageIndex: 0,
            isLocal: true
        )
    }
}
