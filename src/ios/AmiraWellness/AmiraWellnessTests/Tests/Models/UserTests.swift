import XCTest // Latest - Access to Apple's XCTest framework for unit testing
@testable import AmiraWellness

class UserTests: XCTestCase {
    
    func testUserInitialization() {
        // Create a test UUID
        let userId = UUID()
        
        // Create test dates for createdAt and updatedAt
        let createdAt = TestData.createTestDate(daysOffset: -30) // 30 days ago
        let updatedAt = TestData.createTestDate(daysOffset: -5) // 5 days ago
        
        // Initialize a User with all properties
        let user = User(
            id: userId,
            email: "test@example.com",
            name: "Test User",
            createdAt: createdAt,
            updatedAt: updatedAt,
            emailVerified: true,
            accountStatus: .active,
            subscriptionTier: .premium,
            languagePreference: "es",
            lastLoginDate: TestData.createTestDate(daysOffset: -1),
            preferences: ["notificationsEnabled": true, "dailyReminderTime": "09:00"]
        )
        
        // Assert that all properties match the provided values
        XCTAssertEqual(user.id, userId)
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.name, "Test User")
        XCTAssertEqual(user.createdAt, createdAt)
        XCTAssertEqual(user.updatedAt, updatedAt)
        XCTAssertTrue(user.emailVerified)
        XCTAssertEqual(user.accountStatus, .active)
        XCTAssertEqual(user.subscriptionTier, .premium)
        XCTAssertEqual(user.languagePreference, "es")
        XCTAssertNotNil(user.lastLoginDate)
        XCTAssertNotNil(user.preferences)
        XCTAssertEqual(user.preferences?["notificationsEnabled"] as? Bool, true)
        XCTAssertEqual(user.preferences?["dailyReminderTime"] as? String, "09:00")
    }
    
    func testUserEquality() {
        // Create two identical User instances
        let userId = UUID()
        let createdAt = Date()
        
        let user1 = User(
            id: userId,
            email: "test@example.com",
            name: "Test User",
            createdAt: createdAt
        )
        
        let user2 = User(
            id: userId,
            email: "test@example.com",
            name: "Test User",
            createdAt: createdAt
        )
        
        // Assert that they are equal
        XCTAssertEqual(user1, user2)
        
        // Create a User with a different ID
        let user3 = User(
            id: UUID(),
            email: "test@example.com",
            name: "Test User",
            createdAt: createdAt
        )
        
        // Assert that it is not equal to the original User
        XCTAssertNotEqual(user1, user3)
    }
    
    func testUserCodable() {
        // Create a test User
        let testUser = TestData.mockUser()
        
        do {
            // Encode the User to JSON data
            let encoder = JSONEncoder()
            let userData = try encoder.encode(testUser)
            
            // Decode the JSON data back to a User
            let decoder = JSONDecoder()
            let decodedUser = try decoder.decode(User.self, from: userData)
            
            // Assert that the decoded User equals the original User
            XCTAssertEqual(decodedUser, testUser)
            
            // Note: The preferences property will not be compared in equality
            // because it's excluded from Codable due to [String: Any] not conforming to Codable
        } catch {
            XCTFail("Failed to encode or decode User: \(error)")
        }
    }
    
    func testIsActiveMethod() {
        // Create a User with AccountStatus.active
        let activeUser = User(
            id: UUID(),
            email: "active@example.com",
            createdAt: Date(),
            accountStatus: .active
        )
        
        // Assert that isActive() returns true
        XCTAssertTrue(activeUser.isActive())
        
        // Create a User with AccountStatus.disabled
        let disabledUser = User(
            id: UUID(),
            email: "disabled@example.com",
            createdAt: Date(),
            accountStatus: .disabled
        )
        
        // Assert that isActive() returns false
        XCTAssertFalse(disabledUser.isActive())
        
        // Create a User with AccountStatus.pendingVerification
        let pendingUser = User(
            id: UUID(),
            email: "pending@example.com",
            createdAt: Date(),
            accountStatus: .pendingVerification
        )
        
        // Assert that isActive() returns false
        XCTAssertFalse(pendingUser.isActive())
        
        // Create a User with AccountStatus.deleted
        let deletedUser = User(
            id: UUID(),
            email: "deleted@example.com",
            createdAt: Date(),
            accountStatus: .deleted
        )
        
        // Assert that isActive() returns false
        XCTAssertFalse(deletedUser.isActive())
    }
    
    func testIsPremiumMethod() {
        // Create a User with SubscriptionTier.free
        let freeUser = User(
            id: UUID(),
            email: "free@example.com",
            createdAt: Date(),
            subscriptionTier: .free
        )
        
        // Assert that isPremium() returns false
        XCTAssertFalse(freeUser.isPremium())
        
        // Create a User with SubscriptionTier.premium
        let premiumUser = User(
            id: UUID(),
            email: "premium@example.com",
            createdAt: Date(),
            subscriptionTier: .premium
        )
        
        // Assert that isPremium() returns true
        XCTAssertTrue(premiumUser.isPremium())
    }
    
    func testFormattedJoinDate() {
        // Create a User with a known creation date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let creationDate = dateFormatter.date(from: "2023-01-15")!
        
        let user = User(
            id: UUID(),
            email: "test@example.com",
            createdAt: creationDate
        )
        
        // Get the formattedJoinDate string
        let formattedDate = user.formattedJoinDate()
        
        // Assert that the string format matches the expected pattern
        // The exact format will depend on the locale, but we can check if it contains the year
        XCTAssertTrue(formattedDate.contains("2023"), "Formatted date should contain the year")
        XCTAssertTrue(formattedDate.count > 5, "Formatted date should be a reasonable length")
    }
    
    func testGetPreference() {
        // Create a User with test preferences
        let preferences: [String: Any] = [
            "notificationsEnabled": true,
            "dailyReminderTime": "09:00",
            "themeMode": "dark"
        ]
        
        let user = User(
            id: UUID(),
            email: "test@example.com",
            createdAt: Date(),
            preferences: preferences
        )
        
        // Retrieve a preference value using getPreference()
        let notificationsEnabled = user.getPreference(key: "notificationsEnabled") as? Bool
        
        // Assert that the retrieved value matches the expected value
        XCTAssertEqual(notificationsEnabled, true)
        
        // Try to retrieve a non-existent preference
        let nonExistentPreference = user.getPreference(key: "nonExistentKey")
        
        // Assert that nil is returned
        XCTAssertNil(nonExistentPreference)
    }
    
    func testWithUpdatedPreferences() {
        // Create a User with initial preferences
        let initialPreferences: [String: Any] = [
            "notificationsEnabled": true,
            "dailyReminderTime": "09:00"
        ]
        
        let user = User(
            id: UUID(),
            email: "test@example.com",
            createdAt: Date(),
            preferences: initialPreferences
        )
        
        // Create new preferences to add
        let newPreferences: [String: Any] = [
            "themeMode": "dark",
            "dailyReminderTime": "10:00" // This should override the existing value
        ]
        
        // Call withUpdatedPreferences() to get a new User
        let updatedUser = user.withUpdatedPreferences(newPreferences: newPreferences)
        
        // Assert that the new User has the updated preferences
        XCTAssertEqual(updatedUser.preferences?["themeMode"] as? String, "dark")
        XCTAssertEqual(updatedUser.preferences?["dailyReminderTime"] as? String, "10:00")
        XCTAssertEqual(updatedUser.preferences?["notificationsEnabled"] as? Bool, true)
        
        // Assert that the original User is unchanged
        XCTAssertEqual(user.preferences?["dailyReminderTime"] as? String, "09:00")
        XCTAssertNil(user.preferences?["themeMode"])
        
        // Assert that the updatedAt date is updated
        XCTAssertNotNil(updatedUser.updatedAt)
    }
    
    func testWithUpdatedName() {
        // Create a User with an initial name
        let user = User(
            id: UUID(),
            email: "test@example.com",
            name: "Initial Name",
            createdAt: Date()
        )
        
        // Call withUpdatedName() to get a new User
        let updatedUser = user.withUpdatedName(newName: "Updated Name")
        
        // Assert that the new User has the updated name
        XCTAssertEqual(updatedUser.name, "Updated Name")
        
        // Assert that the original User is unchanged
        XCTAssertEqual(user.name, "Initial Name")
        
        // Assert that the updatedAt date is updated
        XCTAssertNotNil(updatedUser.updatedAt)
    }
    
    func testWithUpdatedLanguagePreference() {
        // Create a User with an initial language preference
        let user = User(
            id: UUID(),
            email: "test@example.com",
            createdAt: Date(),
            languagePreference: "es"
        )
        
        // Call withUpdatedLanguagePreference() to get a new User
        let updatedUser = user.withUpdatedLanguagePreference(newLanguage: "en")
        
        // Assert that the new User has the updated language preference
        XCTAssertEqual(updatedUser.languagePreference, "en")
        
        // Assert that the original User is unchanged
        XCTAssertEqual(user.languagePreference, "es")
        
        // Assert that the updatedAt date is updated
        XCTAssertNotNil(updatedUser.updatedAt)
    }
    
    func testWithUpdatedSubscriptionTier() {
        // Create a User with SubscriptionTier.free
        let user = User(
            id: UUID(),
            email: "test@example.com",
            createdAt: Date(),
            subscriptionTier: .free
        )
        
        // Call withUpdatedSubscriptionTier() with SubscriptionTier.premium
        let updatedUser = user.withUpdatedSubscriptionTier(newTier: .premium)
        
        // Assert that the new User has SubscriptionTier.premium
        XCTAssertEqual(updatedUser.subscriptionTier, .premium)
        
        // Assert that the original User is unchanged
        XCTAssertEqual(user.subscriptionTier, .free)
        
        // Assert that the updatedAt date is updated
        XCTAssertNotNil(updatedUser.updatedAt)
    }
    
    func testAccountStatusEnum() {
        // Create instances of each AccountStatus case
        let active = AccountStatus.active
        let disabled = AccountStatus.disabled
        let pendingVerification = AccountStatus.pendingVerification
        let deleted = AccountStatus.deleted
        
        // Assert that the raw values match the expected strings
        XCTAssertEqual(active.rawValue, "active")
        XCTAssertEqual(disabled.rawValue, "disabled")
        XCTAssertEqual(pendingVerification.rawValue, "pendingVerification")
        XCTAssertEqual(deleted.rawValue, "deleted")
        
        // Test Codable conformance by encoding and decoding
        do {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            
            // Test active
            let activeData = try encoder.encode(active)
            let decodedActive = try decoder.decode(AccountStatus.self, from: activeData)
            XCTAssertEqual(decodedActive, active)
            
            // Test disabled
            let disabledData = try encoder.encode(disabled)
            let decodedDisabled = try decoder.decode(AccountStatus.self, from: disabledData)
            XCTAssertEqual(decodedDisabled, disabled)
            
            // Test pendingVerification
            let pendingData = try encoder.encode(pendingVerification)
            let decodedPending = try decoder.decode(AccountStatus.self, from: pendingData)
            XCTAssertEqual(decodedPending, pendingVerification)
            
            // Test deleted
            let deletedData = try encoder.encode(deleted)
            let decodedDeleted = try decoder.decode(AccountStatus.self, from: deletedData)
            XCTAssertEqual(decodedDeleted, deleted)
        } catch {
            XCTFail("Failed to encode or decode AccountStatus: \(error)")
        }
    }
    
    func testSubscriptionTierEnum() {
        // Create instances of each SubscriptionTier case
        let free = SubscriptionTier.free
        let premium = SubscriptionTier.premium
        
        // Assert that the raw values match the expected strings
        XCTAssertEqual(free.rawValue, "free")
        XCTAssertEqual(premium.rawValue, "premium")
        
        // Test Codable conformance by encoding and decoding
        do {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            
            // Test free
            let freeData = try encoder.encode(free)
            let decodedFree = try decoder.decode(SubscriptionTier.self, from: freeData)
            XCTAssertEqual(decodedFree, free)
            
            // Test premium
            let premiumData = try encoder.encode(premium)
            let decodedPremium = try decoder.decode(SubscriptionTier.self, from: premiumData)
            XCTAssertEqual(decodedPremium, premium)
        } catch {
            XCTFail("Failed to encode or decode SubscriptionTier: \(error)")
        }
    }
    
    func testUserPreferencesConstants() {
        // Access each UserPreferences constant
        let notificationsEnabled = UserPreferences.notificationsEnabled
        let dailyReminderTime = UserPreferences.dailyReminderTime
        let reminderDays = UserPreferences.reminderDays
        let themeMode = UserPreferences.themeMode
        let biometricAuthEnabled = UserPreferences.biometricAuthEnabled
        
        // Assert that each constant has the expected string value
        XCTAssertEqual(notificationsEnabled, "notificationsEnabled")
        XCTAssertEqual(dailyReminderTime, "dailyReminderTime")
        XCTAssertEqual(reminderDays, "reminderDays")
        XCTAssertEqual(themeMode, "themeMode")
        XCTAssertEqual(biometricAuthEnabled, "biometricAuthEnabled")
    }
}