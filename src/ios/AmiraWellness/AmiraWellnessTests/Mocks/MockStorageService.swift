//
//  MockStorageService.swift
//  AmiraWellnessTests
//
//  Created for Amira Wellness
//

import Foundation // Latest
import Combine // Latest

@testable import AmiraWellness

/// A mock implementation of the StorageService for unit testing purposes
class MockStorageService {
    
    // MARK: - Shared Instance
    
    /// Shared instance of the MockStorageService
    static let shared = MockStorageService()
    
    // MARK: - Mock Properties
    
    /// Dictionary to store mock data
    var mockStorage: [String: Any] = [:]
    
    /// Dictionary to store mock file URLs
    var mockFileURLs: [String: URL] = [:]
    
    /// Dictionary to store predefined mock results for operations
    var mockResults: [String: Result<Any, StorageError>] = [:]
    
    /// Dictionary to store predefined mock file results
    var mockFileResults: [String: Result<URL, StorageError>] = [:]
    
    /// Dictionary to track operation counts by storage key
    var operationCount: [String: Int] = [:]
    
    /// Flag to simulate errors
    var shouldSimulateError: Bool = false
    
    /// The error to simulate when shouldSimulateError is true
    var simulatedError: StorageError = .storageNotAvailable
    
    /// Flag to simulate storage availability
    var isStorageAvailable: Bool = true
    
    /// Logger instance
    private let logger = Logger.shared
    
    // MARK: - Initialization
    
    /// Initializes the MockStorageService with default values
    init() {
        reset()
    }
    
    // MARK: - Mock Control Methods
    
    /// Resets all mock storage and counters
    func reset() {
        mockStorage = [:]
        mockFileURLs = [:]
        mockResults = [:]
        mockFileResults = [:]
        operationCount = [:]
        shouldSimulateError = false
        simulatedError = .storageNotAvailable
        isStorageAvailable = true
    }
    
    /// Sets mock data for a specific key and data type
    func setMockData(_ data: Any, forKey key: String, dataType: StorageDataType) {
        let storageKey = getStorageKey(key: key, dataType: dataType)
        mockStorage[storageKey] = data
        operationCount[storageKey] = operationCount[storageKey] ?? 0
    }
    
    /// Sets a mock result for a specific key and data type
    func setMockResult<T>(_ result: Result<T, StorageError>, forKey key: String, dataType: StorageDataType) {
        let storageKey = getStorageKey(key: key, dataType: dataType)
        // We need to cast the generic result to store it in our dictionary
        mockResults[storageKey] = result.map { $0 as Any }
        operationCount[storageKey] = operationCount[storageKey] ?? 0
    }
    
    /// Sets a mock file URL for a specific file name and data type
    func setMockFileURL(_ fileURL: URL, fileName: String, dataType: StorageDataType) {
        let storageKey = getStorageKey(key: fileName, dataType: dataType)
        mockFileURLs[storageKey] = fileURL
        operationCount[storageKey] = operationCount[storageKey] ?? 0
    }
    
    /// Sets a mock file result for a specific file name and data type
    func setMockFileResult(_ result: Result<URL, StorageError>, fileName: String, dataType: StorageDataType) {
        let storageKey = getStorageKey(key: fileName, dataType: dataType)
        mockFileResults[storageKey] = result
        operationCount[storageKey] = operationCount[storageKey] ?? 0
    }
    
    /// Configures the mock to simulate a specific error
    func simulateError(_ error: StorageError) {
        shouldSimulateError = true
        simulatedError = error
    }
    
    /// Stops the mock from simulating errors
    func stopSimulatingError() {
        shouldSimulateError = false
    }
    
    /// Sets whether storage should be considered available
    func setStorageAvailability(_ available: Bool) {
        isStorageAvailable = available
    }
    
    /// Gets the number of operations performed for a specific key and data type
    func getOperationCount(forKey key: String, dataType: StorageDataType) -> Int {
        let storageKey = getStorageKey(key: key, dataType: dataType)
        return operationCount[storageKey] ?? 0
    }
    
    // MARK: - StorageService Interface Implementation
    
    /// Mock implementation of storeCodable method
    func storeCodable<T: Codable>(_ data: T, forKey key: String, dataType: StorageDataType, sensitivity: StorageSensitivity = .nonsensitive) -> Result<Void, StorageError> {
        let storageKey = getStorageKey(key: key, dataType: dataType)
        operationCount[storageKey] = (operationCount[storageKey] ?? 0) + 1
        
        // Check if storage is available
        guard isStorageAvailable else {
            return .failure(.storageNotAvailable)
        }
        
        // Check if we should simulate an error
        if shouldSimulateError {
            return .failure(simulatedError)
        }
        
        // Check if we have a predefined result for this key
        if let mockResult = mockResults[storageKey] {
            return mockResult.map { _ in () }
        }
        
        // If no predefined result, store the data
        mockStorage[storageKey] = data
        return .success(())
    }
    
    /// Mock implementation of retrieveCodable method
    func retrieveCodable<T: Codable>(forKey key: String, dataType: StorageDataType, sensitivity: StorageSensitivity = .nonsensitive) -> Result<T, StorageError> {
        let storageKey = getStorageKey(key: key, dataType: dataType)
        operationCount[storageKey] = (operationCount[storageKey] ?? 0) + 1
        
        // Check if storage is available
        guard isStorageAvailable else {
            return .failure(.storageNotAvailable)
        }
        
        // Check if we should simulate an error
        if shouldSimulateError {
            return .failure(simulatedError)
        }
        
        // Check if we have a predefined result for this key
        if let mockResult = mockResults[storageKey] {
            switch mockResult {
            case .success(let value):
                if let typedValue = value as? T {
                    return .success(typedValue)
                } else {
                    return .failure(.dataConversionFailed)
                }
            case .failure(let error):
                return .failure(error)
            }
        }
        
        // If no predefined result, check if we have data for this key
        if let data = mockStorage[storageKey] {
            if let typedData = data as? T {
                return .success(typedData)
            } else {
                return .failure(.dataConversionFailed)
            }
        }
        
        return .failure(.fileNotFound)
    }
    
    /// Mock implementation of storeFile method
    func storeFile(fileURL: URL, fileName: String, dataType: StorageDataType, sensitivity: StorageSensitivity = .nonsensitive) -> Result<URL, StorageError> {
        let storageKey = getStorageKey(key: fileName, dataType: dataType)
        operationCount[storageKey] = (operationCount[storageKey] ?? 0) + 1
        
        // Check if storage is available
        guard isStorageAvailable else {
            return .failure(.storageNotAvailable)
        }
        
        // Check if we should simulate an error
        if shouldSimulateError {
            return .failure(simulatedError)
        }
        
        // Check if we have a predefined result for this key
        if let mockResult = mockFileResults[storageKey] {
            return mockResult
        }
        
        // If no predefined result, create a mock destination URL
        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        
        // Store the mock URL
        mockFileURLs[storageKey] = destinationURL
        
        return .success(destinationURL)
    }
    
    /// Mock implementation of retrieveFileURL method
    func retrieveFileURL(fileName: String, dataType: StorageDataType, sensitivity: StorageSensitivity = .nonsensitive) -> Result<URL, StorageError> {
        let storageKey = getStorageKey(key: fileName, dataType: dataType)
        operationCount[storageKey] = (operationCount[storageKey] ?? 0) + 1
        
        // Check if storage is available
        guard isStorageAvailable else {
            return .failure(.storageNotAvailable)
        }
        
        // Check if we should simulate an error
        if shouldSimulateError {
            return .failure(simulatedError)
        }
        
        // Check if we have a predefined result for this key
        if let mockResult = mockFileResults[storageKey] {
            return mockResult
        }
        
        // If no predefined result, check if we have a URL for this key
        if let fileURL = mockFileURLs[storageKey] {
            return .success(fileURL)
        }
        
        return .failure(.fileNotFound)
    }
    
    /// Mock implementation of deleteData method
    func deleteData(forKey key: String, dataType: StorageDataType, sensitivity: StorageSensitivity = .nonsensitive) -> Result<Void, StorageError> {
        let storageKey = getStorageKey(key: key, dataType: dataType)
        operationCount[storageKey] = (operationCount[storageKey] ?? 0) + 1
        
        // Check if storage is available
        guard isStorageAvailable else {
            return .failure(.storageNotAvailable)
        }
        
        // Check if we should simulate an error
        if shouldSimulateError {
            return .failure(simulatedError)
        }
        
        // Check if we have a predefined result for this key
        if let mockResult = mockResults[storageKey] {
            return mockResult.map { _ in () }
        }
        
        // Remove data from mockStorage dictionary for this storage key
        mockStorage.removeValue(forKey: storageKey)
        mockFileURLs.removeValue(forKey: storageKey)
        
        return .success(())
    }
    
    /// Mock implementation of clearStorage method
    func clearStorage(dataType: StorageDataType) -> Result<Void, StorageError> {
        let prefix = "\(dataType)_"
        operationCount[String(describing: dataType)] = (operationCount[String(describing: dataType)] ?? 0) + 1
        
        // Check if storage is available
        guard isStorageAvailable else {
            return .failure(.storageNotAvailable)
        }
        
        // Check if we should simulate an error
        if shouldSimulateError {
            return .failure(simulatedError)
        }
        
        // Remove all entries from mockStorage that start with the prefix
        mockStorage = mockStorage.filter { !$0.key.hasPrefix(prefix) }
        mockFileURLs = mockFileURLs.filter { !$0.key.hasPrefix(prefix) }
        
        return .success(())
    }
    
    /// Mock implementation of getAudioFileURL method
    func getAudioFileURL(fileName: String) -> URL {
        let storageKey = getStorageKey(key: fileName, dataType: .audio)
        operationCount[storageKey] = (operationCount[storageKey] ?? 0) + 1
        
        // Check if there's a mock file URL for this storage key
        if let fileURL = mockFileURLs[storageKey] {
            return fileURL
        }
        
        // Create a mock URL for the audio file
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Audio").appendingPathComponent(fileName)
        mockFileURLs[storageKey] = fileURL
        
        return fileURL
    }
    
    /// Mock implementation of getImageFileURL method
    func getImageFileURL(fileName: String) -> URL {
        let storageKey = getStorageKey(key: fileName, dataType: .images)
        operationCount[storageKey] = (operationCount[storageKey] ?? 0) + 1
        
        // Check if there's a mock file URL for this storage key
        if let fileURL = mockFileURLs[storageKey] {
            return fileURL
        }
        
        // Create a mock URL for the image file
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Images").appendingPathComponent(fileName)
        mockFileURLs[storageKey] = fileURL
        
        return fileURL
    }
    
    /// Mock implementation of getCacheFileURL method
    func getCacheFileURL(fileName: String) -> URL {
        let storageKey = getStorageKey(key: fileName, dataType: .cache)
        operationCount[storageKey] = (operationCount[storageKey] ?? 0) + 1
        
        // Check if there's a mock file URL for this storage key
        if let fileURL = mockFileURLs[storageKey] {
            return fileURL
        }
        
        // Create a mock URL for the cache file
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Cache").appendingPathComponent(fileName)
        mockFileURLs[storageKey] = fileURL
        
        return fileURL
    }
    
    /// Mock implementation of fileExists method
    func fileExists(atPath fileURL: URL) -> Bool {
        // Check if the fileURL exists in any of the values in mockFileURLs
        return mockFileURLs.values.contains(fileURL)
    }
    
    // MARK: - Private Helper Methods
    
    /// Helper method to generate a consistent storage key
    private func getStorageKey(key: String, dataType: StorageDataType) -> String {
        // Combine dataType and key to create a unique storage key
        return "\(dataType)_\(key)"
    }
}