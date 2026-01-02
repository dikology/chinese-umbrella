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
struct DIContainer {
    // MARK: - Domain Layer

    // Use Cases
    static let authUseCase = AuthUseCase(repository: authRepository, keychainService: keychainService)
    static let bookMetadataService = DefaultBookMetadataService()
    static let bookUploadUseCase = DefaultBookUploadUseCase(
        ocrService: ocrService,
        imageProcessingService: imageProcessingService,
        textSegmentationService: textSegmentationService,
        bookMetadataService: bookMetadataService,
        bookRepository: bookRepository
    )

    static let editBookUseCase = DefaultEditBookUseCase(
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
    static let authRepository = AuthRepositoryImpl()
    static let bookRepository = BookRepositoryImpl(coreDataManager: coreDataManager)
    static let dictionaryService = CEDICTDictionaryService()
    static let dictionaryRepository = DictionaryRepositoryImpl(dictionaryService: dictionaryService)
    static let wordMarkerRepository = WordMarkerRepositoryImpl()

    // TODO: Implement in future phases
    // static let readingProgressRepository = ReadingProgressRepositoryImpl()
    // static let proficiencyRepository = ProficiencyRepositoryImpl()
    // static let userPreferencesRepository = UserPreferencesRepositoryImpl()

    // MARK: - Infrastructure Layer

    // Services
    static let keychainService = KeychainService()
    static let ocrService = AppleVisionOCRService()
    static let imageProcessingService = DefaultImageProcessingService()
    static let textSegmentationService = LocalTextSegmentationService()
    // static let notificationService = NotificationService()
    // static let storageService = FileSystemStorageService()
    // static let loggingService = ConsoleLoggingService()

    // MARK: - Data Sources

    // TODO: Implement in future phases
    // static let apiClient = APIClient()
    // static let networkManager = NetworkManager()

    // MARK: - Core Data

    static let coreDataManager = CoreDataManager.shared

    // MARK: - View Models

    @MainActor
    static let authViewModel = AuthViewModel(authUseCase: authUseCase)

    // Note: LibraryViewModel is now created in ContentView to share the same authViewModel instance
    // static let libraryViewModel = LibraryViewModel(bookRepository: bookRepository, authViewModel: authViewModel)

    @MainActor
    static func makeReadingViewModel() -> ReadingViewModel {
        return ReadingViewModel(
            bookRepository: bookRepository,
            dictionaryRepository: dictionaryRepository,
            wordMarkerRepository: wordMarkerRepository,
            textSegmentationService: textSegmentationService
        )
    }

    // MARK: - Preview Instances (for SwiftUI Previews)

    @MainActor
    static let preview = DIContainer(
        coreDataManager: .preview,
        inMemory: true
    )

    let coreDataManager: CoreDataManager

    init(coreDataManager: CoreDataManager = .shared, inMemory: Bool = false) {
        self.coreDataManager = inMemory ? .preview : coreDataManager
    }
}
