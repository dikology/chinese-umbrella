//
//  EditBookScreenUITests.swift
//  umbrellaUITests
//
//  Created by Денис on 31.12.2025.
//

import XCTest

final class EditBookScreenUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Screen Rendering Tests

    func testEditBookScreenRendersWithValidBook() throws {
        // Given: App is launched and user navigates to library
        let app = XCUIApplication()
        app.launch()

        // Navigate to a book that can be edited (assuming test data exists)
        // This would need to be implemented based on your app's navigation structure

        // When: User swipes to edit a book
        // Then: EditBookScreen should appear with book information visible

        // Verify screen elements are present
        XCTAssertTrue(app.staticTexts["Edit Book"].exists, "Edit Book title should be visible")
        XCTAssertTrue(app.staticTexts["Update book information or add new pages"].exists, "Subtitle should be visible")

        // Verify book information is displayed
        XCTAssertTrue(app.staticTexts["Current Book Information"].exists, "Current book info section should exist")
        XCTAssertTrue(app.staticTexts["Current pages:"].exists, "Current pages label should exist")
    }

    func testEditBookScreenShowsBookDetailsCorrectly() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to edit screen for a book with known data
        // This test assumes you have test data or can create it programmatically

        // Verify book title is displayed
        let titleTextField = app.textFields["Book Title"]
        XCTAssertTrue(titleTextField.exists, "Book title text field should exist")
        XCTAssertFalse(titleTextField.value as? String == "", "Book title should not be empty")

        // Verify page count is shown
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Current pages:'")).element.exists)
    }

    // MARK: - User Interaction Tests

    func testEditBookScreenAllowsTitleEditing() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to edit screen
        let titleTextField = app.textFields["Book Title"]
        XCTAssertTrue(titleTextField.exists)

        // When: User taps and edits the title
        titleTextField.tap()
        titleTextField.typeText(" Updated")

        // Then: Text should be updated
        let updatedTitle = titleTextField.value as? String
        XCTAssertTrue(updatedTitle?.contains("Updated") == true, "Title should be updated")
    }

    func testEditBookScreenShowsPhotoSelectionOptions() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to edit screen

        // Verify camera option is present
        XCTAssertTrue(app.buttons["Take Photos"].exists, "Camera option should be available")

        // Verify photo picker option is present
        XCTAssertTrue(app.buttons["Select from Library"].exists, "Photo library option should be available")
    }

    func testEditBookScreenShowsUpdateButtonWhenChangesMade() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to edit screen

        // Initially, update button should not be visible (or disabled)
        let updateButton = app.buttons["Update Book"]
        XCTAssertFalse(updateButton.isEnabled, "Update button should be disabled initially")

        // When: User adds photos or changes title
        let titleTextField = app.textFields["Book Title"]
        titleTextField.tap()
        titleTextField.typeText(" New")

        // Then: Update button should become enabled
        XCTAssertTrue(updateButton.exists, "Update button should appear")
        XCTAssertTrue(updateButton.isEnabled, "Update button should be enabled")
    }

    // MARK: - Error Handling Tests

    func testEditBookScreenShowsErrorForEmptyTitle() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to edit screen and clear title, add photos, then try to save
        let titleTextField = app.textFields["Book Title"]
        titleTextField.tap()
        titleTextField.clearText() // Assuming clearText() extension exists

        // Add a photo (simulate)
        // This would require setting up test photos or mocking

        // Try to update
        let updateButton = app.buttons["Update Book"]
        updateButton.tap()

        // Verify error is shown
        XCTAssertTrue(app.alerts["Edit Error"].exists, "Error alert should appear for empty title")
    }

    func testEditBookScreenHandlesBookWithNoPages() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to edit screen for a book with 0 pages
        // This requires having test data with empty books

        // Verify "Current pages: 0" is shown
        let pageCountLabel = app.staticTexts["Current pages:"].firstMatch
        XCTAssertTrue(pageCountLabel.exists)

        let pageCountValue = pageCountLabel.sibling(staticTexts: containing: "0")
        XCTAssertTrue(pageCountValue.exists, "Should show 0 pages for empty book")
    }

    // MARK: - Navigation Tests

    func testEditBookScreenCancelButtonDismissesScreen() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to edit screen
        XCTAssertTrue(app.buttons["Cancel"].exists, "Cancel button should exist")

        // When: User taps cancel
        app.buttons["Cancel"].tap()

        // Then: Screen should be dismissed
        XCTAssertFalse(app.staticTexts["Edit Book"].exists, "Edit screen should be dismissed")
    }

    func testEditBookScreenSuccessfulUpdateDismissesScreen() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to edit screen, make valid changes, and save
        let titleTextField = app.textFields["Book Title"]
        titleTextField.tap()
        titleTextField.typeText(" Updated")

        // Simulate adding photos (would need test setup)
        // ...

        let updateButton = app.buttons["Update Book"]
        updateButton.tap()

        // Verify screen is dismissed after successful update
        XCTAssertFalse(app.staticTexts["Edit Book"].exists, "Edit screen should be dismissed after successful update")
    }
}
