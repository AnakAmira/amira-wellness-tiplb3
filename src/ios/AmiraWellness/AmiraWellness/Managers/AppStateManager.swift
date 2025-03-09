import Foundation // Latest
import Combine // Latest
import UIKit // Latest
import UserNotifications // Latest

// Internal imports
import AuthService // src/ios/AmiraWellness/AmiraWellness/Services/Authentication/AuthService.swift
import NetworkMonitor // src/ios/AmiraWellness/AmiraWellness/Services/Network/NetworkMonitor.swift
import OfflineSyncService // src/ios/AmiraWellness/AmiraWellness/Services/Offline/OfflineSyncService.swift
import NotificationManager // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/NotificationManager.swift
import UserDefaultsManager // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/UserDefaultsManager.swift
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift
import AppConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/AppConstants.swift
import User // src/ios/AmiraWellness/AmiraWellness/Models/User.swift

/// Defines the possible states of the application
enum AppState {
    case initializing
    case onboarding
    case authenticated
    case unauthenticated
}

/// Defines the possible network connectivity states
enum NetworkState {
    case connected
    case disconnected
}

/// Defines the possible synchronization states
enum SyncState {
    case idle
    case syncing
    case completed
    case failed
}

/// Defines notification names for app state changes
enum AppStateNotification {
    static let stateChanged = Notification.Name("AppStateChanged")
}

/// A singleton manager class that coordinates the overall application state
@objc final class AppStateManager: NSObject, UNUserNotificationCenterDelegate {
    
    /// Shared instance of the AppStateManager
    static let shared = AppStateManager()
    
    // MARK: - Private Properties
    
    private let authService: AuthService
    private let networkMonitor: NetworkMonitor
    private let offlineSyncService: OfflineSyncService
    private let notificationManager: NotificationManager
    private let userDefaultsManager: UserDefaultsManager
    private let logger: Logger
    
    private var appState: AppState = .initializing
    private var networkState: NetworkState = .disconnected
    private var syncState: SyncState = .idle
    private var currentUser: User?
    
    private let appStateSubject = CurrentValueSubject<AppState, Never>(.initializing)
    private let networkStateSubject = CurrentValueSubject<NetworkState, Never>(.disconnected)
    private let syncStateSubject = CurrentValueSubject<SyncState, Never>(.idle)
    
    private var cancellables = Set<AnyCancellable>()
    
    private var hasCompletedOnboarding: Bool {
        get {
            return userDefaultsManager.getBool(forKey: AppConstants.UserDefaults.hasCompletedOnboarding)
        }
        set {
            userDefaultsManager.setBool(newValue, forKey: AppConstants.UserDefaults.hasCompletedOnboarding)
        }
    }
    
    private var isFirstLaunch: Bool {
        get {
            // Check if the appOpenCount is 0, indicating it's the first launch
            return userDefaultsManager.getInt(forKey: AppConstants.UserDefaults.appOpenCount, defaultValue: 0) == 0
        }
    }
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private override init() {
        // Initialize internal dependencies
        authService = AuthService.shared
        networkMonitor = NetworkMonitor.shared
        offlineSyncService = OfflineSyncService.shared
        notificationManager = NotificationManager.shared
        userDefaultsManager = UserDefaultsManager.shared
        logger = Logger.shared
        
        // Set initial states
        appState = .initializing
        networkState = .disconnected
        syncState = .idle
        currentUser = nil
        
        // Initialize subjects
        appStateSubject = CurrentValueSubject<AppState, Never>(appState)
        networkStateSubject = CurrentValueSubject<NetworkState, Never>(networkState)
        syncStateSubject = CurrentValueSubject<SyncState, Never>(syncState)
        
        // Initialize cancellables
        cancellables = Set<AnyCancellable>()
        
        super.init()
        
        // Set up notification delegate
        setupNotifications()
        
        // Check if user has completed onboarding
        hasCompletedOnboarding = userDefaultsManager.getBool(forKey: AppConstants.UserDefaults.hasCompletedOnboarding)
        
        // Check if this is the first launch of the app
        if isFirstLaunch {
            // Perform first launch setup
            logger.info("First launch detected, performing initial setup", category: .general)
            userDefaultsManager.setInt(1, forKey: AppConstants.UserDefaults.appOpenCount)
        } else {
            // Increment app open count
            let currentCount = userDefaultsManager.getInt(forKey: AppConstants.UserDefaults.appOpenCount, defaultValue: 0)
            userDefaultsManager.setInt(currentCount + 1, forKey: AppConstants.UserDefaults.appOpenCount)
        }
        
        // Set up Combine subscriptions
        setupSubscriptions()
        
        // Restore authentication session
        authService.restoreSession()
        
        // Determine initial app state
        determineInitialAppState()
        
        logger.info("AppStateManager initialized", category: .general)
    }
    
    // MARK: - Public Methods
    
    /// Initializes the application state manager and starts monitoring services
    func initialize() {
        // Start network monitoring
        networkMonitor.startMonitoring()
        
        // Configure offline sync
        offlineSyncService.setAutoSync(enabled: true)
        
        // Request notification authorization if needed
        notificationManager.requestAuthorization { granted, error in
            if let error = error {
                self.logger.error("Failed to request notification authorization: \(error)", category: .general)
            } else if granted {
                self.logger.info("Notification authorization granted", category: .general)
            } else {
                self.logger.info("Notification authorization denied", category: .general)
            }
        }
        
        // Restore authentication session
        authService.restoreSession()
        
        // Update application state
        determineInitialAppState()
        
        logger.info("AppStateManager initialization complete", category: .general)
    }
    
    /// Returns a publisher that emits app state changes
    func appStatePublisher() -> AnyPublisher<AppState, Never> {
        return appStateSubject.eraseToAnyPublisher()
    }
    
    /// Returns a publisher that emits network state changes
    func networkStatePublisher() -> AnyPublisher<NetworkState, Never> {
        return networkStateSubject.eraseToAnyPublisher()
    }
    
    /// Returns a publisher that emits sync state changes
    func syncStatePublisher() -> AnyPublisher<SyncState, Never> {
        return syncStateSubject.eraseToAnyPublisher()
    }
    
    /// Returns the current application state
    func getCurrentAppState() -> AppState {
        return appState
    }
    
    /// Returns the current network state
    func getCurrentNetworkState() -> NetworkState {
        return networkState
    }
    
    /// Returns the current sync state
    func getCurrentSyncState() -> SyncState {
        return syncState
    }
    
    /// Returns the current authenticated user
    func getCurrentUser() -> User? {
        return currentUser
    }
    
    /// Returns whether the device is currently connected to the network
    func isNetworkConnected() -> Bool {
        return networkMonitor.isConnected()
    }
    
    /// Returns whether there are pending sync operations
    func hasPendingSyncOperations() -> Bool {
        return offlineSyncService.getPendingOperationsCount() > 0
    }
    
    /// Marks onboarding as completed and updates app state
    func completeOnboarding() {
        hasCompletedOnboarding = true
        userDefaultsManager.setBool(true, forKey: AppConstants.UserDefaults.hasCompletedOnboarding)
        updateAppState(newState: authService.isAuthenticated() ? .authenticated : .unauthenticated)
        logger.info("Onboarding completed", category: .general)
    }
    
    /// Resets onboarding status for testing purposes
    func resetOnboarding() {
        hasCompletedOnboarding = false
        userDefaultsManager.setBool(false, forKey: AppConstants.UserDefaults.hasCompletedOnboarding)
        updateAppState(newState: .onboarding)
        logger.info("Onboarding reset", category: .general)
    }
    
    /// Manually triggers data synchronization
    func triggerSync() {
        if networkMonitor.isConnected() {
            offlineSyncService.sync()
            logger.info("Manual sync triggered", category: .sync)
        } else {
            logger.warning("Manual sync requested but device is offline", category: .sync)
        }
    }
    
    /// Handles application becoming active
    func handleAppDidBecomeActive() {
        // Refresh authentication status
        authService.restoreSession()
        
        // Trigger sync if needed
        if networkMonitor.isConnected() && offlineSyncService.getPendingOperationsCount() > 0 {
            offlineSyncService.sync()
        }
        
        logger.info("Application did become active", category: .general)
    }
    
    /// Handles application resigning active state
    func handleAppWillResignActive() {
        // Perform any cleanup or state saving needed
        
        logger.info("Application will resign active", category: .general)
    }
    
    /// Handles application entering background
    func handleAppDidEnterBackground() {
        // Save any pending state changes
        
        logger.info("Application did enter background", category: .general)
    }
    
    /// Handles application entering foreground
    func handleAppWillEnterForeground() {
        // Refresh authentication status
        authService.restoreSession()
        
        // Check network status
        if networkMonitor.isConnected() {
            // Trigger sync if needed
            if offlineSyncService.getPendingOperationsCount() > 0 {
                offlineSyncService.sync()
            }
        }
        
        logger.info("Application will enter foreground", category: .general)
    }
    
    // MARK: - UNUserNotificationCenterDelegate Methods
    
    /// Handles notification response from user
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        notificationManager.handleNotificationResponse(response: response, completionHandler: completionHandler)
    }
    
    /// Handles notification presentation while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        notificationManager.handleWillPresentNotification(notification: notification, completionHandler: completionHandler)
    }
    
    // MARK: - Private Methods
    
    /// Updates the application state and notifies observers
    private func updateAppState(newState: AppState) {
        guard appState != newState else { return }
        
        appState = newState
        appStateSubject.send(newState)
        
        NotificationCenter.default.post(name: AppStateNotification.stateChanged, object: nil)
        logger.debug("App state updated to \(newState)", category: .general)
    }
    
    /// Updates the network state and notifies observers
    private func updateNetworkState(newState: NetworkState) {
        guard networkState != newState else { return }
        
        networkState = newState
        networkStateSubject.send(newState)
        
        logger.debug("Network state updated to \(newState)", category: .general)
    }
    
    /// Updates the sync state and notifies observers
    private func updateSyncState(newState: SyncState) {
        guard syncState != newState else { return }
        
        syncState = newState
        syncStateSubject.send(newState)
        
        logger.debug("Sync state updated to \(newState)", category: .sync)
    }
    
    /// Handles changes in authentication state
    private func handleAuthStateChange(authState: AuthService.AuthState) {
        switch authState {
        case .authenticated(let user):
            currentUser = user
            updateAppState(newState: .authenticated)
            logger.info("User authenticated: \(user.email)", category: .authentication)
            
        case .unauthenticated:
            currentUser = nil
            updateAppState(newState: .unauthenticated)
            logger.info("User unauthenticated", category: .authentication)
            
        case .loading:
            // Do nothing, handled by the loading state itself
            break
        }
    }
    
    /// Handles changes in network connectivity status
    private func handleNetworkStatusChange(status: NetworkStatus) {
        let newState: NetworkState = status == .connected ? .connected : .disconnected
        updateNetworkState(newState: newState)
        
        if newState == .connected && offlineSyncService.getPendingOperationsCount() > 0 {
            offlineSyncService.sync()
        }
        
        logger.info("Network status changed to \(status)", category: .general)
    }
    
    /// Handles changes in synchronization status
    private func handleSyncStatusChange(status: OfflineSyncService.SyncStatus) {
        let newState: SyncState
        
        switch status {
        case .idle:
            newState = .idle
        case .inProgress:
            newState = .syncing
        case .completed:
            newState = .completed
        case .failed:
            newState = .failed
        }
        
        updateSyncState(newState: newState)
        logger.info("Sync status changed to \(status)", category: .sync)
    }
    
    /// Sets up notification handling
    private func setupNotifications() {
        notificationManager.setNotificationDelegate(delegate: self)
        
        notificationManager.requestAuthorization { granted, error in
            if let error = error {
                self.logger.error("Failed to request notification authorization: \(error)", category: .general)
            } else if granted {
                self.logger.info("Notification authorization granted", category: .general)
            } else {
                self.logger.info("Notification authorization denied", category: .general)
            }
        }
        
        logger.info("Notification setup complete", category: .general)
    }
    
    /// Determines the initial application state
    private func determineInitialAppState() {
        if hasCompletedOnboarding {
            if authService.isAuthenticated() {
                updateAppState(newState: .authenticated)
            } else {
                updateAppState(newState: .unauthenticated)
            }
        } else {
            updateAppState(newState: .onboarding)
        }
        
        logger.info("Initial app state determined: \(appState)", category: .general)
    }
    
    /// Sets up Combine subscriptions for state changes
    private func setupSubscriptions() {
        authService.authStatePublisher()
            .sink { [weak self] authState in
                self?.handleAuthStateChange(authState: authState)
            }
            .store(in: &cancellables)
        
        networkMonitor.statusPublisher
            .sink { [weak self] status in
                self?.handleNetworkStatusChange(status: status)
            }
            .store(in: &cancellables)
        
        offlineSyncService.statusPublisher
            .sink { [weak self] status in
                self?.handleSyncStatusChange(status: status)
            }
            .store(in: &cancellables)
        
        logger.info("Combine subscriptions setup complete", category: .general)
    }
}