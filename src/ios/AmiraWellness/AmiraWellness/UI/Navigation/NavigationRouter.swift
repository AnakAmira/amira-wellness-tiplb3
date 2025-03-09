import SwiftUI // SwiftUI - Latest - Framework for building the user interface
import Combine // Combine - Latest - Reactive programming framework for handling navigation state

// Internal imports
import ViewFactory // src/ios/AmiraWellness/AmiraWellness/UI/Navigation/ViewFactory.swift - Factory for creating views with proper dependencies
import UserDefaultsManager // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/UserDefaultsManager.swift - Manage user preferences and application state
import AppConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/AppConstants.swift - Access application constants including UserDefaults keys
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift - Logging navigation events and errors
import EmotionalState // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalState.swift - Used as parameter type for emotional check-in related navigation

/// Defines possible navigation destinations in the application
enum NavigationDestination {
    case onboarding
    case login
    case register
    case forgotPassword
    case mainTabView
    case journalDetail(String)
    case recordJournal
    case emotionalCheckin
    case toolDetail(String)
    case toolInProgress(String)
    case toolCompletion(String)
}

/// Defines the main tabs in the application's tab bar
enum TabDestination: Int {
    case home = 0
    case journal
    case tools
    case progress
    case profile
}

/// A protocol for managing tab navigation
protocol TabNavigationProtocol: ObservableObject {
    var selectedTab: Int { get set }
}

/// A router class that manages navigation between different screens in the application
class NavigationRouter: TabNavigationProtocol, ObservableObject {
    private let viewFactory: ViewFactory
    @Published private(set) var currentDestination: NavigationDestination?
    @Published var selectedTab: Int
    private var cancellables = Set<AnyCancellable>()

    /// Initializes the NavigationRouter with a view factory
    /// - Parameter viewFactory: The view factory
    init(viewFactory: ViewFactory = ViewFactory()) {
        self.viewFactory = viewFactory // Store the provided viewFactory for later use
        self.currentDestination = nil // Initialize currentDestination as nil
        self.selectedTab = 0 // Initialize selectedTab as 0 (home tab)
        self.cancellables = [] // Initialize cancellables as an empty set
    }

    /// Determines the initial destination based on user state
    /// - Returns: The initial view to display
    func determineStartDestination() -> AnyView {
        if !UserDefaultsManager.shared.getBool(forKey: AppConstants.UserDefaults.hasCompletedOnboarding) { // Check if user has completed onboarding using UserDefaultsManager
            currentDestination = .onboarding // Update currentDestination accordingly
            return AnyView(viewFactory.makeOnboardingView(onboardingCompleted: { [weak self] in
                self?.navigateToLogin()
            })) // If not completed onboarding, return onboarding view
        } else if currentDestination == .onboarding {
            currentDestination = .login
            return AnyView(viewFactory.makeLoginView(onNavigateToRegister: { [weak self] in
                self?.navigateToRegister()
            }, onNavigateToForgotPassword: { [weak self] in
                self?.navigateToForgotPassword()
            }, onNavigateToMainTabView: { [weak self] in
                self?.navigateToMainTabView()
            }))
        }
        else {
            currentDestination = .login
            return AnyView(viewFactory.makeLoginView(onNavigateToRegister: { [weak self] in
                self?.navigateToRegister()
            }, onNavigateToForgotPassword: { [weak self] in
                self?.navigateToForgotPassword()
            }, onNavigateToMainTabView: { [weak self] in
                self?.navigateToMainTabView()
            }))
        }
    }

    /// Navigates to the onboarding screen
    func navigateToOnboarding() {
        currentDestination = .onboarding // Set currentDestination to .onboarding
        Logger.debug("Navigating to onboarding screen") // Log navigation event
    }

    /// Navigates to the login screen
    func navigateToLogin() {
        currentDestination = .login // Set currentDestination to .login
        Logger.debug("Navigating to login screen") // Log navigation event
    }

    /// Navigates to the registration screen
    func navigateToRegister() {
        currentDestination = .register // Set currentDestination to .register
        Logger.debug("Navigating to register screen") // Log navigation event
    }

    /// Navigates to the forgot password screen
    func navigateToForgotPassword() {
        currentDestination = .forgotPassword // Set currentDestination to .forgotPassword
        Logger.debug("Navigating to forgot password screen") // Log navigation event
    }

    /// Navigates to the main tab view
    func navigateToMainTabView() {
        currentDestination = .mainTabView // Set currentDestination to .mainTabView
        Logger.debug("Navigating to main tab view") // Log navigation event
    }

    /// Navigates to a specific journal detail screen
    /// - Parameter journalId: The ID of the journal to navigate to
    func navigateToJournalDetail(journalId: String) {
        currentDestination = .journalDetail(journalId) // Set currentDestination to .journalDetail(journalId)
        Logger.debug("Navigating to journal detail screen with journal ID: \(journalId)") // Log navigation event with journal ID
    }

    /// Navigates to the record journal screen
    func navigateToRecordJournal() {
        currentDestination = .recordJournal // Set currentDestination to .recordJournal
        Logger.debug("Navigating to record journal screen") // Log navigation event
    }

    /// Navigates to the emotional check-in screen
    func navigateToEmotionalCheckin() {
        currentDestination = .emotionalCheckin // Set currentDestination to .emotionalCheckin
        Logger.debug("Navigating to emotional check-in screen") // Log navigation event
    }

    /// Navigates to a specific tool detail screen
    /// - Parameter toolId: The ID of the tool to navigate to
    func navigateToToolDetail(toolId: String) {
        currentDestination = .toolDetail(toolId) // Set currentDestination to .toolDetail(toolId)
        Logger.debug("Navigating to tool detail screen with tool ID: \(toolId)") // Log navigation event with tool ID
    }

    /// Navigates to the tool in progress screen
    /// - Parameter toolId: The ID of the tool to navigate to
    func navigateToToolInProgress(toolId: String) {
        currentDestination = .toolInProgress(toolId) // Set currentDestination to .toolInProgress(toolId)
        Logger.debug("Navigating to tool in progress screen with tool ID: \(toolId)") // Log navigation event with tool ID
    }

    /// Navigates to the tool completion screen
    /// - Parameter toolId: The ID of the tool to navigate to
    func navigateToToolCompletion(toolId: String) {
        currentDestination = .toolCompletion(toolId) // Set currentDestination to .toolCompletion(toolId)
        Logger.debug("Navigating to tool completion screen with tool ID: \(toolId)") // Log navigation event with tool ID
    }

    /// Navigates to a specific tab in the main tab view
    /// - Parameter tab: The tab to navigate to
    func navigateToTab(tab: TabDestination) {
        selectedTab = tab.rawValue // Set selectedTab to the raw value of the tab
        currentDestination = .mainTabView // Ensure currentDestination is .mainTabView
        Logger.debug("Navigating to tab: \(tab)") // Log navigation event with tab information
    }

    /// Navigates back to the previous screen
    func goBack() {
        // Determine the appropriate previous destination based on current state
        // Update currentDestination to the previous destination
        // Log navigation event
    }

    /// Handles deep links to navigate to specific screens
    /// - Parameter url: The URL to handle
    /// - Returns: Whether the deep link was handled successfully
    func handleDeepLink(url: URL) -> Bool {
        // Parse the URL to extract path components and parameters
        // Determine the appropriate destination based on the URL path
        // Navigate to the determined destination
        // Return true if the deep link was handled, false otherwise
        // Log deep link handling result
        return false
    }

    /// Returns the appropriate view for the current destination
    /// - Returns: The view for the current destination
    @ViewBuilder
    func currentView() -> some View {
        switch currentDestination {
        case .onboarding:
            viewFactory.makeOnboardingView(onboardingCompleted: { [weak self] in
                self?.navigateToLogin()
            })
        case .login:
            viewFactory.makeLoginView(onNavigateToRegister: { [weak self] in
                self?.navigateToRegister()
            }, onNavigateToForgotPassword: { [weak self] in
                self?.navigateToForgotPassword()
            }, onNavigateToMainTabView: { [weak self] in
                self?.navigateToMainTabView()
            })
        case .register:
            viewFactory.makeRegisterView(onNavigateToLogin: { [weak self] in
                self?.navigateToLogin()
            }, onRegistrationSuccess: { [weak self] in
                self?.navigateToMainTabView()
            })
        case .forgotPassword:
            viewFactory.makeForgotPasswordView(onNavigateToLogin: { [weak self] in
                self?.navigateToLogin()
            }, onGoBack: { [weak self] in
                self?.goBack()
            })
        case .mainTabView:
            viewFactory.makeMainTabView(selectedTab: Binding(
                get: { self.selectedTab },
                set: { self.selectedTab = $0 }
            ))
        case .journalDetail(let journalId):
            viewFactory.makeJournalDetailView(journalId: UUID(uuidString: journalId)!)
        case .recordJournal:
            viewFactory.makeRecordJournalView()
        case .emotionalCheckin:
            viewFactory.makeEmotionalCheckinView()
        case .toolDetail(let toolId):
            viewFactory.makeToolDetailView(toolId: toolId)
        case .toolInProgress(let toolId):
            viewFactory.makeToolInProgressView(toolId: toolId)
        case .toolCompletion(let toolId):
            viewFactory.makeToolCompletionView(toolId: toolId)
        case .none:
            Text("No destination")
        }
    }

    /// Marks onboarding as completed and navigates to login
    func completeOnboarding() {
        UserDefaultsManager.shared.setBool(true, forKey: AppConstants.UserDefaults.hasCompletedOnboarding) // Set UserDefaultsManager.shared.hasCompletedOnboarding to true
        navigateToLogin() // Navigate to login screen
        Logger.debug("Onboarding completed") // Log onboarding completion
    }
}