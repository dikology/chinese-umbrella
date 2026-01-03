# Authentication Strategy - Chinese Umbrella iOS App

**Document Version:** 1.0  
**Last Updated:** January 3, 2026  
**Status:** Phase 1 Implementation Plan

---

## Executive Summary

This document outlines the authentication strategy for the Chinese Umbrella iOS app across different phases of development. **For Phase 1 (local-only app), we recommend disabling the current authentication system** and using an auto-created anonymous user. Authentication will be re-introduced in Phase 2 when multi-device sync and web portal features are implemented.

**Key Recommendations:**
- ✅ **Phase 1**: Remove auth screens, auto-create anonymous local user
- ✅ Fix hardcoded UUID issue by using the anonymous user's ID
- ✅ **Phase 2+**: Re-enable authentication with data migration path

---

## Current Implementation Analysis

### What Exists Now

The codebase has a **fully implemented authentication system**:

#### Components
1. **Auth Domain Layer**
   - `AppUser` entity (`Domain/Entities/User.swift`)
   - `AuthRepository` protocol
   - `AuthUseCase` with signup, login, Apple Sign In
   - `AuthError` enum with typed errors

2. **Auth Data Layer**
   - `AuthRepositoryImpl` with Core Data persistence
   - `UserEntity` Core Data model
   - Password hashing (simple SHA256 for Phase 1)
   - Apple ID credential handling

3. **Auth Presentation Layer**
   - `AuthViewModel` with form validation
   - `AuthScreen` UI with email/password and Apple Sign In
   - Loading states, error handling

4. **Infrastructure**
   - `KeychainService` for storing auth tokens
   - Session management (currentUserId stored in Keychain)

#### Current User Flow
```
App Launch
  ↓
Check if authenticated (AuthViewModel.checkAuthenticationStatus)
  ↓
  ├─ YES → Show LibraryScreen
  └─ NO  → Show AuthScreen (blocks access to app)
```

**Source:** `umbrellaApp.swift:30-38`

```swift
if authViewModel.isAuthenticated {
    ContentView(authViewModel: authViewModel)
} else {
    AuthScreen(viewModel: authViewModel)
}
```

---

## The Problem with Current Approach for Phase 1

### Issue #1: UX Friction for Local-Only App

**Current Behavior:** Users must create an account before reading any books.

**Problems:**
- Unnecessary signup friction for a local-only reading app
- No network sync means authentication provides no value
- Users bounced at the gate before experiencing the app's core value proposition

**User Expectation:** Install app → Open app → Start reading immediately

### Issue #2: Hardcoded UUID Breaking Data Integrity

**Location:** `ReadingViewModel.swift:146`

```swift
let markedWord = AppMarkedWord(
    userId: UUID(), // TODO: Get from auth context
    word: word,
    readingDate: Date(),
    ...
)
```

**Impact:**
- Every marked word gets a **random UUID** as userId
- Impossible to query "all words marked by this user"
- Data corruption when multiple reading sessions create different UUIDs
- Breaks relationship between `UserEntity` and `MarkedWord` entities

**Why It Exists:** ReadingViewModel doesn't have access to current user ID because:
1. No userId passed to `DIContainer.makeReadingViewModel()`
2. ReadingViewModel doesn't hold reference to AuthViewModel
3. The TODO indicates this was known but deferred

### Issue #3: Multi-User Architecture with Single User

**Current Schema:** Core Data supports multiple users
- User entity has one-to-many relationships with Books and MarkedWords
- All queries filter by `userId` (see `BookRepositoryImpl:75, 175, 192`)

**Phase 1 Reality:** Only one user per device (no account switching, no sync)

**Result:** Architectural overhead with no benefit

---

## Recommended Phase 1 Strategy: Anonymous User

### Approach: Auto-Create Default User on First Launch

Instead of forcing authentication, **create a single anonymous user automatically** and use it for all data.

#### Implementation Plan

**Step 1: Create Anonymous User Service**

Create `AnonymousUserService.swift`:

```swift
// Infrastructure/Services/AnonymousUserService.swift
import Foundation

final class AnonymousUserService {
    private let keychainService: KeychainService
    private let authRepository: AuthRepository
    
    private let anonymousUserIdKey = "anonymousUserId"
    
    init(keychainService: KeychainService, authRepository: AuthRepository) {
        self.keychainService = keychainService
        self.authRepository = authRepository
    }
    
    /// Get or create the anonymous user for this device
    func getOrCreateAnonymousUser() async throws -> AppUser {
        // Check if we already have an anonymous user ID
        if let existingId = try? keychainService.retrieve(key: anonymousUserIdKey),
           let userId = UUID(uuidString: existingId),
           let user = try? await authRepository.getUserById(userId) {
            return user
        }
        
        // Create new anonymous user
        let anonymousUser = AppUser(
            email: "anonymous@local.device",
            displayName: "Local User",
            hskLevel: 1,
            vocabularyMasteryPct: 0.0
        )
        
        // Save to Core Data
        let savedUser = try await saveAnonymousUser(anonymousUser)
        
        // Store ID for future launches
        try keychainService.store(key: anonymousUserIdKey, value: savedUser.id.uuidString)
        
        return savedUser
    }
    
    private func saveAnonymousUser(_ user: AppUser) async throws -> AppUser {
        // Direct Core Data save bypassing auth repository's validation
        // (since anonymous user doesn't have real email/password)
        // Implementation details...
        return user
    }
}
```

**Step 2: Update App Launch Flow**

Modify `umbrellaApp.swift`:

```swift
@main
struct umbrellaApp: App {
    @State private var currentUser: AppUser?
    @State private var isInitializing = true
    let coreDataManager = CoreDataManager.shared

    init() {
        // Preload dictionary
        Task {
            do {
                try DIContainer.dictionaryService.preloadDictionary()
                print("Dictionary preloaded successfully")
            } catch {
                print("Failed to preload dictionary: \(error)")
            }
        }
        
        // Get or create anonymous user
        Task { @MainActor in
            do {
                let anonymousService = DIContainer.anonymousUserService
                currentUser = try await anonymousService.getOrCreateAnonymousUser()
                isInitializing = false
            } catch {
                print("Failed to initialize anonymous user: \(error)")
                // Create fallback user
                currentUser = AppUser(
                    email: "fallback@local.device",
                    displayName: "Local User"
                )
                isInitializing = false
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            if isInitializing {
                // Show splash/loading screen while initializing
                LoadingView()
            } else if let user = currentUser {
                // Go directly to main app
                ContentView(currentUser: user)
                    .environment(\.managedObjectContext, coreDataManager.viewContext)
            }
        }
    }
}
```

**Step 3: Pass User ID Through View Hierarchy**

Update `ContentView.swift`:

```swift
struct ContentView: View {
    let currentUser: AppUser
    
    var body: some View {
        LibraryScreen(
            viewModel: LibraryViewModel(
                bookRepository: DIContainer.bookRepository,
                userId: currentUser.id
            )
        )
    }
}
```

**Step 4: Fix ReadingViewModel Hardcoded UUID**

Update `DIContainer.swift`:

```swift
@MainActor
static func makeReadingViewModel(userId: UUID) -> ReadingViewModel {
    return ReadingViewModel(
        userId: userId,  // ✅ Pass user ID
        bookRepository: bookRepository,
        dictionaryRepository: dictionaryRepository,
        wordMarkerRepository: wordMarkerRepository,
        textSegmentationService: textSegmentationService
    )
}
```

Update `ReadingViewModel.swift`:

```swift
@Observable
final class ReadingViewModel {
    private let userId: UUID  // ✅ Store user ID
    
    // ... other properties
    
    init(
        userId: UUID,  // ✅ Accept user ID
        bookRepository: BookRepository,
        dictionaryRepository: DictionaryRepository,
        wordMarkerRepository: WordMarkerRepository,
        textSegmentationService: TextSegmentationService
    ) {
        self.userId = userId
        self.bookRepository = bookRepository
        self.dictionaryRepository = dictionaryRepository
        self.wordMarkerRepository = wordMarkerRepository
        self.textSegmentationService = textSegmentationService
    }
    
    func markWordAsDifficult(_ word: String) async {
        // ...
        let markedWord = AppMarkedWord(
            userId: self.userId,  // ✅ Use actual user ID
            word: word,
            readingDate: Date(),
            contextSnippet: extractContextSnippet(for: word),
            textId: currentBook?.id ?? UUID(),
            pageNumber: currentPageIndex + 1
        )
        _ = try await wordMarkerRepository.markWord(markedWord)
    }
}
```

Update `ReadingScreen.swift` to pass userId when creating ReadingViewModel.

**Step 5: Update LibraryViewModel**

Remove dependency on `AuthViewModel`:

```swift
final class LibraryViewModel {
    private let bookRepository: BookRepository
    private let userId: UUID  // ✅ Direct userId instead of AuthViewModel
    
    // Remove AuthViewModelProtocol
    
    init(bookRepository: BookRepository, userId: UUID) {
        self.bookRepository = bookRepository
        self.userId = userId
    }
    
    @MainActor
    func loadBooks() async {
        // Use self.userId directly instead of authViewModel.currentUser?.id
        guard let books = try? await bookRepository.getBooks(for: userId) else {
            return
        }
        self.books = books
        applyFiltering()
    }
}
```

**Step 6: Disable Auth-Related Code (Don't Delete)**

Keep all auth code but mark as Phase 2:

```swift
// Phase 1: Commented out, will re-enable in Phase 2
// import AuthenticationServices

// Phase 2: Re-enable authentication
// static let authViewModel = AuthViewModel(authUseCase: authUseCase)
// static let authUseCase = AuthUseCase(repository: authRepository, keychainService: keychainService)
```

Add comments to auth files:

```swift
// AuthScreen.swift
// ⚠️ Phase 1: This screen is not used (anonymous user auto-created)
// Phase 2: Re-enable when implementing multi-device sync
```

---

## Phase 1 Architecture Summary

### Data Flow
```
App Launch
  ↓
AnonymousUserService.getOrCreateAnonymousUser()
  ↓
Check Keychain for "anonymousUserId"
  ↓
  ├─ Found → Fetch user from Core Data → Return user
  └─ Not Found → Create new user → Save to Core Data → Store ID in Keychain → Return user
  ↓
Pass user.id through view hierarchy
  ↓
ReadingViewModel uses actual userId (not random UUID)
  ↓
All books, marked words correctly associated with user
```

### Benefits
✅ **No UX friction** - Users start reading immediately  
✅ **Data integrity** - All data correctly associated with single user  
✅ **Simple architecture** - No multi-user complexity in Phase 1  
✅ **Future-proof** - Easy to migrate to authenticated users in Phase 2  
✅ **Keeps existing code** - Auth system remains intact, just disabled

---

## Phase 2+: Re-Enable Authentication

### When to Re-Introduce Auth

**Triggers:**
- Multi-device sync implementation (iCloud, backend API)
- Web portal for adding/managing books from desktop
- Family/classroom sharing features
- Analytics tied to user accounts

**PRD Reference:** See `umbrella-prd.md` Phase 2 (Months 5-10) - Multi-Platform Sync

### Migration Path from Anonymous to Authenticated User

When user signs up/logs in for the first time:

```swift
func migrateAnonymousDataToAuthenticatedUser(newUser: AppUser, anonymousUserId: UUID) async throws {
    // 1. Update all books to new user
    try await bookRepository.transferBooks(from: anonymousUserId, to: newUser.id)
    
    // 2. Update all marked words to new user
    try await wordMarkerRepository.transferMarkedWords(from: anonymousUserId, to: newUser.id)
    
    // 3. Update reading progress
    try await progressRepository.transferProgress(from: anonymousUserId, to: newUser.id)
    
    // 4. Delete anonymous user
    try await authRepository.deleteUser(anonymousUserId)
    
    // 5. Clear anonymous user ID from Keychain
    try keychainService.delete(key: "anonymousUserId")
    
    // 6. Store authenticated user session
    try keychainService.store(key: "currentUserId", value: newUser.id.uuidString)
}
```

### Phase 2 Features to Implement

1. **Optional Authentication**
   - "Continue without account" → Keep using anonymous user
   - "Sign up / Log in" → Migrate data, enable sync

2. **Multi-Device Sync**
   - Backend API for syncing books, progress, marked words
   - Conflict resolution (last-write-wins or operational transformation)
   - Offline queue for pending changes

3. **Account Management**
   - Settings screen with "Sign out" option
   - User profile (display name, HSK level, vocabulary stats)
   - Delete account (with data export option)

4. **Re-Enable Apple Sign In**
   - Simplest auth flow for iOS users
   - No password management needed
   - Automatic keychain integration

---

## Implementation Checklist

### Phase 1 - Anonymous User (This Sprint)

**Priority 0 (Must Fix Now):**
- [ ] Create `AnonymousUserService.swift`
- [ ] Update `umbrellaApp.swift` to auto-create anonymous user
- [ ] Add `userId: UUID` parameter to `ReadingViewModel` init
- [ ] Fix line 146 in `ReadingViewModel.swift` to use `self.userId`
- [ ] Update `DIContainer.makeReadingViewModel()` to accept userId
- [ ] Pass userId from LibraryScreen → ReadingScreen → ReadingViewModel
- [ ] Remove `AuthViewModel` dependency from `LibraryViewModel`
- [ ] Add `userId: UUID` parameter to `LibraryViewModel` init
- [ ] Test: Create book → Mark words → Verify userId is consistent

**Priority 1 (Clean Up):**
- [ ] Comment out `AuthScreen` in navigation
- [ ] Add "Phase 2" comments to all auth-related files
- [ ] Remove unused `AuthViewModelProtocol` (or keep for Phase 2)
- [ ] Update README to note "Auth system disabled in Phase 1"

**Priority 2 (Nice to Have):**
- [ ] Add simple onboarding screen (skip auth, show app features)
- [ ] Add "Settings" screen with user display name edit
- [ ] Add HSK level selection (stored in anonymous user profile)

### Phase 2 - Multi-Device Sync (Future)

**Backend Requirements:**
- [ ] Design REST API for user authentication
- [ ] Implement JWT token-based session management
- [ ] Create sync endpoints (books, progress, marked words)
- [ ] Set up PostgreSQL with user/book/progress tables

**iOS Changes:**
- [ ] Re-enable `AuthScreen` with "Continue as Guest" option
- [ ] Implement data migration from anonymous → authenticated user
- [ ] Add API client layer for network sync
- [ ] Implement offline sync queue with conflict resolution
- [ ] Add "Sign out" functionality (keep local data or delete)
- [ ] Test migration path thoroughly

**Web Portal (Phase 2):**
- [ ] Build Next.js web app with same auth system
- [ ] Share backend API for book management
- [ ] OCR upload from desktop (easier than mobile for PDFs)

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **Data loss during Phase 2 migration** | High | Implement comprehensive migration tests; add data export before migration; keep anonymous data as backup |
| **User confusion about "anonymous" vs "authenticated"** | Medium | Clear UI messaging: "Sign up to sync across devices"; Add in-app explanation |
| **Keychain data lost (anonymous user ID)** | Medium | Graceful fallback: If anonymousUserId not found but Core Data has users, pick first user; Alert user if data can't be recovered |
| **Core Data corruption breaking anonymous user fetch** | Low | Add error handling; create new anonymous user if fetch fails; Log error to crash reporting |

---

## Testing Strategy

### Phase 1 Tests

**Unit Tests:**
```swift
// AnonymousUserServiceTests.swift
@Test("Creates new anonymous user on first launch")
func testCreateAnonymousUser() async throws {
    let service = AnonymousUserService(...)
    let user = try await service.getOrCreateAnonymousUser()
    #expect(user.email == "anonymous@local.device")
    #expect(user.id != nil)
}

@Test("Returns same user on subsequent launches")
func testReturnsExistingUser() async throws {
    let service = AnonymousUserService(...)
    let user1 = try await service.getOrCreateAnonymousUser()
    let user2 = try await service.getOrCreateAnonymousUser()
    #expect(user1.id == user2.id)
}

// ReadingViewModelTests.swift
@Test("Marked words use correct userId")
func testMarkedWordUsesActualUserId() async throws {
    let userId = UUID()
    let viewModel = ReadingViewModel(userId: userId, ...)
    await viewModel.markWordAsDifficult("你好")
    
    let markedWords = try await wordMarkerRepository.getMarkedWords(for: userId)
    #expect(markedWords.first?.userId == userId)
}
```

**Integration Tests:**
```swift
@Test("Anonymous user persists across app restarts")
func testAnonymousUserPersistence() async throws {
    // Launch 1
    let user1 = try await anonymousService.getOrCreateAnonymousUser()
    let userId1 = user1.id
    
    // Simulate app restart (clear in-memory state)
    // ...
    
    // Launch 2
    let user2 = try await anonymousService.getOrCreateAnonymousUser()
    #expect(user2.id == userId1)
}

@Test("Books and marked words query correctly with anonymous user")
func testDataIntegrityWithAnonymousUser() async throws {
    let user = try await anonymousService.getOrCreateAnonymousUser()
    
    // Create book
    let book = AppBook(...)
    try await bookRepository.saveBook(book, userId: user.id)
    
    // Mark word
    let markedWord = AppMarkedWord(userId: user.id, word: "你好", ...)
    try await wordMarkerRepository.markWord(markedWord)
    
    // Query
    let books = try await bookRepository.getBooks(for: user.id)
    let markedWords = try await wordMarkerRepository.getMarkedWords(for: user.id)
    
    #expect(books.count == 1)
    #expect(markedWords.count == 1)
}
```

### Phase 2 Migration Tests

```swift
@Test("Migrate anonymous user data to authenticated user")
func testDataMigration() async throws {
    // Setup: Anonymous user with books and marked words
    let anonymousUser = try await anonymousService.getOrCreateAnonymousUser()
    let book = AppBook(...)
    try await bookRepository.saveBook(book, userId: anonymousUser.id)
    
    // Migrate to authenticated user
    let newUser = AppUser(email: "real@example.com", displayName: "Real User")
    try await migrationService.migrateData(from: anonymousUser.id, to: newUser.id)
    
    // Verify: Data now associated with new user
    let books = try await bookRepository.getBooks(for: newUser.id)
    #expect(books.count == 1)
    
    let anonymousBooks = try await bookRepository.getBooks(for: anonymousUser.id)
    #expect(anonymousBooks.count == 0)
}
```

---

## Conclusion

### Phase 1 Summary

**Recommended Approach:** Disable authentication, use auto-created anonymous user

**Impact:**
- ✅ **Fixes critical bug** (hardcoded UUID in ReadingViewModel)
- ✅ **Improves UX** (no signup friction for local app)
- ✅ **Maintains data integrity** (all data correctly associated)
- ✅ **Preserves architecture** (auth code ready for Phase 2)

**Effort Estimate:** 4-6 hours
- 2 hours: Implement `AnonymousUserService`
- 1 hour: Update ViewModels to accept/use userId
- 1 hour: Update app launch flow
- 1-2 hours: Testing and debugging

### Next Steps

1. **Immediate:** Implement anonymous user service (this sprint)
2. **Short-term:** Test thoroughly, remove auth screens from navigation
3. **Long-term (Phase 2):** Re-enable authentication with migration path when building sync features

### Key Principle

> **Phase 1 = Local First, Simple UX**  
> Don't add complexity (authentication) until it provides value (multi-device sync)

---

**Document Status:** Ready for Implementation  
**Reviewed By:** Senior iOS Engineer  
**Next Review:** After Phase 1 completion, before Phase 2 planning

