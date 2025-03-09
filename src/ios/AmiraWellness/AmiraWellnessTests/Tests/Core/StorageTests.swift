# src/ios/AmiraWellness/AmiraWellnessTests/Tests/Core/StorageTests.swift
```swift
import XCTest // Latest
import Foundation // Latest

@testable import AmiraWellness // The module being tested

/// Test suite for the `StorageService` class
class StorageTests: XCTestCase {
    
    /// Instance of the `StorageService` to be tested
    var sut: StorageService!
    
    /// Instance of the `MockStorageService` for isolated testing
    var mockStorage: MockStorageService!
    
    /// A test key used for storing and retrieving data
    let testKey = "testKey"
    
    /// A test file URL used for file operations
    var testFileURL: URL!
    
    /// A test file name used for file operations
    let testFileName = "testFile.txt"
    
    /// Set up the test environment before each test
    override func setUp() {
        super.setUp()
        
        // Initialize sut with StorageService.shared
        sut = StorageService.shared
        
        // Initialize mockStorage with MockStorageService.shared
        mockStorage = MockStorageService.shared
        
        // Reset the mock storage to ensure clean state
        mockStorage.reset()
        
        // Initialize testKey with a unique test identifier
        
        // Create a temporary file URL for testing file operations
        let tempDirURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        testFileURL = tempDirURL.appendingPathComponent(testFileName)
        
        // Initialize testFileName with a unique test file name
        
        // Create a test file with sample content
        createTestFile(fileName: testFileName, content: "Test file content")
    }
    
    /// Clean up after each test
    override func tearDown() {
        // Reset the mock storage to clean up test data
        mockStorage.reset()
        
        // Delete any test files created during tests
        deleteTestFile(fileURL: testFileURL)
        
        super.tearDown()
    }
    
    /// Test storing a Codable object with non-sensitive data
    func testStoreCodableNonSensitive() {
        // Create a test user object using TestData.mockUser()
        let user = TestData.mockUser()
        
        // Store the user object using sut.storeCodable with .nonsensitive sensitivity
        let result = sut.storeCodable(user, forKey: testKey, dataType: .preferences, sensitivity: .nonsensitive)
        
        // Verify the operation succeeds
        switch result {
        case .success:
            break
        case .failure(let error):
            XCTFail("Failed to store codable: \(error)")
        }
        
        // Retrieve the stored user object
        let retrievedResult: Result<User, StorageService.StorageError> = sut.retrieveCodable(forKey: testKey, dataType: .preferences, sensitivity: .nonsensitive)
        
        // Verify the retrieved user matches the original user
        switch retrievedResult {
        case .success(let retrievedUser):
            XCTAssertEqual(retrievedUser, user, "Retrieved user should match the original user")
        case .failure(let error):
            XCTFail("Failed to retrieve codable: \(error)")
        }
    }
    
    /// Test storing a Codable object with sensitive data
    func testStoreCodableSensitive() {
        // Create a test journal object using TestData.mockJournal()
        let journal = TestData.mockJournal()
        
        // Store the journal object using sut.storeCodable with .sensitive sensitivity
        let result = sut.storeCodable(journal, forKey: testKey, dataType: .journals, sensitivity: .sensitive)
        
        // Verify the operation succeeds
        switch result {
        case .success:
            break
        case .failure(let error):
            XCTFail("Failed to store codable: \(error)")
        }
        
        // Retrieve the stored journal object
        let retrievedResult: Result<Journal, StorageService.StorageError> = sut.retrieveCodable(forKey: testKey, dataType: .journals, sensitivity: .sensitive)
        
        // Verify the retrieved journal matches the original journal
        switch retrievedResult {
        case .success(let retrievedJournal):
            XCTAssertEqual(retrievedJournal, journal, "Retrieved journal should match the original journal")
        case .failure(let error):
            XCTFail("Failed to retrieve codable: \(error)")
        }
    }
    
    /// Test retrieving a Codable object with non-sensitive data
    func testRetrieveCodableNonSensitive() {
        // Create a test emotional state object using TestData.mockEmotionalState()
        let emotionalState = TestData.mockEmotionalState()
        
        // Set up the mock storage with the test data
        mockStorage.setMockData(emotionalState, forKey: testKey, dataType: .emotions)
        
        // Retrieve the emotional state object using sut.retrieveCodable with .nonsensitive sensitivity
        let result: Result<EmotionalState, StorageService.StorageError> = sut.retrieveCodable(forKey: testKey, dataType: .emotions, sensitivity: .nonsensitive)
        
        // Verify the operation succeeds
        switch result {
        case .success(let retrievedEmotionalState):
            // Verify the retrieved emotional state matches the original emotional state
            XCTAssertEqual(retrievedEmotionalState, emotionalState, "Retrieved emotional state should match the original")
        case .failure(let error):
            XCTFail("Failed to retrieve codable: \(error)")
        }
    }
    
    /// Test retrieving a Codable object with sensitive data
    func testRetrieveCodableSensitive() {
        // Create a test journal object using TestData.mockJournal()
        let journal = TestData.mockJournal()
        
        // Set up the mock storage with the test data
        mockStorage.setMockData(journal, forKey: testKey, dataType: .journals)
        
        // Retrieve the journal object using sut.retrieveCodable with .sensitive sensitivity
        let result: Result<Journal, StorageService.StorageError> = sut.retrieveCodable(forKey: testKey, dataType: .journals, sensitivity: .sensitive)
        
        // Verify the operation succeeds
        switch result {
        case .success(let retrievedJournal):
            // Verify the retrieved journal matches the original journal
            XCTAssertEqual(retrievedJournal, journal, "Retrieved journal should match the original")
        case .failure(let error):
            XCTFail("Failed to retrieve codable: \(error)")
        }
    }
    
    /// Test storing a file
    func testStoreFile() {
        // Create a test file with sample content
        
        // Store the file using sut.storeFile
        let result = sut.storeFile(fileURL: testFileURL, fileName: testFileName, dataType: .audio, sensitivity: .nonsensitive)
        
        // Verify the operation succeeds
        switch result {
        case .success(let url):
            // Verify the returned URL is valid
            XCTAssertNotNil(url, "Returned URL should not be nil")
            
            // Verify the file exists at the returned URL
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "File should exist at the returned URL")
        case .failure(let error):
            XCTFail("Failed to store file: \(error)")
        }
    }
    
    /// Test retrieving a file URL
    func testRetrieveFileURL() {
        // Set up the mock storage with a test file URL
        mockStorage.setMockFileURL(testFileURL, fileName: testFileName, dataType: .audio)
        
        // Retrieve the file URL using sut.retrieveFileURL
        let result = sut.retrieveFileURL(fileName: testFileName, dataType: .audio, sensitivity: .nonsensitive)
        
        // Verify the operation succeeds
        switch result {
        case .success(let url):
            // Verify the retrieved URL matches the expected URL
            XCTAssertEqual(url, testFileURL, "Retrieved URL should match the expected URL")
        case .failure(let error):
            XCTFail("Failed to retrieve file URL: \(error)")
        }
    }
    
    /// Test deleting stored data
    func testDeleteData() {
        // Create a test tool object using TestData.mockTool()
        let tool = TestData.mockTool()
        
        // Store the tool object using sut.storeCodable
        let storeResult = sut.storeCodable(tool, forKey: testKey, dataType: .tools, sensitivity: .nonsensitive)
        
        // Verify the storage operation succeeds
        switch storeResult {
        case .success:
            break
        case .failure(let error):
            XCTFail("Failed to store codable: \(error)")
            return
        }
        
        // Delete the stored data using sut.deleteData
        let deleteResult = sut.deleteData(forKey: testKey, dataType: .tools, sensitivity: .nonsensitive)
        
        // Verify the deletion operation succeeds
        switch deleteResult {
        case .success:
            break
        case .failure(let error):
            XCTFail("Failed to delete data: \(error)")
            return
        }
        
        // Attempt to retrieve the deleted data
        let retrieveResult: Result<Tool, StorageService.StorageError> = sut.retrieveCodable(forKey: testKey, dataType: .tools, sensitivity: .nonsensitive)
        
        // Verify the retrieval operation fails with .fileNotFound error
        switch retrieveResult {
        case .success:
            XCTFail("Retrieval should have failed")
        case .failure(let error):
            XCTAssertEqual(error, .userDefaultsError, "Error should be .fileNotFound")
        }
    }
    
    /// Test clearing all storage for a specific data type
    func testClearStorage() {
        // Create multiple test objects of the same data type
        let tool1 = TestData.mockTool(category: .breathing)
        let tool2 = TestData.mockTool(category: .meditation)
        
        // Store the objects using sut.storeCodable
        let storeResult1 = sut.storeCodable(tool1, forKey: "tool1", dataType: .tools, sensitivity: .nonsensitive)
        let storeResult2 = sut.storeCodable(tool2, forKey: "tool2", dataType: .tools, sensitivity: .nonsensitive)
        
        // Verify the storage operations succeed
        switch (storeResult1, storeResult2) {
        case (.success, .success):
            break
        default:
            XCTFail("Failed to store codable")
            return
        }
        
        // Clear the storage for the data type using sut.clearStorage
        let clearResult = sut.clearStorage(dataType: .tools)
        
        // Verify the clear operation succeeds
        switch clearResult {
        case .success:
            break
        case .failure(let error):
            XCTFail("Failed to clear storage: \(error)")
            return
        }
        
        // Attempt to retrieve the cleared data
        let retrieveResult1: Result<Tool, StorageService.StorageError> = sut.retrieveCodable(forKey: "tool1", dataType: .tools, sensitivity: .nonsensitive)
        let retrieveResult2: Result<Tool, StorageService.StorageError> = sut.retrieveCodable(forKey: "tool2", dataType: .tools, sensitivity: .nonsensitive)
        
        // Verify the retrieval operations fail with .fileNotFound error
        switch (retrieveResult1, retrieveResult2) {
        case (.failure(let error1), .failure(let error2)):
            XCTAssertEqual(error1, .userDefaultsError, "Error should be .fileNotFound")
            XCTAssertEqual(error2, .userDefaultsError, "Error should be .fileNotFound")
        default:
            XCTFail("Retrieval should have failed")
        }
    }
    
    /// Test getting a URL for an audio file
    func testGetAudioFileURL() {
        // Get an audio file URL using sut.getAudioFileURL
        let audioFileURL = sut.getAudioFileURL(fileName: testFileName)
        
        // Verify the URL is not nil
        XCTAssertNotNil(audioFileURL, "Audio file URL should not be nil")
        
        // Verify the URL path contains 'Audio' directory
        XCTAssertTrue(audioFileURL.path.contains("Audio"), "Audio file URL should contain 'Audio' directory")
        
        // Verify the URL filename matches the expected filename
        XCTAssertTrue(audioFileURL.lastPathComponent == testFileName, "Audio file URL should have the correct filename")
    }
    
    /// Test getting a URL for an image file
    func testGetImageFileURL() {
        // Get an image file URL using sut.getImageFileURL
        let imageFileURL = sut.getImageFileURL(fileName: testFileName)
        
        // Verify the URL is not nil
        XCTAssertNotNil(imageFileURL, "Image file URL should not be nil")
        
        // Verify the URL path contains 'Images' directory
        XCTAssertTrue(imageFileURL.path.contains("Images"), "Image file URL should contain 'Images' directory")
        
        // Verify the URL filename matches the expected filename
        XCTAssertTrue(imageFileURL.lastPathComponent == testFileName, "Image file URL should have the correct filename")
    }
    
    /// Test getting a URL for a cache file
    func testGetCacheFileURL() {
        // Get a cache file URL using sut.getCacheFileURL
        let cacheFileURL = sut.getCacheFileURL(fileName: testFileName)
        
        // Verify the URL is not nil
        XCTAssertNotNil(cacheFileURL, "Cache file URL should not be nil")
        
        // Verify the URL path contains cache directory
        XCTAssertTrue(cacheFileURL.path.contains("Cache"), "Cache file URL should contain cache directory")
        
        // Verify the URL filename matches the expected filename
        XCTAssertTrue(cacheFileURL.lastPathComponent == testFileName, "Cache file URL should have the correct filename")
    }
    
    /// Test checking if a file exists
    func testFileExists() {
        // Create a test file
        
        // Check if the file exists using sut.fileExists
        let fileExists = sut.fileExists(atPath: testFileURL)
        
        // Verify the result is true
        XCTAssertTrue(fileExists, "File should exist")
        
        // Delete the test file
        deleteTestFile(fileURL: testFileURL)
        
        // Check if the file exists again
        let fileNotExists = sut.fileExists(atPath: testFileURL)
        
        // Verify the result is false
        XCTAssertFalse(fileNotExists, "File should not exist")
    }
    
    /// Test error handling when storing a Codable object fails
    func testStoreCodableError() {
        // Configure the mock storage to simulate a specific error
        mockStorage.simulateError(.storageNotAvailable)
        
        // Attempt to store a test object using sut.storeCodable
        let user = TestData.mockUser()
        let result = sut.storeCodable(user, forKey: testKey, dataType: .preferences, sensitivity: .nonsensitive)
        
        // Verify the operation fails with the expected error
        switch result {
        case .success:
            XCTFail("Operation should have failed")
        case .failure(let error):
            XCTAssertEqual(error, .userDefaultsError, "Error should be .storageNotAvailable")
        }
        
        // Stop simulating the error
        mockStorage.stopSimulatingError()
    }
    
    /// Test error handling when retrieving a Codable object fails
    func testRetrieveCodableError() {
        // Configure the mock storage to simulate a specific error
        mockStorage.simulateError(.storageNotAvailable)
        
        // Attempt to retrieve a test object using sut.retrieveCodable
        let result: Result<User, StorageService.StorageError> = sut.retrieveCodable(forKey: testKey, dataType: .preferences, sensitivity: .nonsensitive)
        
        // Verify the operation fails with the expected error
        switch result {
        case .success:
            XCTFail("Operation should have failed")
        case .failure(let error):
            XCTAssertEqual(error, .userDefaultsError, "Error should be .storageNotAvailable")
        }
        
        // Stop simulating the error
        mockStorage.stopSimulatingError()
    }
    
    /// Test error handling when storing a file fails
    func testStoreFileError() {
        // Configure the mock storage to simulate a specific error
        mockStorage.simulateError(.storageNotAvailable)
        
        // Attempt to store a test file using sut.storeFile
        let result = sut.storeFile(fileURL: testFileURL, fileName: testFileName, dataType: .audio, sensitivity: .nonsensitive)
        
        // Verify the operation fails with the expected error
        switch result {
        case .success:
            XCTFail("Operation should have failed")
        case .failure(let error):
            XCTAssertEqual(error, .fileOperationFailed, "Error should be .storageNotAvailable")
        }
        
        // Stop simulating the error
        mockStorage.stopSimulatingError()
    }
    
    /// Test error handling when retrieving a file URL fails
    func testRetrieveFileURLError() {
        // Configure the mock storage to simulate a specific error
        mockStorage.simulateError(.storageNotAvailable)
        
        // Attempt to retrieve a file URL using sut.retrieveFileURL
        let result = sut.retrieveFileURL(fileName: testFileName, dataType: .audio, sensitivity: .nonsensitive)
        
        // Verify the operation fails with the expected error
        switch result {
        case .success:
            XCTFail("Operation should have failed")
        case .failure(let error):
            XCTAssertEqual(error, .fileNotFound, "Error should be .storageNotAvailable")
        }
        
        // Stop simulating the error
        mockStorage.stopSimulatingError()
    }
    
    /// Test error handling when deleting data fails
    func testDeleteDataError() {
        // Configure the mock storage to simulate a specific error
        mockStorage.simulateError(.storageNotAvailable)
        
        // Attempt to delete data using sut.deleteData
        let result = sut.deleteData(forKey: testKey, dataType: .preferences, sensitivity: .nonsensitive)
        
        // Verify the operation fails with the expected error
        switch result {
        case .success:
            XCTFail("Operation should have failed")
        case .failure(let error):
            XCTAssertEqual(error, .secureStorageError, "Error should be .storageNotAvailable")
        }
        
        // Stop simulating the error
        mockStorage.stopSimulatingError()
    }
    
    /// Test error handling when clearing storage fails
    func testClearStorageError() {
        // Configure the mock storage to simulate a specific error
        mockStorage.simulateError(.storageNotAvailable)
        
        // Attempt to clear storage using sut.clearStorage
        let result = sut.clearStorage(dataType: .preferences)
        
        // Verify the operation fails with the expected error
        switch result {
        case .success:
            XCTFail("Operation should have failed")
        case .failure(let error):
            XCTAssertEqual(error, .fileOperationFailed, "Error should be .storageNotAvailable")
        }
        
        // Stop simulating the error
        mockStorage.stopSimulatingError()
    }
    
    // MARK: - Helper Methods
    
    /// Helper method to create a test file with sample content
    private func createTestFile(fileName: String, content: String) -> URL {
        // Get the temporary directory URL
        let tempDirURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        
        // Create a file URL with the temporary directory and fileName
        let fileURL = tempDirURL.appendingPathComponent(fileName)
        
        // Convert the content string to Data
        let data = content.data(using: .utf8)!
        
        // Write the data to the file URL
        try? data.write(to: fileURL)
        
        // Return the file URL
        return fileURL
    }
    
    /// Helper method to delete a test file
    private func deleteTestFile(fileURL: URL) {
        // Check if the file exists
        if FileManager.default.fileExists(atPath: fileURL.path) {
            // If it exists, delete the file
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                // Handle any errors during deletion
                print("Error deleting test file: \(error)")
            }
        }
    }
}