//
// JournalScreen.swift
// AmiraWellnessUITests
//
// Screen object for UI testing of the journal-related functionality in the Amira Wellness app,
// implementing the Page Object pattern to provide methods for interacting with journal screens.
//

import XCTest

/// Screen object for journal-related screens in UI tests, providing methods to interact with journal list, creation, and detail views
class JournalScreen: BaseScreen {
    // MARK: - UI Elements
    
    // Main views
    let journalListView: XCUIElement
    let createJournalButton: XCUIElement
    let preCheckInView: XCUIElement
    let recordingView: XCUIElement
    let postCheckInView: XCUIElement
    let journalDetailView: XCUIElement
    
    // Emotional check-in elements
    let emotionSelector: XCUIElement
    let intensitySlider: XCUIElement
    let notesTextField: XCUIElement
    let titleTextField: XCUIElement
    let continueButton: XCUIElement
    let saveButton: XCUIElement
    
    // Recording controls
    let pauseResumeButton: XCUIElement
    let stopButton: XCUIElement
    let cancelButton: XCUIElement
    
    // Journal detail elements
    let playButton: XCUIElement
    let favoriteButton: XCUIElement
    let deleteButton: XCUIElement
    let confirmDeleteButton: XCUIElement
    let cancelDeleteButton: XCUIElement
    let emotionalShiftSection: XCUIElement
    
    // List view elements
    let searchField: XCUIElement
    let filterButton: XCUIElement
    let sortButton: XCUIElement
    
    // MARK: - Initialization
    
    /// Initializes a new JournalScreen with the application instance
    /// - Parameter app: The XCUIApplication instance
    override init(app: XCUIApplication) {
        super.init(app: app)
        
        // Initialize UI elements
        journalListView = app.otherElements["journalListView"]
        createJournalButton = app.buttons["createJournalButton"]
        preCheckInView = app.otherElements["preCheckInView"]
        recordingView = app.otherElements["recordingView"]
        postCheckInView = app.otherElements["postCheckInView"]
        journalDetailView = app.otherElements["journalDetailView"]
        
        emotionSelector = app.otherElements["emotionSelector"]
        intensitySlider = app.sliders["intensitySlider"]
        notesTextField = app.textFields["notesTextField"]
        titleTextField = app.textFields["titleTextField"]
        continueButton = app.buttons["continueButton"]
        saveButton = app.buttons["saveButton"]
        
        pauseResumeButton = app.buttons["pauseResumeButton"]
        stopButton = app.buttons["stopButton"]
        cancelButton = app.buttons["cancelButton"]
        
        playButton = app.buttons["playButton"]
        favoriteButton = app.buttons["favoriteButton"]
        deleteButton = app.buttons["deleteButton"]
        confirmDeleteButton = app.buttons["confirmDeleteButton"]
        cancelDeleteButton = app.buttons["cancelDeleteButton"]
        emotionalShiftSection = app.otherElements["emotionalShiftSection"]
        
        searchField = app.searchFields["searchField"]
        filterButton = app.buttons["filterButton"]
        sortButton = app.buttons["sortButton"]
        
        // Set root element for the base class
        rootElement = app.otherElements["journalScreenContainer"]
    }
    
    // MARK: - Journal List Methods
    
    /// Checks if the journal list screen is displayed
    /// - Parameter timeout: The maximum time to wait for the screen to appear
    /// - Returns: Whether the journal list is displayed
    func isJournalListDisplayed(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return waitForElementToAppear(journalListView, timeout: timeout)
    }
    
    /// Taps the create journal button
    /// - Returns: Whether the button was successfully tapped
    func tapCreateJournalButton() -> Bool {
        return tapElement(createJournalButton, TimeoutDuration.standard)
    }
    
    // MARK: - Pre-Check-In Methods
    
    /// Checks if the pre-recording emotional check-in screen is displayed
    /// - Parameter timeout: The maximum time to wait for the screen to appear
    /// - Returns: Whether the pre-check-in screen is displayed
    func isPreCheckInDisplayed(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return waitForElementToAppear(preCheckInView, timeout: timeout)
    }
    
    /// Completes the pre-recording emotional check-in
    /// - Parameters:
    ///   - emotion: The name of the emotion to select
    ///   - intensity: The intensity value (1-10)
    ///   - notes: Optional notes to enter
    /// - Returns: Whether the check-in was completed successfully
    func completePreCheckIn(emotion: String, intensity: Int, notes: String? = nil) -> Bool {
        // Select the emotion in the emotion selector grid
        let emotionButton = app.buttons[emotion]
        guard tapElement(emotionButton) else {
            return false
        }
        
        // Adjust the intensity slider to the specified value
        let normalizedValue = Double(intensity) / 10.0
        intensitySlider.adjust(toNormalizedSliderPosition: normalizedValue)
        
        // Enter notes if provided
        if let notes = notes {
            guard enterText(notesTextField, text: notes) else {
                return false
            }
        }
        
        // Tap the continue button
        guard tapElement(continueButton) else {
            return false
        }
        
        // Return whether the recording view appears
        return isRecordingViewDisplayed()
    }
    
    // MARK: - Recording Methods
    
    /// Checks if the recording view is displayed
    /// - Parameter timeout: The maximum time to wait for the screen to appear
    /// - Returns: Whether the recording view is displayed
    func isRecordingViewDisplayed(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return waitForElementToAppear(recordingView, timeout: timeout)
    }
    
    /// Taps the pause/resume button during recording
    /// - Returns: Whether the button was successfully tapped
    func tapPauseResumeButton() -> Bool {
        return tapElement(pauseResumeButton, TimeoutDuration.standard)
    }
    
    /// Taps the stop button to end recording
    /// - Returns: Whether the button was successfully tapped
    func tapStopButton() -> Bool {
        return tapElement(stopButton, TimeoutDuration.standard)
    }
    
    /// Taps the cancel button during recording
    /// - Returns: Whether the button was successfully tapped
    func tapCancelButton() -> Bool {
        return tapElement(cancelButton, TimeoutDuration.standard)
    }
    
    // MARK: - Post-Check-In Methods
    
    /// Checks if the post-recording emotional check-in screen is displayed
    /// - Parameter timeout: The maximum time to wait for the screen to appear
    /// - Returns: Whether the post-check-in screen is displayed
    func isPostCheckInDisplayed(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return waitForElementToAppear(postCheckInView, timeout: timeout)
    }
    
    /// Completes the post-recording emotional check-in
    /// - Parameters:
    ///   - emotion: The name of the emotion to select
    ///   - intensity: The intensity value (1-10)
    ///   - title: The title for the journal entry
    ///   - notes: Optional notes to enter
    /// - Returns: Whether the check-in was completed successfully
    func completePostCheckIn(emotion: String, intensity: Int, title: String, notes: String? = nil) -> Bool {
        // Tap the emotion in the emotion selector grid
        let emotionButton = app.buttons[emotion]
        guard tapElement(emotionButton) else {
            return false
        }
        
        // Adjust the intensity slider to the specified value
        let normalizedValue = Double(intensity) / 10.0
        intensitySlider.adjust(toNormalizedSliderPosition: normalizedValue)
        
        // Enter the title in the title text field
        guard enterText(titleTextField, text: title) else {
            return false
        }
        
        // If notes is not nil, enter the notes in the notes text field
        if let notes = notes {
            guard enterText(notesTextField, text: notes) else {
                return false
            }
        }
        
        // Tap the save button
        guard tapElement(saveButton) else {
            return false
        }
        
        // Return whether the journal list appears
        return isJournalListDisplayed()
    }
    
    // MARK: - Journal List Interaction Methods
    
    /// Taps a journal entry at the specified index in the list
    /// - Parameter index: The index of the journal to tap
    /// - Returns: Whether the journal was successfully tapped
    func tapJournalAtIndex(_ index: Int) -> Bool {
        let journalCell = app.cells.element(matching: .cell, identifier: "journalCell_\(index)")
        let tapped = tapElement(journalCell)
        return tapped && isJournalDetailDisplayed()
    }
    
    // MARK: - Journal Detail Methods
    
    /// Checks if the journal detail view is displayed
    /// - Parameter timeout: The maximum time to wait for the screen to appear
    /// - Returns: Whether the journal detail view is displayed
    func isJournalDetailDisplayed(timeout: TimeInterval = TimeoutDuration.standard) -> Bool {
        return waitForElementToAppear(journalDetailView, timeout: timeout)
    }
    
    /// Taps the play button in the journal detail view
    /// - Returns: Whether the button was successfully tapped
    func tapPlayButton() -> Bool {
        return tapElement(playButton, TimeoutDuration.standard)
    }
    
    /// Taps the favorite button in the journal detail view
    /// - Returns: Whether the button was successfully tapped
    func tapFavoriteButton() -> Bool {
        return tapElement(favoriteButton, TimeoutDuration.standard)
    }
    
    /// Taps the delete button in the journal detail view
    /// - Returns: Whether the button was successfully tapped
    func tapDeleteButton() -> Bool {
        return tapElement(deleteButton, TimeoutDuration.standard)
    }
    
    /// Confirms journal deletion in the confirmation dialog
    /// - Returns: Whether the confirmation was successful
    func confirmDelete() -> Bool {
        return tapElement(confirmDeleteButton, TimeoutDuration.standard)
    }
    
    /// Cancels journal deletion in the confirmation dialog
    /// - Returns: Whether the cancellation was successful
    func cancelDelete() -> Bool {
        return tapElement(cancelDeleteButton, TimeoutDuration.standard)
    }
    
    /// Verifies that the emotional shift section is displayed in the journal detail view
    /// - Returns: Whether the emotional shift section is displayed
    func verifyEmotionalShiftDisplayed() -> Bool {
        return verifyElementExists(emotionalShiftSection, TimeoutDuration.standard)
    }
    
    // MARK: - Composite Actions
    
    /// Creates a new journal with default values
    /// - Parameter title: Optional title for the journal entry (default if nil)
    /// - Returns: Whether the journal was created successfully
    func createNewJournal(title: String? = nil) -> Bool {
        let journalTitle = title ?? "Test Journal \(Date())"
        
        // Call tapCreateJournalButton()
        guard tapCreateJournalButton() else {
            return false
        }
        
        // Call completePreCheckIn with default values
        guard completePreCheckIn(emotion: "Calma", intensity: 5) else {
            return false
        }
        
        // Wait for a short recording duration (5 seconds)
        sleep(5)
        
        // Call tapStopButton()
        guard tapStopButton() else {
            return false
        }
        
        // Call completePostCheckIn with default values and the provided title or a default title
        return completePostCheckIn(emotion: "Alegría", intensity: 7, title: journalTitle)
    }
    
    /// Deletes a journal at the specified index
    /// - Parameter index: The index of the journal to delete
    /// - Returns: Whether the journal was deleted successfully
    func deleteJournalAtIndex(_ index: Int) -> Bool {
        // Call tapJournalAtIndex(index)
        guard tapJournalAtIndex(index) else {
            return false
        }
        
        // Call tapDeleteButton()
        guard tapDeleteButton() else {
            return false
        }
        
        // Call confirmDelete()
        guard confirmDelete() else {
            return false
        }
        
        // Return whether the journal list is displayed
        return isJournalListDisplayed()
    }
    
    /// Verifies the number of journals in the list
    /// - Parameter expectedCount: The expected number of journals
    /// - Returns: Whether the journal count matches the expected count
    func verifyJournalCount(_ expectedCount: Int) -> Bool {
        // Get the count of journal cells in the list
        let journalCells = app.cells.matching(identifier: "journalCell")
        
        // Compare with the expected count
        return journalCells.count == expectedCount
    }
    
    /// Searches for a journal by title
    /// - Parameter searchText: The text to search for
    /// - Returns: Whether the search was performed successfully
    func searchForJournal(_ searchText: String) -> Bool {
        // Tap the search field
        guard tapElement(searchField) else {
            return false
        }
        
        // Enter the search text
        guard enterText(searchField, text: searchText) else {
            return false
        }
        
        // Tap the search button on the keyboard
        app.keyboards.buttons["search"].tap()
        
        // Return whether the search results are displayed
        return waitForLoadingToComplete()
    }
    
    /// Taps the filter button to show filter options
    /// - Returns: Whether the button was successfully tapped
    func tapFilterButton() -> Bool {
        return tapElement(filterButton, TimeoutDuration.standard)
    }
    
    /// Selects a filter option from the filter sheet
    /// - Parameter option: The filter option to select
    /// - Returns: Whether the option was selected successfully
    func selectFilterOption(_ option: String) -> Bool {
        // Find the filter option button with the specified text
        let filterOption = app.buttons[option]
        
        // Tap the filter option button
        guard tapElement(filterOption) else {
            return false
        }
        
        // Return whether the journal list is displayed with the filter applied
        return isJournalListDisplayed()
    }
    
    /// Taps the sort button to show sort options
    /// - Returns: Whether the button was successfully tapped
    func tapSortButton() -> Bool {
        return tapElement(sortButton, TimeoutDuration.standard)
    }
    
    /// Selects a sort option from the sort sheet
    /// - Parameter option: The sort option to select
    /// - Returns: Whether the option was selected successfully
    func selectSortOption(_ option: String) -> Bool {
        // Find the sort option button with the specified text
        let sortOption = app.buttons[option]
        
        // Tap the sort option button
        guard tapElement(sortOption) else {
            return false
        }
        
        // Return whether the journal list is displayed with the sort applied
        return isJournalListDisplayed()
    }
}