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
    static let bookUploadUseCase = DefaultBookUploadUseCase(
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

    // TODO: Implement in future phases
    // static let readingProgressRepository = ReadingProgressRepositoryImpl()
    // static let dictionaryRepository = DictionaryRepositoryImpl()
    // static let wordMarkerRepository = WordMarkerRepositoryImpl()
    // static let proficiencyRepository = ProficiencyRepositoryImpl()
    // static let userPreferencesRepository = UserPreferencesRepositoryImpl()

    // MARK: - Infrastructure Layer

    // Services
    static let keychainService = KeychainService()
    static let ocrService = AppleVisionOCRService()
    static let imageProcessingService = DefaultImageProcessingService()
    static let textSegmentationService = HanLPSegmentationService()
    // static let dictionaryService = CEDICTDictionaryService()
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

    @MainActor
    static let libraryViewModel = LibraryViewModel(bookRepository: bookRepository, authViewModel: authViewModel)

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
