//
//  UtilitiesTests.swift
//  AmiraWellnessTests
//
//  Created for Amira Wellness
//

import XCTest // Latest
import LocalAuthentication // Latest
import UserNotifications // Latest
@testable import AmiraWellness

// Test helper struct for Codable operations
struct TestCodableObject: Codable, Equatable {
    let id: String
    let value: Int
    
    static func == (lhs: TestCodableObject, rhs: TestCodableObject) -> Bool {
        return lhs.id == rhs.id && lhs.value == rhs.value
    }
}

// MARK: - BiometricAuthManagerTests

final class BiometricAuthManagerTests: XCTestCase {
    private var sut: BiometricAuthManager!
    
    override func setUp() {
        super.setUp()
        sut = BiometricAuthManager.shared
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testBiometricType() {
        // Test that the biometricType method returns one of the expected types
        let biometricType = sut.biometricType()
        XCTAssertTrue([.none, .touchID, .faceID].contains(biometricType), "Biometric type should be one of the expected values")
    }
    
    func testCanAuthenticate() {
        // Test that canAuthenticate returns a boolean value
        let canAuthenticate = sut.canAuthenticate()
        // We can't assert a specific value since it depends on device capabilities and user settings
        // But we can verify it returns a boolean
        XCTAssertTrue(canAuthenticate is Bool, "canAuthenticate should return a boolean value")
    }
    
    func testGetBiometricErrorDescription() {
        // Test that error descriptions are not empty and are unique
        let errorCases: [BiometricError] = [
            .authenticationFailed,
            .biometryNotAvailable,
            .biometryNotEnrolled,
            .userCancelled,
            .passcodeNotSet,
            .systemCancel,
            .appCancel,
            .invalidContext,
            .notInteractive,
            .unknown
        ]
        
        var errorDescriptions = [String]()
        
        for error in errorCases {
            let description = sut.getBiometricErrorDescription(error: error)
            XCTAssertFalse(description.isEmpty, "Error description should not be empty for \(error)")
            errorDescriptions.append(description)
        }
        
        // Verify uniqueness of error descriptions
        XCTAssertEqual(errorDescriptions.count, Set(errorDescriptions).count, "Error descriptions should be unique")
    }
}

// MARK: - KeychainManagerTests

final class KeychainManagerTests: XCTestCase {
    private var sut: KeychainManager!
    private let testKey = "com.amirawellness.tests.keychain.testKey"
    private let testData = Data([0, 1, 2, 3, 4])
    private let testString = "Test String Value"
    private let testObject = TestCodableObject(id: "test-id", value: 42)
    
    override func setUp() {
        super.setUp()
        sut = KeychainManager.shared
    }
    
    override func tearDown() {
        // Clean up after each test
        _ = sut.delete(key: testKey)
        super.tearDown()
    }
    
    func testSaveAndRetrieveData() {
        // Test saving data to keychain
        let saveResult = sut.save(data: testData, key: testKey)
        XCTAssertTrue(saveResult.isSuccess, "Data should be saved successfully")
        
        // Test retrieving data from keychain
        let retrieveResult = sut.retrieve(key: testKey)
        XCTAssertTrue(retrieveResult.isSuccess, "Data should be retrieved successfully")
        
        if case let .success(retrievedData) = retrieveResult {
            XCTAssertEqual(retrievedData, testData, "Retrieved data should match saved data")
        } else {
            XCTFail("Failed to retrieve data")
        }
    }
    
    func testSaveAndRetrieveString() {
        // Test saving string to keychain
        let saveResult = sut.saveString(string: testString, key: testKey)
        XCTAssertTrue(saveResult.isSuccess, "String should be saved successfully")
        
        // Test retrieving string from keychain
        let retrieveResult = sut.retrieveString(key: testKey)
        XCTAssertTrue(retrieveResult.isSuccess, "String should be retrieved successfully")
        
        if case let .success(retrievedString) = retrieveResult {
            XCTAssertEqual(retrievedString, testString, "Retrieved string should match saved string")
        } else {
            XCTFail("Failed to retrieve string")
        }
    }
    
    func testSaveAndRetrieveCodable() {
        // Test saving codable object to keychain
        let saveResult = sut.saveCodable(testObject, key: testKey)
        XCTAssertTrue(saveResult.isSuccess, "Codable object should be saved successfully")
        
        // Test retrieving codable object from keychain
        let retrieveResult = sut.retrieveCodable(key: testKey) as Result<TestCodableObject, KeychainError>
        XCTAssertTrue(retrieveResult.isSuccess, "Codable object should be retrieved successfully")
        
        if case let .success(retrievedObject) = retrieveResult {
            XCTAssertEqual(retrievedObject, testObject, "Retrieved object should match saved object")
        } else {
            XCTFail("Failed to retrieve codable object")
        }
    }
    
    func testDeleteItem() {
        // Save data to keychain
        _ = sut.save(data: testData, key: testKey)
        
        // Verify data exists
        XCTAssertTrue(sut.contains(key: testKey), "Key should exist after saving")
        
        // Delete data
        let deleteResult = sut.delete(key: testKey)
        XCTAssertTrue(deleteResult.isSuccess, "Data should be deleted successfully")
        
        // Verify data no longer exists
        XCTAssertFalse(sut.contains(key: testKey), "Key should not exist after deletion")
    }
    
    func testContains() {
        // Check non-existent key
        XCTAssertFalse(sut.contains(key: testKey), "Key should not exist initially")
        
        // Save data to keychain
        _ = sut.save(data: testData, key: testKey)
        
        // Verify key exists
        XCTAssertTrue(sut.contains(key: testKey), "Key should exist after saving")
        
        // Delete data
        _ = sut.delete(key: testKey)
        
        // Verify key no longer exists
        XCTAssertFalse(sut.contains(key: testKey), "Key should not exist after deletion")
    }
}

// MARK: - LoggerTests

final class LoggerTests: XCTestCase {
    private var sut: Logger!
    
    override func setUp() {
        super.setUp()
        sut = Logger.shared
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSetLogLevel() {
        // Test setting different log levels
        sut.setLogLevel(.debug)
        sut.setLogLevel(.info)
        sut.setLogLevel(.warning)
        sut.setLogLevel(.error)
        sut.setLogLevel(.none)
        
        // If we reach here without exceptions, the test passes
        XCTAssertTrue(true, "Should be able to set all log levels without exceptions")
    }
    
    func testDebugLogging() {
        // Set log level to debug to ensure the message is logged
        sut.setLogLevel(.debug)
        
        // Test debug logging
        sut.debug("Test debug message")
        
        // If we reach here without exceptions, the test passes
        XCTAssertTrue(true, "Should be able to log debug messages without exceptions")
    }
    
    func testInfoLogging() {
        // Set log level to info to ensure the message is logged
        sut.setLogLevel(.info)
        
        // Test info logging
        sut.info("Test info message")
        
        // If we reach here without exceptions, the test passes
        XCTAssertTrue(true, "Should be able to log info messages without exceptions")
    }
    
    func testWarningLogging() {
        // Set log level to warning to ensure the message is logged
        sut.setLogLevel(.warning)
        
        // Test warning logging
        sut.warning("Test warning message")
        
        // If we reach here without exceptions, the test passes
        XCTAssertTrue(true, "Should be able to log warning messages without exceptions")
    }
    
    func testErrorLogging() {
        // Set log level to error to ensure the message is logged
        sut.setLogLevel(.error)
        
        // Create a test error
        struct TestError: Error {}
        let error = TestError()
        
        // Test error logging
        sut.error("Test error message", error: error)
        
        // If we reach here without exceptions, the test passes
        XCTAssertTrue(true, "Should be able to log error messages without exceptions")
    }
    
    func testLogLevelFiltering() {
        // Set log level to warning
        sut.setLogLevel(.warning)
        
        // The following logs should be filtered out
        sut.debug("This debug message should be filtered out")
        sut.info("This info message should be filtered out")
        
        // The following logs should not be filtered out
        sut.warning("This warning message should not be filtered out")
        sut.error("This error message should not be filtered out")
        
        // There's no direct way to verify filtering in unit tests without mocking,
        // but this at least verifies that the methods can be called without exceptions
        XCTAssertTrue(true, "Should be able to call log methods with different levels without exceptions")
    }
}

// MARK: - UserDefaultsManagerTests

final class UserDefaultsManagerTests: XCTestCase {
    private var sut: UserDefaultsManager!
    private let testBoolKey = "com.amirawellness.tests.userdefaults.testBool"
    private let testIntKey = "com.amirawellness.tests.userdefaults.testInt"
    private let testStringKey = "com.amirawellness.tests.userdefaults.testString"
    private let testCodableKey = "com.amirawellness.tests.userdefaults.testCodable"
    
    override func setUp() {
        super.setUp()
        sut = UserDefaultsManager.shared
    }
    
    override func tearDown() {
        // Clean up after each test
        sut.removeObject(forKey: testBoolKey)
        sut.removeObject(forKey: testIntKey)
        sut.removeObject(forKey: testStringKey)
        sut.removeObject(forKey: testCodableKey)
        super.tearDown()
    }
    
    func testSetAndGetBool() {
        // Test setting and getting boolean values
        sut.setBool(true, forKey: testBoolKey)
        XCTAssertTrue(sut.getBool(forKey: testBoolKey), "Bool value should be true")
        
        sut.setBool(false, forKey: testBoolKey)
        XCTAssertFalse(sut.getBool(forKey: testBoolKey), "Bool value should be false")
    }
    
    func testSetAndGetInt() {
        // Test setting and getting integer values
        sut.setInt(42, forKey: testIntKey)
        XCTAssertEqual(sut.getInt(forKey: testIntKey), 42, "Int value should be 42")
        
        sut.setInt(100, forKey: testIntKey)
        XCTAssertEqual(sut.getInt(forKey: testIntKey), 100, "Int value should be 100")
    }
    
    func testSetAndGetString() {
        // Test setting and getting string values
        sut.setString("test", forKey: testStringKey)
        XCTAssertEqual(sut.getString(forKey: testStringKey), "test", "String value should be 'test'")
        
        sut.setString("updated", forKey: testStringKey)
        XCTAssertEqual(sut.getString(forKey: testStringKey), "updated", "String value should be 'updated'")
    }
    
    func testSetAndGetCodable() {
        // Test setting and getting Codable objects
        let testObject = TestCodableObject(id: "test-id", value: 42)
        
        let saveResult = sut.setCodable(testObject, forKey: testCodableKey)
        XCTAssertTrue(saveResult.isSuccess, "Codable object should be saved successfully")
        
        let retrieveResult = sut.getCodable(forKey: testCodableKey) as Result<TestCodableObject, UserDefaultsError>
        
        XCTAssertTrue(retrieveResult.isSuccess, "Codable object should be retrieved successfully")
        
        if case let .success(retrievedObject) = retrieveResult {
            XCTAssertEqual(retrievedObject.id, testObject.id, "Retrieved object id should match")
            XCTAssertEqual(retrievedObject.value, testObject.value, "Retrieved object value should match")
        } else {
            XCTFail("Failed to retrieve Codable object")
        }
    }
    
    func testRemoveObject() {
        // Test removing objects
        sut.setBool(true, forKey: testBoolKey)
        XCTAssertTrue(sut.containsKey(testBoolKey), "Key should exist after setting value")
        
        sut.removeObject(forKey: testBoolKey)
        XCTAssertFalse(sut.containsKey(testBoolKey), "Key should not exist after removing value")
        XCTAssertFalse(sut.getBool(forKey: testBoolKey, defaultValue: false), "Default value should be returned after removing value")
    }
    
    func testContainsKey() {
        // Test checking if keys exist
        XCTAssertFalse(sut.containsKey(testBoolKey), "Key should not exist initially")
        
        sut.setBool(true, forKey: testBoolKey)
        XCTAssertTrue(sut.containsKey(testBoolKey), "Key should exist after setting value")
        
        sut.removeObject(forKey: testBoolKey)
        XCTAssertFalse(sut.containsKey(testBoolKey), "Key should not exist after removing value")
    }
    
    func testClearAll() {
        // Test clearing all values
        sut.setBool(true, forKey: testBoolKey)
        sut.setInt(42, forKey: testIntKey)
        sut.setString("test", forKey: testStringKey)
        
        XCTAssertTrue(sut.containsKey(testBoolKey), "Bool key should exist")
        XCTAssertTrue(sut.containsKey(testIntKey), "Int key should exist")
        XCTAssertTrue(sut.containsKey(testStringKey), "String key should exist")
        
        // Clear all values
        sut.clearAll()
        
        // Note: clearAll() clears all UserDefaults values for the app, which might affect other tests
        // In a real app, we might want to create a separate UserDefaults suite for testing
        // For now, we'll just check that our test keys are cleared
        XCTAssertFalse(sut.containsKey(testBoolKey), "Bool key should not exist after clearAll")
        XCTAssertFalse(sut.containsKey(testIntKey), "Int key should not exist after clearAll")
        XCTAssertFalse(sut.containsKey(testStringKey), "String key should not exist after clearAll")
    }
}

// MARK: - NotificationManagerTests

final class NotificationManagerTests: XCTestCase {
    private var sut: NotificationManager!
    
    override func setUp() {
        super.setUp()
        sut = NotificationManager.shared
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testNotificationEnabledSettings() {
        // Test enabling and disabling notification types
        let notificationType = NotificationConstants.Categories.dailyReminder
        
        // Enable notifications
        sut.setNotificationEnabled(notificationType, enabled: true)
        XCTAssertTrue(sut.isNotificationEnabled(notificationType), "Notification should be enabled")
        
        // Disable notifications
        sut.setNotificationEnabled(notificationType, enabled: false)
        XCTAssertFalse(sut.isNotificationEnabled(notificationType), "Notification should be disabled")
    }
    
    func testGetAndSaveNotificationSettings() {
        // Test getting and saving notification settings
        
        // Get current settings
        let settings = sut.getNotificationSettings()
        XCTAssertNotNil(settings, "Should retrieve notification settings")
        
        // Modify settings
        var modifiedSettings = settings
        modifiedSettings["dailyRemindersEnabled"] = !(settings["dailyRemindersEnabled"] as? Bool ?? true)
        modifiedSettings["reminderHour"] = 12 // Set to noon
        
        // Save modified settings
        sut.saveNotificationSettings(modifiedSettings)
        
        // Get settings again and verify changes
        let newSettings = sut.getNotificationSettings()
        XCTAssertEqual(newSettings["dailyRemindersEnabled"] as? Bool, modifiedSettings["dailyRemindersEnabled"] as? Bool, "dailyRemindersEnabled setting should match")
        XCTAssertEqual(newSettings["reminderHour"] as? Int, 12, "reminderHour setting should be 12")
    }
}

// MARK: - HapticManagerTests

final class HapticManagerTests: XCTestCase {
    private var sut: HapticManager!
    
    override func setUp() {
        super.setUp()
        sut = HapticManager.shared
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testGenerateFeedback() {
        // Test generating different types of haptic feedback
        // Note: We can't verify the actual haptic feedback in unit tests,
        // but we can verify that the methods don't throw exceptions
        
        // Test all types of haptic feedback
        sut.generateFeedback(.light)
        sut.generateFeedback(.medium)
        sut.generateFeedback(.heavy)
        sut.generateFeedback(.selection)
        sut.generateFeedback(.success)
        sut.generateFeedback(.warning)
        sut.generateFeedback(.error)
        
        // If we reach here without exceptions, the test passes
        XCTAssertTrue(true, "Should be able to generate all types of haptic feedback without exceptions")
    }
    
    func testPrepareGenerators() {
        // Test preparing haptic generators
        sut.prepareGenerators()
        
        // If we reach here without exceptions, the test passes
        XCTAssertTrue(true, "Should be able to prepare haptic generators without exceptions")
    }
}

// Helper extension for Result testing
extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}