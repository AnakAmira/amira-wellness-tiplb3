# src/ios/AmiraWellness/AmiraWellness/Managers/AnalyticsManager.swift
import Foundation // Latest
import Combine // Latest

// Internal imports
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift
import AppConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/AppConstants.swift
import User // src/ios/AmiraWellness/AmiraWellness/Models/User.swift
import APIClient // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIClient.swift

/// Defines the types of events that can be tracked in the analytics system
enum AnalyticsEventType: String {
    case appOpen
    case appClose
    case screenView
    case featureUse
    case journalRecorded
    case emotionalCheckIn
    case toolUsed
    case achievementEarned
    case streakUpdated
    case errorOccurred
    case userSignUp
    case userLogin
    case userLogout
    case subscriptionChanged
    case settingsChanged
}

/// Defines user properties that can be tracked for analytics segmentation
enum AnalyticsUserProperty: String {
    case subscriptionTier
    case language
    case appVersion
    case osVersion
    case deviceModel
    case hasCompletedOnboarding
    case daysActive
    case streakCount
    case journalCount
    case emotionalCheckInCount
    case toolUsageCount
}

/// A singleton manager that handles analytics tracking with privacy considerations
final class AnalyticsManager {
    /// Shared instance of AnalyticsManager
    static let shared = AnalyticsManager()

    // MARK: - Private Properties

    private var isEnabled: Bool
    private var userId: String?
    private var sessionId: UUID?
    private var sessionStartTime: Date?
    private var userProperties: [String: Any] = [:]
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Initialization

    /// Private initializer for singleton pattern
    private init() {
        // Initialize isEnabled based on user preferences and feature flags
        self.isEnabled = AppConstants.FeatureFlags.defaultFeatureStates[AppConstants.FeatureFlags.advancedAnalytics] ?? false

        // Generate a unique session ID
        self.sessionId = UUID()

        // Set session start time to current date
        self.sessionStartTime = Date()

        // Initialize empty user properties dictionary
        self.userProperties = [:]

        // Initialize empty cancellables set
        self.cancellables = []

        // Set up app lifecycle observation for session tracking
        setupLifecycleObservation()
    }

    // MARK: - Public Methods

    /// Configures the analytics manager with user information
    /// - Parameter user: The user object containing user information
    func configure(user: User?) {
        // Set userId to user.id if user is provided, otherwise use anonymous ID
        self.userId = user?.id.uuidString ?? "anonymous"

        // Update user properties with basic information
        updateUserProperties(user: user)

        // Log configuration event
        Logger.shared.info("Analytics manager configured for user: \(self.userId ?? "unknown")", category: .general)
    }

    /// Enables or disables analytics tracking
    /// - Parameter enabled: A boolean indicating whether analytics tracking should be enabled
    func setEnabled(enabled: Bool) {
        // Set isEnabled to the provided value
        self.isEnabled = enabled

        // If disabled, clear any cached analytics data
        if !enabled {
            // Clear any cached analytics data
            Logger.shared.info("Analytics tracking disabled, clearing cached data", category: .general)
            // TODO: Implement clearing cached data if applicable
        }

        // Log the change in analytics state
        Logger.shared.info("Analytics tracking \(enabled ? "enabled" : "disabled")", category: .general)
    }

    /// Tracks an analytics event with optional parameters
    /// - Parameters:
    ///   - eventType: The type of analytics event to track
    ///   - parameters: Optional dictionary of parameters to include with the event
    func trackEvent(eventType: AnalyticsEventType, parameters: [String: Any]? = nil) {
        // Check if analytics is enabled
        guard isEnabled else {
            Logger.shared.debug("Analytics is disabled, skipping event: \(eventType)", category: .general)
            return
        }

        // Sanitize parameters to remove any sensitive information
        let sanitizedParameters = sanitizeParameters(parameters: parameters)

        // Create event dictionary with event type, timestamp, session ID, and parameters
        var event: [String: Any] = [
            "event_type": eventType.rawValue,
            "timestamp": Date().timeIntervalSince1970,
            "session_id": sessionId?.uuidString ?? "unknown",
            "user_id": userId ?? "anonymous"
        ]

        // Add additional parameters if provided
        if let sanitizedParameters = sanitizedParameters {
            event["parameters"] = sanitizedParameters
        }

        // Log the event locally
        Logger.shared.info("Tracking event: \(eventType), parameters: \(sanitizedParameters ?? [:])", category: .general)

        // Queue event for batch sending if appropriate
        queueEvent(event: event)

        // Send event to backend if immediate sending is required
        // TODO: Implement immediate sending logic if needed
    }

    /// Tracks when a user views a screen
    /// - Parameters:
    ///   - screenName: The name of the screen being viewed
    ///   - parameters: Optional dictionary of parameters to include with the event
    func trackScreenView(screenName: String, parameters: [String: Any]? = nil) {
        // Create parameters dictionary with screen name
        var params: [String: Any] = ["screen_name": screenName]

        // Add additional parameters if provided
        if let parameters = parameters {
            params.merge(parameters) { (_, new) in new }
        }

        // Call trackEvent with .screenView event type and parameters
        trackEvent(eventType: .screenView, parameters: params)
    }

    /// Tracks when a user uses a specific feature
    /// - Parameters:
    ///   - featureName: The name of the feature being used
    ///   - parameters: Optional dictionary of parameters to include with the event
    func trackFeatureUse(featureName: String, parameters: [String: Any]? = nil) {
        // Create parameters dictionary with feature name
        var params: [String: Any] = ["feature_name": featureName]

        // Add additional parameters if provided
        if let parameters = parameters {
            params.merge(parameters) { (_, new) in new }
        }

        // Call trackEvent with .featureUse event type and parameters
        trackEvent(eventType: .featureUse, parameters: params)
    }

    /// Tracks when a user records a voice journal
    /// - Parameters:
    ///   - duration: The duration of the recording in seconds
    ///   - hasEmotionalShift: A boolean indicating whether the user experienced an emotional shift
    ///   - additionalParameters: Optional dictionary of parameters to include with the event
    func trackJournalRecorded(duration: TimeInterval, hasEmotionalShift: Bool, additionalParameters: [String: Any]? = nil) {
        // Create parameters dictionary with duration and emotional shift flag
        var params: [String: Any] = [
            "duration": duration,
            "has_emotional_shift": hasEmotionalShift
        ]

        // Add additional parameters if provided
        if let additionalParameters = additionalParameters {
            params.merge(additionalParameters) { (_, new) in new }
        }

        // Call trackEvent with .journalRecorded event type and parameters
        trackEvent(eventType: .journalRecorded, parameters: params)
    }

    /// Tracks when a user completes an emotional check-in
    /// - Parameters:
    ///   - emotionType: The type of emotion selected
    ///   - intensity: The intensity of the emotion
    ///   - context: The context in which the check-in was performed
    ///   - additionalParameters: Optional dictionary of parameters to include with the event
    func trackEmotionalCheckIn(emotionType: String, intensity: Int, context: String? = nil, additionalParameters: [String: Any]? = nil) {
        // Create parameters dictionary with emotion type, intensity, and context
        var params: [String: Any] = [
            "emotion_type": emotionType,
            "intensity": intensity
        ]
        if let context = context {
            params["context"] = context
        }

        // Add additional parameters if provided
        if let additionalParameters = additionalParameters {
            params.merge(additionalParameters) { (_, new) in new }
        }

        // Call trackEvent with .emotionalCheckIn event type and parameters
        trackEvent(eventType: .emotionalCheckIn, parameters: params)
    }

    /// Tracks when a user uses a tool from the library
    /// - Parameters:
    ///   - toolId: The ID of the tool used
    ///   - toolName: The name of the tool used
    ///   - category: The category of the tool used
    ///   - duration: The duration of the tool usage in seconds
    ///   - completed: A boolean indicating whether the user completed the tool usage
    ///   - additionalParameters: Optional dictionary of parameters to include with the event
    func trackToolUsed(toolId: String, toolName: String, category: String, duration: TimeInterval, completed: Bool, additionalParameters: [String: Any]? = nil) {
        // Create parameters dictionary with tool ID, name, category, duration, and completion status
        var params: [String: Any] = [
            "tool_id": toolId,
            "tool_name": toolName,
            "category": category,
            "duration": duration,
            "completed": completed
        ]

        // Add additional parameters if provided
        if let additionalParameters = additionalParameters {
            params.merge(additionalParameters) { (_, new) in new }
        }

        // Call trackEvent with .toolUsed event type and parameters
        trackEvent(eventType: .toolUsed, parameters: params)
    }

    /// Tracks when a user earns an achievement
    /// - Parameters:
    ///   - achievementId: The ID of the achievement earned
    ///   - achievementName: The name of the achievement earned
    ///   - additionalParameters: Optional dictionary of parameters to include with the event
    func trackAchievementEarned(achievementId: String, achievementName: String, additionalParameters: [String: Any]? = nil) {
        // Create parameters dictionary with achievement ID and name
        var params: [String: Any] = [
            "achievement_id": achievementId,
            "achievement_name": achievementName
        ]

        // Add additional parameters if provided
        if let additionalParameters = additionalParameters {
            params.merge(additionalParameters) { (_, new) in new }
        }

        // Call trackEvent with .achievementEarned event type and parameters
        trackEvent(eventType: .achievementEarned, parameters: params)
    }

    /// Tracks when a user's streak is updated
    /// - Parameters:
    ///   - streakCount: The current streak count
    ///   - isNewRecord: A boolean indicating whether the streak is a new record
    ///   - additionalParameters: Optional dictionary of parameters to include with the event
    func trackStreakUpdated(streakCount: Int, isNewRecord: Bool, additionalParameters: [String: Any]? = nil) {
        // Create parameters dictionary with streak count and new record flag
        var params: [String: Any] = [
            "streak_count": streakCount,
            "is_new_record": isNewRecord
        ]

        // Add additional parameters if provided
        if let additionalParameters = additionalParameters {
            params.merge(additionalParameters) { (_, new) in new }
        }

        // Call trackEvent with .streakUpdated event type and parameters
        trackEvent(eventType: .streakUpdated, parameters: params)
    }

    /// Tracks when an error occurs in the application
    /// - Parameters:
    ///   - errorDomain: The domain of the error
    ///   - errorCode: The code of the error
    ///   - errorDescription: An optional description of the error
    ///   - additionalParameters: Optional dictionary of parameters to include with the event
    func trackError(errorDomain: String, errorCode: Int, errorDescription: String? = nil, additionalParameters: [String: Any]? = nil) {
        // Create parameters dictionary with error domain, code, and description
        var params: [String: Any] = [
            "error_domain": errorDomain,
            "error_code": errorCode
        ]

        // Ensure no sensitive information is included in error details
        if let errorDescription = errorDescription {
            params["error_description"] = errorDescription
        }

        // Add additional parameters if provided
        if let additionalParameters = additionalParameters {
            params.merge(additionalParameters) { (_, new) in new }
        }

        // Call trackEvent with .errorOccurred event type and parameters
        trackEvent(eventType: .errorOccurred, parameters: params)
    }

    /// Sets a user property for analytics segmentation
    /// - Parameters:
    ///   - property: The AnalyticsUserProperty to set
    ///   - value: The value to set for the property
    func setUserProperty(property: AnalyticsUserProperty, value: Any) {
        // Check if analytics is enabled
        guard isEnabled else {
            Logger.shared.debug("Analytics is disabled, skipping user property: \(property)", category: .general)
            return
        }

        // Update userProperties dictionary with the property and value
        userProperties[property.rawValue] = value

        // Log the property update
        Logger.shared.info("Set user property: \(property) to value: \(value)", category: .general)
    }

    /// Sends queued analytics events to the backend
    func flushEvents() {
        // Check if there are events to flush
        guard let eventsData = UserDefaults.standard.data(forKey: "analytics_events"),
              let events = try? JSONSerialization.jsonObject(with: eventsData, options: []) as? [[String: Any]],
              !events.isEmpty else {
            Logger.shared.debug("No analytics events to flush", category: .general)
            return
        }

        // Prepare batch of events for sending
        Logger.shared.info("Flushing \(events.count) analytics events to backend", category: .general)

        // Send events to backend using APIClient
        // TODO: Implement APIClient call to send events
        APIClient.shared.requestEmpty(endpoint: .healthCheck) { result in
            switch result {
            case .success:
                // On success, clear sent events from queue
                UserDefaults.standard.removeObject(forKey: "analytics_events")
                Logger.shared.info("Successfully flushed analytics events", category: .general)
            case .failure(let error):
                // On failure, keep events in queue for retry
                Logger.shared.error("Failed to flush analytics events: \(error)", category: .general)
            }
        }

        // Log the flush operation result
        // TODO: Implement logging of flush operation result
    }

    // MARK: - Private Methods

    /// Starts a new analytics session
    private func startSession() {
        // Generate a new session ID
        sessionId = UUID()

        // Set session start time to current date
        sessionStartTime = Date()

        // Track app open event with session information
        trackEvent(eventType: .appOpen, parameters: [
            "session_id": sessionId?.uuidString ?? "unknown",
            "start_time": sessionStartTime?.timeIntervalSince1970 ?? 0
        ])

        // Log session start
        Logger.shared.info("New analytics session started with ID: \(sessionId?.uuidString ?? "unknown")", category: .general)
    }

    /// Ends the current analytics session
    private func endSession() {
        // Calculate session duration
        guard let startTime = sessionStartTime else {
            Logger.shared.warning("No session start time found, cannot calculate duration", category: .general)
            return
        }
        let duration = Date().timeIntervalSince(startTime)

        // Track app close event with session duration
        trackEvent(eventType: .appClose, parameters: ["session_duration": duration])

        // Flush any pending analytics events
        flushEvents()

        // Log session end
        Logger.shared.info("Analytics session ended after \(duration) seconds", category: .general)
    }

    /// Sets up observation of app lifecycle events for session tracking
    private func setupLifecycleObservation() {
        // Subscribe to NotificationCenter for UIApplication.didBecomeActiveNotification
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                // When app becomes active, call startSession
                self?.startSession()
            }
            .store(in: &cancellables)

        // Subscribe to NotificationCenter for UIApplication.willResignActiveNotification
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                // When app resigns active, call endSession
                self?.endSession()
            }
            .store(in: &cancellables)
    }

    /// Removes or anonymizes sensitive information from analytics parameters
    /// - Parameter parameters: The original parameters dictionary
    /// - Returns: A sanitized parameters dictionary
    private func sanitizeParameters(parameters: [String: Any]?) -> [String: Any] {
        // If parameters is nil, return empty dictionary
        guard var parameters = parameters else {
            return [:]
        }

        // Create a copy of the parameters dictionary
        var sanitized = parameters

        // Remove any known sensitive keys (emails, personal identifiers, etc.)
        let sensitiveKeys = ["email", "password", "credit_card", "ssn"]
        for key in sensitiveKeys {
            sanitized.removeValue(forKey: key)
        }

        // Anonymize any potentially sensitive values
        // TODO: Implement anonymization logic for specific data types

        // Return the sanitized dictionary
        return sanitized
    }

    /// Queues an analytics event for batch sending
    /// - Parameter event: The analytics event to queue
    private func queueEvent(event: [String: Any]) {
        // Add event to queue in UserDefaults
        var events: [[String: Any]] = (UserDefaults.standard.array(forKey: "analytics_events") as? [[String: Any]]) ?? []
        events.append(event)
        UserDefaults.standard.set(events, forKey: "analytics_events")

        // Check if queue size exceeds threshold
        if events.count >= 10 {
            // If threshold exceeded, flush events
            flushEvents()
        }
    }

    /// Gathers device information for analytics context
    /// - Returns: Dictionary of device information
    private func getDeviceInfo() -> [String: String] {
        // Get device model information
        let deviceModel = UIDevice.current.model

        // Get OS version information
        let osVersion = UIDevice.current.systemVersion

        // Get app version and build number
        let appVersion = AppConstants.App.version
        let appBuild = AppConstants.App.build

        // Return dictionary with device information
        return [
            "device_model": deviceModel,
            "os_version": osVersion,
            "app_version": appVersion,
            "app_build": appBuild
        ]
    }

    /// Updates user properties with basic information
    /// - Parameter user: The user object containing user information
    private func updateUserProperties(user: User?) {
        // Set subscription tier
        setUserProperty(property: .subscriptionTier, value: user?.subscriptionTier.rawValue ?? "free")

        // Set language preference
        setUserProperty(property: .language, value: user?.languagePreference ?? "es")

        // Set app version
        setUserProperty(property: .appVersion, value: AppConstants.App.version)

        // Set OS version
        setUserProperty(property: .osVersion, value: UIDevice.current.systemVersion)

        // Set device model
        setUserProperty(property: .deviceModel, value: UIDevice.current.model)

        // Set has completed onboarding
        setUserProperty(property: .hasCompletedOnboarding, value: UserDefaults.standard.bool(forKey: AppConstants.UserDefaults.hasCompletedOnboarding))

        // TODO: Add other user properties as needed
    }
}