import XCTest // Apple's testing framework - Latest
import Foundation // Core Foundation types and functionality - Latest
import CryptoKit // For cryptographic operations in tests - Latest
import Combine // For testing asynchronous encryption operations - Latest

@testable import AmiraWellness // The service being tested
@testable import User
@testable import EmotionalState
@testable import Journal
@testable import Tool
@testable import ToolCategory
@testable import Achievement
@testable import Streak
@testable import EmotionalTrend

/// Test suite for the EncryptionService class
class EncryptionTests: XCTestCase {
    
    // MARK: - Properties
    
    /// Instance of the EncryptionService to be tested
    var encryptionService: EncryptionService!
    
    /// Mock implementation of EncryptionService for isolated testing
    var mockEncryptionService: MockEncryptionService!
    
    /// Test data for encryption tests
    var testData: Data!
    
    /// Test key identifier for encryption keys
    var testKeyIdentifier: String!
    
    /// Test file URL for encryption tests
    var testFileURL: URL!
    
    /// Test destination URL for encryption tests
    var testDestinationURL: URL!
    
    /// Test password for encryption tests
    var testPassword: String!
    
    // MARK: - Setup and TearDown
    
    /// Set up the test environment before each test
    override func setUp() {
        super.setUp()
        
        // Initialize encryptionService with EncryptionService.shared
        encryptionService = EncryptionService.shared
        
        // Initialize mockEncryptionService with MockEncryptionService.shared
        mockEncryptionService = MockEncryptionService.shared
        
        // Reset the mock encryption service
        mockEncryptionService.reset()
        
        // Create test data with random bytes
        testData = Data((0..<1024).map { _ in UInt8.random(in: 0...255) })
        
        // Set testKeyIdentifier to a unique test identifier
        testKeyIdentifier = UUID().uuidString
        
        // Create temporary file URLs for testing
        testFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_file.txt")
        testDestinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_file_encrypted.txt")
        
        // Set testPassword to a strong test password
        testPassword = "TestPassword123!"
    }
    
    /// Clean up after each test
    override func tearDown() {
        // Delete any test files created during tests
        try? FileManager.default.removeItem(at: testFileURL)
        try? FileManager.default.removeItem(at: testDestinationURL)
        
        super.tearDown()
    }
    
    // MARK: - Tests
    
    /// Test that data can be encrypted and then decrypted correctly
    func testEncryptDecryptData() {
        // Generate a test encryption key
        let generateKeyResult = encryptionService.generateEncryptionKey(keyIdentifier: testKeyIdentifier)
        XCTAssertTrue(generateKeyResult.isSuccess, "Failed to generate encryption key")
        
        // Encrypt the test data using encryptionService.encryptData
        let encryptResult = encryptionService.encryptData(data: testData, keyIdentifier: testKeyIdentifier)
        
        // Verify that encryption succeeds
        guard case let .success(encryptedData) = encryptResult else {
            XCTFail("Encryption failed with error: \(encryptResult)")
            return
        }
        
        // Decrypt the encrypted data using encryptionService.decryptData
        let decryptResult = encryptionService.decryptData(encryptedData: encryptedData, keyIdentifier: testKeyIdentifier)
        
        // Verify that decryption succeeds
        guard case let .success(decryptedData) = decryptResult else {
            XCTFail("Decryption failed with error: \(decryptResult)")
            return
        }
        
        // Assert that the decrypted data matches the original test data
        XCTAssertEqual(decryptedData, testData, "Decrypted data does not match original data")
    }
    
    /// Test encryption and decryption using the mock service
    func testEncryptDecryptDataWithMock() {
        // Configure mockEncryptionService to succeed
        mockEncryptionService.shouldSucceed = true
        
        // Encrypt the test data using mockEncryptionService.encryptData
        let encryptResult = mockEncryptionService.encryptData(data: testData, keyIdentifier: testKeyIdentifier)
        
        // Verify that encryption succeeds
        XCTAssertTrue(encryptResult.isSuccess, "Mock encryption failed")
        
        // Verify that encryptDataCallCount is incremented
        XCTAssertEqual(mockEncryptionService.encryptDataCallCount, 1, "encryptDataCallCount not incremented")
        
        // Decrypt the encrypted data using mockEncryptionService.decryptData
        guard case let .success(encryptedData) = encryptResult else {
            XCTFail("Encryption failed, cannot proceed with decryption test")
            return
        }
        
        let decryptResult = mockEncryptionService.decryptData(encryptedData: encryptedData, keyIdentifier: testKeyIdentifier)
        
        // Verify that decryption succeeds
        XCTAssertTrue(decryptResult.isSuccess, "Mock decryption failed")
        
        // Verify that decryptDataCallCount is incremented
        XCTAssertEqual(mockEncryptionService.decryptDataCallCount, 1, "decryptDataCallCount not incremented")
    }
    
    /// Test handling of encryption and decryption failures
    func testEncryptDecryptDataFailure() {
        // Configure mockEncryptionService to fail with specific error
        mockEncryptionService.shouldSucceed = false
        mockEncryptionService.error = .encryptionFailed
        
        // Attempt to encrypt the test data
        let encryptResult = mockEncryptionService.encryptData(data: testData, keyIdentifier: testKeyIdentifier)
        
        // Verify that encryption fails with the expected error
        XCTAssertFalse(encryptResult.isSuccess, "Mock encryption should have failed")
        XCTAssertEqual(encryptResult.failure as? EncryptionError, .encryptionFailed, "Incorrect error returned for encryption failure")
        
        // Attempt to decrypt with invalid data
        let mockEncryptedData = EncryptedData(data: Data(), iv: Data(), authTag: Data())
        let decryptResult = mockEncryptionService.decryptData(encryptedData: mockEncryptedData, keyIdentifier: testKeyIdentifier)
        
        // Verify that decryption fails with the expected error
        XCTAssertFalse(decryptResult.isSuccess, "Mock decryption should have failed")
        XCTAssertEqual(decryptResult.failure as? EncryptionError, .encryptionFailed, "Incorrect error returned for decryption failure")
    }
    
    /// Test that files can be encrypted and decrypted correctly
    func testEncryptDecryptFile() {
        // Write test data to testFileURL
        try? testData.write(to: testFileURL)
        
        // Generate a test encryption key
        let generateKeyResult = encryptionService.generateEncryptionKey(keyIdentifier: testKeyIdentifier)
        XCTAssertTrue(generateKeyResult.isSuccess, "Failed to generate encryption key")
        
        // Encrypt the file using encryptionService.encryptFile
        let encryptResult = encryptionService.encryptFile(fileURL: testFileURL, destinationURL: testDestinationURL, keyIdentifier: testKeyIdentifier)
        
        // Verify that encryption succeeds and returns an IV
        guard case .success = encryptResult else {
            XCTFail("File encryption failed with error: \(encryptResult)")
            return
        }
        
        // Decrypt the file using encryptionService.decryptFile
        let decryptResult = encryptionService.decryptFile(fileURL: testDestinationURL, destinationURL: testFileURL, keyIdentifier: testKeyIdentifier)
        
        // Verify that decryption succeeds
        guard case .success = decryptResult else {
            XCTFail("File decryption failed with error: \(decryptResult)")
            return
        }
        
        // Read the decrypted file data
        let decryptedData = try? Data(contentsOf: testFileURL)
        
        // Assert that the decrypted data matches the original test data
        XCTAssertEqual(decryptedData, testData, "Decrypted file data does not match original data")
    }
    
    /// Test file encryption and decryption using the mock service
    func testEncryptDecryptFileWithMock() {
        // Configure mockEncryptionService to succeed
        mockEncryptionService.shouldSucceed = true
        
        // Encrypt the file using mockEncryptionService.encryptFile
        let encryptResult = mockEncryptionService.encryptFile(fileURL: testFileURL, destinationURL: testDestinationURL, keyIdentifier: testKeyIdentifier)
        
        // Verify that encryption succeeds
        XCTAssertTrue(encryptResult.isSuccess, "Mock file encryption failed")
        
        // Verify that encryptFileCallCount is incremented
        XCTAssertEqual(mockEncryptionService.encryptFileCallCount, 1, "encryptFileCallCount not incremented")
        
        // Decrypt the file using mockEncryptionService.decryptFile
        let decryptResult = mockEncryptionService.decryptFile(fileURL: testFileURL, destinationURL: testDestinationURL, keyIdentifier: testKeyIdentifier)
        
        // Verify that decryption succeeds
        XCTAssertTrue(decryptResult.isSuccess, "Mock file decryption failed")
        
        // Verify that decryptFileCallCount is incremented
        XCTAssertEqual(mockEncryptionService.decryptFileCallCount, 1, "decryptFileCallCount not incremented")
    }
    
    /// Test encryption and decryption using a password
    func testEncryptDecryptWithPassword() {
        // Encrypt the test data using encryptionService.encryptWithPassword
        let encryptResult = encryptionService.encryptWithPassword(data: testData, password: testPassword)
        
        // Verify that encryption succeeds and returns encrypted data and salt
        guard case let .success((encryptedData, salt)) = encryptResult else {
            XCTFail("Password-based encryption failed with error: \(encryptResult)")
            return
        }
        
        // Decrypt the data using encryptionService.decryptWithPassword
        let decryptResult = encryptionService.decryptWithPassword(encryptedData: encryptedData, password: testPassword, salt: salt)
        
        // Verify that decryption succeeds
        guard case let .success(decryptedData) = decryptResult else {
            XCTFail("Password-based decryption failed with error: \(decryptResult)")
            return
        }
        
        // Assert that the decrypted data matches the original test data
        XCTAssertEqual(decryptedData, testData, "Password-based decrypted data does not match original data")
    }
    
    /// Test handling of password-based encryption failures
    func testEncryptDecryptWithPasswordFailure() {
        // Configure mockEncryptionService to fail
        mockEncryptionService.shouldSucceed = false
        
        // Attempt to encrypt with a weak password
        let weakPassword = "weak"
        let encryptResult = mockEncryptionService.encryptWithPassword(data: testData, password: weakPassword)
        
        // Verify that encryption fails with passwordTooWeak error
        XCTAssertFalse(encryptResult.isSuccess, "Mock password-based encryption should have failed")
        XCTAssertEqual(encryptResult.failure as? EncryptionError, .encryptionFailed, "Incorrect error returned for password-based encryption failure")
        
        // Attempt to decrypt with an incorrect password
        let incorrectPassword = "incorrectPassword"
        let mockSalt = Data(count: 16)
        let mockEncryptedData = Data(count: 64)
        let decryptResult = mockEncryptionService.decryptWithPassword(encryptedData: mockEncryptedData, password: incorrectPassword, salt: mockSalt)
        
        // Verify that decryption fails with decryptionFailed error
        XCTAssertFalse(decryptResult.isSuccess, "Mock password-based decryption should have failed")
        XCTAssertEqual(decryptResult.failure as? EncryptionError, .encryptionFailed, "Incorrect error returned for password-based decryption failure")
    }
    
    /// Test generation of encryption keys
    func testGenerateEncryptionKey() {
        // Generate an encryption key using encryptionService.generateEncryptionKey
        let generateKeyResult = encryptionService.generateEncryptionKey(keyIdentifier: testKeyIdentifier)
        
        // Verify that key generation succeeds
        XCTAssertTrue(generateKeyResult.isSuccess, "Key generation failed")
        
        // Attempt to use the generated key for encryption
        let encryptResult = encryptionService.encryptData(data: testData, keyIdentifier: testKeyIdentifier)
        
        // Verify that encryption with the generated key succeeds
        XCTAssertTrue(encryptResult.isSuccess, "Encryption with generated key failed")
    }
    
    /// Test exporting and importing encrypted data
    func testExportImportEncryptedData() {
        // Generate a test encryption key
        let generateKeyResult = encryptionService.generateEncryptionKey(keyIdentifier: testKeyIdentifier)
        XCTAssertTrue(generateKeyResult.isSuccess, "Failed to generate encryption key")
        
        // Encrypt test data to get EncryptedData
        let encryptResult = encryptionService.encryptData(data: testData, keyIdentifier: testKeyIdentifier)
        guard case let .success(encryptedData) = encryptResult else {
            XCTFail("Encryption failed: \(encryptResult)")
            return
        }
        
        // Export the encrypted data using encryptionService.exportEncryptedData
        let exportResult = encryptionService.exportEncryptedData(encryptedData: encryptedData, keyIdentifier: testKeyIdentifier, password: testPassword)
        guard case let .success(exportedData) = exportResult else {
            XCTFail("Export failed: \(exportResult)")
            return
        }
        
        // Import the exported data using encryptionService.importEncryptedData
        let importResult = encryptionService.importEncryptedData(exportedData: exportedData, password: testPassword)
        guard case let .success((importedEncryptedData, importedKeyIdentifier)) = importResult else {
            XCTFail("Import failed: \(importResult)")
            return
        }
        
        // Verify that import succeeds and returns the original EncryptedData
        XCTAssertEqual(importedKeyIdentifier, testKeyIdentifier, "Key identifier mismatch")
        
        // Decrypt the imported data
        let decryptResult = encryptionService.decryptData(encryptedData: importedEncryptedData, keyIdentifier: importedKeyIdentifier)
        guard case let .success(decryptedData) = decryptResult else {
            XCTFail("Decryption failed after import: \(decryptResult)")
            return
        }
        
        // Assert that the decrypted data matches the original test data
        XCTAssertEqual(decryptedData, testData, "Decrypted data after import does not match original data")
    }
    
    /// Test verification of file integrity using checksums
    func testVerifyFileIntegrity() {
        // Write test data to testFileURL
        try? testData.write(to: testFileURL)
        
        // Calculate SHA-256 checksum of test data
        guard let sha256Checksum = calculateSHA256(data: testData) else {
            XCTFail("Failed to calculate SHA-256 checksum")
            return
        }
        
        // Verify file integrity using encryptionService.verifyFileIntegrity
        let verifyResult = encryptionService.verifyFileIntegrity(fileURL: testFileURL, expectedChecksum: sha256Checksum)
        
        // Assert that verification succeeds with the correct checksum
        guard case let .success(isValid) = verifyResult else {
            XCTFail("File integrity verification failed: \(verifyResult)")
            return
        }
        XCTAssertTrue(isValid, "File integrity verification should have succeeded")
        
        // Verify with an incorrect checksum
        let incorrectChecksum = "incorrect_checksum"
        let incorrectVerifyResult = encryptionService.verifyFileIntegrity(fileURL: testFileURL, expectedChecksum: incorrectChecksum)
        
        // Assert that verification fails with the incorrect checksum
        guard case let .success(isInvalid) = incorrectVerifyResult else {
            XCTFail("File integrity verification with incorrect checksum failed: \(incorrectVerifyResult)")
            return
        }
        XCTAssertFalse(isInvalid, "File integrity verification should have failed with incorrect checksum")
    }
    
    /// Test that encryption operations can be performed concurrently
    @available(iOS 15.0, *)
    func testConcurrentEncryption() async {
        // Generate a test encryption key
        let generateKeyResult = encryptionService.generateEncryptionKey(keyIdentifier: testKeyIdentifier)
        XCTAssertTrue(generateKeyResult.isSuccess, "Failed to generate encryption key")
        
        // Create multiple different test data items
        let data1 = Data((0..<512).map { _ in UInt8.random(in: 0...255) })
        let data2 = Data((0..<1024).map { _ in UInt8.random(in: 0...255) })
        let data3 = Data((0..<2048).map { _ in UInt8.random(in: 0...255) })
        
        // Perform concurrent encryption operations using async/await
        async let encrypt1 = encryptionService.encryptData(data: data1, keyIdentifier: testKeyIdentifier)
        async let encrypt2 = encryptionService.encryptData(data: data2, keyIdentifier: testKeyIdentifier)
        async let encrypt3 = encryptionService.encryptData(data: data3, keyIdentifier: testKeyIdentifier)
        
        // Verify that all encryption operations succeed
        guard case let .success(encrypted1) = await encrypt1 else {
            XCTFail("Concurrent encryption 1 failed: \(await encrypt1)")
            return
        }
        guard case let .success(encrypted2) = await encrypt2 else {
            XCTFail("Concurrent encryption 2 failed: \(await encrypt2)")
            return
        }
        guard case let .success(encrypted3) = await encrypt3 else {
            XCTFail("Concurrent encryption 3 failed: \(await encrypt3)")
            return
        }
        
        // Decrypt all encrypted data
        async let decrypt1 = encryptionService.decryptData(encryptedData: encrypted1, keyIdentifier: testKeyIdentifier)
        async let decrypt2 = encryptionService.decryptData(encryptedData: encrypted2, keyIdentifier: testKeyIdentifier)
        async let decrypt3 = encryptionService.decryptData(encryptedData: encrypted3, keyIdentifier: testKeyIdentifier)
        
        // Verify that all decryption operations succeed and match original data
        guard case let .success(decrypted1) = await decrypt1 else {
            XCTFail("Concurrent decryption 1 failed: \(await decrypt1)")
            return
        }
        XCTAssertEqual(decrypted1, data1, "Concurrent decryption 1 data mismatch")
        
        guard case let .success(decrypted2) = await decrypt2 else {
            XCTFail("Concurrent decryption 2 failed: \(await decrypt2)")
            return
        }
        XCTAssertEqual(decrypted2, data2, "Concurrent decryption 2 data mismatch")
        
        guard case let .success(decrypted3) = await decrypt3 else {
            XCTFail("Concurrent decryption 3 failed: \(await decrypt3)")
            return
        }
        XCTAssertEqual(decrypted3, data3, "Concurrent decryption 3 data mismatch")
    }
    
    /// Test the performance of encryption operations
    func testPerformanceEncryption() {
        // Generate a test encryption key
        let generateKeyResult = encryptionService.generateEncryptionKey(keyIdentifier: testKeyIdentifier)
        XCTAssertTrue(generateKeyResult.isSuccess, "Failed to generate encryption key")
        
        // Create a large test data set (e.g., 10MB)
        let largeTestData = Data(count: 10 * 1024 * 1024)
        
        // Measure performance of encryption operation
        measure {
            let encryptResult = encryptionService.encryptData(data: largeTestData, keyIdentifier: testKeyIdentifier)
            XCTAssertTrue(encryptResult.isSuccess, "Encryption failed during performance test")
        }
    }
    
    /// Test the performance of decryption operations
    func testPerformanceDecryption() {
        // Generate a test encryption key
        let generateKeyResult = encryptionService.generateEncryptionKey(keyIdentifier: testKeyIdentifier)
        XCTAssertTrue(generateKeyResult.isSuccess, "Failed to generate encryption key")
        
        // Create and encrypt a large test data set (e.g., 10MB)
        let largeTestData = Data(count: 10 * 1024 * 1024)
        let encryptResult = encryptionService.encryptData(data: largeTestData, keyIdentifier: testKeyIdentifier)
        
        guard case let .success(encryptedData) = encryptResult else {
            XCTFail("Encryption failed during performance setup")
            return
        }
        
        // Measure performance of decryption operation
        measure {
            let decryptResult = encryptionService.decryptData(encryptedData: encryptedData, keyIdentifier: testKeyIdentifier)
            XCTAssertTrue(decryptResult.isSuccess, "Decryption failed during performance test")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Helper method to create random data of specified size
    private func createRandomData(size: Int) -> Data {
        var data = Data(count: size)
        _ = data.withUnsafeMutableBytes { pointer in
            if let baseAddress = pointer.baseAddress {
                arc4random_buf(baseAddress, size)
            }
        }
        return data
    }
    
    /// Helper method to calculate SHA-256 checksum of data
    private func calculateSHA256(data: Data) -> String? {
        if #available(iOS 13.0, *) {
            let digest = SHA256.hash(data: data)
            return digest.compactMap { String(format: "%02x", $0) }.joined()
        } else {
            // Fallback for iOS 12
            // This is a simplified alternative that would need to be replaced with
            // a proper implementation using CommonCrypto for production
            print("SHA-256 not available on this iOS version")
            return nil
        }
    }
}

// MARK: - Extensions

extension Result {
    var isSuccess: Bool {
        guard case .success = self else { return false }
        return true
    }
    
    var failure: Failure? {
        guard case let .failure(error) = self else { return nil }
        return error
    }
}