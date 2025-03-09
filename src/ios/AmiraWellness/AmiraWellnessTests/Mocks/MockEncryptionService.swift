//
//  MockEncryptionService.swift
//  AmiraWellnessTests
//
//  Created for Amira Wellness
//

import Foundation // Latest
import Combine // Latest

/// A mock implementation of EncryptionService for testing purposes
class MockEncryptionService {
    
    // MARK: - Singleton
    
    /// Shared instance of the MockEncryptionService
    static let shared = MockEncryptionService()
    
    // MARK: - Control Properties
    
    /// Controls whether operations succeed or fail
    var shouldSucceed: Bool = true
    
    /// The error to return when shouldSucceed is false
    var error: EncryptionError = .encryptionFailed
    
    /// Mock data to return for successful operations
    var mockEncryptedData: Data = Data(repeating: 0, count: 64)
    var mockDecryptedData: Data = Data(repeating: 1, count: 64)
    var mockIV: String = "0123456789abcdef"
    
    /// Storage for tracking encrypted data
    var encryptedDataStore: [String: Data] = [:]
    var encryptedFileStore: [String: String] = [:]
    
    // MARK: - Call Counters
    
    var encryptDataCallCount: Int = 0
    var decryptDataCallCount: Int = 0
    var encryptFileCallCount: Int = 0
    var decryptFileCallCount: Int = 0
    var encryptWithPasswordCallCount: Int = 0
    var decryptWithPasswordCallCount: Int = 0
    var generateEncryptionKeyCallCount: Int = 0
    var exportEncryptedDataCallCount: Int = 0
    var importEncryptedDataCallCount: Int = 0
    var verifyFileIntegrityCallCount: Int = 0
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private init() {
        shouldSucceed = true
        error = .encryptionFailed
        mockEncryptedData = Data(repeating: 0, count: 64)
        mockDecryptedData = Data(repeating: 1, count: 64)
        mockIV = "0123456789abcdef"
        encryptedDataStore = [:]
        encryptedFileStore = [:]
        
        encryptDataCallCount = 0
        decryptDataCallCount = 0
        encryptFileCallCount = 0
        decryptFileCallCount = 0
        encryptWithPasswordCallCount = 0
        decryptWithPasswordCallCount = 0
        generateEncryptionKeyCallCount = 0
        exportEncryptedDataCallCount = 0
        importEncryptedDataCallCount = 0
        verifyFileIntegrityCallCount = 0
    }
    
    // MARK: - Public Methods
    
    /// Resets the mock to its default state
    func reset() {
        shouldSucceed = true
        error = .encryptionFailed
        encryptedDataStore = [:]
        encryptedFileStore = [:]
        
        encryptDataCallCount = 0
        decryptDataCallCount = 0
        encryptFileCallCount = 0
        decryptFileCallCount = 0
        encryptWithPasswordCallCount = 0
        decryptWithPasswordCallCount = 0
        generateEncryptionKeyCallCount = 0
        exportEncryptedDataCallCount = 0
        importEncryptedDataCallCount = 0
        verifyFileIntegrityCallCount = 0
    }
    
    /// Mock implementation of encryptData
    func encryptData(data: Data, keyIdentifier: String) -> Result<EncryptedData, EncryptionError> {
        encryptDataCallCount += 1
        
        if shouldSucceed {
            // Store the data for potential later retrieval
            encryptedDataStore[keyIdentifier] = data
            
            // Create a mock EncryptedData
            let encryptedData = createMockEncryptedData(originalData: data)
            return .success(encryptedData)
        } else {
            return .failure(error)
        }
    }
    
    /// Mock implementation of decryptData
    func decryptData(encryptedData: EncryptedData, keyIdentifier: String) -> Result<Data, EncryptionError> {
        decryptDataCallCount += 1
        
        if shouldSucceed {
            // If we have stored data for this key, return it
            if let storedData = encryptedDataStore[keyIdentifier] {
                return .success(storedData)
            }
            // Otherwise return the mock data
            return .success(mockDecryptedData)
        } else {
            return .failure(error)
        }
    }
    
    /// Mock implementation of encryptFile
    func encryptFile(fileURL: URL, destinationURL: URL, keyIdentifier: String) -> Result<String, EncryptionError> {
        encryptFileCallCount += 1
        
        if shouldSucceed {
            // Store the file path for potential later retrieval
            encryptedFileStore[keyIdentifier] = fileURL.path
            return .success(mockIV)
        } else {
            return .failure(error)
        }
    }
    
    /// Mock implementation of decryptFile
    func decryptFile(fileURL: URL, destinationURL: URL, keyIdentifier: String, iv: String = "") -> Result<Void, EncryptionError> {
        decryptFileCallCount += 1
        
        if shouldSucceed {
            return .success(())
        } else {
            return .failure(error)
        }
    }
    
    /// Mock implementation of encryptWithPassword
    func encryptWithPassword(data: Data, password: String) -> Result<(encryptedData: Data, salt: Data), EncryptionError> {
        encryptWithPasswordCallCount += 1
        
        if shouldSucceed {
            // Create mock salt
            let salt = createRandomData(length: 16)
            return .success((encryptedData: mockEncryptedData, salt: salt))
        } else {
            return .failure(error)
        }
    }
    
    /// Mock implementation of decryptWithPassword
    func decryptWithPassword(encryptedData: Data, password: String, salt: Data) -> Result<Data, EncryptionError> {
        decryptWithPasswordCallCount += 1
        
        if shouldSucceed {
            return .success(mockDecryptedData)
        } else {
            return .failure(error)
        }
    }
    
    /// Mock implementation of generateEncryptionKey
    func generateEncryptionKey(keyIdentifier: String, useBiometricProtection: Bool = false) -> Result<Void, EncryptionError> {
        generateEncryptionKeyCallCount += 1
        
        if shouldSucceed {
            return .success(())
        } else {
            return .failure(error)
        }
    }
    
    /// Mock implementation of exportEncryptedData
    func exportEncryptedData(encryptedData: EncryptedData, keyIdentifier: String, password: String) -> Result<Data, EncryptionError> {
        exportEncryptedDataCallCount += 1
        
        if shouldSucceed {
            return .success(mockEncryptedData)
        } else {
            return .failure(error)
        }
    }
    
    /// Mock implementation of importEncryptedData
    func importEncryptedData(exportedData: Data, password: String) -> Result<(encryptedData: EncryptedData, keyIdentifier: String), EncryptionError> {
        importEncryptedDataCallCount += 1
        
        if shouldSucceed {
            // Create a mock EncryptedData
            let encryptedData = createMockEncryptedData(originalData: mockDecryptedData)
            return .success((encryptedData: encryptedData, keyIdentifier: "test-key"))
        } else {
            return .failure(error)
        }
    }
    
    /// Mock implementation of verifyFileIntegrity
    func verifyFileIntegrity(fileURL: URL, expectedChecksum: String) -> Result<Bool, EncryptionError> {
        verifyFileIntegrityCallCount += 1
        
        if shouldSucceed {
            return .success(true)
        } else {
            return .failure(error)
        }
    }
    
    // MARK: - Private Methods
    
    /// Helper method to create mock encrypted data
    private func createMockEncryptedData(originalData: Data) -> EncryptedData {
        // Create mock IV and auth tag
        let iv = createRandomData(length: 12) // Standard for AES-GCM
        let authTag = createRandomData(length: 16) // Standard for AES-GCM
        
        return EncryptedData(data: originalData, iv: iv, authTag: authTag)
    }
    
    /// Helper method to create random data of specified length
    private func createRandomData(length: Int) -> Data {
        var data = Data(count: length)
        _ = data.withUnsafeMutableBytes { pointer in
            if let baseAddress = pointer.baseAddress {
                arc4random_buf(baseAddress, length)
            }
        }
        return data
    }
}