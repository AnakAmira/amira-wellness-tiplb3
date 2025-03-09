import SwiftUI // SwiftUI - Latest - Framework for building the user interface
import UIKit // UIKit - Latest - Access to UIApplication for scene delegate methods
import Combine // Combine - Latest - Reactive programming for state management

// Internal imports
import AppConfig // src/ios/AmiraWellness/AmiraWellness/Config/AppConfig.swift - Access application configuration settings
import DIContainer // src/ios/AmiraWellness/AmiraWellness/Core/DI/DIContainer.swift - Access dependency injection container for service initialization
import AppCoordinator // src/ios/AmiraWellness/AmiraWellness/UI/Navigation/AppCoordinator.swift - Coordinate application navigation and screen flow
import AppStateManager // src/ios/AmiraWellness/AmiraWellness/Managers/AppStateManager.swift - Manage application state and lifecycle events
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift - Log application events and errors

/// The main SwiftUI App structure for the Amira Wellness application
@main
struct AmiraWellnessApp: App {
    @StateObject private var coordinator: AppCoordinator = AppCoordinator()
    private let appStateManager: AppStateManager = AppStateManager.shared
    private var cancellables: Set<AnyCancellable> = []

    /// Initializes the app with required services and managers
    init() {
        // Initialize coordinator with a new AppCoordinator()
        // Initialize appStateManager with AppStateManager.shared
        // Initialize cancellables as an empty Set<AnyCancellable>()

        // Call setupApp() to initialize core services
        setupApp()
    }

    /// Builds the main app view hierarchy
    var body: some Scene {
        WindowGroup {
            // Return coordinator.rootView() as the root view
            coordinator.rootView()
            // Add .onAppear to start the coordinator when the app appears
                .onAppear {
                    coordinator.start()
                }
            // Add .onOpenURL to handle deep links
                .onOpenURL { url in
                    coordinator.handleDeepLink(url: url)
                }
            // Add .onContinueUserActivity to handle universal links
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    coordinator.handleUniversalLink(userActivity: userActivity)
                }
        }
    }

    /// Initializes core services and configurations
    private func setupApp() {
        // Log app initialization start
        Logger.shared.info("Setting up Amira Wellness app...")

        // Configure app appearance (colors, fonts, etc.)
        configureAppearance()

        // Initialize AppStateManager
        appStateManager.initialize()

        // Ensure DIContainer is ready
        _ = DIContainer.shared

        // Register for scene lifecycle notifications
        registerForSceneNotifications()

        // Log app initialization completion
        Logger.shared.info("Amira Wellness app setup completed.")
    }

    /// Configures the global appearance settings for the app
    private func configureAppearance() {
        // Configure UINavigationBar appearance
        UINavigationBar.appearance().barTintColor = UIColor(ColorConstants.background)
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(ColorConstants.textPrimary)]

        // Configure UITabBar appearance
        UITabBar.appearance().barTintColor = UIColor(ColorConstants.background)
        UITabBar.appearance().backgroundColor = UIColor(ColorConstants.background)
    }

    /// Registers for scene lifecycle notifications
    private func registerForSceneNotifications() {
        // Register for willEnterForeground notification
        NotificationCenter.default.publisher(for: UIScene.willEnterForegroundNotification)
            .sink { [weak self] notification in
                self?.handleSceneWillEnterForeground(notification: notification)
            }
            .store(in: &cancellables)

        // Register for didEnterBackground notification
        NotificationCenter.default.publisher(for: UIScene.didEnterBackgroundNotification)
            .sink { [weak self] notification in
                self?.handleSceneDidEnterBackground(notification: notification)
            }
            .store(in: &cancellables)

        // Register for willResignActive notification
        NotificationCenter.default.publisher(for: UIScene.willResignActiveNotification)
            .sink { [weak self] notification in
                self?.handleSceneWillResignActive(notification: notification)
            }
            .store(in: &cancellables)

        // Register for didBecomeActive notification
        NotificationCenter.default.publisher(for: UIScene.didBecomeActiveNotification)
            .sink { [weak self] notification in
                self?.handleSceneDidBecomeActive(notification: notification)
            }
            .store(in: &cancellables)
    }

    /// Handles scene entering foreground notification
    @objc private func handleSceneWillEnterForeground(notification: Notification) {
        // Log scene will enter foreground
        Logger.shared.info("Scene will enter foreground")

        // Call appStateManager.handleAppWillEnterForeground()
        appStateManager.handleAppWillEnterForeground()
    }

    /// Handles scene entering background notification
    @objc private func handleSceneDidEnterBackground(notification: Notification) {
        // Log scene did enter background
        Logger.shared.info("Scene did enter background")

        // Call appStateManager.handleAppDidEnterBackground()
        appStateManager.handleAppDidEnterBackground()
    }

    /// Handles scene will resign active notification
    @objc private func handleSceneWillResignActive(notification: Notification) {
        // Log scene will resign active
        Logger.shared.info("Scene will resign active")

        // Call appStateManager.handleAppWillResignActive()
        appStateManager.handleAppWillResignActive()
    }

    /// Handles scene becoming active notification
    @objc private func handleSceneDidBecomeActive(notification: Notification) {
        // Log scene did become active
        Logger.shared.info("Scene did become active")

        // Call appStateManager.handleAppDidBecomeActive()
        appStateManager.handleAppDidBecomeActive()
    }
}