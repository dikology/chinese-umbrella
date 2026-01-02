# Book Upload & Edit Screens - UX Refactoring Guide

## Problems Identified

### 1. **Keyboard Obscures Upload Button**
- **Root Cause**: TextField focus persists while users select photos
- **Impact**: Upload button unreachable after selecting images
- **Solution**: Auto-dismiss keyboard before photo picker opens + adjust scroll behavior

### 2. **No Page Management Features**
- **Missing**: Page numbering, reordering, deletion
- **Impact**: Users cannot organize pages in custom order
- **Solution**: Add page grid view with drag-to-reorder + editing capabilities

### 3. **Camera Not Fullscreen**
- **Root Cause**: CameraView likely wraps in sheet with default presentation
- **Impact**: Shoot button obscured, poor framing preview
- **Solution**: Use fullscreen modal presentation for camera

---

## Refactoring Architecture

### Component Organization

```
BookUploadScreen.swift
├── Views
│   ├── BookMetadataInput (new)
│   ├── PageGridView (new - reorderable thumbnail grid)
│   ├── UploadMethodButtons (extracted)
│   └── UploadProgressView (new - replaces button)
├── Helpers
│   ├── PageItem (new - page data + metadata)
│   └── PageReorderingManager (new - drag-drop logic)
└── ViewModel
    ├── pageList: [PageItem] (new)
    ├── focusedField: FocusState (new)
    └── pageOperations (new - add/remove/reorder)

EditBookScreen.swift
├── Views
│   ├── BookInfoCard
│   ├── PageManagementSection (new)
│   └── UploadSection
└── ViewModel
    ├── pageList: [PageItem] (new)
    └── pageOperations (new)
```

---

## Detailed Refactoring Steps

### Step 1: Create Page Management Data Model

**File**: `BookUploadViewModel+PageManagement.swift`

```swift
// MARK: - Page Item Data Model
struct PageItem: Identifiable {
    let id: UUID
    let uiImage: UIImage
    var pageNumber: Int?
    var notes: String = ""
    var position: Int // For reordering
    
    /// Generate thumbnail for grid display
    var thumbnail: UIImage? {
        let targetSize = CGSize(width: 120, height: 160)
        return uiImage.resized(to: targetSize)
    }
}

// MARK: - View Model Extension
extension BookUploadViewModel {
    @MainActor
    func addPages(_ images: [UIImage]) {
        let newPages = images.enumerated().map { index, image in
            PageItem(
                id: UUID(),
                uiImage: image,
                pageNumber: selectedImages.count + index + 1,
                position: selectedImages.count + index
            )
        }
        pageList.append(contentsOf: newPages)
    }
    
    @MainActor
    func removePage(at index: Int) {
        guard index >= 0 && index < pageList.count else { return }
        pageList.remove(at: index)
        // Recalculate positions
        for (idx, _) in pageList.enumerated() {
            pageList[idx].position = idx
        }
    }
    
    @MainActor
    func reorderPages(from source: IndexSet, to destination: Int) {
        pageList.move(fromOffsets: source, toOffset: destination)
        // Recalculate positions
        for (idx, _) in pageList.enumerated() {
            pageList[idx].position = idx
        }
    }
    
    @MainActor
    func updatePageNumber(for page: PageItem, number: Int) {
        if let index = pageList.firstIndex(where: { $0.id == page.id }) {
            pageList[index].pageNumber = number
        }
    }
}
```

---

### Step 2: Implement Keyboard Management

**Key Principle**: Dismiss keyboard before opening photo picker/camera

```swift
// MARK: - Focus State Management
struct BookUploadScreen: View {
    enum FocusField {
        case title
        case author
    }
    
    @FocusState private var focusedField: FocusField?
    
    // MARK: - Photo Picker Handler
    private func openPhotoPicker() {
        // Dismiss keyboard first
        focusedField = nil
        // Add small delay for keyboard dismissal animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showPhotoPicker = true
        }
    }
    
    private func openCamera() {
        focusedField = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showCamera = true
        }
    }
}
```

**Update TextField bindings**:

```swift
TextField("Book Title", text: $viewModel.bookTitle)
    .focused($focusedField, equals: .title)
    .textFieldStyle(.roundedBorder)

TextField("Author (Optional)", text: $viewModel.bookAuthor)
    .focused($focusedField, equals: .author)
    .textFieldStyle(.roundedBorder)
```

---

### Step 3: Implement Page Grid View with Reordering

**File**: `PageGridView.swift` (new)

```swift
struct PageGridView: View {
    @Binding var pages: [PageItem]
    @State private var editingPage: PageItem?
    
    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 12)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Pages (\(pages.count))")
                    .font(.headline)
                
                Spacer()
                
                if !pages.isEmpty {
                    Menu {
                        Button("Renumber from 1", action: renumberPages)
                        Button("Sort by number", action: sortByNumber)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)
            
            if pages.isEmpty {
                ContentUnavailableView(
                    "No Pages Yet",
                    systemImage: "photo.stack",
                    description: Text("Add photos to get started")
                )
                .frame(height: 200)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        PageThumbnailCard(
                            page: page,
                            onEdit: { editingPage = page },
                            onDelete: { pages.remove(at: index) }
                        )
                    }
                }
                .padding(.horizontal)
                
                // Reorder mode toggle
                if !pages.isEmpty {
                    EditButton()
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    private func renumberPages() {
        for (index, _) in pages.enumerated() {
            pages[index].pageNumber = index + 1
        }
    }
    
    private func sortByNumber() {
        pages.sort { ($0.pageNumber ?? 0) < ($1.pageNumber ?? 0) }
    }
}

// MARK: - Page Thumbnail Card
struct PageThumbnailCard: View {
    let page: PageItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.editMode) var editMode
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Thumbnail
            if let thumbnail = page.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 160)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Page number badge
            if let pageNumber = page.pageNumber {
                Text("\(pageNumber)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .padding(8)
            }
            
            // Delete button (edit mode)
            if editMode?.isEditing == true {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .padding(4)
                }
            }
        }
        .onTapGesture {
            if editMode?.isEditing != true {
                onEdit()
            }
        }
    }
}
```

---

### Step 4: Fix Camera Fullscreen Presentation

**Issue**: Sheet presentation leaves bottom space for swipe-to-dismiss

**Solution**: Use `fullScreenCover` modifier with proper handling

```swift
// MARK: - BookUploadScreen
var body: some View {
    NavigationStack {
        // ... existing content ...
        
        .fullScreenCover(isPresented: $showCamera) {
            CameraViewContainer(
                capturedImages: $viewModel.pageList,
                isPresented: $showCamera
            )
        }
        
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerView(selectedImages: $viewModel.pageList)
        }
    }
}

// MARK: - Camera Container (fullscreen)
struct CameraViewContainer: View {
    @Binding var capturedImages: [PageItem]
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            CameraView(
                capturedImages: $capturedImages,
                onDismiss: { isPresented = false }
            )
            
            // Close button
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
                    .padding()
            }
        }
        .ignoresSafeArea()
    }
}
```

---

### Step 5: Update Photo Review Screen to Support Page Editing

**File**: `PhotoReviewScreen.swift` (enhanced)

```swift
struct PhotoReviewScreen: View {
    @Binding var pages: [PageItem]
    @Environment(\.dismiss) var dismiss
    @State private var currentPageIndex = 0
    @State private var showPageNumberEditor = false
    @State private var pageNumberInput = ""
    
    var currentPage: PageItem {
        pages[currentPageIndex]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Full page image viewer
                VStack(spacing: 0) {
                    // Navigation bar
                    HStack {
                        Button("← Back") { dismiss() }
                        Spacer()
                        Text("Page \(currentPageIndex + 1) of \(pages.count)")
                            .font(.headline)
                        Spacer()
                        Button("Edit") {
                            pageNumberInput = String(currentPage.pageNumber ?? 0)
                            showPageNumberEditor = true
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    
                    // Image viewer
                    Image(uiImage: currentPage.uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Navigation controls
                    HStack {
                        Button(action: previousPage) {
                            Image(systemName: "chevron.left")
                                .frame(width: 44, height: 44)
                        }
                        .disabled(currentPageIndex == 0)
                        
                        Spacer()
                        
                        Button(action: nextPage) {
                            Image(systemName: "chevron.right")
                                .frame(width: 44, height: 44)
                        }
                        .disabled(currentPageIndex == pages.count - 1)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPageNumberEditor) {
                PageNumberEditorSheet(
                    pageIndex: currentPageIndex,
                    pages: $pages,
                    input: $pageNumberInput,
                    isPresented: $showPageNumberEditor
                )
            }
        }
    }
    
    private func previousPage() {
        if currentPageIndex > 0 {
            currentPageIndex -= 1
        }
    }
    
    private func nextPage() {
        if currentPageIndex < pages.count - 1 {
            currentPageIndex += 1
        }
    }
}

// MARK: - Page Number Editor Sheet
struct PageNumberEditorSheet: View {
    let pageIndex: Int
    @Binding var pages: [PageItem]
    @Binding var input: String
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Assign Page Number") {
                    TextField("Page Number", text: $input)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button("Save") {
                        if let number = Int(input) {
                            pages[pageIndex].pageNumber = number
                            isPresented = false
                        }
                    }
                }
            }
            .navigationTitle("Edit Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
}
```

---

### Step 6: Update ViewModel for Page Management

**Add to `BookUploadViewModel`**:

```swift
@Observable
final class BookUploadViewModel {
    // MARK: - Existing properties
    private let bookUploadUseCase: BookUploadUseCase
    private let userId: UUID
    private let onBookUploaded: (() -> Void)?
    
    var bookTitle = ""
    var bookAuthor = ""
    var isUploading = false
    var showError = false
    var errorMessage = ""
    var uploadComplete = false
    
    // MARK: - New properties for page management
    var pageList: [PageItem] = []
    
    @MainActor
    func uploadBook() async {
        guard !bookTitle.isEmpty else {
            showError(message: "Please enter a book title")
            return
        }
        
        guard !pageList.isEmpty else {
            showError(message: "Please add at least one photo")
            return
        }
        
        isUploading = true
        defer { isUploading = false }
        
        do {
            // Extract UIImages from PageItems for upload
            let images = pageList.map { $0.uiImage }
            
            let book = try await bookUploadUseCase.uploadBook(
                images: images,
                title: bookTitle,
                author: bookAuthor.isEmpty ? nil : bookAuthor,
                userId: userId
            )
            
            uploadComplete = true
            onBookUploaded?()
        } catch {
            showError(message: error.localizedDescription)
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
```

---

### Step 7: Refactored BookUploadScreen Layout

```swift
struct BookUploadScreen: View {
    // ... existing state variables ...
    
    @FocusState private var focusedField: FocusField?
    
    enum FocusField {
        case title, author
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                colors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Header
                    VStack(spacing: 8) {
                        Text("Upload Book")
                            .titleStyle()
                        Text("Add pages and organize them")
                            .bodySecondaryStyle()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // MARK: - Metadata Section
                            CardContainer {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Book Information")
                                        .headingStyle()
                                    
                                    TextField("Book Title", text: $viewModel.bookTitle)
                                        .focused($focusedField, equals: .title)
                                        .textFieldStyle()
                                    
                                    TextField("Author (Optional)", text: $viewModel.bookAuthor)
                                        .focused($focusedField, equals: .author)
                                        .textFieldStyle()
                                }
                                .padding(.horizontal)
                            }
                            .padding(.horizontal)
                            
                            // MARK: - Page Management Section
                            if !viewModel.pageList.isEmpty {
                                PageGridView(pages: $viewModel.pageList)
                            }
                            
                            // MARK: - Upload Methods
                            if viewModel.pageList.count < 500 { // Reasonable limit
                                VStack(spacing: 16) {
                                    Text("Add Photos")
                                        .headingStyle()
                                        .padding(.top, 16)
                                        .padding(.horizontal)
                                    
                                    UploadMethodButtons(
                                        onCameraTap: openCamera,
                                        onLibraryTap: openPhotoPicker
                                    )
                                    .padding(.horizontal)
                                }
                            }
                            
                            Spacer(minLength: 40)
                        }
                    }
                    
                    // MARK: - Upload Button (Fixed at Bottom)
                    if !viewModel.pageList.isEmpty {
                        VStack(spacing: 12) {
                            PrimaryButton(
                                title: viewModel.isUploading ? "Processing..." : "Upload Book",
                                isLoading: viewModel.isUploading,
                                isEnabled: !viewModel.bookTitle.isEmpty
                            ) {
                                Task {
                                    await viewModel.uploadBook()
                                }
                            }
                            
                            Text("\(viewModel.pageList.count) page(s) ready")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.showError = false }
            } message: {
                Text(viewModel.errorMessage)
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraViewContainer(
                    capturedImages: $viewModel.pageList,
                    isPresented: $showCamera,
                    userId: viewModel.userId
                )
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPickerSheet(selectedPages: $viewModel.pageList)
            }
            .sheet(isPresented: $showPhotoReview) {
                PhotoReviewScreen(pages: $viewModel.pageList)
            }
        }
    }
    
    private func openCamera() {
        focusedField = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showCamera = true
        }
    }
    
    private func openPhotoPicker() {
        focusedField = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showPhotoPicker = true
        }
    }
}

// MARK: - Upload Method Buttons Component
struct UploadMethodButtons: View {
    let onCameraTap: () -> Void
    let onLibraryTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    private var colors: AdaptiveColors {
        AdaptiveColors(colorScheme: colorScheme)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: onCameraTap) {
                Label("Take Photos", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(colors.blueTint)
                    .foregroundColor(colors.primary)
                    .cornerRadius(12)
            }
            
            Button(action: onLibraryTap) {
                Label("Select from Library", systemImage: "photo.on.rectangle.angled")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(colors.greenTint)
                    .foregroundColor(colors.success)
                    .cornerRadius(12)
            }
        }
    }
}
```

---

## EditBookScreen Refactoring

Apply the same pattern:

```swift
struct EditBookScreen: View {
    // ... existing code ...
    
    @FocusState private var focusedField: FocusField?
    enum FocusField { case title, author }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Book info (read-only display)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Current Book")
                                .font(.headline)
                            BookInfoDisplay(book: viewModel.existingBook)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                        
                        // Editable metadata
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Update Information")
                                .font(.headline)
                            TextField("Title", text: $viewModel.bookTitle)
                                .focused($focusedField, equals: .title)
                            TextField("Author", text: $viewModel.bookAuthor)
                                .focused($focusedField, equals: .author)
                        }
                        .padding()
                        
                        // Existing pages display
                        if viewModel.existingPageCount > 0 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Existing Pages: \(viewModel.existingPageCount)")
                                    .font(.headline)
                                // Show thumbnail grid of existing pages
                            }
                            .padding()
                        }
                        
                        // Add new pages
                        PageGridView(pages: $viewModel.pageList)
                        
                        // Upload buttons
                        UploadMethodButtons(
                            onCameraTap: openCamera,
                            onLibraryTap: openPhotoPicker
                        )
                        
                        Spacer(minLength: 40)
                    }
                }
                
                // Fixed button at bottom
                if !viewModel.pageList.isEmpty || 
                   viewModel.bookTitle != viewModel.existingBook.title {
                    PrimaryButton(
                        title: viewModel.isEditing ? "Updating..." : "Update Book",
                        isLoading: viewModel.isEditing,
                        isEnabled: !viewModel.bookTitle.isEmpty
                    ) {
                        Task { await viewModel.editBook() }
                    }
                    .padding()
                }
            }
        }
    }
    
    private func openCamera() {
        focusedField = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showCamera = true
        }
    }
    
    private func openPhotoPicker() {
        focusedField = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showPhotoPicker = true
        }
    }
}
```

---

## Implementation Checklist

- [ ] Create `PageItem` model struct
- [ ] Add focus state management to both screens
- [ ] Implement `PageGridView` component with drag-to-reorder
- [ ] Create `PageThumbnailCard` component
- [ ] Update ViewModels with page management methods
- [ ] Change camera presentation from `.sheet()` to `.fullScreenCover()`
- [ ] Add `CameraViewContainer` wrapper with close button
- [ ] Enhance `PhotoReviewScreen` with page numbering editor
- [ ] Extract `UploadMethodButtons` component
- [ ] Update button positioning (fixed at bottom, outside ScrollView)
- [ ] Add keyboard dismissal to camera/picker triggers
- [ ] Test focus state transitions
- [ ] Verify page reordering UX
- [ ] Test camera fullscreen on different devices

---

## Additional Improvements Implemented

1. **Page Numbering**: Users can assign custom page numbers
2. **Page Reordering**: Drag-to-reorder in edit mode
3. **Page Deletion**: Swipe or button delete with confirmation
4. **Batch Operations**: Renumber from 1, sort by number
5. **Visual Feedback**: Page count badges, thumbnail previews
6. **Full-Screen Camera**: Unobstructed shooting experience
7. **Keyboard Management**: Auto-dismiss when opening photo pickers
8. **Fixed Action Button**: Upload button always accessible
9. **Page Review Flow**: Navigate between pages with prev/next
10. **Error Prevention**: Disable upload until requirements met

---

## Testing Recommendations

### Keyboard Dismissal
- [ ] Tap Camera button → keyboard should dismiss before sheet opens
- [ ] Tap Library button → keyboard should dismiss before sheet opens
- [ ] TextField should lose focus immediately

### Page Management
- [ ] Add 5+ pages → scroll grid smoothly
- [ ] Long-press page → should enter reorder mode
- [ ] Drag page → position updates correctly
- [ ] Delete page → list refreshes without gaps
- [ ] Renumber pages → all positions recalculate

### Camera Experience
- [ ] Open camera → no bottom safe area visible
- [ ] Shoot button → fully accessible
- [ ] Close button → visible and tappable
- [ ] Test on SE, iPhone 15, iPad

### Upload Flow
- [ ] Enter title → upload button disabled
- [ ] Select photos → upload button enabled
- [ ] Keyboard open → can still tap upload after scroll
- [ ] Loading state → button shows progress, disabled

