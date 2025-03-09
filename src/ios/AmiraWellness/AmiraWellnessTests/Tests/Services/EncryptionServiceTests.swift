import XCTest // Apple's testing framework - Latest
import Foundation // Core Foundation types and functionality - Latest
import Combine // For testing asynchronous operations - Latest

@testable import AmiraWellness // Import the main module for testing

/// Test suite for the EncryptionService class
class EncryptionServiceTests: XCTestCase {

    // MARK: - Properties

    var encryptionService: EncryptionService! // The service being tested
    var keyManagementService: KeyManagementService! // Used to test integration with key management
    var testKeyIdentifier: String! // Unique identifier for test keys
    var testData: Data! // Sample data for encryption tests
    var testFileURL: URL! // URL for a temporary test file
    var testDestinationURL: URL! // URL for the encrypted test file
    var testPassword: String! // Test password for password-based encryption
    private var cancellables: Set<AnyCancellable> = [] // For Combine subscriptions

    // MARK: - Setup and Tear Down

    /// Set up method called before each test
    override func setUp() {
        super.setUp()

        // Initialize encryptionService with EncryptionService.shared
        encryptionService = EncryptionService.shared

        // Initialize keyManagementService with KeyManagementService.shared
        keyManagementService = KeyManagementService.shared

        // Set testKeyIdentifier to a unique test identifier
        testKeyIdentifier = "test-key-\(UUID().uuidString)"

        // Initialize testData with sample data for encryption tests
        testData = "This is a test string for encryption".data(using: .utf8)!

        // Create temporary file URLs for file encryption tests
        testFileURL = createTemporaryFileURL(filename: "test_file.txt")
        testDestinationURL = createTemporaryFileURL(filename: "test_file.encrypted")

        // Set testPassword to a strong test password
        testPassword = "P@$$wOrd123!"

        // Initialize cancellables array for Combine subscriptions
        cancellables = []

        // Generate a test encryption key using keyManagementService
        let generateKeyResult = keyManagementService.generateDataKey(identifier: testKeyIdentifier)
        XCTAssertTrue(generateKeyResult.isSuccess, "Failed to generate test encryption key")
    }

    /// Tear down method called after each test
    override func tearDown() {
        // Clean up any temporary files created during tests
        if FileManager.default.fileExists(atPath: testFileURL.path) {
            try? FileManager.default.removeItem(at: testFileURL)
        }
        if FileManager.default.fileExists(atPath: testDestinationURL.path) {
            try? FileManager.default.removeItem(at: testDestinationURL)
        }

        // Cancel any active Combine subscriptions
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

        // Call super.tearDown()
        super.tearDown()
    }

    // MARK: - Tests

    /// Tests that data can be encrypted and then decrypted correctly
    func testEncryptDecryptData() {
        // Encrypt testData using encryptionService.encryptData
        let encryptResult = encryptionService.encryptData(data: testData, keyIdentifier: testKeyIdentifier)

        // Verify encryption succeeds and returns EncryptedData
        guard case let .success(encryptedData) = encryptResult else {
            XCTFail("Encryption failed: \(encryptResult)")
            return
        }

        // Verify encrypted data is different from original data
        XCTAssertNotEqual(encryptedData.data, testData, "Encrypted data should not match original data")

        // Decrypt the encrypted data using encryptionService.decryptData
        let decryptResult = encryptionService.decryptData(encryptedData: encryptedData, keyIdentifier: testKeyIdentifier)

        // Verify decryption succeeds and returns the original data
        guard case let .success(decryptedData) = decryptResult else {
            XCTFail("Decryption failed: \(decryptResult)")
            return
        }

        // Assert that decrypted data matches original testData
        XCTAssertEqual(decryptedData, testData, "Decrypted data should match original data")
    }

    /// Tests that decryption fails with an invalid key
    func testEncryptDecryptDataWithInvalidKey() {
        // Encrypt testData using encryptionService.encryptData
        let encryptResult = encryptionService.encryptData(data: testData, keyIdentifier: testKeyIdentifier)

        // Verify encryption succeeds and returns EncryptedData
        guard case let .success(encryptedData) = encryptResult else {
            XCTFail("Encryption failed: \(encryptResult)")
            return
        }

        // Attempt to decrypt with an invalid key identifier
        let invalidKeyIdentifier = "invalid-key"
        let decryptResult = encryptionService.decryptData(encryptedData: encryptedData, keyIdentifier: invalidKeyIdentifier)

        // Verify decryption fails with EncryptionError.keyRetrievalFailed
        guard case let .failure(error) = decryptResult else {
            XCTFail("Decryption should have failed with an invalid key")
            return
        }

        XCTAssertEqual(error, EncryptionError.keyRetrievalFailed, "Decryption should fail with keyRetrievalFailed error")
    }

    /// Tests that a file can be encrypted and then decrypted correctly
    func testEncryptDecryptFile() {
        // Write testData to testFileURL
        do {
            try testData.write(to: testFileURL)
        } catch {
            XCTFail("Failed to write test data to file: \(error)")
            return
        }

        // Encrypt the file using encryptionService.encryptFile
        let encryptResult = encryptionService.encryptFile(fileURL: testFileURL, destinationURL: testDestinationURL, keyIdentifier: testKeyIdentifier)

        // Verify encryption succeeds and returns an IV string
        guard case .success = encryptResult else {
            XCTFail("File encryption failed: \(encryptResult)")
            return
        }

        // Verify the encrypted file exists at the destination
        XCTAssertTrue(FileManager.default.fileExists(atPath: testDestinationURL.path), "Encrypted file should exist at destination")

        // Verify the encrypted file content differs from original
        do {
            let encryptedData = try Data(contentsOf: testDestinationURL)
            XCTAssertNotEqual(encryptedData, testData, "Encrypted file content should not match original")
        } catch {
            XCTFail("Failed to read encrypted file: \(error)")
            return
        }

        // Create a new destination URL for the decrypted file
        let decryptedDestinationURL = createTemporaryFileURL(filename: "test_file.decrypted")

        // Decrypt the file using encryptionService.decryptFile
        let decryptResult = encryptionService.decryptFile(fileURL: testDestinationURL, destinationURL: decryptedDestinationURL, keyIdentifier: testKeyIdentifier)

        // Verify decryption succeeds
        guard case .success = decryptResult else {
            XCTFail("File decryption failed: \(decryptResult)")
            return
        }

        // Read the decrypted file content
        let decryptedData: Data
        do {
            decryptedData = try Data(contentsOf: decryptedDestinationURL)
        } catch {
            XCTFail("Failed to read decrypted file: \(error)")
            return
        }

        // Assert that decrypted content matches original testData
        XCTAssertEqual(decryptedData, testData, "Decrypted file content should match original data")
    }

    /// Tests that file decryption fails with an invalid key
    func testEncryptDecryptFileWithInvalidKey() {
        // Write testData to testFileURL
        do {
            try testData.write(to: testFileURL)
        } catch {
            XCTFail("Failed to write test data to file: \(error)")
            return
        }

        // Encrypt the file using encryptionService.encryptFile
        let encryptResult = encryptionService.encryptFile(fileURL: testFileURL, destinationURL: testDestinationURL, keyIdentifier: testKeyIdentifier)

        // Verify encryption succeeds and returns an IV string
        guard case .success = encryptResult else {
            XCTFail("File encryption failed: \(encryptResult)")
            return
        }

        // Create a new destination URL for the decrypted file
        let decryptedDestinationURL = createTemporaryFileURL(filename: "test_file.decrypted")

        // Attempt to decrypt with an invalid key identifier
        let invalidKeyIdentifier = "invalid-key"
        let decryptResult = encryptionService.decryptFile(fileURL: testDestinationURL, destinationURL: decryptedDestinationURL, keyIdentifier: invalidKeyIdentifier)

        // Verify decryption fails with EncryptionError.keyRetrievalFailed
        guard case let .failure(error) = decryptResult else {
            XCTFail("Decryption should have failed with an invalid key")
            return
        }

        XCTAssertEqual(error, EncryptionError.keyRetrievalFailed, "Decryption should fail with keyRetrievalFailed error")
    }

    /// Tests that data can be encrypted and decrypted with a password
    func testEncryptDecryptWithPassword() {
        // Encrypt testData using encryptionService.encryptWithPassword
        let encryptResult = encryptionService.encryptWithPassword(data: testData, password: testPassword)

        // Verify encryption succeeds and returns encrypted data and salt
        guard case let .success((encryptedData, salt)) = encryptResult else {
            XCTFail("Password-based encryption failed: \(encryptResult)")
            return
        }

        // Decrypt the data using encryptionService.decryptWithPassword
        let decryptResult = encryptionService.decryptWithPassword(encryptedData: encryptedData, password: testPassword, salt: salt)

        // Verify decryption succeeds and returns the original data
        guard case let .success(decryptedData) = decryptResult else {
            XCTFail("Password-based decryption failed: \(decryptResult)")
            return
        }

        // Assert that decrypted data matches original testData
        XCTAssertEqual(decryptedData, testData, "Decrypted data should match original data")
    }

    /// Tests that encryption fails with a weak password
    func testEncryptWithWeakPassword() {
        // Attempt to encrypt testData with a weak password
        let weakPassword = "password"
        let encryptResult = encryptionService.encryptWithPassword(data: testData, password: weakPassword)

        // Verify encryption fails with EncryptionError.passwordTooWeak
        guard case let .failure(error) = encryptResult else {
            XCTFail("Encryption should have failed with a weak password")
            return
        }

        XCTAssertEqual(error, EncryptionError.passwordTooWeak, "Encryption should fail with passwordTooWeak error")
    }

    /// Tests that decryption fails with an incorrect password
    func testDecryptWithWrongPassword() {
        // Encrypt testData using encryptionService.encryptWithPassword
        let encryptResult = encryptionService.encryptWithPassword(data: testData, password: testPassword)

        // Verify encryption succeeds and returns encrypted data and salt
        guard case let .success((encryptedData, salt)) = encryptResult else {
            XCTFail("Password-based encryption failed: \(encryptResult)")
            return
        }

        // Attempt to decrypt with an incorrect password
        let incorrectPassword = "wrongpassword"
        let decryptResult = encryptionService.decryptWithPassword(encryptedData: encryptedData, password: incorrectPassword, salt: salt)

        // Verify decryption fails with EncryptionError.decryptionFailed
        guard case let .failure(error) = decryptResult else {
            XCTFail("Decryption should have failed with an incorrect password")
            return
        }

        XCTAssertEqual(error, EncryptionError.decryptionFailed, "Decryption should fail with decryptionFailed error")
    }

    /// Tests that encryption keys can be generated successfully
    func testGenerateEncryptionKey() {
        // Generate a new encryption key with a unique identifier
        let newKeyIdentifier = "new-test-key-\(UUID().uuidString)"
        let generateResult = encryptionService.generateEncryptionKey(keyIdentifier: newKeyIdentifier)

        // Verify key generation succeeds
        XCTAssertTrue(generateResult.isSuccess, "Key generation should succeed")

        // Attempt to retrieve the generated key
        let retrieveResult = keyManagementService.getDataKey(identifier: newKeyIdentifier)

        // Verify key retrieval succeeds
        XCTAssertTrue(retrieveResult.isSuccess, "Key retrieval should succeed after generation")

        // Encrypt data using the new key
        let encryptResult = encryptionService.encryptData(data: testData, keyIdentifier: newKeyIdentifier)

        // Verify encryption succeeds
        XCTAssertTrue(encryptResult.isSuccess, "Encryption should succeed with the new key")
    }

    /// Tests that encrypted data can be exported and imported
    func testExportImportEncryptedData() {
        // Encrypt testData using encryptionService.encryptData
        let encryptResult = encryptionService.encryptData(data: testData, keyIdentifier: testKeyIdentifier)

        // Verify encryption succeeds and returns EncryptedData
        guard case let .success(encryptedData) = encryptResult else {
            XCTFail("Encryption failed: \(encryptResult)")
            return
        }

        // Export the encrypted data using encryptionService.exportEncryptedData
        let exportPassword = "exportPassword123!"
        let exportResult = encryptionService.exportEncryptedData(encryptedData: encryptedData, keyIdentifier: testKeyIdentifier, password: exportPassword)

        // Verify export succeeds and returns exportable data
        guard case let .success(exportData) = exportResult else {
            XCTFail("Export failed: \(exportResult)")
            return
        }

        // Import the exported data using encryptionService.importEncryptedData
        let importResult = encryptionService.importEncryptedData(exportedData: exportData, password: exportPassword)

        // Verify import succeeds and returns the original EncryptedData and key identifier
        guard case let .success((importedEncryptedData, importedKeyIdentifier)) = importResult else {
            XCTFail("Import failed: \(importResult)")
            return
        }

        XCTAssertEqual(importedKeyIdentifier, testKeyIdentifier, "Imported key identifier should match original")

        // Decrypt the imported data using encryptionService.decryptData
        let decryptResult = encryptionService.decryptData(encryptedData: importedEncryptedData, keyIdentifier: importedKeyIdentifier)

        // Verify decryption succeeds and returns the original data
        guard case let .success(decryptedData) = decryptResult else {
            XCTFail("Decryption failed after import: \(decryptResult)")
            return
        }

        // Assert that decrypted data matches original testData
        XCTAssertEqual(decryptedData, testData, "Decrypted data should match original data after import")
    }

    /// Tests that file integrity verification works correctly
    func testVerifyFileIntegrity() {
        // Write testData to testFileURL
        do {
            try testData.write(to: testFileURL)
        } catch {
            XCTFail("Failed to write test data to file: \(error)")
            return
        }

        // Calculate expected checksum for the file
        guard let expectedChecksum = calculateChecksum(fileURL: testFileURL) else {
            XCTFail("Failed to calculate checksum for test file")
            return
        }

        // Verify file integrity with correct checksum
        let verifyResult = encryptionService.verifyFileIntegrity(fileURL: testFileURL, expectedChecksum: expectedChecksum)

        // Assert that verification returns true
        guard case let .success(isValid) = verifyResult else {
            XCTFail("File integrity verification failed: \(verifyResult)")
            return
        }

        XCTAssertTrue(isValid, "File integrity verification should pass with correct checksum")

        // Verify file integrity with incorrect checksum
        let incorrectChecksum = "incorrect-checksum"
        let invalidVerifyResult = encryptionService.verifyFileIntegrity(fileURL: testFileURL, expectedChecksum: incorrectChecksum)

        // Assert that verification returns false
        guard case let .success(isInvalid) = invalidVerifyResult else {
            XCTFail("File integrity verification failed with incorrect checksum: \(invalidVerifyResult)")
            return
        }

        XCTAssertFalse(isInvalid, "File integrity verification should fail with incorrect checksum")
    }

    /// Tests that encryption errors are properly handled and reported
    func testEncryptionErrorHandling() {
        // Set up scenarios for different encryption errors
        let mockEncryptionService = MockEncryptionService.shared
        mockEncryptionService.shouldSucceed = false

        // Test each error scenario and verify correct error is returned
        mockEncryptionService.error = .keyRetrievalFailed
        var encryptResult = mockEncryptionService.encryptData(data: testData, keyIdentifier: testKeyIdentifier)
        XCTAssertEqual(encryptResult.failureValue as? EncryptionError, .keyRetrievalFailed, "Incorrect error for key retrieval failure")

        mockEncryptionService.error = .encryptionFailed
        encryptResult = mockEncryptionService.encryptData(data: testData, keyIdentifier: testKeyIdentifier)
        XCTAssertEqual(encryptResult.failureValue as? EncryptionError, .encryptionFailed, "Incorrect error for encryption failure")

        mockEncryptionService.error = .decryptionFailed
        let encryptedData = EncryptedData(data: testData, iv: Data(), authTag: nil)
        var decryptResult = mockEncryptionService.decryptData(encryptedData: encryptedData, keyIdentifier: testKeyIdentifier)
        XCTAssertEqual(decryptResult.failureValue as? EncryptionError, .decryptionFailed, "Incorrect error for decryption failure")

        // Verify error descriptions are meaningful and helpful
        // (This can be expanded with more specific error descriptions)
        XCTAssertNotNil(EncryptionError.keyRetrievalFailed.localizedDescription, "Error description should not be nil")

        // Reset the mock
        mockEncryptionService.reset()
    }

    /// Tests that multiple encryption operations can run concurrently
    @available(iOS 15.0, *)
    func testConcurrentEncryptionOperations() async {
        // Create multiple data items to encrypt
        let dataItems = (0..<5).map { index in
            "Test data item \(index)".data(using: .utf8)!
        }

        // Start concurrent encryption tasks for all items
        let encryptResults = await withTaskGroup(of: Result<EncryptedData, EncryptionError>.self) { group -> [Result<EncryptedData, EncryptionError>] in
            for dataItem in dataItems {
                group.addTask {
                    return self.encryptionService.encryptData(data: dataItem, keyIdentifier: self.testKeyIdentifier)
                }
            }

            var results: [Result<EncryptedData, EncryptionError>] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        // Wait for all tasks to complete
        // Verify all encryptions succeeded
        XCTAssertEqual(encryptResults.count, dataItems.count, "Number of encryption results should match number of data items")
        XCTAssertTrue(encryptResults.allSatisfy { $0.isSuccess }, "All encryptions should succeed")

        // Decrypt all encrypted data concurrently
        let decryptResults = await withTaskGroup(of: Result<Data, EncryptionError>.self) { group -> [Result<Data, EncryptionError>] in
            for result in encryptResults {
                guard case let .success(encryptedData) = result else {
                    continue
                }
                group.addTask {
                    return self.encryptionService.decryptData(encryptedData: encryptedData, keyIdentifier: self.testKeyIdentifier)
                }
            }

            var results: [Result<Data, EncryptionError>] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        // Verify all decryptions succeeded and match original data
        XCTAssertEqual(decryptResults.count, dataItems.count, "Number of decryption results should match number of data items")
        XCTAssertTrue(decryptResults.allSatisfy { $0.isSuccess }, "All decryptions should succeed")

        for (index, result) in decryptResults.enumerated() {
            guard case let .success(decryptedData) = result else {
                continue
            }
            XCTAssertEqual(decryptedData, dataItems[index], "Decrypted data should match original data")
        }
    }

    /// Tests the performance of encryption operations
    func testPerformanceEncryption() {
        // Create a large test data sample
        let largeTestData = Data(repeating: 0, count: 1024 * 1024 * 10) // 10MB

        // Measure performance of encryption operation
        measure {
            let encryptResult = self.encryptionService.encryptData(data: largeTestData, keyIdentifier: self.testKeyIdentifier)
            XCTAssertTrue(encryptResult.isSuccess, "Encryption should succeed")
        }
    }

    /// Tests the performance of decryption operations
    func testPerformanceDecryption() {
        // Create and encrypt a large test data sample
        let largeTestData = Data(repeating: 0, count: 1024 * 1024 * 10) // 10MB
        let encryptResult = self.encryptionService.encryptData(data: largeTestData, keyIdentifier: self.testKeyIdentifier)

        guard case let .success(encryptedData) = encryptResult else {
            XCTFail("Encryption failed: \(encryptResult)")
            return
        }

        // Measure performance of decryption operation
        measure {
            let decryptResult = self.encryptionService.decryptData(encryptedData: encryptedData, keyIdentifier: self.testKeyIdentifier)
            XCTAssertTrue(decryptResult.isSuccess, "Decryption should succeed")
        }
    }

    // MARK: - Helper Methods

    /// Helper method to create a temporary file URL
    private func createTemporaryFileURL(filename: String) -> URL {
        // Get the temporary directory URL
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory

        // Append the filename to create a complete URL
        let fileURL = temporaryDirectoryURL.appendingPathComponent(filename)

        // Return the temporary file URL
        return fileURL
    }

    /// Helper method to calculate a SHA-256 checksum for a file
    private func calculateChecksum(fileURL: URL) -> String? {
        // Read the file data from fileURL
        guard let fileData = try? Data(contentsOf: fileURL) else {
            return nil
        }

        // Calculate SHA-256 hash of the data
        let sha256 = SHA256.hash(data: fileData)

        // Convert hash to hexadecimal string
        return sha256.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Extensions

extension Result {
    var isSuccess: Bool {
        guard case .success = self else { return false }
        return true
    }

    var failureValue: Failure? {
        guard case let .failure(value) = self else { return nil }
        return value
    }
}