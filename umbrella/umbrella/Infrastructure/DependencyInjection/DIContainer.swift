//
//  DIContainer.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation

/// Dependency Injection Container for the Chinese Umbrella App
/// Provides centralized access to all dependencies following Clean Architecture
///
/// Phase 1 (Week 5-6): Camera integration, photo picker, image handling
/// Added book upload functionality with OCR processing
class DIContainer {
    // MARK: - Domain Layer

    // Use Cases
    lazy var authUseCase = AuthUseCase(repository: authRepository, keychainService: keychainService)
    lazy var bookMetadataService = DefaultBookMetadataService()
    lazy var bookUploadUseCase = DefaultBookUploadUseCase(
        ocrService: ocrService,
        imageProcessingService: imageProcessingService,
        textSegmentationService: textSegmentationService,
        bookMetadataService: bookMetadataService,
        bookRepository: bookRepository
    )

    lazy var editBookUseCase = DefaultEditBookUseCase(
        ocrService: ocrService,
        imageProcessingService: imageProcessingService,
        textSegmentationService: textSegmentationService,
        bookRepository: bookRepository
    )
    // static let readingUseCase = ReadingUseCase(repository: readingProgressRepository, dictionaryRepository: dictionaryRepository)
    // static let wordMarkingUseCase = WordMarkingUseCase(repository: wordMarkerRepository)
    // static let proficiencyCalculationUseCase = ProficiencyCalculationUseCase(repository: proficiencyRepository)
    // static let libraryManagementUseCase = LibraryManagementUseCase(repository: bookRepository)

    // MARK: - Data Layer

    // Repositories - Currently implemented
    lazy var authRepository = AuthRepositoryImpl()
    private(set) var bookRepository: BookRepository!
    lazy var dictionaryService = CEDICTDictionaryService()
    lazy var dictionaryRepository = DictionaryRepositoryImpl(dictionaryService: dictionaryService)
    lazy var wordMarkerRepository = WordMarkerRepositoryImpl()

    // TODO: Implement in future phases
    // static let readingProgressRepository = ReadingProgressRepositoryImpl()
    // static let proficiencyRepository = ProficiencyRepositoryImpl()
    // static let userPreferencesRepository = UserPreferencesRepositoryImpl()

    // MARK: - Infrastructure Layer

    // Services
    lazy var keychainService = KeychainService()
    lazy var ocrService = AppleVisionOCRService()
    lazy var imageProcessingService = DefaultImageProcessingService()
    lazy var textSegmentationService = LocalTextSegmentationService(dictionaryService: dictionaryService)
    // static let notificationService = NotificationService()
    // static let storageService = FileSystemStorageService()
    // static let loggingService = ConsoleLoggingService()

    // MARK: - Data Sources

    // TODO: Implement in future phases
    // static let apiClient = APIClient()
    // static let networkManager = NetworkManager()

    // MARK: - Core Data (Injected)

    private(set) lazy var coreDataManager: CoreDataManager = CoreDataManager()

    // MARK: - View Models

    @MainActor
    lazy var anonymousUserService = AnonymousUserService(keychainService: keychainService, authRepository: authRepository, coreDataManager: coreDataManager)

    @MainActor
    func makeReadingViewModel(userId: UUID) -> ReadingViewModel {
        return ReadingViewModel(
            userId: userId,
            bookRepository: bookRepository,
            dictionaryRepository: dictionaryRepository,
            wordMarkerRepository: wordMarkerRepository,
            textSegmentationService: textSegmentationService
        )
    }

    // MARK: - Preview Instances (for SwiftUI Previews and Simulator Mock Mode)

    @MainActor
    static let preview = DIContainer(coreDataManager: .preview, isPreviewMode: true)

    // MARK: - Initialization

    init(coreDataManager: CoreDataManager? = nil, isPreviewMode: Bool = false) {
        // Initialize coreDataManager - use provided one or create new
        self.coreDataManager = coreDataManager ?? CoreDataManager()

        // Initialize repositories based on mode
        bookRepository = isPreviewMode ? MockBookRepository() : BookRepositoryImpl(coreDataManager: self.coreDataManager)
    }

    // MARK: - Test Helpers

    /// Create a DIContainer with in-memory Core Data for testing
    static func withTestContainer() -> DIContainer {
        let container = DIContainer()
        container.coreDataManager = CoreDataManager(inMemory: true)
        return container
    }
}
