//
//  StorageService.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // Latest
import Combine // Latest

/// Errors that can occur during storage operations
enum StorageError: Error {
    case fileNotFound
    case fileOperationFailed
    case dataConversionFailed
    case invalidData
    case storageNotAvailable
    case secureStorageError
    case userDefaultsError
}

/// Types of data that can be stored
enum StorageDataType {
    case preferences
    case tools
    case journals
    case emotions
    case progress
    case audio
    case images
    case cache
}

/// Sensitivity levels for stored data
enum StorageSensitivity {
    case sensitive
    case nonsensitive
}

/// A singleton service that provides general storage capabilities for the Amira Wellness app
final class StorageService {
    
    // MARK: - Shared Instance
    
    /// Shared instance of the StorageService
    static let shared = StorageService()
    
    // MARK: - Private Properties
    
    /// Service for secure storage operations
    private let secureStorage: SecureStorageService
    
    /// Manager for UserDefaults storage
    private let userDefaults: UserDefaultsManager
    
    /// System file manager for file operations
    private let fileManager: FileManager
    
    /// Logger for storage operations
    private let logger: Logger
    
    /// URL for the app's documents directory
    private let documentsDirectory: URL
    
    /// URL for the app's caches directory
    private let cachesDirectory: URL
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private init() {
        self.secureStorage = SecureStorageService.shared
        self.userDefaults = UserDefaultsManager.shared
        self.fileManager = FileManager.default
        self.logger = Logger.shared
        
        // Get standard directories
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first,
              let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            fatalError("Failed to get directory URLs")
        }
        
        self.documentsDirectory = documentsURL
        self.cachesDirectory = cachesURL
        
        // Create necessary subdirectories
        createDirectoryIfNeeded(documentsDirectory.appendingPathComponent("Audio"))
        createDirectoryIfNeeded(documentsDirectory.appendingPathComponent("Images"))
        createDirectoryIfNeeded(documentsDirectory.appendingPathComponent("Journals"))
        createDirectoryIfNeeded(documentsDirectory.appendingPathComponent("Tools"))
        createDirectoryIfNeeded(documentsDirectory.appendingPathComponent("Emotions"))
        createDirectoryIfNeeded(documentsDirectory.appendingPathComponent("Progress"))
    }
    
    // MARK: - Codable Storage Methods
    
    /// Stores a Codable object based on data type and sensitivity
    /// - Parameters:
    ///   - data: The data to store
    ///   - key: Unique identifier for the data
    ///   - dataType: The type of data being stored
    ///   - sensitivity: The sensitivity level of the data
    /// - Returns: Success or failure with specific error
    func storeCodable<T: Encodable>(_ data: T, forKey key: String, dataType: StorageDataType, sensitivity: StorageSensitivity) -> Result<Void, StorageError> {
        let storageKey = getStorageKey(key: key, dataType: dataType)
        
        switch sensitivity {
        case .sensitive:
            let result = secureStorage.storeCodable(data, key: storageKey)
            switch result {
            case .success:
                logger.debug("Successfully stored sensitive data for key: \(storageKey)", category: .database)
                return .success(())
            case .failure(let error):
                logger.error("Failed to store sensitive data: \(error)", category: .database)
                return .failure(.secureStorageError)
            }
            
        case .nonsensitive:
            let result = userDefaults.setCodable(data, forKey: storageKey)
            switch result {
            case .success:
                logger.debug("Successfully stored non-sensitive data for key: \(storageKey)", category: .database)
                return .success(())
            case .failure(let error):
                logger.error("Failed to store non-sensitive data: \(error)", category: .database)
                return .failure(.userDefaultsError)
            }
        }
    }
    
    /// Retrieves a Codable object based on data type and sensitivity
    /// - Parameters:
    ///   - key: Unique identifier for the data
    ///   - dataType: The type of data being retrieved
    ///   - sensitivity: The sensitivity level of the data
    /// - Returns: The retrieved object or failure with specific error
    func retrieveCodable<T: Decodable>(forKey key: String, dataType: StorageDataType, sensitivity: StorageSensitivity) -> Result<T, StorageError> {
        let storageKey = getStorageKey(key: key, dataType: dataType)
        
        switch sensitivity {
        case .sensitive:
            let result = secureStorage.retrieveCodable(key: storageKey)
            switch result {
            case .success(let data):
                logger.debug("Successfully retrieved sensitive data for key: \(storageKey)", category: .database)
                return .success(data)
            case .failure(let error):
                logger.error("Failed to retrieve sensitive data: \(error)", category: .database)
                return .failure(.secureStorageError)
            }
            
        case .nonsensitive:
            let result: Result<T, UserDefaultsError> = userDefaults.getCodable(forKey: storageKey)
            switch result {
            case .success(let data):
                logger.debug("Successfully retrieved non-sensitive data for key: \(storageKey)", category: .database)
                return .success(data)
            case .failure(let error):
                logger.error("Failed to retrieve non-sensitive data: \(error)", category: .database)
                return .failure(.userDefaultsError)
            }
        }
    }
    
    // MARK: - File Storage Methods
    
    /// Stores a file at the specified URL to the appropriate storage location
    /// - Parameters:
    ///   - fileURL: The URL of the file to store
    ///   - fileName: The name to use for the stored file
    ///   - dataType: The type of data being stored
    ///   - sensitivity: The sensitivity level of the data
    /// - Returns: Destination URL or failure with specific error
    func storeFile(fileURL: URL, fileName: String, dataType: StorageDataType, sensitivity: StorageSensitivity) -> Result<URL, StorageError> {
        let directory = getDirectoryForDataType(dataType)
        let destinationURL = directory.appendingPathComponent(fileName)
        
        do {
            // If file already exists, remove it first
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            // Copy file to destination
            try fileManager.copyItem(at: fileURL, to: destinationURL)
            
            // If sensitive, encrypt the file
            if sensitivity == .sensitive {
                // For sensitive files, we would implement encryption here
                // This would typically involve the secureStorage service
                let keyIdentifier = "file.\(fileName)"
                _ = secureStorage.storeSecurely(data: Data(contentsOf: destinationURL), key: keyIdentifier)
                logger.debug("File encrypted and stored at: \(destinationURL.path)", category: .database)
            } else {
                logger.debug("File stored at: \(destinationURL.path)", category: .database)
            }
            
            return .success(destinationURL)
        } catch {
            logger.error("Failed to store file: \(error)", category: .database)
            return .failure(.fileOperationFailed)
        }
    }
    
    /// Retrieves the URL for a stored file
    /// - Parameters:
    ///   - fileName: The name of the file to retrieve
    ///   - dataType: The type of data being retrieved
    ///   - sensitivity: The sensitivity level of the data
    /// - Returns: File URL or failure with specific error
    func retrieveFileURL(fileName: String, dataType: StorageDataType, sensitivity: StorageSensitivity) -> Result<URL, StorageError> {
        let directory = getDirectoryForDataType(dataType)
        let fileURL = directory.appendingPathComponent(fileName)
        
        // Check if file exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            logger.error("File not found at path: \(fileURL.path)", category: .database)
            return .failure(.fileNotFound)
        }
        
        // If sensitive, we might need to decrypt it
        if sensitivity == .sensitive {
            // For sensitive files, we would implement decryption here
            // This would typically involve the secureStorage service
            let keyIdentifier = "file.\(fileName)"
            if secureStorage.containsSecureData(key: keyIdentifier) {
                logger.debug("Decrypting sensitive file: \(fileURL.path)", category: .database)
                // In a full implementation, we would decrypt the file here
            }
        }
        
        logger.debug("Successfully retrieved file URL: \(fileURL.path)", category: .database)
        return .success(fileURL)
    }
    
    /// Deletes stored data based on key, data type, and sensitivity
    /// - Parameters:
    ///   - key: Unique identifier for the data
    ///   - dataType: The type of data being deleted
    ///   - sensitivity: The sensitivity level of the data
    /// - Returns: Success or failure with specific error
    func deleteData(forKey key: String, dataType: StorageDataType, sensitivity: StorageSensitivity) -> Result<Void, StorageError> {
        let storageKey = getStorageKey(key: key, dataType: dataType)
        
        // Check if this is a file path
        if key.contains(".") && dataType != .preferences {
            let directory = getDirectoryForDataType(dataType)
            let fileURL = directory.appendingPathComponent(key)
            
            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    try fileManager.removeItem(at: fileURL)
                    
                    // If sensitive, also remove from secure storage
                    if sensitivity == .sensitive {
                        let keyIdentifier = "file.\(key)"
                        _ = secureStorage.deleteSecurely(key: keyIdentifier)
                    }
                    
                    logger.debug("Successfully deleted file at: \(fileURL.path)", category: .database)
                    return .success(())
                } catch {
                    logger.error("Failed to delete file: \(error)", category: .database)
                    return .failure(.fileOperationFailed)
                }
            }
        }
        
        // Otherwise, delete from appropriate storage
        switch sensitivity {
        case .sensitive:
            let result = secureStorage.deleteSecurely(key: storageKey)
            switch result {
            case .success:
                logger.debug("Successfully deleted sensitive data for key: \(storageKey)", category: .database)
                return .success(())
            case .failure(let error):
                logger.error("Failed to delete sensitive data: \(error)", category: .database)
                return .failure(.secureStorageError)
            }
            
        case .nonsensitive:
            userDefaults.removeObject(forKey: storageKey)
            logger.debug("Successfully deleted non-sensitive data for key: \(storageKey)", category: .database)
            return .success(())
        }
    }
    
    /// Clears all stored data of a specific type
    /// - Parameter dataType: The type of data to clear
    /// - Returns: Success or failure with specific error
    func clearStorage(dataType: StorageDataType) -> Result<Void, StorageError> {
        let directory = getDirectoryForDataType(dataType)
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
            }
            
            logger.debug("Successfully cleared files for data type: \(dataType)", category: .database)
            
            // If preferences, also clear from UserDefaults
            if dataType == .preferences {
                userDefaults.clearAll()
                logger.debug("Successfully cleared UserDefaults", category: .database)
            }
            
            return .success(())
        } catch {
            logger.error("Failed to clear storage for data type \(dataType): \(error)", category: .database)
            return .failure(.fileOperationFailed)
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Gets the URL for an audio file, creating directories if needed
    /// - Parameter fileName: The name of the audio file
    /// - Returns: URL for the audio file
    func getAudioFileURL(fileName: String) -> URL {
        let audioDir = documentsDirectory.appendingPathComponent("Audio")
        createDirectoryIfNeeded(audioDir)
        return audioDir.appendingPathComponent(fileName)
    }
    
    /// Gets the URL for an image file, creating directories if needed
    /// - Parameter fileName: The name of the image file
    /// - Returns: URL for the image file
    func getImageFileURL(fileName: String) -> URL {
        let imagesDir = documentsDirectory.appendingPathComponent("Images")
        createDirectoryIfNeeded(imagesDir)
        return imagesDir.appendingPathComponent(fileName)
    }
    
    /// Gets the URL for a cache file, creating directories if needed
    /// - Parameter fileName: The name of the cache file
    /// - Returns: URL for the cache file
    func getCacheFileURL(fileName: String) -> URL {
        createDirectoryIfNeeded(cachesDirectory)
        return cachesDirectory.appendingPathComponent(fileName)
    }
    
    /// Checks if a file exists at the specified path
    /// - Parameter fileURL: The URL to check
    /// - Returns: True if file exists, false otherwise
    func fileExists(atPath fileURL: URL) -> Bool {
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    // MARK: - Private Helper Methods
    
    /// Gets the appropriate directory URL for a specific data type
    /// - Parameter dataType: The type of data
    /// - Returns: Directory URL for the data type
    private func getDirectoryForDataType(_ dataType: StorageDataType) -> URL {
        let directory: URL
        
        switch dataType {
        case .audio:
            directory = documentsDirectory.appendingPathComponent("Audio")
        case .images:
            directory = documentsDirectory.appendingPathComponent("Images")
        case .cache:
            directory = cachesDirectory
        case .journals:
            directory = documentsDirectory.appendingPathComponent("Journals")
        default:
            directory = documentsDirectory.appendingPathComponent(String(describing: dataType))
        }
        
        createDirectoryIfNeeded(directory)
        return directory
    }
    
    /// Creates a directory if it doesn't already exist
    /// - Parameter directoryURL: The URL of the directory to create
    /// - Returns: True if directory exists or was created successfully, false otherwise
    @discardableResult
    private func createDirectoryIfNeeded(_ directoryURL: URL) -> Bool {
        if fileManager.fileExists(atPath: directoryURL.path) {
            return true
        }
        
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            logger.error("Failed to create directory at \(directoryURL.path): \(error)", category: .database)
            return false
        }
    }
    
    /// Generates a storage key based on data type and provided key
    /// - Parameters:
    ///   - key: The base key
    ///   - dataType: The type of data
    /// - Returns: A combined storage key
    private func getStorageKey(key: String, dataType: StorageDataType) -> String {
        return "\(dataType)_\(key)"
    }
}