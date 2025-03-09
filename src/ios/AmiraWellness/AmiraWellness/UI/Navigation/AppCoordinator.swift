# src/ios/AmiraWellness/AmiraWellness/UI/Navigation/AppCoordinator.swift
import SwiftUI // SwiftUI - Latest - Framework for building the user interface
import Combine // Combine - Latest - Reactive programming framework for handling state changes

// Internal imports
import NavigationRouter // src/ios/AmiraWellness/AmiraWellness/UI/Navigation/NavigationRouter.swift - Manages navigation between different screens in the application
import ViewFactory // src/ios/AmiraWellness/AmiraWellness/UI/Navigation/ViewFactory.swift - Factory for creating views with proper dependencies
import DIContainer // src/ios/AmiraWellness/AmiraWellness/Core/DI/DIContainer.swift - Access to the dependency injection container
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift - Logging navigation events and errors
import AnalyticsManager // src/ios/AmiraWellness/AmiraWellness/Managers/AnalyticsManager.swift - Tracking navigation events for analytics

/// A coordinator class that manages the application's navigation flow and lifecycle
@MainActor
@ObservableObject
class AppCoordinator {
    @MainActor
    @ObservableObject
    // MARK: - Properties

    private let router: NavigationRouter
    private let viewFactory: ViewFactory
    @Published var isInitialized: Bool = false
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// Initializes the AppCoordinator with dependencies
    init() {
        // Create a ViewFactory instance with DIContainer.shared
        self.viewFactory = ViewFactory(container: DIContainer.shared)
        // Create a NavigationRouter instance with the viewFactory
        self.router = NavigationRouter(viewFactory: viewFactory)
        // Initialize isInitialized to false
        self.isInitialized = false
        // Initialize cancellables as an empty set
        self.cancellables = []

        // Set up subscriptions to router state changes
        router.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Starts the coordinator and determines the initial navigation flow
    func start() {
        // Log the start of the application
        Logger.debug("Starting the application")

        // Track app launch event with AnalyticsManager
        AnalyticsManager.shared.trackEvent(eventType: .appOpen)

        // Call router.determineStartDestination() to set the initial screen
        router.determineStartDestination()

        // Set isInitialized to true
        isInitialized = true
    }

    /// Handles deep links to navigate to specific screens
    /// - Parameter url: The URL to handle
    /// - Returns: Whether the deep link was handled successfully
    func handleDeepLink(url: URL) -> Bool {
        // Log the deep link URL
        Logger.debug("Handling deep link: \(url)")

        // Ensure the coordinator is initialized
        guard isInitialized else {
            return false
        }

        // Forward the URL to router.handleDeepLink(url)
        let handled = router.handleDeepLink(url: url)

        // Track deep link event with AnalyticsManager
        AnalyticsManager.shared.trackEvent(eventType: .screenView, parameters: ["deep_link_url": url.absoluteString])

        // Return the result of the router's deep link handling
        return handled
    }

    /// Handles universal links (web URLs associated with the app)
    /// - Parameter userActivity: The NSUserActivity containing the universal link
    /// - Returns: Whether the universal link was handled successfully
    func handleUniversalLink(userActivity: NSUserActivity) -> Bool {
        // Check if the userActivity type is browsingWeb
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb else {
            return false
        }

        // Extract the webpageURL from the userActivity
        guard let webpageURL = userActivity.webpageURL else {
            return false
        }

        // Forward to handleDeepLink if URL is valid
        return handleDeepLink(url: webpageURL)
    }

    /// Handles navigation triggered by notifications
    /// - Parameter userInfo: The notification user info dictionary
    func handleNotification(userInfo: [AnyHashable: Any]) {
        // Extract navigation data from userInfo
        guard let notificationTypeString = userInfo[NotificationConstants.UserInfo.notificationType] as? String,
              let notificationType = NotificationType(rawValue: notificationTypeString) else {
            Logger.error("Invalid notification user info")
            return
        }

        // Determine the appropriate destination based on notification type
        var destination: NavigationDestination?

        switch notificationType {
        case .dailyReminder:
            destination = .emotionalCheckin
        case .streakReminder:
            destination = .mainTabView
        case .achievement:
            destination = .mainTabView
        case .affirmation:
            destination = .mainTabView
        case .wellnessTip:
            destination = .mainTabView
        case .appUpdate:
            destination = .mainTabView
        }

        // Navigate to the determined destination using the router
        if let destination = destination {
            switch destination {
            case .mainTabView:
                router.navigateToTab(tab: .home)
            default:
                Logger.error("Invalid notification destination")
            }
        }

        // Track notification navigation event with AnalyticsManager
        AnalyticsManager.shared.trackEvent(eventType: .screenView, parameters: ["notification_type": notificationTypeString])
    }

    /// Returns the root view of the application
    /// - Returns: The root view of the application
    func rootView() -> AnyView {
        // Return router.currentView() wrapped in AnyView
        return AnyView(router.currentView())
    }
}