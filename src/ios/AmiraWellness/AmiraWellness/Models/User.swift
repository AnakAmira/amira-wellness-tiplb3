import Foundation // Foundation - Latest - Access to core Foundation types and Codable protocol

/// Represents the status of a user account in the Amira Wellness application
enum AccountStatus: String, Codable, Equatable {
    case active
    case disabled
    case pendingVerification
    case deleted
}

/// Represents the subscription tier of a user in the Amira Wellness application
enum SubscriptionTier: String, Codable, Equatable {
    case free
    case premium
}

/// Model representing a user in the Amira Wellness application
struct User: Codable, Identifiable, Equatable {
    // MARK: - Properties
    
    /// Unique identifier for the user
    let id: UUID
    
    /// User's email address, used for authentication and notifications
    let email: String
    
    /// User's name (optional)
    var name: String?
    
    /// Date when the user account was created
    let createdAt: Date
    
    /// Date when the user account was last updated
    var updatedAt: Date?
    
    /// Whether the user's email has been verified
    var emailVerified: Bool
    
    /// Current status of the user account
    var accountStatus: AccountStatus
    
    /// User's subscription tier
    var subscriptionTier: SubscriptionTier
    
    /// User's preferred language (defaults to Spanish)
    var languagePreference: String
    
    /// Date of the user's last login
    var lastLoginDate: Date?
    
    /// Dictionary containing user-specific preferences
    var preferences: [String: Any]?
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case id, email, name, createdAt, updatedAt, emailVerified, accountStatus, subscriptionTier, languagePreference, lastLoginDate
        // Note: preferences is intentionally excluded from Codable due to [String: Any] not conforming to Codable
    }
    
    // MARK: - Initializer
    
    /// Initializes a User with the provided parameters
    init(
        id: UUID,
        email: String,
        name: String? = nil,
        createdAt: Date,
        updatedAt: Date? = nil,
        emailVerified: Bool = false,
        accountStatus: AccountStatus = .pendingVerification,
        subscriptionTier: SubscriptionTier = .free,
        languagePreference: String = "es",
        lastLoginDate: Date? = nil,
        preferences: [String: Any]? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.emailVerified = emailVerified
        self.accountStatus = accountStatus
        self.subscriptionTier = subscriptionTier
        self.languagePreference = languagePreference
        self.lastLoginDate = lastLoginDate
        self.preferences = preferences
    }
    
    // MARK: - Methods
    
    /// Determines if the user account is active
    func isActive() -> Bool {
        return accountStatus == .active
    }
    
    /// Determines if the user has a premium subscription
    func isPremium() -> Bool {
        return subscriptionTier == .premium
    }
    
    /// Returns a formatted string representation of when the user joined
    func formattedJoinDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
    
    /// Retrieves a user preference value by key
    func getPreference(key: String) -> Any? {
        return preferences?[key]
    }
    
    /// Creates a new user with updated preferences
    func withUpdatedPreferences(newPreferences: [String: Any]) -> User {
        var updatedUser = self
        
        if updatedUser.preferences == nil {
            updatedUser.preferences = [:]
        }
        
        for (key, value) in newPreferences {
            updatedUser.preferences?[key] = value
        }
        
        updatedUser.updatedAt = Date()
        return updatedUser
    }
    
    /// Creates a new user with updated name
    func withUpdatedName(newName: String) -> User {
        var updatedUser = self
        updatedUser.name = newName
        updatedUser.updatedAt = Date()
        return updatedUser
    }
    
    /// Creates a new user with updated language preference
    func withUpdatedLanguagePreference(newLanguage: String) -> User {
        var updatedUser = self
        updatedUser.languagePreference = newLanguage
        updatedUser.updatedAt = Date()
        return updatedUser
    }
    
    /// Creates a new user with updated subscription tier
    func withUpdatedSubscriptionTier(newTier: SubscriptionTier) -> User {
        var updatedUser = self
        updatedUser.subscriptionTier = newTier
        updatedUser.updatedAt = Date()
        return updatedUser
    }
}

/// Constants for user preference keys
struct UserPreferences {
    static let notificationsEnabled = "notificationsEnabled"
    static let dailyReminderTime = "dailyReminderTime"
    static let reminderDays = "reminderDays"
    static let themeMode = "themeMode"
    static let biometricAuthEnabled = "biometricAuthEnabled"
}