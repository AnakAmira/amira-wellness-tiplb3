import XCTest
import Combine
@testable import AmiraWellness

final class JournalListViewModelTests: XCTestCase {
    // MARK: - Properties
    
    var mockJournalService: MockJournalService!
    var viewModel: JournalListViewModel!
    var navigatedToJournalId: UUID?
    var navigatedToRecordJournal: Bool = false
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockJournalService = MockJournalService.shared
        mockJournalService.reset()
        navigatedToJournalId = nil
        navigatedToRecordJournal = false
        cancellables = Set<AnyCancellable>()
        
        viewModel = JournalListViewModel(
            journalService: mockJournalService,
            navigateToJournalDetailHandler: { [weak self] journalId in
                self?.navigatedToJournalId = journalId
            },
            navigateToRecordJournalHandler: { [weak self] in
                self?.navigatedToRecordJournal = true
            }
        )
    }
    
    override func tearDown() {
        cancellables.forEach { $0.cancel() }
        mockJournalService.reset()
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testInitialState() {
        // Assert initial state is correct
        XCTAssertEqual(viewModel.journals, [])
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.selectedFilter, .all)
        XCTAssertEqual(viewModel.selectedSortOption, .dateNewest)
        XCTAssertNil(viewModel.selectedEmotionFilter)
        XCTAssertEqual(viewModel.searchText, "")
    }
    
    func testLoadJournalsSuccess() {
        // Prepare mock data
        let mockJournals = TestData.mockJournalArray()
        mockJournalService.getJournalsResult = { completion in
            completion(.success(mockJournals))
        }
        
        // Call the method under test
        viewModel.loadJournals()
        
        // Verify result
        XCTAssertEqual(mockJournalService.getJournalsCallCount, 1)
        XCTAssertEqual(viewModel.journals, mockJournals)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadJournalsFailure() {
        // Prepare mock error
        let error = JournalServiceError.networkError("Test error")
        mockJournalService.getJournalsResult = { completion in
            completion(.failure(error))
        }
        
        // Call the method under test
        viewModel.loadJournals()
        
        // Verify result
        XCTAssertEqual(mockJournalService.getJournalsCallCount, 1)
        XCTAssertEqual(viewModel.journals, [])
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.localizedDescription)
    }
    
    func testRefreshJournals() {
        // Call the method under test
        viewModel.refreshJournals()
        
        // Verify result
        XCTAssertEqual(mockJournalService.getJournalsCallCount, 1)
    }
    
    func testDeleteJournalSuccess() {
        // Prepare test data
        let mockJournals = TestData.mockJournalArray()
        viewModel.journals = mockJournals
        mockJournalService.journals = mockJournals
        
        // Configure mock service
        mockJournalService.deleteJournalResult = { _ in .success(()) }
        
        // Get ID to delete
        let journalIdToDelete = mockJournals[0].id
        
        // Call the method under test
        viewModel.deleteJournal(journalId: journalIdToDelete)
        
        // Verify result
        XCTAssertEqual(mockJournalService.deleteJournalCallCount, 1)
        XCTAssertFalse(viewModel.journals.contains(where: { $0.id == journalIdToDelete }))
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testDeleteJournalFailure() {
        // Prepare test data
        let mockJournals = TestData.mockJournalArray()
        viewModel.journals = mockJournals
        mockJournalService.journals = mockJournals
        
        // Configure mock service with failure
        let error = JournalServiceError.networkError("Test error")
        mockJournalService.deleteJournalResult = { _ in .failure(error) }
        
        // Get ID to delete
        let journalIdToDelete = mockJournals[0].id
        
        // Call the method under test
        viewModel.deleteJournal(journalId: journalIdToDelete)
        
        // Verify result
        XCTAssertEqual(mockJournalService.deleteJournalCallCount, 1)
        XCTAssertTrue(viewModel.journals.contains(where: { $0.id == journalIdToDelete }))
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.localizedDescription)
    }
    
    func testToggleFavoriteSuccess() {
        // Prepare test data
        let mockJournals = TestData.mockJournalArray()
        viewModel.journals = mockJournals
        mockJournalService.journals = mockJournals
        
        // Get journal to toggle and its initial state
        let journal = mockJournals[0]
        let journalId = journal.id
        let initialFavoriteState = journal.isFavorite
        
        // Create updated journal with toggled favorite state
        let updatedJournal = Journal(
            id: journal.id,
            userId: journal.userId,
            title: journal.title,
            createdAt: journal.createdAt,
            updatedAt: Date(),
            durationSeconds: journal.durationSeconds,
            isFavorite: !initialFavoriteState,
            isUploaded: journal.isUploaded,
            storagePath: journal.storagePath,
            encryptionIv: journal.encryptionIv,
            preEmotionalState: journal.preEmotionalState,
            postEmotionalState: journal.postEmotionalState,
            audioMetadata: journal.audioMetadata,
            localFileUrl: journal.localFileUrl
        )
        
        // Configure mock service
        mockJournalService.toggleFavoriteResult = { _ in .success(updatedJournal) }
        
        // Call the method under test
        viewModel.toggleFavorite(journalId: journalId)
        
        // Verify result
        XCTAssertEqual(mockJournalService.toggleFavoriteCallCount, 1)
        
        // Find the journal in the updated list
        if let updatedJournalInViewModel = viewModel.journals.first(where: { $0.id == journalId }) {
            XCTAssertEqual(updatedJournalInViewModel.isFavorite, !initialFavoriteState)
        } else {
            XCTFail("Journal not found in viewModel.journals after toggleFavorite")
        }
        
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testToggleFavoriteFailure() {
        // Prepare test data
        let mockJournals = TestData.mockJournalArray()
        viewModel.journals = mockJournals
        mockJournalService.journals = mockJournals
        
        // Get journal to toggle
        let journal = mockJournals[0]
        let journalId = journal.id
        let initialFavoriteState = journal.isFavorite
        
        // Configure mock service with failure
        let error = JournalServiceError.networkError("Test error")
        mockJournalService.toggleFavoriteResult = { _ in .failure(error) }
        
        // Call the method under test
        viewModel.toggleFavorite(journalId: journalId)
        
        // Verify result
        XCTAssertEqual(mockJournalService.toggleFavoriteCallCount, 1)
        
        // Find the journal in the list and verify its state is unchanged
        if let journalInViewModel = viewModel.journals.first(where: { $0.id == journalId }) {
            XCTAssertEqual(journalInViewModel.isFavorite, initialFavoriteState)
        } else {
            XCTFail("Journal not found in viewModel.journals after toggleFavorite")
        }
        
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.localizedDescription)
    }
    
    func testNavigateToJournalDetail() {
        // Prepare test data
        let journalId = UUID()
        
        // Call the method under test
        viewModel.navigateToJournalDetail(journalId: journalId)
        
        // Verify result
        XCTAssertEqual(navigatedToJournalId, journalId)
    }
    
    func testNavigateToRecordJournal() {
        // Call the method under test
        viewModel.navigateToRecordJournal()
        
        // Verify result
        XCTAssertTrue(navigatedToRecordJournal)
    }
    
    func testSetFilter() {
        // Prepare test data
        let mockJournals = TestData.mockJournalArray(count: 5)
        // Make some journals favorites
        var journals = mockJournals
        journals[0].isFavorite = true
        journals[2].isFavorite = true
        
        viewModel.journals = journals
        mockJournalService.journals = journals
        
        // Call the method under test
        viewModel.setFilter(.favorites)
        
        // Verify result
        XCTAssertEqual(viewModel.selectedFilter, .favorites)
        XCTAssertEqual(viewModel.journals.count, 2)
        XCTAssertTrue(viewModel.journals.allSatisfy { $0.isFavorite })
        
        // Test switching back to all
        viewModel.setFilter(.all)
        
        // Verify result
        XCTAssertEqual(viewModel.selectedFilter, .all)
        XCTAssertEqual(viewModel.journals.count, journals.count)
    }
    
    func testSetSortOption() {
        // Prepare test data with different creation dates and durations
        let calendar = Calendar.current
        let now = Date()
        
        let journal1 = Journal(
            id: UUID(),
            title: "A Journal",
            createdAt: calendar.date(byAdding: .day, value: -2, to: now)!,
            durationSeconds: 120,
            storagePath: "path1",
            encryptionIv: "iv1",
            preEmotionalState: TestData.mockEmotionalState()
        )
        
        let journal2 = Journal(
            id: UUID(),
            title: "B Journal",
            createdAt: calendar.date(byAdding: .day, value: -1, to: now)!,
            durationSeconds: 180,
            storagePath: "path2",
            encryptionIv: "iv2",
            preEmotionalState: TestData.mockEmotionalState()
        )
        
        let journal3 = Journal(
            id: UUID(),
            title: "C Journal",
            createdAt: now,
            durationSeconds: 60,
            storagePath: "path3",
            encryptionIv: "iv3",
            preEmotionalState: TestData.mockEmotionalState()
        )
        
        let journals = [journal1, journal2, journal3]
        viewModel.journals = journals
        mockJournalService.journals = journals
        
        // Test date oldest sort
        viewModel.setSortOption(.dateOldest)
        
        // Verify result
        XCTAssertEqual(viewModel.selectedSortOption, .dateOldest)
        XCTAssertEqual(viewModel.journals[0].id, journal1.id) // Oldest first
        XCTAssertEqual(viewModel.journals[1].id, journal2.id)
        XCTAssertEqual(viewModel.journals[2].id, journal3.id)
        
        // Test duration longest sort
        viewModel.setSortOption(.durationLongest)
        
        // Verify result
        XCTAssertEqual(viewModel.selectedSortOption, .durationLongest)
        XCTAssertEqual(viewModel.journals[0].id, journal2.id) // Longest first (180s)
        XCTAssertEqual(viewModel.journals[1].id, journal1.id) // Second longest (120s)
        XCTAssertEqual(viewModel.journals[2].id, journal3.id) // Shortest (60s)
    }
    
    func testSetEmotionFilter() {
        // Prepare test data with different emotions
        let state1 = EmotionalState(
            emotionType: .joy,
            intensity: 7,
            context: .preJournaling
        )
        
        let state2 = EmotionalState(
            emotionType: .calm,
            intensity: 5,
            context: .postJournaling
        )
        
        let state3 = EmotionalState(
            emotionType: .anxiety,
            intensity: 8,
            context: .preJournaling
        )
        
        let journal1 = Journal(
            id: UUID(),
            title: "Journal 1",
            createdAt: Date(),
            durationSeconds: 120,
            storagePath: "path1",
            encryptionIv: "iv1",
            preEmotionalState: state1,
            postEmotionalState: state2
        )
        
        let journal2 = Journal(
            id: UUID(),
            title: "Journal 2",
            createdAt: Date(),
            durationSeconds: 180,
            storagePath: "path2",
            encryptionIv: "iv2",
            preEmotionalState: state3,
            postEmotionalState: state1
        )
        
        let journal3 = Journal(
            id: UUID(),
            title: "Journal 3",
            createdAt: Date(),
            durationSeconds: 60,
            storagePath: "path3",
            encryptionIv: "iv3",
            preEmotionalState: state2,
            postEmotionalState: nil
        )
        
        let journals = [journal1, journal2, journal3]
        viewModel.journals = journals
        mockJournalService.journals = journals
        
        // Test filtering by joy
        viewModel.setEmotionFilter(.joy)
        
        // Verify result
        XCTAssertEqual(viewModel.selectedEmotionFilter, .joy)
        XCTAssertEqual(viewModel.selectedFilter, .emotion)
        XCTAssertEqual(viewModel.journals.count, 2) // journal1 and journal2 have joy
        XCTAssertTrue(viewModel.journals.contains(where: { $0.id == journal1.id }))
        XCTAssertTrue(viewModel.journals.contains(where: { $0.id == journal2.id }))
        
        // Test clearing filter
        viewModel.setEmotionFilter(nil)
        
        // Verify result
        XCTAssertNil(viewModel.selectedEmotionFilter)
        XCTAssertEqual(viewModel.journals.count, 3) // All journals
    }
    
    func testUpdateSearchText() {
        // Prepare test data with different titles
        let journal1 = Journal(
            id: UUID(),
            title: "Morning Reflection",
            createdAt: Date(),
            durationSeconds: 120,
            storagePath: "path1",
            encryptionIv: "iv1",
            preEmotionalState: TestData.mockEmotionalState()
        )
        
        let journal2 = Journal(
            id: UUID(),
            title: "Afternoon Thoughts",
            createdAt: Date(),
            durationSeconds: 180,
            storagePath: "path2",
            encryptionIv: "iv2",
            preEmotionalState: TestData.mockEmotionalState()
        )
        
        let journal3 = Journal(
            id: UUID(),
            title: "Evening Meditation",
            createdAt: Date(),
            durationSeconds: 60,
            storagePath: "path3",
            encryptionIv: "iv3",
            preEmotionalState: TestData.mockEmotionalState()
        )
        
        let journals = [journal1, journal2, journal3]
        viewModel.journals = journals
        mockJournalService.journals = journals
        
        // Test filtering by search text
        viewModel.updateSearchText("Morning")
        
        // Verify result
        XCTAssertEqual(viewModel.searchText, "Morning")
        XCTAssertEqual(viewModel.journals.count, 1)
        XCTAssertEqual(viewModel.journals[0].id, journal1.id)
        
        // Test clearing search text
        viewModel.updateSearchText("")
        
        // Verify result
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertEqual(viewModel.journals.count, 3) // All journals
    }
    
    func testGetEmotionTypeOptions() {
        // Call the method under test
        let emotionTypes = viewModel.getEmotionTypeOptions()
        
        // Verify result
        XCTAssertEqual(emotionTypes, EmotionType.allCases)
    }
    
    func testJournalCreatedSubscription() {
        // Prepare test data
        let newJournal = TestData.mockJournal()
        
        // Set up expectation for journals array to update
        let expectation = XCTestExpectation(description: "Journal created event updates journals array")
        
        viewModel.$journals
            .dropFirst() // Skip initial value
            .sink { journals in
                XCTAssertTrue(journals.contains(where: { $0.id == newJournal.id }))
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Trigger the event
        mockJournalService.journalCreatedPublisher().send(newJournal)
        
        // Wait for expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testJournalUpdatedSubscription() {
        // Prepare test data
        let journals = TestData.mockJournalArray()
        viewModel.journals = journals
        mockJournalService.journals = journals
        
        // Create an updated version of the first journal
        let originalJournal = journals[0]
        let updatedJournal = Journal(
            id: originalJournal.id,
            userId: originalJournal.userId,
            title: "Updated Title",
            createdAt: originalJournal.createdAt,
            updatedAt: Date(),
            durationSeconds: originalJournal.durationSeconds,
            isFavorite: !originalJournal.isFavorite,
            isUploaded: originalJournal.isUploaded,
            storagePath: originalJournal.storagePath,
            encryptionIv: originalJournal.encryptionIv,
            preEmotionalState: originalJournal.preEmotionalState,
            postEmotionalState: originalJournal.postEmotionalState,
            audioMetadata: originalJournal.audioMetadata,
            localFileUrl: originalJournal.localFileUrl
        )
        
        // Set up expectation for journals array to update
        let expectation = XCTestExpectation(description: "Journal updated event updates journals array")
        
        viewModel.$journals
            .dropFirst() // Skip initial value
            .sink { journals in
                if let journal = journals.first(where: { $0.id == updatedJournal.id }) {
                    XCTAssertEqual(journal.title, "Updated Title")
                    XCTAssertEqual(journal.isFavorite, !originalJournal.isFavorite)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Trigger the event
        mockJournalService.journalUpdatedPublisher().send(updatedJournal)
        
        // Wait for expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testJournalDeletedSubscription() {
        // Prepare test data
        let journals = TestData.mockJournalArray()
        viewModel.journals = journals
        mockJournalService.journals = journals
        
        let journalIdToDelete = journals[0].id
        
        // Set up expectation for journals array to update
        let expectation = XCTestExpectation(description: "Journal deleted event updates journals array")
        
        viewModel.$journals
            .dropFirst() // Skip initial value
            .sink { journals in
                XCTAssertFalse(journals.contains(where: { $0.id == journalIdToDelete }))
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Trigger the event
        mockJournalService.journalDeletedPublisher().send(journalIdToDelete)
        
        // Wait for expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testErrorSubscription() {
        // Prepare test data
        let error = JournalServiceError.networkError("Test error")
        
        // Set up expectation for errorMessage to update
        let expectation = XCTestExpectation(description: "Error event updates errorMessage")
        
        viewModel.$errorMessage
            .dropFirst() // Skip initial value
            .sink { errorMessage in
                XCTAssertEqual(errorMessage, error.localizedDescription)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Trigger the event
        mockJournalService.errorPublisher().send(error)
        
        // Wait for expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCombinedFiltering() {
        // Prepare test data with different emotions, favorite status, and titles
        let state1 = EmotionalState(
            emotionType: .joy,
            intensity: 7,
            context: .preJournaling
        )
        
        let state2 = EmotionalState(
            emotionType: .calm,
            intensity: 5,
            context: .postJournaling
        )
        
        let journal1 = Journal(
            id: UUID(),
            title: "Happy Day Reflection",
            createdAt: Date(),
            durationSeconds: 120,
            isFavorite: true,
            storagePath: "path1",
            encryptionIv: "iv1",
            preEmotionalState: state1,
            postEmotionalState: state2
        )
        
        let journal2 = Journal(
            id: UUID(),
            title: "Happy Thoughts",
            createdAt: Date(),
            durationSeconds: 180,
            isFavorite: false,
            storagePath: "path2",
            encryptionIv: "iv2",
            preEmotionalState: state1,
            postEmotionalState: nil
        )
        
        let journal3 = Journal(
            id: UUID(),
            title: "Calm Evening",
            createdAt: Date(),
            durationSeconds: 60,
            isFavorite: true,
            storagePath: "path3",
            encryptionIv: "iv3",
            preEmotionalState: state2,
            postEmotionalState: nil
        )
        
        let journals = [journal1, journal2, journal3]
        viewModel.journals = journals
        mockJournalService.journals = journals
        
        // Apply favorite filter
        viewModel.setFilter(.favorites)
        
        // Verify favorite filter
        XCTAssertEqual(viewModel.journals.count, 2)
        XCTAssertTrue(viewModel.journals.contains(where: { $0.id == journal1.id }))
        XCTAssertTrue(viewModel.journals.contains(where: { $0.id == journal3.id }))
        
        // Apply search text filter
        viewModel.updateSearchText("Happy")
        
        // Verify combined filters (favorites + search text)
        XCTAssertEqual(viewModel.journals.count, 1)
        XCTAssertEqual(viewModel.journals[0].id, journal1.id)
        
        // Apply emotion filter
        viewModel.setEmotionFilter(.joy)
        
        // Verify combined filters (favorites + search text + emotion)
        XCTAssertEqual(viewModel.journals.count, 1)
        XCTAssertEqual(viewModel.journals[0].id, journal1.id)
    }
}