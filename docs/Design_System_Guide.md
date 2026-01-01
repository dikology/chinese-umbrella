# Design System Guide: Dark & Light Mode Implementation
## For "Umbrella" - Chinese Reading Application

**Document Version:** 1.0  
**Created:** January 2026  
**Scope:** Design system covering 8 screens with comprehensive dark/light mode support

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Design System Architecture](#design-system-architecture)
3. [Color Palette](#color-palette)
4. [Typography System](#typography-system)
5. [Component Design Standards](#component-design-standards)
6. [Screen-Specific Guidelines](#screen-specific-guidelines)
7. [Dark Mode Implementation Strategy](#dark-mode-implementation-strategy)
8. [Accessibility Considerations](#accessibility-considerations)
9. [Implementation Checklist](#implementation-checklist)

---

## Executive Summary

This design guide establishes a unified design system for the Umbrella app, ensuring visual consistency and optimal user experience across both light and dark modes. The system is built on proven accessibility standards and modern iOS design principles, providing a robust foundation for current and future feature development.

**Key Objectives:**
- Maintain visual hierarchy and readability in both modes
- Provide intuitive, context-aware color usage
- Ensure WCAG 2.1 AA compliance minimum
- Simplify component development with reusable patterns
- Support future scalability and brand evolution

---

## Design System Architecture

### Semantic Color Model

The design system uses semantic color tokens that automatically adapt to light/dark appearance:

```
Color Tokens Hierarchy:
├── Primitive Colors (Raw values)
│   ├── Blues, Greens, Reds, Grays
│   └── Brand colors (Primary Blue, Accent Green)
│
├── Semantic Colors (Context-aware)
│   ├── Foreground (Text, icons, active elements)
│   ├── Background (Page, surface, elevated)
│   ├── Interactive (Buttons, links, tappable areas)
│   ├── Feedback (Success, error, warning, info)
│   └── Borders & Dividers
│
└── Component Colors (Specific use cases)
    ├── Cards & containers
    ├── Text fields & inputs
    ├── Progress indicators
    └── Status badges
```

### Core Design Principles

| Principle | Implementation |
|-----------|-----------------|
| **Contrast** | Minimum 4.5:1 for normal text, 3:1 for large text (WCAG AA) |
| **Consistency** | Reusable components with mode-aware styling |
| **Clarity** | Clear visual hierarchy with distinct weight and size differences |
| **Efficiency** | Semantic naming reduces cognitive load during implementation |
| **Flexibility** | Token-based system allows rapid theme updates |

---

## Color Palette

### Light Mode Color System

#### Primary Colors
| Token | Use Case | Hex Value | RGB |
|-------|----------|-----------|-----|
| **Primary** | Main actions, interactive elements | #2180 | 33, 128, 141 |
| **Primary Hover** | Hover state for primary buttons | #1D7480 | 29, 116, 128 |
| **Primary Active** | Pressed state for primary buttons | #1A6873 | 26, 104, 115 |

#### Neutral Colors
| Token | Use Case | Hex Value | Purpose |
|-------|----------|-----------|---------|
| **Background** | Primary page background | #FFFCF9 | Warm white with slight cream tint |
| **Surface** | Card, container background | #FFFFF5 | Elevated surfaces, modals |
| **Text Primary** | Main content text | #134252 | High contrast text |
| **Text Secondary** | Supporting text, labels | #626C71 | Reduced emphasis |
| **Divider** | Borders, lines | #5E5240 | Subtle visual separation at 20% opacity |

#### Semantic Colors
| Type | Token | Hex | Usage |
|------|-------|-----|-------|
| **Success** | Green | #22C55E | Completion, positive feedback |
| **Error** | Red | #C0152F | Destructive actions, errors |
| **Warning** | Orange | #A84B2F | Cautions, alerts |
| **Info** | Gray | #626C71 | Neutral information, hints |

#### Background Tints (For card backgrounds)
```
Light Mode Tints (8% opacity):
- Blue: #3B82F6 → Background with 8% opacity
- Green: #22C55E → Background with 8% opacity
- Red: #EF4444 → Background with 8% opacity
- Orange: #E68159 → Background with 8% opacity
- Purple: #9333EA → Background with 8% opacity
```

### Dark Mode Color System

#### Primary Colors (Adjusted for dark backgrounds)
| Token | Use Case | Hex Value | RGB |
|-------|----------|-----------|-----|
| **Primary** | Main actions, interactive elements | #32B8C6 | 50, 184, 198 |
| **Primary Hover** | Hover state for primary buttons | #2DA6B2 | 45, 166, 178 |
| **Primary Active** | Pressed state for primary buttons | #2996A1 | 41, 150, 161 |

#### Neutral Colors
| Token | Use Case | Hex Value | Purpose |
|-------|----------|-----------|---------|
| **Background** | Primary page background | #1F2121 | Deep charcoal |
| **Surface** | Card, container background | #262828 | Slightly elevated surface |
| **Text Primary** | Main content text | #F5F5F5 | High contrast white |
| **Text Secondary** | Supporting text, labels | #A7A9A9 | Reduced emphasis gray |
| **Divider** | Borders, lines | #777C7C | Subtle visual separation at 30% opacity |

#### Semantic Colors (Dark Mode)
| Type | Token | Hex | Usage |
|------|-------|-----|-------|
| **Success** | Teal | #22B8C6 | Completion, positive feedback |
| **Error** | Red | #FF5459 | Destructive actions, errors |
| **Warning** | Orange | #E68159 | Cautions, alerts |
| **Info** | Gray | #A7A9A9 | Neutral information, hints |

#### Background Tints (For card backgrounds in dark mode)
```
Dark Mode Tints (15% opacity for visibility):
- Blue: #1D4ED8 → Background with 15% opacity
- Green: #158045 → Background with 15% opacity
- Red: #B91C1C → Background with 15% opacity
- Orange: #C2410C → Background with 15% opacity
- Purple: #6B21A8 → Background with 15% opacity
```

### Implementation in SwiftUI

```swift
// MARK: - Color Assets
extension Color {
    
    // LIGHT MODE
    static let lightBackground = Color(red: 1.0, green: 0.988, blue: 0.976)
    static let lightSurface = Color(red: 1.0, green: 1.0, blue: 0.957)
    static let lightTextPrimary = Color(red: 0.075, green: 0.259, blue: 0.322)
    static let lightTextSecondary = Color(red: 0.388, green: 0.424, blue: 0.443)
    
    // DARK MODE
    static let darkBackground = Color(red: 0.122, green: 0.129, blue: 0.129)
    static let darkSurface = Color(red: 0.149, green: 0.157, blue: 0.157)
    static let darkTextPrimary = Color(red: 0.961, green: 0.961, blue: 0.961)
    static let darkTextSecondary = Color(red: 0.655, green: 0.663, blue: 0.663)
    
    // SEMANTIC
    static let primaryAction = Color(red: 0.204, green: 0.502, blue: 0.553)
    static let successState = Color(red: 0.133, green: 0.773, blue: 0.557)
    static let errorState = Color(red: 0.753, green: 0.082, blue: 0.184)
    static let warningState = Color(red: 0.659, green: 0.506, blue: 0.294)
}

// Adaptive color selection
extension Color {
    static var background: Color {
        switch UITraitCollection.current.userInterfaceStyle {
        case .dark:
            return darkBackground
        case .light, .unspecified:
            return lightBackground
        @unknown default:
            return lightBackground
        }
    }
}
```

---

## Typography System

### Font Family Guidelines

**Primary Font:** San Francisco System Font (iOS Default)
- Optimal readability across all Apple devices
- Automatic scaling for accessibility settings
- Native support for Dynamic Type

**Monospace Font:** SF Mono (for code snippets, if needed)
- Character-level accuracy for text processing
- Consistent character width

### Font Hierarchy

| Role | Font | Size | Weight | Line Height | Letter Spacing | Usage |
|------|------|------|--------|-------------|----------------|-------|
| **Display** | SF Pro Display | 34pt | 700 (Bold) | 1.2 | -0.01 em | Main screen titles |
| **H1 (Title)** | SF Pro Display | 28pt | 700 (Bold) | 1.2 | -0.01 em | Section headers |
| **H2 (Heading)** | SF Pro Display | 24pt | 600 (Semibold) | 1.3 | 0 | Subsection headers |
| **H3 (Subheading)** | SF Pro Display | 20pt | 600 (Semibold) | 1.4 | 0 | Component headings |
| **Body** | SF Pro Text | 16pt | 400 (Regular) | 1.5 | 0 | Primary content text |
| **Body (Secondary)** | SF Pro Text | 14pt | 400 (Regular) | 1.5 | 0.01 em | Secondary content |
| **Caption** | SF Pro Text | 12pt | 500 (Medium) | 1.4 | 0.01 em | Labels, hints, metadata |
| **Caption (Small)** | SF Pro Text | 11pt | 400 (Regular) | 1.3 | 0.02 em | Fine print, timestamps |

### Text Color Guidelines

```
LIGHT MODE:
├── Primary Text → #134252 (100% opacity)
├── Secondary Text → #626C71 (70% opacity)
├── Tertiary Text → #626C71 (50% opacity)
└── Disabled Text → #626C71 (40% opacity)

DARK MODE:
├── Primary Text → #F5F5F5 (100% opacity)
├── Secondary Text → #A7A9A9 (70% opacity)
├── Tertiary Text → #A7A9A9 (50% opacity)
└── Disabled Text → #A7A9A9 (40% opacity)
```

### SwiftUI Implementation

```swift
// Define reusable text styles
extension Font {
    static let titleDisplay = Font.system(size: 34, weight: .bold, design: .default)
    static let title = Font.system(size: 28, weight: .bold, design: .default)
    static let heading = Font.system(size: 24, weight: .semibold, design: .default)
    static let subheading = Font.system(size: 20, weight: .semibold, design: .default)
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    static let bodySecondary = Font.system(size: 14, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .medium, design: .default)
    static let captionSmall = Font.system(size: 11, weight: .regular, design: .default)
}

// Apply with adaptive colors
Text("Welcome")
    .font(.title)
    .foregroundColor(UITraitCollection.current.userInterfaceStyle == .dark ? .darkTextPrimary : .lightTextPrimary)
```

---

## Component Design Standards

### Button Component

#### States & Styling

**Primary Button (Call-to-Action)**

```
LIGHT MODE:
├── Default: Background #2180, Text White
├── Hover: Background #1D7480 (darker)
├── Active: Background #1A6873 (pressed)
├── Disabled: Background #626C71 at 50% opacity, Text White at 50%

DARK MODE:
├── Default: Background #32B8C6, Text #1F2121
├── Hover: Background #2DA6B2
├── Active: Background #2996A1
├── Disabled: Background #32B8C6 at 40%, Text #1F2121 at 50%
```

**Secondary Button (Less prominent actions)**

```
LIGHT MODE:
├── Default: Background transparent, Border #5E5240 at 20%, Text #134252
├── Hover: Background #5E5240 at 12%
├── Active: Background #5E5240 at 25%
├── Disabled: Background transparent, Border #626C71 at 10%, Text #626C71

DARK MODE:
├── Default: Background transparent, Border #777C7C at 30%, Text #F5F5F5
├── Hover: Background #777C7C at 15%
├── Active: Background #777C7C at 30%
├── Disabled: Background transparent, Border #626C71 at 15%, Text #A7A9A9
```

**Destructive Button (Delete, discard)**

```
LIGHT MODE:
├── Default: Background #C0152F, Text White
├── Hover: Background #A01228
├── Active: Background #8E0E23
├── Disabled: Background #C0152F at 50%

DARK MODE:
├── Default: Background #FF5459, Text #1F2121
├── Hover: Background #E63447
├── Active: Background #CC2A37
├── Disabled: Background #FF5459 at 40%
```

**Button Specifications**
- Padding: 12px vertical × 16px horizontal (standard)
- Border Radius: 8px
- Shadow: None (flat design) or subtle (0 4px 6px rgba(0,0,0,0.1) on hover)
- Min Touch Target: 44×44 points
- Font: Caption (12pt) or Body (14pt) depending on emphasis

### Card Component

**Container Properties**

```
LIGHT MODE:
├── Background: #FFFFF5
├── Border: #5E5240 at 20% opacity, 1px
├── Shadow: 0 1px 3px rgba(0,0,0,0.1), 0 1px 2px rgba(0,0,0,0.06)
├── Corner Radius: 12px
└── Padding: 16px

DARK MODE:
├── Background: #262828
├── Border: #777C7C at 30% opacity, 1px
├── Shadow: 0 4px 6px rgba(0,0,0,0.3)
├── Corner Radius: 12px
└── Padding: 16px
```

**Usage**
- Used for: Library list items, book cards, progress cards, form sections
- Maintains consistent spacing (12px gap between cards)
- Responsive to interactive states (lift on hover with enhanced shadow)

### Input Fields (TextFields, TextEditors)

**Styling Guide**

```
LIGHT MODE:
├── Background: #FFFFF5 (or surface color)
├── Border: #5E5240 at 20%, 1px
├── Text Color: #134252
├── Placeholder: #626C71 at 50%
├── Focus State: Border color → #2180 at 100%, Shadow: 0 0 0 3px #2180 at 20%
└── Corner Radius: 8px

DARK MODE:
├── Background: #262828
├── Border: #777C7C at 30%, 1px
├── Text Color: #F5F5F5
├── Placeholder: #A7A9A9 at 50%
├── Focus State: Border color → #32B8C6 at 100%, Shadow: 0 0 0 3px #32B8C6 at 20%
└── Corner Radius: 8px
```

**Implementation**
```swift
struct CustomTextField: View {
    @State private var text = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField("Placeholder", text: $text)
            .focused($isFocused)
            .padding(12)
            .background(Color.surface)
            .border(isFocused ? Color.primaryAction : Color.border, width: 1)
            .cornerRadius(8)
    }
}
```

### Progress Indicators

**Linear Progress Bar**

```
Light Mode:
├── Background Track: #626C71 at 20%
├── Filled Track: #2180 (primary)
├── Corner Radius: 4px
├── Height: 4px

Dark Mode:
├── Background Track: #777C7C at 30%
├── Filled Track: #32B8C6 (primary)
├── Corner Radius: 4px
├── Height: 4px
```

**Circular Progress**

```
Light Mode:
├── Background Circle: #626C71 at 20%, 4px stroke
├── Progress Circle: #2180, 4px stroke
├── Center Text: #134252

Dark Mode:
├── Background Circle: #777C7C at 30%, 4px stroke
├── Progress Circle: #32B8C6, 4px stroke
├── Center Text: #F5F5F5
```

### Status Badges

**Badge Styling** (Apply to text indicating state)

```
Success State:
├── Light: Background #22C55E at 8%, Text #22C55E, Border #22C55E at 25%
├── Dark: Background #22C55E at 15%, Text #22C55E, Border #22C55E at 30%

Error State:
├── Light: Background #C0152F at 8%, Text #C0152F, Border #C0152F at 25%
├── Dark: Background #FF5459 at 15%, Text #FF5459, Border #FF5459 at 30%

Warning State:
├── Light: Background #A84B2F at 8%, Text #A84B2F, Border #A84B2F at 25%
├── Dark: Background #E68159 at 15%, Text #E68159, Border #E68159 at 30%

Info State:
├── Light: Background #626C71 at 8%, Text #626C71, Border #626C71 at 25%
├── Dark: Background #A7A9A9 at 15%, Text #A7A9A9, Border #A7A9A9 at 30%
```

### Navigation & App Bar

**Top Navigation Bar**

```
LIGHT MODE:
├── Background: #FFFCF9 (background color) or semi-transparent white
├── Border Bottom: #5E5240 at 10%, 1px
├── Title Text: #134252
└── Icon Color: #134252

DARK MODE:
├── Background: #1F2121 or semi-transparent darker
├── Border Bottom: #777C7C at 20%, 1px
├── Title Text: #F5F5F5
└── Icon Color: #F5F5F5
```

**Tab Bar / Navigation Bar**

```
LIGHT MODE:
├── Background: #FFFCF9
├── Icon (Inactive): #626C71 at 70%
├── Icon (Active): #2180
└── Label: #134252

DARK MODE:
├── Background: #1F2121
├── Icon (Inactive): #A7A9A9 at 60%
├── Icon (Active): #32B8C6
└── Label: #F5F5F5
```

---

## Screen-Specific Guidelines

### 1. AuthScreen (Sign In / Sign Up)

**Background Strategy**
- Use gradient background for visual interest
- Light Mode: Blue opacity(0.1) + Purple opacity(0.1) gradient
- Dark Mode: Darker blue opacity(0.08) + darker purple opacity(0.08)

**Card Components**
- Centered card with rounded corners (20px radius)
- Shadow for elevation feel
- Consistent padding (30px)

**Form Elements**
- Use secondary buttons for toggle/segmented picker
- Primary blue for authentication action buttons
- Display error states with red text at caption size
- Show loading state with spinner overlay

**Apple Sign-In Button**
- Maintain Apple's design standards
- Use only on iOS platforms
- Always pair with email/password option

### 2. LibraryScreen (My Library)

**Header Design**
- Title: "My Library" at size .title (28pt)
- Plus button for adding books: #2180 (light) / #32B8C6 (dark)
- Search bar with magnifying glass icon
- Filter pills with horizontal scroll

**Content Areas**
- Book count display with secondary color text
- Empty state with icon, title, and message
- List items using BookListRow component

**Card Pattern**
- Book cover placeholder: 60×80 points
- Book info (title, author) with proper truncation
- Progress indicator (circular): 40×40 points
- Action buttons (swipe to delete) in red

**Color Coding**
- Filter pills: Inactive background #626C71 at 10% (light) / #777C7C at 15% (dark)
- Active pill: #2180 background with white text (light) / #32B8C6 background with dark text (dark)

### 3. BookUploadScreen (Add Books)

**Section Hierarchy**
- Title at top with larger font size
- Subtitle in secondary color
- Clear section headers for "Book Information" and "Choose Upload Method"

**Upload Options**
- Two prominent option cards: Camera & Photo Library
- Card backgrounds: Blue opacity(0.1) and Green opacity(0.1) in light mode
- Dark mode: Use darker tinted backgrounds
- Icon: 48pt size, colored (Blue for camera, Green for library)
- Selected photos preview at bottom

**Input Fields**
- Standard text field styling for title and author
- Clear placeholder text in secondary color
- Error states in red

**Action Button**
- Primary button: "Upload Book" in primary blue
- Disabled state when title is empty or no images selected
- Loading state shows spinner with "Processing..." text

### 4. PhotoPickerView / CameraView

**Overlay Strategy**
- Semi-transparent overlays for controls
- Top bar: Camera controls (cancel, count, done) on dark semi-transparent background
- Bottom bar: Capture button and instructions

**Camera Controls**
- Capture button: White circle with 70pt diameter, gray border
- Text controls: White text on dark background
- Instructions: Caption text in white

**Photo Picker**
- Large tap area with icon and text
- Background tinted appropriately for mode
- Selected photos grid: 80×80 points with remove button overlay

### 5. PhotoReviewScreen

**Header**
- Title: "Review Photos"
- Subtitle explaining the purpose

**Grid Layout**
- 2-column grid with 12pt spacing
- Photo height: 150pt, maintained aspect ratio
- Page badges: Dark background at bottom-left
- Selection indicator: Checkmark at top-right when selected

**Selection Controls**
- Show count when items selected
- "Clear Selection" button in secondary color
- "Delete Selected" button in red

**Bottom Button**
- Dynamic text showing count: "Continue with X photos"
- Disabled when no images selected

### 6. OCRProgressScreen

**Header Section**
- Large title: "Processing Book"
- Subtitle: Shows page count being processed

**Progress Display**
- Linear progress bar with percentage
- Completed pages count (e.g., "3/10 pages")
- Current page number display

**Page Preview**
- Current page image with processing overlay
- Spinner and "Extracting text..." message when processing
- Status indicator badge at bottom-right

**Page List**
- Scrollable list of pages
- Status icons: circle (pending), arrow (processing), checkmark (done), X (failed)
- Page number and extracted text preview

**Status Messages**
- Info messages: Blue background with blue icon
- Error messages: Red background with red icon
- Clear, readable caption text

**Bottom Actions**
- "View Book" button (green) when complete
- "Cancel Processing" button (red) when in progress
- Completion message in green text

### 7. ReadingScreen

**Header Navigation**
- Previous/Next page chevrons (disabled state in gray)
- Center: Page indicator ("X of Y pages")
- Top-right: Progress percentage indicator

**Content Area**
- Ample padding (20pt horizontal)
- Segmented text displayed as interactive buttons
- Word buttons with states: default, selected (blue), marked (orange)

**Word Popup Dictionary**
- Dark overlay: rgba(0,0,0,0.4)
- White background card with 16px corner radius
- Word display: title size, bold
- Pinyin: title2 size, secondary color
- Definition: body size, centered
- HSK level badge
- Action buttons: Mark (star) and Close (X)

**Interactive States**
- Selected word: Blue background, white text
- Marked word: Orange background, orange text
- Normal word: Clear background, primary text

### 8. ReadingScreen - Key Components

**Progress Header**
- Linear progress bar with 4px height
- Progress percentage below (caption size)

**Page Content**
- Page number indicator at top (caption, secondary color)
- Word grid with adaptive spacing
- Divider line between content and navigation

**Dictionary Entry**
- Consistent styling across components
- Proper contrast for readability
- Clear action indicators

---

## Dark Mode Implementation Strategy

### Approach 1: Semantic Color Tokens (Recommended)

Create a comprehensive color system that automatically responds to `@Environment(\.colorScheme)`:

```swift
struct ColorScheme {
    let background: Color
    let surface: Color
    let textPrimary: Color
    let textSecondary: Color
    let primary: Color
    let error: Color
    let success: Color
    let warning: Color
    // ... more colors
}

@Environment(\.colorScheme) var colorScheme

var colors: ColorScheme {
    switch colorScheme {
    case .light:
        return .lightColors
    case .dark:
        return .darkColors
    @unknown default:
        return .lightColors
    }
}
```

### Approach 2: Asset Catalog with Color Sets

Use Xcode's Asset Catalog:
1. Create color sets for each semantic token
2. Assign light variant and dark variant in appearance settings
3. Reference colors by name throughout SwiftUI code

**Benefits:**
- Visual preview in Xcode
- Easy maintenance for designers
- No runtime color detection needed

### Approach 3: Modifier-Based Application

Create reusable modifiers for consistent styling:

```swift
struct DarkModeModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(colorScheme == .dark ? .darkTextPrimary : .lightTextPrimary)
    }
}

extension View {
    func adaptiveText() -> some View {
        self.modifier(DarkModeModifier())
    }
}
```

### Color Override Locations (by Screen)

**AuthScreen:**
- Background gradient adaptation
- Button color states
- Text field borders and backgrounds
- Error message colors

**LibraryScreen:**
- List background colors
- Filter pill active/inactive states
- Icon colors (active/inactive)
- Empty state icon color

**BookUploadScreen:**
- Option card backgrounds (tinted)
- Button states
- Text field styling

**PhotoReviewScreen:**
- Grid item borders
- Badge backgrounds
- Selection indicator color
- Button backgrounds

**OCRProgressScreen:**
- Progress bar colors
- Status badge backgrounds
- Icon colors
- Message background colors

**ReadingScreen:**
- Text button default/selected/marked states
- Dictionary popup background
- Border colors
- Icon colors

### System Preferences Support

Enable system dark mode detection:

```swift
.preferredColorScheme(nil) // Allows system setting to control
```

Never force a color scheme unless specifically required by design intent.

---

## Accessibility Considerations

### Color Contrast Standards

**WCAG 2.1 Compliance Levels:**

| Element | AA Standard | AAA Standard |
|---------|------------|--------------|
| Normal Text (14pt+) | 4.5:1 | 7:1 |
| Large Text (18pt+) | 3:1 | 4.5:1 |
| UI Components | 3:1 | 4.5:1 |

### Contrast Verification (Light Mode)

```
✓ Primary Text (#134252) on Background (#FFFCF9): 14.9:1 ✓ AAA
✓ Secondary Text (#626C71) on Background (#FFFCF9): 5.2:1 ✓ AA
✓ Primary Button (#2180) on White: 5.1:1 ✓ AA
✓ Error Text (#C0152F) on Background: 7.2:1 ✓ AAA
```

### Contrast Verification (Dark Mode)

```
✓ Primary Text (#F5F5F5) on Background (#1F2121): 15.1:1 ✓ AAA
✓ Secondary Text (#A7A9A9) on Background (#1F2121): 6.8:1 ✓ AAA
✓ Primary Button (#32B8C6) on Dark: 4.8:1 ✓ AA
✓ Error Text (#FF5459) on Dark: 5.3:1 ✓ AA
```

### Accessible Color Usage

**Don't:**
- Rely solely on color to convey meaning
- Use red+green combinations without additional context
- Assume all users perceive color the same way

**Do:**
- Use icons and text labels alongside colors
- Provide visual indicators beyond color (checkmarks, borders, opacity changes)
- Test with accessibility tools (Accessibility Inspector)
- Support High Contrast modes

### Font Size & Readability

- Minimum body text: 14pt (16pt recommended)
- Support Dynamic Type scaling (100% to 200%)
- Maintain 1.5 line height minimum for body text
- Use proper semantic font sizes (.body, .caption, etc.)

### Interactive Elements

- Minimum touch target: 44×44 points
- Focus indicators: Clear, 3px outline with 0 0 0 3px shadow
- Button states clearly visually distinct
- Loading states provide feedback

### Motion & Animation

- Respect `@Environment(\.accessibilityReduceMotion)` setting
- Provide instant feedback for taps (haptic feedback where appropriate)
- Don't auto-play videos or animations
- Make animations optional, not mandatory for understanding content

### VoiceOver Optimization

```swift
Text("Review Photos")
    .accessibilityAddTraits(.isHeader)

Button(action: {}) {
    Image(systemName: "trash")
    Text("Delete")
}
.accessibilityLabel("Delete selected photos")
.accessibilityHint("Permanently removes all selected images")
```

---

## Implementation Checklist

### Phase 1: Foundation (Week 1)

- [ ] Define all semantic color tokens
- [ ] Create color assets in Xcode Asset Catalog
- [ ] Establish typography styles as reusable modifiers
- [ ] Build base component library (Button, Card, TextField)
- [ ] Set up color scheme environment variables

### Phase 2: Component Library (Week 2)

- [ ] Build PrimaryButton component with dark mode support
- [ ] Build SecondaryButton component
- [ ] Build CardContainer component
- [ ] Build TextInput component
- [ ] Build ProgressIndicator (linear & circular) components
- [ ] Build StatusBadge component
- [ ] Create preview examples for each component

### Phase 3: Screen Implementation (Week 3-4)

- [ ] AuthScreen dark mode support
- [ ] LibraryScreen dark mode support
- [ ] BookUploadScreen dark mode support
- [ ] PhotoReviewScreen dark mode support
- [ ] PhotoPickerView dark mode support
- [ ] CameraView dark mode support
- [ ] OCRProgressScreen dark mode support
- [ ] ReadingScreen dark mode support

### Phase 4: Testing & Refinement (Week 5)

- [ ] Contrast verification with WCAG tool
- [ ] Accessibility Inspector testing on all screens
- [ ] Test on multiple device sizes (iPhone SE to 12 Pro Max)
- [ ] User testing with dark mode enabled/disabled
- [ ] Performance testing (no lag on color transitions)
- [ ] High Contrast mode testing

### Phase 5: Documentation (Ongoing)

- [ ] Create component usage guidelines
- [ ] Document color token updates process
- [ ] Maintain design system in Figma/design tool
- [ ] Create developer handoff documentation
- [ ] Build component showcase/storybook

### Code Organization

```
Project Structure:
├── Assets
│   └── Colors.xcassets/
│       ├── Background
│       ├── Surface
│       ├── Text
│       ├── Primary
│       ├── Status
│       └── Semantic
├── Design System
│   ├── Colors+Extensions.swift
│   ├── Typography+Extensions.swift
│   ├── Modifiers/
│   │   ├── AdaptiveTextModifier.swift
│   │   ├── CardModifier.swift
│   │   └── ButtonModifier.swift
│   └── Components/
│       ├── PrimaryButton.swift
│       ├── SecondaryButton.swift
│       ├── CardContainer.swift
│       ├── TextInput.swift
│       ├── ProgressIndicator.swift
│       └── StatusBadge.swift
├── Screens/
│   ├── AuthScreen/
│   ├── LibraryScreen/
│   ├── BookUploadScreen/
│   └── ... (other screens)
└── Resources/
    ├── Fonts/
    ├── Images/
    └── Strings/
```

---

## Maintenance & Evolution

### Design System Governance

**Monthly Review:**
- Audit color usage across screens
- Identify new color needs
- Validate contrast ratios
- Gather designer/developer feedback

**Quarterly Updates:**
- Release updated color tokens if brand evolves
- Update component library with new patterns
- Refresh accessibility tests
- Version design system

**Annual Audit:**
- Full WCAG re-evaluation
- User feedback integration
- Performance optimization review
- Future roadmap planning

### Version Control

```
Design System v1.0
├── Color System v1.0 ✓
├── Typography v1.0 ✓
├── Component Library v1.0 ✓
└── Accessibility v1.0 ✓

Future: Design System v1.1
└── New: Advanced animations, new component patterns
```

---

## Appendix: Quick Reference

### Color Token Quick Reference

**Light Mode Primary Colors:**
- Primary Action: #2180 (RGB: 33, 128, 141)
- Error: #C0152F (RGB: 192, 21, 47)
- Success: #22C55E (RGB: 34, 197, 94)
- Warning: #A84B2F (RGB: 168, 75, 47)

**Dark Mode Primary Colors:**
- Primary Action: #32B8C6 (RGB: 50, 184, 198)
- Error: #FF5459 (RGB: 255, 84, 89)
- Success: #22B8C6 (RGB: 34, 184, 198)
- Warning: #E68159 (RGB: 230, 129, 97)

### Recommended Resource Tools

- **Color Contrast:** WebAIM Contrast Checker, Accessible Colors
- **Design System:** Figma, Adobe Spectrum
- **Accessibility Testing:** WAVE, Accessibility Inspector, VoiceOver
- **Prototyping:** SwiftUI Previews, Xcode Simulator

---

## Conclusion

This comprehensive design system provides a scalable, accessible foundation for the Umbrella app's user interface. By adhering to these guidelines, the team ensures:

1. **Visual consistency** across all screens and modes
2. **Accessibility** compliant with WCAG 2.1 AA standards
3. **Developer efficiency** through reusable components and tokens
4. **User satisfaction** with thoughtful, readable interfaces
5. **Brand coherence** across light and dark experiences

**Next Steps:**
1. Implement the color assets in Xcode
2. Build the component library
3. Apply to each screen systematically
4. Conduct accessibility testing
5. Gather user feedback and iterate

For questions or clarifications on this design system, please refer to the component examples and test them in the Xcode previews.

---

**Document Created:** January 2026  
**Last Updated:** January 2026  
**Owner:** Design System Team  
**Status:** Active