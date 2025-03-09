//
//  SecureStorageService.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // Latest
import Combine // Latest

/// Errors that can occur during secure storage operations
enum SecureStorageError: Error {
    case encryptionFailed
    case decryptionFailed
    case keychainError
    case dataConversionFailed
    case invalidData
    case storageNotAvailable
    case biometricAuthFailed
}

/// A singleton service that provides secure storage capabilities for sensitive data in the Amira Wellness app
final class SecureStorageService {
    
    // MARK: - Shared Instance
    
    /// Shared instance of the SecureStorageService
    static let shared = SecureStorageService()
    
    // MARK: - Private Properties
    
    /// Service for encryption and decryption operations
    private let encryptionService: EncryptionService
    
    /// Manager for secure Keychain storage
    private let keychainManager: KeychainManager
    
    /// Logger instance for secure logging
    private let logger: Logger
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private init() {
        self.encryptionService = EncryptionService.shared
        self.keychainManager = KeychainManager.shared
        self.logger = Logger.shared
    }
    
    // MARK: - Public Methods
    
    /// Stores data securely using encryption and keychain
    /// - Parameters:
    ///   - data: The data to store securely
    ///   - key: Unique identifier for the data
    ///   - useBiometricProtection: Whether to require biometric authentication for access
    /// - Returns: Success or failure with specific error
    func storeSecurely(data: Data, key: String, useBiometricProtection: Bool = false) -> Result<Void, SecureStorageError> {
        // Generate a unique key identifier for encryption
        let keyIdentifierResult = getKeyIdentifierForData(key: key)
        
        guard case let .success(keyIdentifier) = keyIdentifierResult else {
            if case let .failure(error) = keyIdentifierResult {
                return .failure(error)
            }
            return .failure(.encryptionFailed)
        }
        
        // Encrypt the data
        let encryptResult = encryptionService.encryptData(data: data, keyIdentifier: keyIdentifier)
        
        guard case let .success(encryptedData) = encryptResult else {
            logger.error("Failed to encrypt data for secure storage", category: .encryption)
            return .failure(.encryptionFailed)
        }
        
        // Create a container with the encrypted data and metadata
        let container: [String: Any] = [
            "version": 1,
            "timestamp": Date().timeIntervalSince1970,
            "data": encryptedData.data.base64EncodedString(),
            "iv": encryptedData.iv.base64EncodedString(),
            "authTag": encryptedData.authTag?.base64EncodedString() ?? "",
            "keyIdentifier": keyIdentifier
        ]
        
        // Convert to JSON data
        guard let containerData = try? JSONSerialization.data(withJSONObject: container) else {
            logger.error("Failed to create container for secure storage", category: .encryption)
            return .failure(.dataConversionFailed)
        }
        
        // Store in Keychain
        let accessibilityLevel: KeychainAccessibility = useBiometricProtection ? 
            .whenUnlockedThisDeviceOnly : .afterFirstUnlockThisDeviceOnly
        
        let saveResult = keychainManager.save(
            data: containerData,
            key: key,
            accessibility: accessibilityLevel,
            isBiometricProtected: useBiometricProtection
        )
        
        switch saveResult {
        case .success:
            logger.debug("Successfully stored data securely for key: \(key)", category: .encryption)
            return .success(())
        case .failure:
            logger.error("Failed to store data in Keychain for key: \(key)", category: .encryption)
            return .failure(.keychainError)
        }
    }
    
    /// Retrieves securely stored data using keychain and decryption
    /// - Parameters:
    ///   - key: Unique identifier for the data
    ///   - requireBiometricAuth: Whether to require biometric authentication for access
    /// - Returns: Retrieved data or failure with specific error
    func retrieveSecurely(key: String, requireBiometricAuth: Bool = false) -> Result<Data, SecureStorageError> {
        // Retrieve from Keychain
        let retrieveResult = keychainManager.retrieve(key: key)
        
        switch retrieveResult {
        case .success(let containerData):
            // Parse the container
            guard let container = try? JSONSerialization.jsonObject(with: containerData) as? [String: Any],
                  let dataBase64 = container["data"] as? String,
                  let ivBase64 = container["iv"] as? String,
                  let data = Data(base64Encoded: dataBase64),
                  let iv = Data(base64Encoded: ivBase64),
                  let keyIdentifier = container["keyIdentifier"] as? String else {
                logger.error("Invalid container format in secure storage for key: \(key)", category: .encryption)
                return .failure(.invalidData)
            }
            
            // Extract auth tag if present
            let authTag: Data?
            if let authTagBase64 = container["authTag"] as? String, !authTagBase64.isEmpty {
                authTag = Data(base64Encoded: authTagBase64)
            } else {
                authTag = nil
            }
            
            // Create EncryptedData object
            let encryptedData = EncryptedData(data: data, iv: iv, authTag: authTag)
            
            // Decrypt the data
            let decryptResult = encryptionService.decryptData(encryptedData: encryptedData, keyIdentifier: keyIdentifier)
            
            guard case let .success(decryptedData) = decryptResult else {
                logger.error("Failed to decrypt data from secure storage for key: \(key)", category: .encryption)
                return .failure(.decryptionFailed)
            }
            
            logger.debug("Successfully retrieved and decrypted data for key: \(key)", category: .encryption)
            return .success(decryptedData)
            
        case .failure(let error):
            if error == KeychainError.authFailed {
                logger.error("Biometric authentication failed when retrieving data for key: \(key)", category: .encryption)
                return .failure(.biometricAuthFailed)
            } else if error == KeychainError.itemNotFound {
                logger.error("No data found in secure storage for key: \(key)", category: .encryption)
                return .failure(.invalidData)
            } else {
                logger.error("Failed to retrieve data from Keychain for key: \(key)", category: .encryption)
                return .failure(.keychainError)
            }
        }
    }
    
    /// Deletes securely stored data from keychain
    /// - Parameter key: Unique identifier for the data
    /// - Returns: Success or failure with specific error
    func deleteSecurely(key: String) -> Result<Void, SecureStorageError> {
        let deleteResult = keychainManager.delete(key: key)
        
        switch deleteResult {
        case .success:
            logger.debug("Successfully deleted secure data for key: \(key)", category: .encryption)
            return .success(())
        case .failure:
            logger.error("Failed to delete secure data from Keychain for key: \(key)", category: .encryption)
            return .failure(.keychainError)
        }
    }
    
    /// Stores a Codable object securely
    /// - Parameters:
    ///   - object: The Codable object to store
    ///   - key: Unique identifier for the object
    ///   - useBiometricProtection: Whether to require biometric authentication for access
    /// - Returns: Success or failure with specific error
    func storeCodable<T: Encodable>(_ object: T, key: String, useBiometricProtection: Bool = false) -> Result<Void, SecureStorageError> {
        let encoder = JSONEncoder()
        
        do {
            let data = try encoder.encode(object)
            return storeSecurely(data: data, key: key, useBiometricProtection: useBiometricProtection)
        } catch {
            logger.error("Failed to encode object for secure storage", category: .encryption)
            return .failure(.dataConversionFailed)
        }
    }
    
    /// Retrieves a securely stored Codable object
    /// - Parameters:
    ///   - key: Unique identifier for the object
    ///   - requireBiometricAuth: Whether to require biometric authentication for access
    /// - Returns: Retrieved object or failure with specific error
    func retrieveCodable<T: Decodable>(key: String, requireBiometricAuth: Bool = false) -> Result<T, SecureStorageError> {
        let retrieveResult = retrieveSecurely(key: key, requireBiometricAuth: requireBiometricAuth)
        
        switch retrieveResult {
        case .success(let data):
            let decoder = JSONDecoder()
            
            do {
                let object = try decoder.decode(T.self, from: data)
                return .success(object)
            } catch {
                logger.error("Failed to decode object from secure storage", category: .encryption)
                return .failure(.dataConversionFailed)
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Exports securely stored data with password protection
    /// - Parameters:
    ///   - key: Unique identifier for the data
    ///   - password: Password to protect the exported data
    /// - Returns: Exported data package or failure with specific error
    func secureExport(key: String, password: String) -> Result<Data, SecureStorageError> {
        // Retrieve the data
        let retrieveResult = retrieveSecurely(key: key)
        
        switch retrieveResult {
        case .success(let data):
            // Create metadata for the export package
            let metadata: [String: Any] = [
                "version": 1,
                "format": "AmiraWellness-Export",
                "timestamp": Date().timeIntervalSince1970,
                "keyIdentifier": generateKeyIdentifier(key: key)
            ]
            
            // Create the export data structure
            let exportData: [String: Any] = [
                "metadata": metadata,
                "content": data.base64EncodedString()
            ]
            
            // Convert to JSON
            guard let exportDataJson = try? JSONSerialization.data(withJSONObject: exportData) else {
                logger.error("Failed to create export package", category: .encryption)
                return .failure(.dataConversionFailed)
            }
            
            // Encrypt with password
            let encryptResult = encryptionService.encryptWithPassword(data: exportDataJson, password: password)
            
            guard case let .success((encryptedData, salt)) = encryptResult else {
                logger.error("Failed to encrypt export package", category: .encryption)
                return .failure(.encryptionFailed)
            }
            
            // Create the final package with salt
            let exportPackage: [String: Any] = [
                "format": "AmiraWellness-ProtectedExport",
                "version": 1,
                "salt": salt.base64EncodedString(),
                "data": encryptedData.base64EncodedString()
            ]
            
            // Convert to JSON
            guard let packageData = try? JSONSerialization.data(withJSONObject: exportPackage) else {
                logger.error("Failed to create final export package", category: .encryption)
                return .failure(.dataConversionFailed)
            }
            
            logger.debug("Successfully created secure export package for key: \(key)", category: .encryption)
            return .success(packageData)
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Imports and stores data from a secure export package
    /// - Parameters:
    ///   - exportedData: The exported data package
    ///   - password: Password to decrypt the export
    ///   - key: Unique identifier for storing the imported data
    /// - Returns: Success or failure with specific error
    func secureImport(exportedData: Data, password: String, key: String) -> Result<Void, SecureStorageError> {
        do {
            // Parse the export package
            guard let packageDict = try JSONSerialization.jsonObject(with: exportedData) as? [String: Any],
                  let format = packageDict["format"] as? String,
                  format == "AmiraWellness-ProtectedExport",
                  let saltBase64 = packageDict["salt"] as? String,
                  let dataBase64 = packageDict["data"] as? String,
                  let salt = Data(base64Encoded: saltBase64),
                  let encryptedData = Data(base64Encoded: dataBase64) else {
                logger.error("Invalid export package format", category: .encryption)
                return .failure(.invalidData)
            }
            
            // Decrypt with password
            let decryptResult = encryptionService.decryptWithPassword(
                encryptedData: encryptedData,
                password: password,
                salt: salt
            )
            
            guard case let .success(decryptedData) = decryptResult else {
                logger.error("Failed to decrypt export package", category: .encryption)
                return .failure(.decryptionFailed)
            }
            
            // Parse the decrypted data
            guard let exportDict = try JSONSerialization.jsonObject(with: decryptedData) as? [String: Any],
                  let contentBase64 = exportDict["content"] as? String,
                  let content = Data(base64Encoded: contentBase64) else {
                logger.error("Invalid content in export package", category: .encryption)
                return .failure(.invalidData)
            }
            
            // Store the imported data
            let storeResult = storeSecurely(data: content, key: key)
            
            switch storeResult {
            case .success:
                logger.debug("Successfully imported and stored data for key: \(key)", category: .encryption)
                return .success(())
            case .failure(let error):
                logger.error("Failed to store imported data", category: .encryption)
                return .failure(error)
            }
            
        } catch {
            logger.error("Error processing import package: \(error)", category: .encryption)
            return .failure(.invalidData)
        }
    }
    
    /// Checks if secure data exists for a specific key
    /// - Parameter key: Unique identifier for the data
    /// - Returns: True if secure data exists, false otherwise
    func containsSecureData(key: String) -> Bool {
        return keychainManager.contains(key: key)
    }
    
    /// Migrates data from legacy storage format to current secure format
    /// - Parameters:
    ///   - legacyKey: The key used in the legacy storage
    ///   - newKey: The key to use in the current secure storage
    /// - Returns: Success or failure with specific error
    func migrateFromLegacyStorage(legacyKey: String, newKey: String) -> Result<Void, SecureStorageError> {
        // Check if legacy data exists
        guard containsSecureData(legacyKey) else {
            logger.debug("No legacy data found for key: \(legacyKey)", category: .encryption)
            return .success(()) // Not an error if no legacy data exists
        }
        
        // Retrieve legacy data
        let retrieveResult = keychainManager.retrieve(key: legacyKey)
        
        switch retrieveResult {
        case .success(let legacyData):
            // Store using current secure format
            let storeResult = storeSecurely(data: legacyData, key: newKey)
            
            switch storeResult {
            case .success:
                // Clean up legacy data
                let _ = keychainManager.delete(key: legacyKey)
                logger.debug("Successfully migrated data from legacy key: \(legacyKey) to new key: \(newKey)", category: .encryption)
                return .success(())
            case .failure(let error):
                logger.error("Failed to store migrated data for key: \(newKey)", category: .encryption)
                return .failure(error)
            }
            
        case .failure:
            logger.error("Failed to retrieve legacy data for key: \(legacyKey)", category: .encryption)
            return .failure(.keychainError)
        }
    }
    
    // MARK: - Private Methods
    
    /// Generates a unique key identifier for encryption
    /// - Parameter key: Base key to generate identifier from
    /// - Returns: Unique key identifier
    private func generateKeyIdentifier(key: String) -> String {
        let appIdentifier = AppConstants.App.bundleIdentifier
        let combinedString = "\(appIdentifier).\(key).\(AppConstants.Security.encryptionKeyIdentifier)"
        
        // Create a hash of the combined string
        let hash = combinedString.data(using: .utf8)?.base64EncodedString() ?? key
        
        return "key.\(hash)"
    }
    
    /// Retrieves the encryption key identifier for stored data
    /// - Parameter key: The storage key
    /// - Returns: Key identifier or error
    private func getKeyIdentifierForData(key: String) -> Result<String, SecureStorageError> {
        // Check if a custom key identifier is stored for this key
        let customKeyId = "\(key).keyIdentifier"
        
        if keychainManager.contains(key: customKeyId) {
            let retrieveResult = keychainManager.retrieveString(key: customKeyId)
            
            switch retrieveResult {
            case .success(let identifier):
                return .success(identifier)
            case .failure:
                // Fall back to standard identifier generation
                break
            }
        }
        
        // Generate a standard identifier
        return .success(generateKeyIdentifier(key: key))
    }
}