# iOS Phase 1 Implementation Plan
## Chinese Language Learning SaaS - MVP

**Document Version:** 1.2 (Merged)
**Target Platform:** iOS 17+
**Timeline:** Months 1-4 (Phase 1)
**Status:** Ready for Development  

---

## 1. Executive Summary

This document outlines the complete implementation plan for the iOS Phase 1 MVP, focusing on native book scanning with OCR, integrated reading experience with automatic page progression, and clickable word segmentation with inline dictionary lookup. The app prioritizes offline-first reading with seamless word marking and proficiency tracking.

### Key MVP Deliverables
- ✅ Photo capture & OCR-based book scanning (using Apple Vision API)
- ✅ Unified reading interface with automatic page continuity
- ✅ Chinese word segmentation (using HanLP or similar)
- ✅ Inline dictionary with tap-to-define
- ✅ Local word marking and annotation storage
- ✅ Proficiency level detection algorithm
- ✅ Offline-first architecture with background sync

### Success Metrics (Phase 1)
- 500 active users with 2 sessions/week
- 80% accuracy in proficiency detection (vs. HSK benchmarks)
- <2s reading interface load time
- 0 critical data loss bugs
- NPS ≥30

---

## 2. App Architecture Overview

### 2.1 Architectural Pattern: MVVM + Clean Architecture

```
┌─────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                │
│  ┌──────────────┬──────────────┬──────────────────┐ │
│  │ Views        │ ViewModels   │ Coordinators     │ │
│  │ (SwiftUI)    │ (State Mgmt) │ (Navigation)     │ │
│  └──────────────┴──────────────┴──────────────────┘ │
└─────────────────────────────────────────────────────┘
         ↓              ↓              ↓
┌─────────────────────────────────────────────────────┐
│                    DOMAIN LAYER                      │
│  ┌──────────────┬──────────────┬──────────────────┐ │
│  │ UseCases     │ Repositories │ Entities         │ │
│  │ (Business    │ (Interface)  │ (Data Models)    │ │
│  │  Logic)      │              │                  │ │
│  └──────────────┴──────────────┴──────────────────┘ │
└─────────────────────────────────────────────────────┘
         ↓              ↓              ↓
┌─────────────────────────────────────────────────────┐
│                    DATA LAYER                        │
│  ┌──────────────┬──────────────┬──────────────────┐ │
│  │ Local DB     │ Remote API   │ File Storage     │ │
│  │ (Core Data)  │ (REST/gRPC)  │ (Documents)      │ │
│  └──────────────┴──────────────┴──────────────────┘ │
└─────────────────────────────────────────────────────┘
```

### 2.2 Technology Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **UI Framework** | SwiftUI | Native, modern, data binding, accessibility |
| **State Management** | @Observable (iOS 17+) | Modern, lightweight, no dependency on Combine |
| **Architecture** | MVVM + Clean | Testability, separation of concerns |
| **Local Database** | Core Data | Native, free, offline support |
| **OCR** | Apple Vision API | Native, accurate, free, on-device processing |
| **Text Segmentation** | HanLP (Swift wrapper) | Accurate Chinese word segmentation |
| **Dictionary** | CEDICT (embedded) | Free, comprehensive, offline |
| **Sync** | CloudKit or custom Backend | Phase 2 feature, prepare APIs now |
| **Analytics** | Custom logging | Proficiency calculation pipeline |
| **Logging** | OSLog (unified logging) | Structured logging with categories |
| **Testing** | Swift Testing | Native testing framework |

### 2.3 Core Modules

```
chinese-umbrella/
├── App/
│   ├── chinese-umbrella.swift (entry point)
│   └── AppDelegate.swift (lifecycle management)
│
├── Presentation/ (UI Layer)
│   ├── Screens/
│   │   ├── AuthScreen/
│   │   ├── OnboardingScreen/
│   │   ├── LibraryScreen/
│   │   ├── BookSelectionScreen/
│   │   ├── ReadingScreen/
│   │   ├── AnalyticsScreen/
│   │   └── SettingsScreen/
│   ├── Components/
│   │   ├── DictionaryPopup.swift
│   │   ├── WordAnnotationOverlay.swift
│   │   ├── ReadingProgressIndicator.swift
│   │   ├── PageNumberIndicator.swift
│   │   └── SessionSummaryCard.swift
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift
│   │   ├── LibraryViewModel.swift
│   │   ├── ReadingViewModel.swift
│   │   ├── AnalyticsViewModel.swift
│   │   └── SettingsViewModel.swift
│   ├── Coordinators/
│   │   ├── AppCoordinator.swift
│   │   ├── AuthCoordinator.swift
│   │   ├── MainCoordinator.swift
│   │   └── ReadingCoordinator.swift
│   └── Styles/
│       ├── Colors.swift
│       ├── Typography.swift
│       └── Layout.swift
│
├── Domain/ (Business Logic)
│   ├── UseCases/
│   │   ├── AuthUseCase.swift
│   │   ├── BookUploadUseCase.swift
│   │   ├── OCRUseCase.swift
│   │   ├── ReadingUseCase.swift
│   │   ├── WordMarkingUseCase.swift
│   │   ├── ProficiencyCalculationUseCase.swift
│   │   ├── DictionaryLookupUseCase.swift
│   │   └── LibraryManagementUseCase.swift
│   ├── Repositories/ (Protocol Definitions)
│   │   ├── AuthRepository.swift
│   │   ├── BookRepository.swift
│   │   ├── ReadingProgressRepository.swift
│   │   ├── DictionaryRepository.swift
│   │   ├── WordMarkerRepository.swift
│   │   ├── ProficiencyRepository.swift
│   │   └── UserPreferencesRepository.swift
│   └── Entities/
│       ├── User.swift
│       ├── Book.swift
│       ├── ReadingSession.swift
│       ├── MarkedWord.swift
│       ├── DictionaryEntry.swift
│       └── ProficiencyLevel.swift
│
├── Data/ (Data Access)
│   ├── Repositories/ (Implementations)
│   │   ├── AuthRepositoryImpl.swift
│   │   ├── BookRepositoryImpl.swift
│   │   ├── ReadingProgressRepositoryImpl.swift
│   │   ├── DictionaryRepositoryImpl.swift
│   │   ├── WordMarkerRepositoryImpl.swift
│   │   ├── ProficiencyRepositoryImpl.swift
│   │   └── UserPreferencesRepositoryImpl.swift
│   ├── DataSources/
│   │   ├── Local/
│   │   │   ├── CoreDataManager.swift
│   │   │   ├── UserDefaults+Extensions.swift
│   │   │   └── FileSystemManager.swift
│   │   └── Remote/
│   │       ├── APIClient.swift
│   │       ├── APIEndpoints.swift
│   │       └── NetworkManager.swift
│   └── Models/
│       ├── DTOs/ (Data Transfer Objects)
│       ├── CoreData/ (NSManagedObject definitions)
│       └── Mappers/ (DTO ↔ Entity conversion)
│
├── Infrastructure/
│   ├── Services/
│   │   ├── OCRService.swift (Vision API wrapper)
│   │   ├── TextSegmentationService.swift (HanLP wrapper)
│   │   ├── DictionaryService.swift (CEDICT lookup)
│   │   ├── SyncService.swift (prepare for Phase 2)
│   │   ├── NotificationService.swift
│   │   ├── StorageService.swift
│   │   └── LoggingService.swift
│   ├── Utilities/
│   │   ├── Extensions/
│   │   ├── Helpers/
│   │   ├── Constants.swift
│   │   └── Enums.swift
│   └── DependencyInjection/
│       └── DIContainer.swift
│
#### Logging System (LoggingService.swift)
|
**Purpose:** Centralized, structured logging using Apple's OSLog framework
|
**Features:**
- **Multiple Log Levels:** debug, info, default, error, fault
- **Categorized Logging:** Auth, Core Data, OCR, Reading, Performance
- **Context Information:** File, function, line number
- **Debug-Only Logging:** Debug logs only appear in development builds
- **Performance Tracking:** Built-in duration logging for operations
|
**Implementation:**
```swift
// Usage examples
logger.auth("User signed up successfully", level: .info)
logger.coreData("Failed to save user", level: .error, error: error)
logger.performance("OCR processing completed", duration: 1.2)

// Debug logs (development only)
logger.debug("Processing page 5 of 10")
```
|
**Log Categories:**
- **Auth:** Authentication events (signup, login, validation)
- **CoreData:** Database operations and errors
- **OCR:** Text recognition and processing
- **Reading:** Session tracking, word marking
- **Performance:** Operation timing and bottlenecks
|
**Benefits:**
- **Production Ready:** Efficient OSLog with log levels
- **Privacy Compliant:** No PII in logs (Phase 1)
- **Debug Support:** Rich context for development
- **Monitoring Ready:** Structured for future analytics
|
├── Resources/
│   ├── Strings/
│   │   ├── Localizable.strings (English)
│   │   └── Localizable.strings (Chinese)
│   ├── Assets.xcassets/
│   ├── Fonts/
│   └── Data/
│       ├── cedict.bin (embedded dictionary)
│       └── hsk_levels.json (HSK frequency data)
│
└── Tests/
    ├── UnitTests/
    │   ├── DomainTests/
    │   ├── DataTests/
    │   └── InfrastructureTests/
    ├── IntegrationTests/
    ├── UITests/
    └── Mocks/
```

---

## 3. Feature Implementation Details

### 3.1 Authentication & Onboarding

#### Views
- **AuthScreen**: Login/signup with email/password, Apple Sign-In

#### ViewModel: AuthViewModel (Modern @Observable)
```swift
@Observable
final class AuthViewModel {
    var isAuthenticated = false
    var currentUser: User?
    var isLoading = false
    var errorMessage: String?
    
    // MARK: Methods
    func signUp(email: String, password: String)
    func signIn(email: String, password: String)
    func signInWithApple(credential: ASAuthorizationAppleIDCredential)
    func logout()
}
```

#### Data Flow
1. User enters credentials → AuthRepository validates locally → API call (Phase 2)
2. JWT token stored in Keychain (secure)

---

### 3.2 Book Management & Upload

#### Views
- **LibraryScreen**: List all books, organize by type (uploaded, public library)
- **BookUploadScreen**: Camera capture + photo picker for multiple pages
- **PhotoReviewScreen**: Review before processing, delete unwanted pages
- **OCRProgressScreen**: Show OCR progress per page

#### ViewModel: LibraryViewModel
```swift
@Observable
final class LibraryViewModel {
    var books: [Book] = []
    var selectedBook: Book?
    var isProcessing = false
    var uploadProgress: Double = 0 // 0.0 - 1.0
    
    // MARK: Methods
    func uploadBook(pages: [UIImage], title: String, author: String?)
    func processOCR(images: [UIImage]) -> [String] // Extracted text per page
    func saveBook(_ book: Book)
    func deleteBook(_ book: Book)
    func fetchLibrary()
}
```

#### Key Implementation Details

**Photo Capture Flow:**
1. Camera screen (SwiftUI camera integration)
2. User takes multiple photos
3. Photos displayed in grid for review
4. User taps "Process" → OCR begins

**OCR Processing (Apple Vision API):**
```swift
protocol OCRService {
    func recognizeText(from image: UIImage) async throws -> String
    func extractTextBlocks(from image: UIImage) async throws -> [TextBlock]
}

class AppleVisionOCRService: OCRService {
    func recognizeText(from image: UIImage) async throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en"] // Mandarin
        let handler = VNImageRequestHandler(cgImage: image.cgImage!)
        try handler.perform([request])
        // Extract text from results, join blocks
    }
}
```

**Data Model: Book**
```swift
struct Book: Identifiable {
    let id: UUID
    let title: String
    let author: String?
    let pages: [BookPage] // Ordered pages
    let createdDate: Date
    let updatedDate: Date
    var currentPageIndex: Int = 0 // Track position
    var isLocal: Bool = true
}

struct BookPage: Identifiable {
    let id: UUID
    let bookId: UUID
    let pageNumber: Int
    let originalImagePath: String // Local file
    let extractedText: String
    let words: [WordSegment] // Segmented words with positions
    let wordsMarked: Set<String> // User-marked words
}
```

---

### 3.3 Reading Interface

#### Views
- **ReadingScreen**: Main reading interface
  - Centered text display (comfortable reading)
  - Current page number indicator
  - Progress bar (position in book)
  - Bottom navigation: prev/next page, mark difficult words
  - Swipe gestures: page left/right

- **DictionaryPopup**: On-demand word lookup
  - Tap word → translucent overlay with definition
  - Show: pinyin, English definition, example sentences
  - Mark as difficult button
  - Tap outside to dismiss

#### ViewModel: ReadingViewModel
```swift
@Observable
final class ReadingViewModel {
    var currentBook: Book?
    var currentPage: BookPage?
    var currentPageIndex: Int = 0
    var pageText: String = ""
    var segmentedWords: [WordSegment] = []
    var selectedWord: WordSegment?
    var dictionaryEntry: DictionaryEntry?
    var markedWordsThisSession: Set<String> = []
    
    // MARK: Methods
    func loadBook(_ book: Book)
    func loadPage(_ index: Int)
    func nextPage()
    func previousPage()
    func selectWord(_ word: WordSegment)
    func markWordAsDifficult(_ word: String)
    func unmarkWord(_ word: String)
}
```

#### Key Implementation: Automatic Page Progression

**Design Goal:** User sees continuous text flow without manual page switching

**Implementation:**
```swift
// Option 1: Seamless page scrolling (preferred)
ScrollView {
    VStack(alignment: .center, spacing: 24) {
        ForEach(currentBook.pages) { page in
            VStack(alignment: .center) {
                ForEach(page.words) { word in
                    WordButton(word: word) { 
                        selectWord(word) 
                    }
                }
                Divider() // Visual page break
                Text("— Page \(page.pageNumber) —")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

// Option 2: Paged scroll view (alternative)
TabView(selection: $currentPageIndex) {
    ForEach(Array(currentBook.pages.enumerated()), id: \.element.id) { index, page in
        ReadingPageView(page: page)
            .tag(index)
    }
}
.tabViewStyle(.page)
```

**Word Segmentation & Rendering:**
```swift
struct WordSegment: Identifiable {
    let id: UUID
    let word: String
    let pinyin: String?
    let startIndex: Int // Position in page text
    let endIndex: Int
    var isMarked: Bool = false
    var definition: DictionaryEntry?
}

// In ReadingPageView
VStack(alignment: .center) {
    Text(attributedPageText) // Build with NSAttributedString
        .font(.system(size: 16))
        .lineSpacing(8)
        .onTapGesture { location in
            // Detect tapped word based on position
            let tappedWord = detectWord(at: location)
            selectWord(tappedWord)
        }
}
```

#### Dictionary Integration

**Word Tap Detection:**
```swift
func detectWord(at location: CGPoint, in text: String) -> WordSegment? {
    // Map tap location to character index in NSAttributedString
    // Look up word in segmentedWords array
    return segmentedWords.first { segment in
        // Check if tap location overlaps with word bounds
    }
}
```

**Dictionary Lookup:**
```swift
protocol DictionaryRepository {
    func lookup(character: String) -> DictionaryEntry?
    func lookup(word: String) -> DictionaryEntry?
    func getExamples(for word: String) -> [String]
}

struct DictionaryEntry: Codable {
    let simplified: String
    let traditional: String
    let pinyin: String
    let englishDefinition: String
    let frequency: HSKLevel? // HSK 1-6 or beyond
    let examples: [String]
}
```

---

### 3.4 Text Segmentation (Chinese Word Breaking)

#### Challenge
Chinese text has no spaces between words, requiring NLP to identify word boundaries.

#### Solution: HanLP Integration

```swift
protocol TextSegmentationService {
    func segment(text: String) -> [String] // Returns array of words
    func segmentWithPositions(text: String) -> [WordSegment]
}

class HanLPSegmentationService: TextSegmentationService {
    // Wraps HanLP library (C++ with Swift bindings or HTTP service)
    
    func segment(text: String) -> [String] {
        // Call HanLP segmenter
        let words = hanLPSegment(text)
        return words
    }
    
    func segmentWithPositions(text: String) -> [WordSegment] {
        let words = segment(text: text)
        var segments: [WordSegment] = []
        var currentIndex = 0
        
        for word in words {
            if let range = text.range(of: word, range: text.index(text.startIndex, offsetBy: currentIndex)..<text.endIndex) {
                let startOffset = text.distance(from: text.startIndex, to: range.lowerBound)
                let endOffset = text.distance(from: text.startIndex, to: range.upperBound)
                
                segments.append(WordSegment(
                    word: word,
                    pinyin: nil, // Look up separately
                    startIndex: startOffset,
                    endIndex: endOffset
                ))
                currentIndex = endOffset
            }
        }
        return segments
    }
}
```

#### Implementation Options
1. **Embedded Library**: HanLP compiled to iOS framework (most complex, best performance)
2. **HTTP Service**: Call segmentation backend (simpler, depends on connectivity)
3. **Pre-tokenized**: For MVP, accept pre-processed books from backend

**Phase 1 Recommendation:** Start with **Option 2** (HTTP service to backend), migrate to embedded in Phase 2.

---

### 3.5 Word Marking & Annotation

#### Feature: Mark Difficult Words

```swift
// In ReadingViewModel
func markWordAsDifficult(_ word: String) {
    markedWordsThisSession.insert(word)
    
    // Local persistence (immediate)
    let markedWord = MarkedWord(
        userId: currentUser.id,
        word: word,
        readingDate: Date(),
        contextSnippet: extractContext(around: word),
        textId: currentBook.id,
        pageNumber: currentPageIndex
    )
    wordMarkerRepository.save(markedWord)
    
    // UI feedback: highlight word, show confirmation
}

func unmarkWord(_ word: String) {
    markedWordsThisSession.remove(word)
    wordMarkerRepository.delete(word: word, from: currentUser.id)
}
```

#### Core Data Schema: MarkedWord
```swift
@NSManaged var userId: UUID
@NSManaged var word: String
@NSManaged var readingDate: Date
@NSManaged var contextSnippet: String
@NSManaged var textId: UUID
@NSManaged var pageNumber: Int
@NSManaged var sessionId: UUID?
@NSManaged var marked: Bool
```

#### UI Feedback
- **Visual Mark**: Subtle background highlight (light orange/yellow)
- **Word Count**: Display "3 words marked this session" in session summary
- **Quick Unmark**: Long-press marked word to unmark

---

#### Proficiency Calculation Algorithm

```swift
struct ProficiencyCalculator {
    let hskLevels: [HSKLevel] // Pre-loaded HSK frequency data
    
    func calculateProficiency(
        markedWords: [String],
        totalUniqueWords: Int,
        historicalMarkedWords: [String]
    ) -> ProficiencyResult {
        // Vocabulary mastery %
        let masteredWords = totalUniqueWords - markedWords.count
        let masteryPct = Double(masteredWords) / Double(totalUniqueWords) * 100
        
        // HSK level inference
        var hskDistribution: [HSKLevel: Int] = [:]
        for word in markedWords {
            if let level = hskLevels.frequency[word] {
                hskDistribution[level, default: 0] += 1
            }
        }
        
        // If >15% of marked words are beyond HSK 4, suggest level is too hard
        let beyondHSK4 = hskDistribution[.hsk5, default: 0] + hskDistribution[.hsk6, default: 0]
        let percentBeyond = Double(beyondHSK4) / Double(markedWords.count) * 100
        
        let estimatedLevel = percentBeyond > 15 ? .hsk4 : .hsk5
        
        return ProficiencyResult(
            masteryPercentage: masteryPct,
            estimatedHSKLevel: estimatedLevel,
            confidenceInterval: (min: estimatedLevel.rawValue - 1, max: estimatedLevel.rawValue + 1),
            recommendation: generateRecommendation(masteryPct)
        )
    }
    
    private func generateRecommendation(_ mastery: Double) -> String {
        if mastery > 90 {
            return "Try a slightly harder text to challenge yourself!"
        } else if mastery > 75 {
            return "Great comprehension! Ready for next level."
        } else if mastery < 40 {
            return "This text might be too challenging. Try an easier one."
        } else {
            return "Good pace. Keep reading similar difficulty texts."
        }
    }
}
```

#### Analytics Dashboard

**AnalyticsScreen shows:**
- Texts read (total count)
- Total words marked (cumulative)
- Current proficiency level badge (HSK 1-6)
- Reading time this week
- Vocabulary mastery % with confidence interval
- Word list (all marked words) with sort/filter options
- Progress chart (proficiency over time)

---

### 3.7 Local Storage & Offline Support

#### Core Data Stack Setup

```swift
class CoreDataManager {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "UmbrellaData")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data load error: \(error)")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
}
```

#### What's Stored Locally
1. **Books**: Metadata + extracted text pages
2. **Reading Progress**: Current page index per book
3. **Marked Words**: All user annotations
4. **Session History**: Reading sessions completed
5. **User Preferences**: HSK level, language settings
6. **Dictionary Cache**: Frequently looked-up words

#### Sync Preparation (Phase 2 Ready)

```swift
protocol SyncService {
    func sync() async throws
    func queueForSync(_ entity: Syncable)
    func getUnsyncedChanges() -> [SyncChange]
}

// Each entity conforms to Syncable
protocol Syncable {
    var isSynced: Bool { get set }
    var syncId: UUID { get }
}
```

**Sync Strategy for Phase 2:**
- Last-write-wins conflict resolution
- Timestamp-based tracking
- Background sync on app launch
- Queue failed syncs for retry

---

## 4. Modern SwiftUI Patterns

### 4.1 Using @Observable in Views

```swift
struct AppRoot: View {
    @State private var authViewModel = AuthViewModel(authUseCase: DIContainer.authUseCase)
    @State private var readingViewModel = ReadingViewModel(
        readingUseCase: DIContainer.readingUseCase,
        dictionaryRepository: DIContainer.dictionaryRepository
    )

    var body: some View {
        if authViewModel.isAuthenticated {
            TabView {
                ReadingScreen()
                    .environment(readingViewModel)
                    .tabItem { Label("Reading", systemImage: "book") }

                AnalyticsScreen()
                    .environment(readingViewModel)
                    .tabItem { Label("Analytics", systemImage: "chart.bar") }

                SettingsScreen()
                    .environment(authViewModel)
                    .tabItem { Label("Settings", systemImage: "gear") }
            }
        } else {
            AuthScreen()
                .environment(authViewModel)
        }
    }
}
```

### 4.2 Environment & Dependency Injection

```swift
struct DIContainer {
    static let authUseCase = AuthUseCase(
        repository: AuthRepositoryImpl()
    )

    static let readingUseCase = ReadingUseCase(
        repository: ReadingProgressRepositoryImpl(),
        dictionaryRepository: DictionaryRepositoryImpl()
    )

    static let dictionaryRepository = DictionaryRepositoryImpl()
}
```

### 4.3 Key Advantages of Modern Stack (iOS 17+)

| Feature | Benefit |
|---------|---------|
| **@Observable** | Fine-grained reactivity, no @Published needed |
| **Async/await** | Cleaner async code, no callback hell |
| **SwiftData** | Modern Core Data alternative, type-safe |
| **Environment** | Simpler dependency injection than @EnvironmentObject |
| **Macro-based** | @Observable generates code automatically |

---

## 5. View Hierarchy & Navigation Flow

### 5.1 Bottom Tab Navigation

```
┌─────────────────────────────────────┐
│        Tab: Reading                 │
│  - Select book from library        │
│  - Read with page navigation       │
│  - Mark words                      │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│        Tab: Analytics              │
│  - Proficiency level              │
│  - Marked words list              │
│  - Reading statistics             │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│        Tab: Settings               │
│  - Profile / HSK level            │
│  - Preferences (font, theme)      │
│  - Sync status                    │
│  - Logout                         │
└─────────────────────────────────────┘
```

### 5.2 Reading Stack Navigation

```
AuthScreen (if logged out)
    ↓
OnboardingScreen (proficiency assessment)
    ↓
LibraryScreen (book list)
    ├─ BookUploadScreen (capture photos)
    ├─ PhotoReviewScreen (edit pages)
    └─ ReadingScreen (main reading) ← Focus of MVP
        ├─ DictionaryPopup (word lookup)
        └─ SessionSummaryCard (end session)
```

---

## 5. UI/UX Design Specifications

### 5.1 Design System (from PRD)

**Colors:**
- Primary Teal: `#208C85` (buttons, accents)
- Background: `#FCFCF9` (light cream)
- Text Primary: `#134252` (dark slate)
- Text Secondary: `#626C71` (medium gray)
- Error: `#C0152F` (red)

**Typography:**
- **H1 (Page Title)**: SF Pro Display, 28pt, weight 600
- **Body (Reading Text)**: SF Pro Display, 16pt, weight 400
- **Dictionary Definition**: SF Pro Display, 14pt, weight 400
- **Pinyin**: SF Pro Display, 12pt, weight 400, gray

**Spacing:** Base unit 4px (4, 8, 12, 16, 20, 24, 32, 48px)

### 5.2 Reading Screen Layout

```
┌─────────────────────────────────────────────┐
│ Top Bar (Safe Area)                         │
│ [Book Title] ... [Page X/Y] ... [⚙️]      │
└─────────────────────────────────────────────┘
│                                             │
│         The moon reflects in                │
│         the river, very beautiful.          │
│                                             │
│         The stars shine brightly            │
│         above the water. This is            │
│         a peaceful night.                   │
│                                             │
│         — Page 1 —                          │
│                                             │
│         Mountains stand tall in             │
│         the distance, covered with          │
│         snow. Their peaks touch             │
│         the sky.                            │
│                                             │
│  (Scrollable, words are tappable)          │
│                                             │
├─────────────────────────────────────────────┤
│ Progress Bar: [████░░░░░░] 35%              │
├─────────────────────────────────────────────┤
│ [◀ Previous] [Mark Word] [Next ▶] [End]   │
└─────────────────────────────────────────────┘
```

### 5.3 Dictionary Popup

**On Word Tap:**
```
┌────────────────────────┐
│ 月 (yuè)               │  ← Word + Pinyin
│                        │
│ Noun: moon             │  ← Definition
│ HSK Level: 3           │  ← Frequency
│                        │
│ Example:               │
│ 月亮在天空闪闪发光    │  ← Example sentence
│                        │
│ [Mark Difficult] [✓]  │  ← Actions
└────────────────────────┘
```

**Properties:**
- Position: Tap location + smart repositioning (avoid going off-screen)
- Background: Translucent white with shadow
- Dismissal: Tap outside or swipe up

---

## 7. Data Models (Core Data)

### 7.1 Entity Relationship Diagram

```
User
├─ 1─* Books
│   └─ 1─* BookPages
│       └─ 1─* WordSegments
├─ 1─* MarkedWords
└─ 1─* UserPreferences

HanLP.BIN (external dictionary resource)
Dictionary (CEDICT, loaded once on first launch)
HSKFrequency (frequency database, preloaded)
```

### 7.2 Core Data Entity Definitions

#### User Entity
```
Attributes:
- id (UUID)
- email (String)
- displayName (String)
- passwordHash (String) [optional for Phase 1]
- hsklevel (Integer 1-6)
- vocabularyMasteryPct (Double)
- createdAt (Date)
- updatedAt (Date)

Relationships:
- books (1-*) → Book
- markedWords (1-*) → MarkedWord
- userPreferences (1-1) → UserPreferences
```

#### Book Entity
```
Attributes:
- id (UUID)
- title (String)
- author (String) [optional]
- createdDate (Date)
- updatedDate (Date)
- isSynced (Bool)

Relationships:
- owner (1-1) ← User
- pages (1-*) → BookPage
```

#### BookPage Entity
```
Attributes:
- id (UUID)
- pageNumber (Integer)
- extractedText (String)
- imageFilePath (String)
- createdAt (Date)
- isSynced (Bool)

Relationships:
- book (1-1) ← Book
- wordSegments (1-*) → WordSegment
- markedWordsOnPage (1-*) → MarkedWord
```

#### WordSegment Entity
```
Attributes:
- id (UUID)
- word (String)
- pinyin (String) [optional]
- startIndex (Integer)
- endIndex (Integer)
- isMarked (Bool)

Relationships:
- page (1-1) ← BookPage
```

#### MarkedWord Entity
```
Attributes:
- id (UUID)
- word (String)
- readingDate (Date)
- contextSnippet (String)
- pageNumber (Integer)
- isSynced (Bool)
- markedCount (Integer) [how many times marked]

Relationships:
- user (1-1) ← User
- book (1-1) ← Book
- page (1-1) ← BookPage
```

#### UserPreferences Entity
```
Attributes:
- id (UUID)
- fontSize (Integer) [14, 16, 18, 20]
- isDarkMode (Bool)
- language (String) ["en", "zh-CN", "zh-TW"]
- autoSyncEnabled (Bool)

Relationships:
- user (1-1) ← User
```

---

## 8. API Contract (for Phase 2 Cloud Sync)

**Note:** Phase 1 is offline-only. These endpoints prepare for Phase 2.

### Authentication

```
POST /api/v1/auth/signup
Request: { email: string, password: string, displayName: string }
Response: { userId: UUID, token: string }

POST /api/v1/auth/signin
Request: { email: string, password: string }
Response: { userId: UUID, token: string }

POST /api/v1/auth/signin-apple
Request: { appleIdentityToken: string }
Response: { userId: UUID, token: string }
```

### Book Upload (Prepare for Phase 2)

```
POST /api/v1/books
Request: {
  title: string,
  author: string?,
  pages: [
    {
      pageNumber: int,
      extractedText: string,
      imageBase64: string
    }
  ]
}
Response: { bookId: UUID, syncedAt: timestamp }
```

### Word Marking Sync

```
POST /api/v1/marked-words/batch
Request: {
  userId: UUID,
  changes: [
    { word: string, bookId: UUID, marked: bool, timestamp: date }
  ]
}
Response: { synced: int, failed: int, lastSyncAt: timestamp }
```

### Proficiency Data

```
GET /api/v1/proficiency
Response: {
  hsklevel: int,
  masteryPercentage: double,
  confidenceInterval: { min: int, max: int },
  lastUpdated: timestamp
}
```

---

## 9. Development Timeline & Milestones

### Month 1: Architecture & Auth
- **Week 1-2**: Project setup, DI container, Core Data schema
- **Week 3**: Authentication (email/password, Apple Sign-In)

### Month 2: OCR & Library
- **Week 5-6**: Camera integration, photo picker, image handling
- **Week 7**: OCR pipeline (Vision API + HanLP service)
- **Week 8**: Book metadata management, library persistence

### Month 3: Reading Interface & Dictionary
- **Week 9-10**: Reading screen UI, page rendering, text segmentation
- **Week 11**: Dictionary integration, inline word lookup
- **Week 12**: Word marking, annotation persistence

### Month 4: Analytics & Polish
- **Week 13**: Session tracking, proficiency calculation
- **Week 14**: Analytics dashboard, word list view
- **Week 15**: Testing, bug fixes, performance optimization
- **Week 16**: Beta launch prep, TestFlight setup

---

## 10. Testing Strategy

### 10.1 Unit Tests (Target: 70% code coverage)

**Domain Layer:**
- `ProficiencyCalculatorTests`: Various mastery %, HSK level output
- `TextSegmentationServiceTests`: Mock HanLP responses
- `DictionaryServiceTests`: CEDICT lookup accuracy

**Data Layer:**
- `BookRepositoryTests`: Save, retrieve, delete books
- `MarkedWordRepositoryTests`: CRUD operations
- `CoreDataManagerTests`: Transaction integrity

**ViewModel Tests:**
- `ReadingViewModelTests`: Page navigation, word marking state
- `AuthViewModelTests`: Login, signup flows

### 10.2 Integration Tests

- Auth flow → Library load → Book upload → Reading
- OCR processing → Text segmentation → Page rendering
- Word marking → Session end → Proficiency calculation
- Core Data persistence across app lifecycle

### 10.3 UI Tests (Swift Testing)

```swift
@Test
func testWordTapOpensDict() async {
    // 1. Navigate to reading screen
    // 2. Tap on a word
    // 3. Verify dictionary popup appears
    // 4. Verify correct definition shown
}

@Test
func testPageNavigation() async {
    // 1. Start on page 1
    // 2. Tap next page button
    // 3. Verify page index updates
    // 4. Verify new page content displays
}

@Test
func testWordMarking() async {
    // 1. Tap to open dictionary
    // 2. Tap "Mark Difficult"
    // 3. Verify word highlighted in text
    // 4. Verify session count updates
}
```

### 10.4 Performance Testing

- App launch time: <2s
- Reading screen load: <1s per page
- Dictionary lookup: <500ms
- OCR processing: <2s per page (Vision API)
- Core Data queries: <100ms

---

## 11. Error Handling & Edge Cases

### 10.1 Offline Scenarios

| Scenario | Behavior |
|----------|----------|
| **No internet on app launch** | Load cached content, show "offline" badge |
| **Text segmentation fails** | Display raw text with character-by-character selection |
| **Dictionary lookup fails** | Show pinyin only, gray out definition |
| **OCR fails on image** | Show error, allow user to retake photo |
| **Core Data read error** | Log error, show graceful fallback |

### 10.2 User Error Handling

```swift
// Invalid proficiency assessment
if assessmentScore < 0 || assessmentScore > 100 {
    showError("Invalid assessment. Please try again.")
    return
}

// Empty book upload
if selectedPhotos.isEmpty {
    showError("Please select at least one page.")
    return
}

// Unsupported image format
if !supportedFormats.contains(image.mimeType) {
    showError("Please use JPG or PNG images.")
    return
}
```

### 10.3 Data Loss Prevention

- **Auto-save**: Mark word as soon as user taps confirm
- **Draft recovery**: Save reading session progress every 30s
- **Backup**: CloudKit backup (Phase 2)
- **Validation**: Verify Core Data integrity on app launch

---

## 12. Phase 1 to Phase 2 Migration Path

### What Phase 2 Adds
1. **Cloud Sync**: CloudKit or custom backend sync for marked words, reading progress
2. **Adaptive Recommendations**: ML-based content filtering per HSK level
3. **Enhanced Library**: Public library with pre-seeded texts
4. **Web Parity**: Reading on web, resume on iOS

### APIs to Prepare in Phase 1
- `SyncService` protocol (interface, mock implementation)
- `RecommendationEngine` interface (ready to plug in)
- Network layer scaffolding (APIClient, endpoints)

### Data Migration Considerations
- Core Data → Backend sync strategy
- Marked words versioning (handle conflicts)
- Reading position tracking (for cross-device sync)

---

## 13. Appendices

### A. Key Dependencies & Frameworks

| Framework | Purpose | Note |
|-----------|---------|------|
| **SwiftUI** | UI rendering | iOS 15+ native |
| **Combine** | Reactive programming | Data binding |
| **Vision** | OCR | Apple-provided |
| **CoreData** | Local persistence | System framework |
| **PhotosUI** | Photo picker | iOS 16+ |
| **CryptoKit** | Password hashing | Keychain integration |
| **CloudKit** | Cloud sync | Prepare for Phase 2 |

### B. HanLP Integration Options

**Option 1: Embedded Framework**
- Pros: Fast, offline
- Cons: Large binary, complex build setup
- Timeline: 2-3 weeks

**Option 2: HTTP Service**
- Pros: Simple, lightweight
- Cons: Requires connectivity, latency
- Timeline: 1 week

**Option 3: Pre-tokenized Books**
- Pros: Simplest MVP
- Cons: Server preprocessing required
- Timeline: <1 week

**Recommendation for Phase 1:** Option 2 (HTTP) with migration path to Option 1 in Phase 2.

### C. Sample User Flow (Screenshot Walkthrough)

1. **Launch App** → AuthScreen
3. **LibraryScreen** → Select "Upload Book"
4. **Camera** → Take 5 photos of book pages
5. **PhotoReview** → Delete unwanted pages, confirm
6. **OCRProgress** → "Processing page 1/5..."
7. **LibraryScreen** → New book appears
8. **ReadingScreen** → Text centered, pages scrollable
9. **Tap Word** → DictionaryPopup with definition + pinyin
10. **Mark Difficult** → Word highlights, count updates
11. **End Session** → SessionSummaryCard shows metrics
12. **AnalyticsScreen** → See proficiency level badge, word list

### D. Accessibility Compliance (WCAG 2.1 AA)

- [ ] All buttons/links: minimum 44x44pt touch target
- [ ] Text contrast: 4.5:1 for body, 3:1 for large text
- [ ] Keyboard navigation: Tab order, skip links
- [ ] Screen reader: Semantic HTML, ARIA labels
- [ ] Focus indicators: 2px teal outline on all interactive elements
- [ ] Font size adjustment: Respect system font size setting

### E. Localization Setup

**Supported Languages (Phase 1):**
- English (primary UI)
- Simplified Chinese (UI + content)
- Traditional Chinese (future)

**Strings File:**
```swift
// Localizable.strings (English)
"tab.reading" = "Reading";
"tab.analytics" = "Analytics";
"tab.settings" = "Settings";
"dict.noResult" = "Word not found.";

// Localizable.strings (Chinese)
"tab.reading" = "阅读";
"tab.analytics" = "分析";
"tab.settings" = "设置";
"dict.noResult" = "未找到此词。";
```

### F. Security Checklist

- [ ] Passwords hashed (bcrypt/Argon2) before storage
- [ ] API keys not hardcoded (use config file)
- [ ] SSL/TLS for all network requests
- [ ] Sensitive data (auth tokens) in Keychain
- [ ] No PII in logs or analytics
- [ ] GDPR compliance: data deletion on request
- [ ] Rate limiting on API calls (Phase 2)

---

## 14. Success Criteria & Launch Readiness

### Phase 1 MVP Checklist

- [ ] Authentication (email/password, Apple Sign-In)
- [ ] Photo capture & OCR pipeline (Vision API + HanLP)
- [ ] Book upload with multi-page support
- [ ] Reading screen with automatic page progression
- [ ] Word segmentation & rendering
- [ ] Dictionary lookup on tap
- [ ] Word marking with persistence
- [ ] Proficiency calculation algorithm
- [ ] Analytics dashboard
- [ ] Offline-first architecture
- [ ] Core Data persistence
- [ ] Error handling & recovery
- [ ] 70%+ unit test coverage
- [ ] WCAG 2.1 AA accessibility compliance
- [ ] Performance targets met (FCP <1.5s, LCP <2.5s)
- [ ] Localization (English + Chinese UI)
- [ ] Beta testing program (50 users)
- [ ] App Store submission ready

### Launch Metrics (4-week Post-Launch)

- 500+ DAU
- 2+ sessions/week average
- <2s session start time
- 80%+ retention
- 0 critical bugs in production
- NPS ≥30

---

## 15. Future Considerations (Beyond Phase 1)

### Phase 2 Focus Areas
1. Cloud sync with conflict resolution
2. Public library with ML-based recommendations
3. Web reading interface
4. Embedded text segmentation (performance)

### Phase 3
1. Teacher tools & classroom management
2. Advanced analytics
3. Bulk book import

### Phase 4
1. AI-generated personalized content
2. Spaced repetition scheduling
3. Multi-platform sync (watch/web/mobile)

---

## Conclusion

This implementation plan provides a clear, detailed roadmap for building a best-in-class iOS reading app with OCR-powered book scanning, seamless reading experience, and intelligent vocabulary tracking. The architecture follows clean principles, supports offline-first usage, and prepares for cloud sync in Phase 2.

**Key Success Factors:**
1. **Seamless reading UX** - No friction between pages
2. **Accurate OCR + segmentation** - Core to proficiency detection
3. **Offline reliability** - Works without connectivity
4. **Accessibility** - Inclusive design from the start

**Ready to proceed with development. Start Month 1 with architecture setup and authentication module.**

---

**Document Approved By:** [Product & Engineering]  
**Last Updated:** December 31, 2025 (Merged with Implementation.md)  
**Next Review:** End of Month 1 (January 31, 2026)
