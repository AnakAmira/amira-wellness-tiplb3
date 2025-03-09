//
//  EncryptionService.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // Latest
import CryptoKit // Latest
import Combine // Latest

/// Errors that can occur during encryption operations
enum EncryptionError: Error {
    case keyRetrievalFailed
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case fileOperationFailed
    case algorithmNotSupported
    case ivGenerationFailed
    case checksumFailed
    case passwordTooWeak
}

/// Container for encrypted data with necessary metadata
struct EncryptedData {
    let data: Data
    let iv: Data
    let authTag: Data?
}

/// A singleton service that provides encryption and decryption functionality for the Amira Wellness app
final class EncryptionService {
    
    // MARK: - Public Properties
    
    /// Shared instance of the EncryptionService
    static let shared = EncryptionService()
    
    // MARK: - Private Properties
    
    /// Key management service for secure key operations
    private let keyManager: KeyManagementService
    
    /// The encryption algorithm used
    private let algorithm: String
    
    /// Size of the initialization vector in bytes
    private let ivSize: Int
    
    /// Size of the authentication tag in bytes
    private let tagSize: Int
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private init() {
        // Initialize dependencies
        self.keyManager = KeyManagementService.shared
        
        // Set encryption parameters based on constants
        self.algorithm = AppConstants.Security.encryptionAlgorithm
        self.ivSize = 12  // Standard for AES-GCM
        self.tagSize = 16 // Standard for AES-GCM
    }
    
    // MARK: - Public Methods
    
    /// Encrypts data using AES-GCM with a secure key
    /// - Parameters:
    ///   - data: The data to encrypt
    ///   - keyIdentifier: Identifier for the encryption key
    /// - Returns: Encrypted data or error
    func encryptData(data: Data, keyIdentifier: String) -> Result<EncryptedData, EncryptionError> {
        // Retrieve the encryption key
        let keyResult = keyManager.getDataKey(identifier: keyIdentifier)
        
        guard case let .success(keyData) = keyResult else {
            Logger.shared.error("Failed to retrieve encryption key", category: .encryption)
            return .failure(.keyRetrievalFailed)
        }
        
        // Generate a random IV
        let ivResult = generateRandomIV()
        
        guard case let .success(iv) = ivResult else {
            return .failure(.ivGenerationFailed)
        }
        
        do {
            // Create a symmetric key from the key data
            let symmetricKey = SymmetricKey(data: keyData)
            
            // Encrypt the data with AES-GCM
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey, nonce: AES.GCM.Nonce(data: iv))
            
            // Get ciphertext and authentication tag
            let encryptedData = sealedBox.ciphertext
            let authTag = sealedBox.tag
            
            Logger.shared.logEncryption("Data encrypted successfully", level: .debug)
            return .success(EncryptedData(data: encryptedData, iv: iv, authTag: authTag))
            
        } catch {
            Logger.shared.error("Data encryption failed: \(error)", category: .encryption)
            return .failure(.encryptionFailed)
        }
    }
    
    /// Decrypts data that was encrypted with AES-GCM
    /// - Parameters:
    ///   - encryptedData: The data to decrypt with its IV and auth tag
    ///   - keyIdentifier: Identifier for the decryption key
    /// - Returns: Decrypted data or error
    func decryptData(encryptedData: EncryptedData, keyIdentifier: String) -> Result<Data, EncryptionError> {
        // Retrieve the decryption key
        let keyResult = keyManager.getDataKey(identifier: keyIdentifier)
        
        guard case let .success(keyData) = keyResult else {
            Logger.shared.error("Failed to retrieve decryption key", category: .encryption)
            return .failure(.keyRetrievalFailed)
        }
        
        do {
            // Create a symmetric key from the key data
            let symmetricKey = SymmetricKey(data: keyData)
            
            // Create a nonce from the IV
            let nonce = try AES.GCM.Nonce(data: encryptedData.iv)
            
            // Create a sealed box using the ciphertext, tag, and nonce
            let sealedBox: AES.GCM.SealedBox
            
            if let authTag = encryptedData.authTag {
                sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: encryptedData.data, tag: authTag)
            } else {
                // Handle the case where authTag might be combined with ciphertext
                Logger.shared.error("Authentication tag missing from encrypted data", category: .encryption)
                return .failure(.invalidData)
            }
            
            // Decrypt the data
            let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
            
            Logger.shared.logEncryption("Data decrypted successfully", level: .debug)
            return .success(decryptedData)
            
        } catch {
            Logger.shared.error("Data decryption failed: \(error)", category: .encryption)
            return .failure(.decryptionFailed)
        }
    }
    
    /// Encrypts a file at the specified URL and saves the result
    /// - Parameters:
    ///   - fileURL: URL of the file to encrypt
    ///   - destinationURL: URL where the encrypted file will be saved
    ///   - keyIdentifier: Identifier for the encryption key
    /// - Returns: Encryption IV (as hex string) or error
    func encryptFile(fileURL: URL, destinationURL: URL, keyIdentifier: String) -> Result<String, EncryptionError> {
        // Read file data
        do {
            let fileData = try Data(contentsOf: fileURL)
            
            // Encrypt the data
            let encryptResult = encryptData(data: fileData, keyIdentifier: keyIdentifier)
            
            guard case let .success(encryptedData) = encryptResult else {
                if case let .failure(error) = encryptResult {
                    return .failure(error)
                }
                return .failure(.encryptionFailed)
            }
            
            // Create a container format with metadata
            let containerDict: [String: Any] = [
                "version": 1,
                "algorithm": algorithm,
                "keyIdentifier": keyIdentifier,
                "timestamp": Date().timeIntervalSince1970,
                "iv": encryptedData.iv.base64EncodedString(),
                "authTag": encryptedData.authTag?.base64EncodedString() ?? "",
                "encryptedData": encryptedData.data.base64EncodedString()
            ]
            
            // Convert to JSON data
            guard let containerData = try? JSONSerialization.data(withJSONObject: containerDict) else {
                Logger.shared.error("Failed to create container format for encrypted file", category: .encryption)
                return .failure(.encryptionFailed)
            }
            
            // Write to destination
            try containerData.write(to: destinationURL)
            
            // Return IV as hex string for reference
            let ivHex = dataToHexString(data: encryptedData.iv)
            
            Logger.shared.logEncryption("File encrypted successfully: \(fileURL.lastPathComponent)", level: .info)
            return .success(ivHex)
            
        } catch {
            Logger.shared.error("File encryption failed: \(error)", category: .encryption)
            return .failure(.fileOperationFailed)
        }
    }
    
    /// Decrypts a file that was encrypted with encryptFile
    /// - Parameters:
    ///   - fileURL: URL of the encrypted file
    ///   - destinationURL: URL where the decrypted file will be saved
    ///   - keyIdentifier: Identifier for the decryption key
    ///   - iv: Optional IV hex string (if not included in container)
    /// - Returns: Success or error
    func decryptFile(fileURL: URL, destinationURL: URL, keyIdentifier: String, iv: String = "") -> Result<Void, EncryptionError> {
        do {
            // Read encrypted file data
            let containerData = try Data(contentsOf: fileURL)
            
            // Parse the container format
            guard let containerDict = try JSONSerialization.jsonObject(with: containerData) as? [String: Any],
                  let encryptedDataB64 = containerDict["encryptedData"] as? String,
                  let encryptedData = Data(base64Encoded: encryptedDataB64) else {
                Logger.shared.error("Invalid container format in encrypted file", category: .encryption)
                return .failure(.invalidData)
            }
            
            // Get IV either from parameter or container
            let ivData: Data
            if !iv.isEmpty {
                // Use provided IV
                let ivResult = hexStringToData(hexString: iv)
                guard case let .success(data) = ivResult else {
                    return .failure(.invalidData)
                }
                ivData = data
            } else if let ivB64 = containerDict["iv"] as? String,
                      let data = Data(base64Encoded: ivB64) {
                // Use IV from container
                ivData = data
            } else {
                Logger.shared.error("Missing IV for file decryption", category: .encryption)
                return .failure(.invalidData)
            }
            
            // Get authentication tag
            let authTagData: Data?
            if let authTagB64 = containerDict["authTag"] as? String,
               let data = Data(base64Encoded: authTagB64) {
                authTagData = data
            } else {
                authTagData = nil
            }
            
            // Create EncryptedData object
            let encryptedDataObj = EncryptedData(data: encryptedData, iv: ivData, authTag: authTagData)
            
            // Decrypt the data
            let decryptResult = decryptData(encryptedData: encryptedDataObj, keyIdentifier: keyIdentifier)
            
            guard case let .success(decryptedData) = decryptResult else {
                if case let .failure(error) = decryptResult {
                    return .failure(error)
                }
                return .failure(.decryptionFailed)
            }
            
            // Write decrypted data to destination
            try decryptedData.write(to: destinationURL)
            
            Logger.shared.logEncryption("File decrypted successfully: \(fileURL.lastPathComponent)", level: .info)
            return .success(())
            
        } catch {
            Logger.shared.error("File decryption failed: \(error)", category: .encryption)
            return .failure(.fileOperationFailed)
        }
    }
    
    /// Encrypts data using a user-provided password
    /// - Parameters:
    ///   - data: The data to encrypt
    ///   - password: The password to derive the encryption key from
    /// - Returns: Encrypted data and salt, or error
    func encryptWithPassword(data: Data, password: String) -> Result<(encryptedData: Data, salt: Data), EncryptionError> {
        // Validate password strength
        guard validatePasswordStrength(password: password) else {
            Logger.shared.error("Password does not meet strength requirements", category: .encryption)
            return .failure(.passwordTooWeak)
        }
        
        // Derive key from password
        let keyDerivationResult = keyManager.deriveKeyFromPassword(password: password)
        
        guard case let .success((derivedKey, salt)) = keyDerivationResult else {
            if case let .failure(error) = keyDerivationResult {
                Logger.shared.error("Key derivation failed", category: .encryption)
                return .failure(.encryptionFailed)
            }
            return .failure(.encryptionFailed)
        }
        
        // Generate a random IV
        let ivResult = generateRandomIV()
        
        guard case let .success(iv) = ivResult else {
            return .failure(.ivGenerationFailed)
        }
        
        do {
            // Create a symmetric key from the derived key
            let symmetricKey = SymmetricKey(data: derivedKey)
            
            // Encrypt the data with AES-GCM
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey, nonce: AES.GCM.Nonce(data: iv))
            
            // Combine IV, ciphertext, and tag into one package
            let containerDict: [String: Any] = [
                "version": 1,
                "algorithm": algorithm,
                "timestamp": Date().timeIntervalSince1970,
                "iv": iv.base64EncodedString(),
                "authTag": sealedBox.tag.base64EncodedString(),
                "encryptedData": sealedBox.ciphertext.base64EncodedString()
            ]
            
            // Convert to JSON data
            guard let containerData = try? JSONSerialization.data(withJSONObject: containerDict) else {
                Logger.shared.error("Failed to create container format for password-encrypted data", category: .encryption)
                return .failure(.encryptionFailed)
            }
            
            Logger.shared.logEncryption("Data encrypted with password successfully", level: .debug)
            return .success((encryptedData: containerData, salt: salt))
            
        } catch {
            Logger.shared.error("Password-based encryption failed: \(error)", category: .encryption)
            return .failure(.encryptionFailed)
        }
    }
    
    /// Decrypts data that was encrypted with a password
    /// - Parameters:
    ///   - encryptedData: The encrypted data
    ///   - password: The password used for encryption
    ///   - salt: The salt used for key derivation
    /// - Returns: Decrypted data or error
    func decryptWithPassword(encryptedData: Data, password: String, salt: Data) -> Result<Data, EncryptionError> {
        // Derive key from password and salt
        let keyDerivationResult = keyManager.deriveKeyFromPassword(password: password, salt: salt)
        
        guard case let .success((derivedKey, _)) = keyDerivationResult else {
            if case let .failure(error) = keyDerivationResult {
                Logger.shared.error("Key derivation failed for decryption", category: .encryption)
                return .failure(.decryptionFailed)
            }
            return .failure(.decryptionFailed)
        }
        
        do {
            // Parse the container format
            guard let containerDict = try JSONSerialization.jsonObject(with: encryptedData) as? [String: Any],
                  let encryptedDataB64 = containerDict["encryptedData"] as? String,
                  let ivB64 = containerDict["iv"] as? String,
                  let authTagB64 = containerDict["authTag"] as? String,
                  let ciphertext = Data(base64Encoded: encryptedDataB64),
                  let iv = Data(base64Encoded: ivB64),
                  let authTag = Data(base64Encoded: authTagB64) else {
                Logger.shared.error("Invalid container format in encrypted data", category: .encryption)
                return .failure(.invalidData)
            }
            
            // Create a symmetric key from the derived key
            let symmetricKey = SymmetricKey(data: derivedKey)
            
            // Create a nonce from the IV
            let nonce = try AES.GCM.Nonce(data: iv)
            
            // Create a sealed box
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: authTag)
            
            // Decrypt the data
            let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
            
            Logger.shared.logEncryption("Data decrypted with password successfully", level: .debug)
            return .success(decryptedData)
            
        } catch {
            Logger.shared.error("Password-based decryption failed: \(error)", category: .encryption)
            return .failure(.decryptionFailed)
        }
    }
    
    /// Generates a new encryption key for a specific identifier
    /// - Parameters:
    ///   - keyIdentifier: Identifier for the new key
    ///   - useBiometricProtection: Whether to protect the key with biometric authentication
    /// - Returns: Success or error
    func generateEncryptionKey(keyIdentifier: String, useBiometricProtection: Bool = false) -> Result<Void, EncryptionError> {
        let keyResult = keyManager.generateDataKey(identifier: keyIdentifier, useBiometricProtection: useBiometricProtection)
        
        switch keyResult {
        case .success:
            Logger.shared.logEncryption("Encryption key generated for identifier: \(keyIdentifier)", level: .info)
            return .success(())
        case .failure(let error):
            // Map KeyManagementError to EncryptionError
            let mappedError: EncryptionError
            switch error {
            case .keyGenerationFailed, .keyStorageFailed:
                mappedError = .encryptionFailed
            case .secureEnclaveNotAvailable, .biometricAuthFailed:
                mappedError = .encryptionFailed
            default:
                mappedError = .encryptionFailed
            }
            
            Logger.shared.error("Failed to generate encryption key: \(error)", category: .encryption)
            return .failure(mappedError)
        }
    }
    
    /// Exports encrypted data in a format suitable for sharing or backup
    /// - Parameters:
    ///   - encryptedData: The encrypted data to export
    ///   - keyIdentifier: Identifier for the encryption key
    ///   - password: Password to protect the export
    /// - Returns: Exportable encrypted package or error
    func exportEncryptedData(encryptedData: EncryptedData, keyIdentifier: String, password: String) -> Result<Data, EncryptionError> {
        // Validate password strength
        guard validatePasswordStrength(password: password) else {
            Logger.shared.error("Password does not meet strength requirements for export", category: .encryption)
            return .failure(.passwordTooWeak)
        }
        
        // Create metadata
        let metadata: [String: Any] = [
            "version": 1,
            "format": "AmiraWellness-Export",
            "timestamp": Date().timeIntervalSince1970,
            "algorithm": algorithm,
            "keyIdentifier": keyIdentifier
        ]
        
        // Serialize the encrypted data
        let dataDict: [String: Any] = [
            "data": encryptedData.data.base64EncodedString(),
            "iv": encryptedData.iv.base64EncodedString(),
            "authTag": encryptedData.authTag?.base64EncodedString() ?? ""
        ]
        
        // Combine metadata and data
        let exportPackage: [String: Any] = [
            "metadata": metadata,
            "encryptedData": dataDict
        ]
        
        // Serialize the package
        guard let exportData = try? JSONSerialization.data(withJSONObject: exportPackage) else {
            Logger.shared.error("Failed to serialize export package", category: .encryption)
            return .failure(.encryptionFailed)
        }
        
        // Encrypt the package with the password
        let encryptResult = encryptWithPassword(data: exportData, password: password)
        
        guard case let .success((packageData, salt)) = encryptResult else {
            if case let .failure(error) = encryptResult {
                return .failure(error)
            }
            return .failure(.encryptionFailed)
        }
        
        // Create final export container with salt
        let exportContainer: [String: Any] = [
            "format": "AmiraWellness-ProtectedExport",
            "version": 1,
            "salt": salt.base64EncodedString(),
            "data": packageData.base64EncodedString()
        ]
        
        // Serialize the container
        guard let containerData = try? JSONSerialization.data(withJSONObject: exportContainer) else {
            Logger.shared.error("Failed to serialize export container", category: .encryption)
            return .failure(.encryptionFailed)
        }
        
        Logger.shared.logEncryption("Data exported successfully", level: .info)
        return .success(containerData)
    }
    
    /// Imports encrypted data that was exported with exportEncryptedData
    /// - Parameters:
    ///   - exportedData: The exported data
    ///   - password: The password used to protect the export
    /// - Returns: Original encrypted data and key identifier, or error
    func importEncryptedData(exportedData: Data, password: String) -> Result<(encryptedData: EncryptedData, keyIdentifier: String), EncryptionError> {
        do {
            // Parse the export container
            guard let containerDict = try JSONSerialization.jsonObject(with: exportedData) as? [String: Any],
                  let format = containerDict["format"] as? String,
                  format == "AmiraWellness-ProtectedExport",
                  let saltB64 = containerDict["salt"] as? String,
                  let dataB64 = containerDict["data"] as? String,
                  let salt = Data(base64Encoded: saltB64),
                  let packageData = Data(base64Encoded: dataB64) else {
                Logger.shared.error("Invalid export container format", category: .encryption)
                return .failure(.invalidData)
            }
            
            // Decrypt the package with the password
            let decryptResult = decryptWithPassword(encryptedData: packageData, password: password, salt: salt)
            
            guard case let .success(decryptedPackage) = decryptResult else {
                if case let .failure(error) = decryptResult {
                    return .failure(error)
                }
                return .failure(.decryptionFailed)
            }
            
            // Parse the decrypted package
            guard let packageDict = try JSONSerialization.jsonObject(with: decryptedPackage) as? [String: Any],
                  let metadata = packageDict["metadata"] as? [String: Any],
                  let encryptedDataDict = packageDict["encryptedData"] as? [String: Any],
                  let keyIdentifier = metadata["keyIdentifier"] as? String,
                  let dataB64 = encryptedDataDict["data"] as? String,
                  let ivB64 = encryptedDataDict["iv"] as? String,
                  let data = Data(base64Encoded: dataB64),
                  let iv = Data(base64Encoded: ivB64) else {
                Logger.shared.error("Invalid package format in imported data", category: .encryption)
                return .failure(.invalidData)
            }
            
            // Extract authentication tag if present
            let authTag: Data?
            if let authTagB64 = encryptedDataDict["authTag"] as? String,
               !authTagB64.isEmpty {
                authTag = Data(base64Encoded: authTagB64)
            } else {
                authTag = nil
            }
            
            // Recreate the EncryptedData object
            let encryptedData = EncryptedData(data: data, iv: iv, authTag: authTag)
            
            Logger.shared.logEncryption("Data imported successfully", level: .info)
            return .success((encryptedData: encryptedData, keyIdentifier: keyIdentifier))
            
        } catch {
            Logger.shared.error("Import failed: \(error)", category: .encryption)
            return .failure(.invalidData)
        }
    }
    
    /// Verifies the integrity of an encrypted file using its checksum
    /// - Parameters:
    ///   - fileURL: URL of the file to verify
    ///   - expectedChecksum: The expected checksum to compare against
    /// - Returns: True if integrity check passes, false if it fails, or error
    func verifyFileIntegrity(fileURL: URL, expectedChecksum: String) -> Result<Bool, EncryptionError> {
        do {
            // Read file data
            let fileData = try Data(contentsOf: fileURL)
            
            // Calculate SHA-256 checksum
            let calculatedChecksum: String
            if #available(iOS 13.0, *) {
                let digest = SHA256.hash(data: fileData)
                calculatedChecksum = digest.compactMap { String(format: "%02x", $0) }.joined()
            } else {
                // Fallback for iOS 12
                // This is a simplified alternative that would need to be replaced with
                // a proper implementation using CommonCrypto for production
                Logger.shared.error("SHA-256 not available on this iOS version", category: .encryption)
                return .failure(.checksumFailed)
            }
            
            // Compare checksums
            let result = calculatedChecksum.lowercased() == expectedChecksum.lowercased()
            
            Logger.shared.logEncryption("File integrity check: \(result ? "passed" : "failed")", level: .info)
            return .success(result)
            
        } catch {
            Logger.shared.error("File integrity check failed: \(error)", category: .encryption)
            return .failure(.fileOperationFailed)
        }
    }
    
    // MARK: - Private Methods
    
    /// Generates a cryptographically secure random IV
    /// - Returns: Random IV data or error
    private func generateRandomIV() -> Result<Data, EncryptionError> {
        var iv = Data(count: ivSize)
        let result = iv.withUnsafeMutableBytes { pointer in
            SecRandomCopyBytes(kSecRandomDefault, ivSize, pointer.baseAddress!)
        }
        
        if result == errSecSuccess {
            return .success(iv)
        } else {
            Logger.shared.error("Failed to generate secure random IV", category: .encryption)
            return .failure(.ivGenerationFailed)
        }
    }
    
    /// Converts binary data to a hexadecimal string representation
    /// - Parameter data: The data to convert
    /// - Returns: Hexadecimal string representation
    private func dataToHexString(data: Data) -> String {
        return data.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Converts a hexadecimal string to binary data
    /// - Parameter hexString: The hexadecimal string to convert
    /// - Returns: Binary data or error
    private func hexStringToData(hexString: String) -> Result<Data, EncryptionError> {
        // Ensure string contains only hex characters
        let regex = try! NSRegularExpression(pattern: "^[0-9a-fA-F]*$")
        let range = NSRange(location: 0, length: hexString.utf16.count)
        guard regex.firstMatch(in: hexString, options: [], range: range) != nil else {
            Logger.shared.error("Invalid hex string provided", category: .encryption)
            return .failure(.invalidData)
        }
        
        // Ensure even number of characters
        var hex = hexString
        if hex.count % 2 != 0 {
            hex = "0" + hex
        }
        
        // Convert to bytes
        var data = Data()
        var index = hex.startIndex
        
        while index < hex.endIndex {
            let byteString = hex[index..<hex.index(index, offsetBy: 2)]
            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            } else {
                Logger.shared.error("Failed to convert hex to byte", category: .encryption)
                return .failure(.invalidData)
            }
            index = hex.index(index, offsetBy: 2)
        }
        
        return .success(data)
    }
    
    /// Validates that a password meets minimum strength requirements
    /// - Parameter password: The password to validate
    /// - Returns: True if password meets requirements, false otherwise
    private func validatePasswordStrength(password: String) -> Bool {
        // Check minimum length
        guard password.count >= AppConstants.Security.passwordMinLength else {
            return false
        }
        
        // Check for required character types if enabled in constants
        if AppConstants.Security.passwordRequiresSpecialCharacter {
            let specialCharacterRegex = ".*[^A-Za-z0-9].*"
            let specialCharacterTest = NSPredicate(format: "SELF MATCHES %@", specialCharacterRegex)
            guard specialCharacterTest.evaluate(with: password) else {
                return false
            }
        }
        
        if AppConstants.Security.passwordRequiresNumber {
            let numberRegex = ".*[0-9].*"
            let numberTest = NSPredicate(format: "SELF MATCHES %@", numberRegex)
            guard numberTest.evaluate(with: password) else {
                return false
            }
        }
        
        if AppConstants.Security.passwordRequiresUppercase {
            let uppercaseRegex = ".*[A-Z].*"
            let uppercaseTest = NSPredicate(format: "SELF MATCHES %@", uppercaseRegex)
            guard uppercaseTest.evaluate(with: password) else {
                return false
            }
        }
        
        return true
    }
}