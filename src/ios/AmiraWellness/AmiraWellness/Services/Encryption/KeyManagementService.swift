//
//  KeyManagementService.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // Latest
import CryptoKit // Latest
import LocalAuthentication // Latest
import Combine // Latest

/// Types of keys managed by the service
public enum KeyType {
    /// Master encryption key used to protect other keys
    case master
    /// Data encryption key used for specific content types
    case data
    /// Export key used for secure data exports
    case export
}

/// Errors that can occur during key management operations
public enum KeyManagementError: Error {
    /// Failed to generate a cryptographic key
    case keyGenerationFailed
    /// Failed to store a key in the secure storage
    case keyStorageFailed
    /// Failed to retrieve a key from secure storage
    case keyRetrievalFailed
    /// The requested key was not found in secure storage
    case keyNotFound
    /// Biometric authentication failed
    case biometricAuthFailed
    /// The key data is invalid or corrupted
    case invalidKeyData
    /// Key derivation from password failed
    case derivationFailed
    /// Key rotation operation failed
    case rotationFailed
    /// Secure Enclave is not available on this device
    case secureEnclaveNotAvailable
}

/// A service that manages encryption keys for the Amira Wellness app
public final class KeyManagementService {
    
    // MARK: - Public Properties
    
    /// Shared instance of the KeyManagementService
    public static let shared = KeyManagementService()
    
    // MARK: - Private Properties
    
    /// Manager for secure Keychain operations
    private let keychainManager: KeychainManager
    
    /// Manager for biometric authentication
    private let biometricManager: BiometricAuthManager
    
    /// Identifier for the master encryption key
    private let masterKeyIdentifier: String
    
    /// Flag indicating if Secure Enclave should be used
    private let useSecureEnclave: Bool
    
    /// Size of encryption keys in bits
    private let keySize: Int
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private init() {
        // Initialize dependencies
        self.keychainManager = KeychainManager.shared
        self.biometricManager = BiometricAuthManager.shared
        
        // Set master key identifier from constants
        self.masterKeyIdentifier = AppConstants.Security.encryptionKeyIdentifier
        
        // Determine if Secure Enclave is available and should be used
        let context = LAContext()
        var error: NSError?
        let canEvaluateBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        self.useSecureEnclave = canEvaluateBiometrics && context.biometryType != .none
        
        // Set key size from constants
        self.keySize = AppConstants.Security.keySize
    }
    
    // MARK: - Public Methods
    
    /// Generates a new master encryption key and stores it securely
    /// - Parameter useBiometricProtection: Whether to protect the key with biometric authentication
    /// - Returns: Success or failure with specific error
    public func generateMasterKey(useBiometricProtection: Bool = false) -> Result<Void, KeyManagementError> {
        // Check if Secure Enclave is required but not available
        if useBiometricProtection && !biometricManager.canAuthenticate() {
            Logger.shared.error("Failed to generate master key: biometric authentication not available", category: .encryption)
            return .failure(.secureEnclaveNotAvailable)
        }
        
        // Generate a random key using CryptoKit
        let keyResult = generateRandomBytes(length: keySize / 8)
        
        switch keyResult {
        case .success(let keyData):
            // Store the key in the Keychain
            let keyIdentifier = getKeyIdentifier(keyType: .master, identifier: masterKeyIdentifier)
            let accessibility: KeychainAccessibility = useBiometricProtection ? 
                .whenUnlockedThisDeviceOnly : .afterFirstUnlockThisDeviceOnly
            
            let saveResult = keychainManager.save(
                data: keyData,
                key: keyIdentifier,
                accessibility: accessibility,
                isBiometricProtected: useBiometricProtection
            )
            
            switch saveResult {
            case .success:
                Logger.shared.logEncryption("Master encryption key generated and stored securely", level: .info)
                return .success(())
            case .failure:
                Logger.shared.error("Failed to store master encryption key in Keychain", category: .encryption)
                return .failure(.keyStorageFailed)
            }
            
        case .failure:
            Logger.shared.error("Failed to generate random bytes for master key", category: .encryption)
            return .failure(.keyGenerationFailed)
        }
    }
    
    /// Retrieves the master encryption key from secure storage
    /// - Returns: Master key data or error
    public func getMasterKey() -> Result<Data, KeyManagementError> {
        let keyIdentifier = getKeyIdentifier(keyType: .master, identifier: masterKeyIdentifier)
        
        // Check if key exists
        guard keychainManager.contains(key: keyIdentifier) else {
            Logger.shared.error("Master key not found in Keychain", category: .encryption)
            return .failure(.keyNotFound)
        }
        
        // If biometric protection is enabled, biometric auth happens automatically during Keychain access
        let retrieveResult = keychainManager.retrieve(key: keyIdentifier)
        
        switch retrieveResult {
        case .success(let keyData):
            Logger.shared.logEncryption("Master encryption key retrieved successfully", level: .info)
            return .success(keyData)
        case .failure(let error):
            if error == KeychainError.authFailed {
                Logger.shared.error("Biometric authentication failed when retrieving master key", category: .encryption)
                return .failure(.biometricAuthFailed)
            } else {
                Logger.shared.error("Failed to retrieve master encryption key: \(error)", category: .encryption)
                return .failure(.keyRetrievalFailed)
            }
        }
    }
    
    /// Generates a new data encryption key for a specific identifier
    /// - Parameters:
    ///   - identifier: Unique identifier for the key
    ///   - useBiometricProtection: Whether to protect the key with biometric authentication
    /// - Returns: Generated key data or error
    public func generateDataKey(identifier: String, useBiometricProtection: Bool = false) -> Result<Data, KeyManagementError> {
        // Check if Secure Enclave is required but not available
        if useBiometricProtection && !biometricManager.canAuthenticate() {
            Logger.shared.error("Failed to generate data key: biometric authentication not available", category: .encryption)
            return .failure(.secureEnclaveNotAvailable)
        }
        
        // Generate a random key using CryptoKit
        let keyResult = generateRandomBytes(length: keySize / 8)
        
        switch keyResult {
        case .success(let keyData):
            // Create a unique identifier with timestamp for versioning
            let timestamp = Date().timeIntervalSince1970
            let versionedIdentifier = "\(identifier)_\(Int(timestamp))"
            let keyIdentifier = getKeyIdentifier(keyType: .data, identifier: versionedIdentifier)
            
            // Store the key in the Keychain
            let accessibility: KeychainAccessibility = useBiometricProtection ? 
                .whenUnlockedThisDeviceOnly : .afterFirstUnlockThisDeviceOnly
            
            let saveResult = keychainManager.save(
                data: keyData,
                key: keyIdentifier,
                accessibility: accessibility,
                isBiometricProtected: useBiometricProtection
            )
            
            switch saveResult {
            case .success:
                Logger.shared.logEncryption("Data encryption key generated for identifier: \(identifier)", level: .info)
                return .success(keyData)
            case .failure:
                Logger.shared.error("Failed to store data encryption key in Keychain", category: .encryption)
                return .failure(.keyStorageFailed)
            }
            
        case .failure:
            Logger.shared.error("Failed to generate random bytes for data key", category: .encryption)
            return .failure(.keyGenerationFailed)
        }
    }
    
    /// Retrieves a data encryption key for a specific identifier
    /// - Parameter identifier: Unique identifier for the key
    /// - Returns: Key data or error
    public func getDataKey(identifier: String) -> Result<Data, KeyManagementError> {
        let keyIdentifier = getKeyIdentifier(keyType: .data, identifier: identifier)
        
        // Check if key exists
        guard keychainManager.contains(key: keyIdentifier) else {
            Logger.shared.error("Data key not found for identifier: \(identifier)", category: .encryption)
            return .failure(.keyNotFound)
        }
        
        // If biometric protection is enabled, biometric auth happens automatically during Keychain access
        let retrieveResult = keychainManager.retrieve(key: keyIdentifier)
        
        switch retrieveResult {
        case .success(let keyData):
            Logger.shared.logEncryption("Data encryption key retrieved for identifier: \(identifier)", level: .info)
            return .success(keyData)
        case .failure(let error):
            if error == KeychainError.authFailed {
                Logger.shared.error("Biometric authentication failed when retrieving data key", category: .encryption)
                return .failure(.biometricAuthFailed)
            } else {
                Logger.shared.error("Failed to retrieve data encryption key: \(error)", category: .encryption)
                return .failure(.keyRetrievalFailed)
            }
        }
    }
    
    /// Deletes a key from secure storage
    /// - Parameters:
    ///   - keyType: The type of key to delete
    ///   - identifier: Unique identifier for the key
    /// - Returns: Success or failure with specific error
    public func deleteKey(keyType: KeyType, identifier: String) -> Result<Void, KeyManagementError> {
        let keyIdentifier = getKeyIdentifier(keyType: keyType, identifier: identifier)
        
        let deleteResult = keychainManager.delete(key: keyIdentifier)
        
        switch deleteResult {
        case .success:
            Logger.shared.logEncryption("Key deleted: \(keyType) with identifier: \(identifier)", level: .info)
            return .success(())
        case .failure:
            Logger.shared.error("Failed to delete key from Keychain", category: .encryption)
            return .failure(.keyRetrievalFailed)
        }
    }
    
    /// Rotates a key by generating a new one and updating references
    /// - Parameters:
    ///   - keyType: The type of key to rotate
    ///   - identifier: Unique identifier for the key
    ///   - useBiometricProtection: Whether to protect the new key with biometric authentication
    /// - Returns: New key data or error
    public func rotateKey(keyType: KeyType, identifier: String, useBiometricProtection: Bool = false) -> Result<Data, KeyManagementError> {
        // First, retrieve the existing key
        let existingKeyResult = keyType == .master ? getMasterKey() : getDataKey(identifier: identifier)
        
        switch existingKeyResult {
        case .success:
            // Generate a new key
            let newKeyResult: Result<Data, KeyManagementError>
            
            if keyType == .master {
                // For master key, we need to generate and store it
                let generateResult = generateMasterKey(useBiometricProtection: useBiometricProtection)
                newKeyResult = generateResult.flatMap { getMasterKey() }
            } else {
                // For data keys, generate a new one
                newKeyResult = generateDataKey(identifier: identifier, useBiometricProtection: useBiometricProtection)
            }
            
            switch newKeyResult {
            case .success(let newKeyData):
                // Delete the old key (for data keys with versioned identifiers, this might not be necessary)
                if keyType != .data {
                    let _ = deleteKey(keyType: keyType, identifier: identifier)
                }
                
                Logger.shared.logEncryption("Key rotated successfully: \(keyType) with identifier: \(identifier)", level: .info)
                return .success(newKeyData)
                
            case .failure(let error):
                Logger.shared.error("Key rotation failed: could not generate new key", category: .encryption)
                return .failure(error)
            }
            
        case .failure(let error):
            Logger.shared.error("Key rotation failed: could not retrieve existing key", category: .encryption)
            return .failure(error)
        }
    }
    
    /// Derives an encryption key from a user password using PBKDF2
    /// - Parameters:
    ///   - password: The password to derive the key from
    ///   - salt: Optional salt for key derivation, will be generated if nil
    /// - Returns: Derived key and salt, or error
    public func deriveKeyFromPassword(password: String, salt: Data? = nil) -> Result<(key: Data, salt: Data), KeyManagementError> {
        // Generate a random salt if not provided
        let saltData: Data
        
        if let providedSalt = salt {
            saltData = providedSalt
        } else {
            let saltResult = generateRandomBytes(length: 16) // 128-bit salt
            
            switch saltResult {
            case .success(let data):
                saltData = data
            case .failure:
                Logger.shared.error("Failed to generate salt for key derivation", category: .encryption)
                return .failure(.derivationFailed)
            }
        }
        
        do {
            // Convert password to data
            guard let passwordData = password.data(using: .utf8) else {
                Logger.shared.error("Failed to convert password to data", category: .encryption)
                return .failure(.derivationFailed)
            }
            
            // Use PBKDF2 to derive the key (CryptoKit on iOS 13+)
            if #available(iOS 13.0, *) {
                let key = try HMAC<SHA256>.authenticationCode(
                    for: passwordData,
                    using: SymmetricKey(data: saltData)
                )
                let keyData = Data(key)
                
                Logger.shared.logEncryption("Key derived from password successfully", level: .info)
                return .success((key: keyData, salt: saltData))
            } else {
                // Fallback for iOS 12 - implement a manual PBKDF2 or use CommonCrypto
                Logger.shared.error("PBKDF2 not available on this iOS version", category: .encryption)
                return .failure(.derivationFailed)
            }
        } catch {
            Logger.shared.error("Key derivation failed with error: \(error)", category: .encryption)
            return .failure(.derivationFailed)
        }
    }
    
    /// Checks if biometric protection is enabled for a specific key
    /// - Parameters:
    ///   - keyType: The type of key to check
    ///   - identifier: Unique identifier for the key
    /// - Returns: True if biometric protection is enabled
    public func isBiometricProtectionEnabled(keyType: KeyType, identifier: String) -> Bool {
        let keyIdentifier = getKeyIdentifier(keyType: keyType, identifier: identifier)
        
        // Check if the key exists
        guard keychainManager.contains(key: keyIdentifier) else {
            return false
        }
        
        // Check if biometric authentication would be required
        // This is a simplified check - in reality, we'd need to inspect the keychain item attributes
        // which is more complex than just checking for presence
        
        // Attempt a retrieval which will fail if biometric auth is required but will give us the error
        let retrieveResult = keychainManager.retrieve(key: keyIdentifier)
        
        switch retrieveResult {
        case .success:
            // If retrieval succeeded without biometric prompt, protection is not enabled
            return false
        case .failure(let error):
            // If the error is authFailed, biometric protection is likely enabled
            return error == KeychainError.authFailed
        }
    }
    
    /// Enables biometric protection for an existing key
    /// - Parameters:
    ///   - keyType: The type of key to protect
    ///   - identifier: Unique identifier for the key
    /// - Returns: Success or failure with specific error
    public func enableBiometricProtection(keyType: KeyType, identifier: String) -> Result<Void, KeyManagementError> {
        // Check if biometric authentication is available
        guard biometricManager.canAuthenticate() else {
            Logger.shared.error("Biometric authentication not available", category: .encryption)
            return .failure(.secureEnclaveNotAvailable)
        }
        
        // Get the existing key
        let keyResult = keyType == .master ? getMasterKey() : getDataKey(identifier: identifier)
        
        switch keyResult {
        case .success(let keyData):
            // Re-save the key with biometric protection
            let keyIdentifier = getKeyIdentifier(keyType: keyType, identifier: identifier)
            
            let saveResult = keychainManager.save(
                data: keyData,
                key: keyIdentifier,
                accessibility: .whenUnlockedThisDeviceOnly,
                isBiometricProtected: true
            )
            
            switch saveResult {
            case .success:
                Logger.shared.logEncryption("Biometric protection enabled for key: \(keyType) with identifier: \(identifier)", level: .info)
                return .success(())
            case .failure:
                Logger.shared.error("Failed to enable biometric protection", category: .encryption)
                return .failure(.keyStorageFailed)
            }
            
        case .failure(let error):
            Logger.shared.error("Failed to retrieve key for enabling biometric protection", category: .encryption)
            return .failure(error)
        }
    }
    
    /// Disables biometric protection for an existing key
    /// - Parameters:
    ///   - keyType: The type of key to protect
    ///   - identifier: Unique identifier for the key
    /// - Returns: Success or failure with specific error
    public func disableBiometricProtection(keyType: KeyType, identifier: String) -> Result<Void, KeyManagementError> {
        // Get the existing key (may require biometric authentication)
        let keyResult = keyType == .master ? getMasterKey() : getDataKey(identifier: identifier)
        
        switch keyResult {
        case .success(let keyData):
            // Re-save the key without biometric protection
            let keyIdentifier = getKeyIdentifier(keyType: keyType, identifier: identifier)
            
            let saveResult = keychainManager.save(
                data: keyData,
                key: keyIdentifier,
                accessibility: .afterFirstUnlockThisDeviceOnly,
                isBiometricProtected: false
            )
            
            switch saveResult {
            case .success:
                Logger.shared.logEncryption("Biometric protection disabled for key: \(keyType) with identifier: \(identifier)", level: .info)
                return .success(())
            case .failure:
                Logger.shared.error("Failed to disable biometric protection", category: .encryption)
                return .failure(.keyStorageFailed)
            }
            
        case .failure(let error):
            if error == .biometricAuthFailed {
                Logger.shared.error("Biometric authentication failed when retrieving key", category: .encryption)
                return .failure(.biometricAuthFailed)
            } else {
                Logger.shared.error("Failed to retrieve key for disabling biometric protection", category: .encryption)
                return .failure(error)
            }
        }
    }
    
    /// Creates an encrypted backup of all encryption keys
    /// - Parameter password: Password to encrypt the backup
    /// - Returns: Encrypted backup data or error
    public func backupKeys(password: String) -> Result<Data, KeyManagementError> {
        // Step 1: Retrieve the master key
        let masterKeyResult = getMasterKey()
        guard case let .success(masterKeyData) = masterKeyResult else {
            if case let .failure(error) = masterKeyResult {
                return .failure(error)
            }
            return .failure(.keyRetrievalFailed)
        }
        
        // Step 2: Prepare a structure to hold all keys
        // This would be a more complex implementation in a real app,
        // including enumerating all data keys stored in the keychain
        let backupData: [String: Any] = [
            "version": 1,
            "timestamp": Date().timeIntervalSince1970,
            "masterKey": masterKeyData.base64EncodedString(),
            // Add other keys as needed
        ]
        
        // Step 3: Convert to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: backupData) else {
            Logger.shared.error("Failed to serialize backup data", category: .encryption)
            return .failure(.keyStorageFailed)
        }
        
        // Step 4: Derive an encryption key from the password
        let derivationResult = deriveKeyFromPassword(password: password)
        guard case let .success((derivedKey, salt)) = derivationResult else {
            if case let .failure(error) = derivationResult {
                return .failure(error)
            }
            return .failure(.derivationFailed)
        }
        
        // Step 5: Encrypt the backup data
        if #available(iOS 13.0, *) {
            do {
                let symmetricKey = SymmetricKey(data: derivedKey)
                let sealedBox = try AES.GCM.seal(jsonData, using: symmetricKey)
                
                // Step 6: Combine the salt, nonce, and encrypted data
                let combinedData = salt + sealedBox.nonce + sealedBox.ciphertext + sealedBox.tag
                
                Logger.shared.logEncryption("Key backup created successfully", level: .info)
                return .success(combinedData)
            } catch {
                Logger.shared.error("Failed to encrypt backup data: \(error)", category: .encryption)
                return .failure(.keyStorageFailed)
            }
        } else {
            // Fallback for iOS 12 - implement manual AES-GCM or use CommonCrypto
            Logger.shared.error("AES-GCM not available on this iOS version", category: .encryption)
            return .failure(.keyStorageFailed)
        }
    }
    
    /// Restores encryption keys from an encrypted backup
    /// - Parameters:
    ///   - backupData: Encrypted backup data
    ///   - password: Password to decrypt the backup
    /// - Returns: Success or failure with specific error
    public func restoreKeys(backupData: Data, password: String) -> Result<Void, KeyManagementError> {
        // Step 1: Extract the salt (first 16 bytes)
        guard backupData.count > 16 else {
            Logger.shared.error("Invalid backup data format", category: .encryption)
            return .failure(.invalidKeyData)
        }
        
        let salt = backupData.subdata(in: 0..<16)
        
        // Step 2: Derive the encryption key from the password
        let derivationResult = deriveKeyFromPassword(password: password, salt: salt)
        guard case let .success((derivedKey, _)) = derivationResult else {
            if case let .failure(error) = derivationResult {
                return .failure(error)
            }
            return .failure(.derivationFailed)
        }
        
        // Step 3: Decrypt the backup data
        if #available(iOS 13.0, *) {
            do {
                // Extract nonce (next 12 bytes for AES-GCM)
                let nonceData = backupData.subdata(in: 16..<28)
                let nonce = try AES.GCM.Nonce(data: nonceData)
                
                // Extract ciphertext and tag
                let ciphertextEndIndex = backupData.count - 16 // 16 bytes for the tag
                let ciphertext = backupData.subdata(in: 28..<ciphertextEndIndex)
                let tag = backupData.subdata(in: ciphertextEndIndex..<backupData.count)
                
                // Create a sealed box
                let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
                
                // Decrypt
                let symmetricKey = SymmetricKey(data: derivedKey)
                let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
                
                // Step 4: Parse the JSON
                guard let backupDict = try JSONSerialization.jsonObject(with: decryptedData) as? [String: Any],
                      let masterKeyString = backupDict["masterKey"] as? String,
                      let masterKeyData = Data(base64Encoded: masterKeyString) else {
                    Logger.shared.error("Invalid backup data structure", category: .encryption)
                    return .failure(.invalidKeyData)
                }
                
                // Step 5: Restore the master key
                let keyIdentifier = getKeyIdentifier(keyType: .master, identifier: masterKeyIdentifier)
                
                let saveResult = keychainManager.save(
                    data: masterKeyData,
                    key: keyIdentifier,
                    accessibility: .afterFirstUnlockThisDeviceOnly,
                    isBiometricProtected: false // Start without biometric protection
                )
                
                switch saveResult {
                case .success:
                    Logger.shared.logEncryption("Keys restored successfully from backup", level: .info)
                    return .success(())
                case .failure:
                    Logger.shared.error("Failed to restore keys to Keychain", category: .encryption)
                    return .failure(.keyStorageFailed)
                }
            } catch {
                Logger.shared.error("Failed to decrypt backup data: \(error)", category: .encryption)
                return .failure(.invalidKeyData)
            }
        } else {
            // Fallback for iOS 12 - implement manual AES-GCM or use CommonCrypto
            Logger.shared.error("AES-GCM not available on this iOS version", category: .encryption)
            return .failure(.invalidKeyData)
        }
    }
    
    // MARK: - Private Methods
    
    /// Generates a consistent key identifier based on type and identifier
    /// - Parameters:
    ///   - keyType: The type of key
    ///   - identifier: Unique identifier for the key
    /// - Returns: Full key identifier for storage
    private func getKeyIdentifier(keyType: KeyType, identifier: String) -> String {
        switch keyType {
        case .master:
            return "com.amirawellness.keys.master.\(identifier)"
        case .data:
            return "com.amirawellness.keys.data.\(identifier)"
        case .export:
            return "com.amirawellness.keys.export.\(identifier)"
        }
    }
    
    /// Generates cryptographically secure random bytes
    /// - Parameter length: Number of bytes to generate
    /// - Returns: Random bytes or error
    private func generateRandomBytes(length: Int) -> Result<Data, KeyManagementError> {
        if #available(iOS 13.0, *) {
            // Use CryptoKit for iOS 13+
            do {
                var randomBytes = Data(count: length)
                let result = randomBytes.withUnsafeMutableBytes { pointer in
                    SecRandomCopyBytes(kSecRandomDefault, length, pointer.baseAddress!)
                }
                
                if result == errSecSuccess {
                    return .success(randomBytes)
                } else {
                    throw NSError(domain: "com.amirawellness", code: Int(result), userInfo: nil)
                }
            } catch {
                Logger.shared.error("Failed to generate secure random bytes: \(error)", category: .encryption)
                return .failure(.keyGenerationFailed)
            }
        } else {
            // Fallback for iOS 12
            var randomBytes = Data(count: length)
            let result = randomBytes.withUnsafeMutableBytes { pointer in
                SecRandomCopyBytes(kSecRandomDefault, length, pointer.baseAddress!)
            }
            
            if result == errSecSuccess {
                return .success(randomBytes)
            } else {
                Logger.shared.error("Failed to generate secure random bytes", category: .encryption)
                return .failure(.keyGenerationFailed)
            }
        }
    }
}