import Foundation // iOS SDK
import Combine // iOS SDK
import SwiftUI // iOS SDK

/// A view model that manages the state and business logic for the journal list screen in the Amira Wellness application.
/// It handles fetching, filtering, sorting, and managing voice journal entries, as well as providing
/// functionality for navigation to related screens.
class JournalListViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// The filtered and sorted list of journals to display
    @Published var journals: [Journal] = []
    
    /// Indicates whether journals are currently being loaded
    @Published var isLoading: Bool = false
    
    /// Error message to display to the user, if any
    @Published var errorMessage: String? = nil
    
    /// The currently selected filter option
    @Published var selectedFilter: JournalFilterOption = .all
    
    /// The currently selected sort option
    @Published var selectedSortOption: JournalSortOption = .dateNewest
    
    /// The currently selected emotion filter, if any
    @Published var selectedEmotionFilter: EmotionType? = nil
    
    /// The current search text for filtering journals
    @Published var searchText: String = ""
    
    // MARK: - Private Properties
    
    /// Service for managing journal entries
    private let journalService: JournalService
    
    /// Handler for navigating to the journal detail screen
    private let navigateToJournalDetailHandler: (UUID) -> Void
    
    /// Handler for navigating to the record journal screen
    private let navigateToRecordJournalHandler: () -> Void
    
    /// The complete unfiltered list of journals
    private var allJournals: [Journal] = []
    
    /// Set of cancellables for managing Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the view model with dependencies and navigation handlers
    /// - Parameters:
    ///   - journalService: Service for managing journal entries
    ///   - navigateToJournalDetailHandler: Handler for navigating to the journal detail screen
    ///   - navigateToRecordJournalHandler: Handler for navigating to the record journal screen
    init(
        journalService: JournalService = JournalService.shared,
        navigateToJournalDetailHandler: @escaping (UUID) -> Void,
        navigateToRecordJournalHandler: @escaping () -> Void
    ) {
        self.journalService = journalService
        self.navigateToJournalDetailHandler = navigateToJournalDetailHandler
        self.navigateToRecordJournalHandler = navigateToRecordJournalHandler
        
        setupSubscriptions()
        loadJournals()
    }
    
    // MARK: - Public Methods
    
    /// Loads journal entries from the service
    func loadJournals() {
        isLoading = true
        errorMessage = nil
        
        journalService.getJournals { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let journals):
                self.allJournals = journals
                self.applyFiltersAndSort()
                Logger.shared.debug("Loaded \(journals.count) journals", category: .database)
                
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                Logger.shared.error("Failed to load journals", error: error, category: .database)
            }
        }
    }
    
    /// Refreshes the journal list
    func refreshJournals() {
        loadJournals()
    }
    
    /// Deletes a journal entry
    /// - Parameter journalId: The ID of the journal to delete
    func deleteJournal(journalId: UUID) {
        journalService.deleteJournal(journalId: journalId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                if let index = self.allJournals.firstIndex(where: { $0.id == journalId }) {
                    self.allJournals.remove(at: index)
                    self.applyFiltersAndSort()
                }
                Logger.shared.debug("Successfully deleted journal with ID: \(journalId)", category: .database)
                
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                Logger.shared.error("Failed to delete journal with ID: \(journalId)", error: error, category: .database)
            }
        }
    }
    
    /// Toggles the favorite status of a journal
    /// - Parameter journalId: The ID of the journal to toggle favorite status
    func toggleFavorite(journalId: UUID) {
        journalService.toggleFavorite(journalId: journalId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let updatedJournal):
                if let index = self.allJournals.firstIndex(where: { $0.id == journalId }) {
                    self.allJournals[index] = updatedJournal
                    self.applyFiltersAndSort()
                }
                Logger.shared.debug("Successfully toggled favorite for journal with ID: \(journalId)", category: .database)
                
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                Logger.shared.error("Failed to toggle favorite for journal with ID: \(journalId)", error: error, category: .database)
            }
        }
    }
    
    /// Navigates to the journal detail screen
    /// - Parameter journalId: The ID of the journal to view
    func navigateToJournalDetail(journalId: UUID) {
        navigateToJournalDetailHandler(journalId)
        Logger.shared.debug("Navigating to journal detail for ID: \(journalId)", category: .userInterface)
    }
    
    /// Navigates to the record journal screen
    func navigateToRecordJournal() {
        navigateToRecordJournalHandler()
        Logger.shared.debug("Navigating to record journal screen", category: .userInterface)
    }
    
    /// Sets the filter option and applies filtering
    /// - Parameter filter: The filter option to set
    func setFilter(_ filter: JournalFilterOption) {
        selectedFilter = filter
        
        // Reset emotion filter if not using emotion filter
        if filter != .emotion {
            selectedEmotionFilter = nil
        }
        
        applyFiltersAndSort()
        Logger.shared.debug("Set journal filter to: \(filter)", category: .userInterface)
    }
    
    /// Sets the sort option and applies sorting
    /// - Parameter sortOption: The sort option to set
    func setSortOption(_ sortOption: JournalSortOption) {
        selectedSortOption = sortOption
        applyFiltersAndSort()
        Logger.shared.debug("Set journal sort option to: \(sortOption)", category: .userInterface)
    }
    
    /// Sets the emotion filter and applies filtering
    /// - Parameter emotionType: The emotion type to filter by, or nil to clear the filter
    func setEmotionFilter(_ emotionType: EmotionType?) {
        selectedEmotionFilter = emotionType
        
        // If setting an emotion filter, also set the filter type to emotion
        if emotionType != nil {
            selectedFilter = .emotion
        }
        
        applyFiltersAndSort()
        Logger.shared.debug("Set emotion filter to: \(emotionType?.displayName() ?? "nil")", category: .userInterface)
    }
    
    /// Updates the search text and applies filtering
    /// - Parameter text: The search text to set
    func updateSearchText(_ text: String) {
        searchText = text
        applyFiltersAndSort()
        
        // Only log if the search text is substantial to avoid excessive logging
        if text.count > 2 || text.isEmpty {
            Logger.shared.debug("Updated search text to: \"\(text)\"", category: .userInterface)
        }
    }
    
    /// Returns all available emotion types for filtering
    /// - Returns: Array of emotion types
    func getEmotionTypeOptions() -> [EmotionType] {
        return EmotionType.allCases
    }
    
    // MARK: - Private Methods
    
    /// Applies current filters and sorting to the journal list
    private func applyFiltersAndSort() {
        journals = sortJournals(filterJournals(allJournals))
    }
    
    /// Sets up Combine subscriptions to journal service events
    private func setupSubscriptions() {
        journalService.journalCreatedPublisher()
            .sink { [weak self] journal in
                guard let self = self else { return }
                self.allJournals.append(journal)
                self.applyFiltersAndSort()
            }
            .store(in: &cancellables)
        
        journalService.journalUpdatedPublisher()
            .sink { [weak self] journal in
                guard let self = self else { return }
                if let index = self.allJournals.firstIndex(where: { $0.id == journal.id }) {
                    self.allJournals[index] = journal
                    self.applyFiltersAndSort()
                }
            }
            .store(in: &cancellables)
        
        journalService.journalDeletedPublisher()
            .sink { [weak self] journalId in
                guard let self = self else { return }
                self.allJournals.removeAll { $0.id == journalId }
                self.applyFiltersAndSort()
            }
            .store(in: &cancellables)
        
        journalService.errorPublisher()
            .sink { [weak self] error in
                guard let self = self else { return }
                self.errorMessage = error.localizedDescription
            }
            .store(in: &cancellables)
    }
    
    /// Filters journals based on current filter settings
    /// - Parameter journals: The journals to filter
    /// - Returns: Filtered journals
    private func filterJournals(_ journals: [Journal]) -> [Journal] {
        var filteredJournals = journals
        
        // Apply main filter
        switch selectedFilter {
        case .all:
            // No filtering needed
            break
        case .favorites:
            filteredJournals = filteredJournals.filter { $0.isFavorite }
        case .emotion:
            if let emotionType = selectedEmotionFilter {
                filteredJournals = filteredJournals.filter { 
                    $0.preEmotionalState.emotionType == emotionType || 
                    $0.postEmotionalState?.emotionType == emotionType 
                }
            }
        }
        
        // Apply search text filter if present
        if !searchText.isEmpty {
            filteredJournals = searchJournals(filteredJournals, searchText: searchText)
        }
        
        return filteredJournals
    }
    
    /// Sorts journals based on the current sort option
    /// - Parameter journals: The journals to sort
    /// - Returns: Sorted journals
    private func sortJournals(_ journals: [Journal]) -> [Journal] {
        switch selectedSortOption {
        case .dateNewest:
            return journals.sorted { $0.createdAt > $1.createdAt }
        case .dateOldest:
            return journals.sorted { $0.createdAt < $1.createdAt }
        case .durationLongest:
            return journals.sorted { $0.durationSeconds > $1.durationSeconds }
        case .durationShortest:
            return journals.sorted { $0.durationSeconds < $1.durationSeconds }
        case .titleAZ:
            return journals.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .titleZA:
            return journals.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        }
    }
    
    /// Filters journals based on search text
    /// - Parameters:
    ///   - journals: The journals to filter
    ///   - searchText: The search text to filter by
    /// - Returns: Filtered journals matching search text
    private func searchJournals(_ journals: [Journal], searchText: String) -> [Journal] {
        guard !searchText.isEmpty else { return journals }
        
        return journals.filter { journal in
            journal.title.localizedCaseInsensitiveContains(searchText)
        }
    }
}