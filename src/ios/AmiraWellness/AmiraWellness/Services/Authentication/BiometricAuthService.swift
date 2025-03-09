//
//  BiometricAuthService.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // Latest
import Combine // Latest
import LocalAuthentication // Latest

/// Errors that can occur during biometric authentication operations
enum BiometricAuthError: Error {
    case authenticationFailed
    case credentialsNotFound
    case storageError
    case biometryNotAvailable
    case userCancelled
    case unknown
}

/// A service that provides biometric authentication capabilities for secure credential storage and retrieval
class BiometricAuthService {
    /// Shared instance for singleton access
    static let shared = BiometricAuthService()
    
    /// KeychainManager instance for secure storage
    private let keychainManager: KeychainManager
    
    /// BiometricAuthManager instance for biometric authentication
    private let biometricAuthManager: BiometricAuthManager
    
    /// Key used to store credentials in the keychain
    private let credentialsKey: String
    
    /// Key used to store whether biometric authentication is enabled
    private let biometricEnabledKey: String
    
    /// Prompt displayed to the user during biometric authentication
    private let biometricPrompt: String
    
    /// Private initializer for singleton pattern
    private init() {
        keychainManager = KeychainManager.shared
        biometricAuthManager = BiometricAuthManager.shared
        credentialsKey = "biometric_credentials"
        biometricEnabledKey = AppConstants.Keychain.biometricEnabled
        biometricPrompt = AppConstants.Security.biometricAuthenticationReason
    }
    
    /// Checks if biometric authentication is available on the device
    /// - Returns: True if biometric authentication is available
    func isBiometricAuthAvailable() -> Bool {
        return biometricAuthManager.canAuthenticate()
    }
    
    /// Gets the type of biometric authentication available on the device
    /// - Returns: The type of biometric authentication (none, touchID, faceID)
    func getBiometricType() -> BiometricType {
        return biometricAuthManager.biometricType()
    }
    
    /// Checks if biometric authentication is enabled for the user
    /// - Returns: True if biometric authentication is enabled
    func isBiometricAuthEnabled() -> Bool {
        // First check if biometric auth is available
        guard isBiometricAuthAvailable() else {
            return false
        }
        
        // Check if the user has enabled biometric authentication
        let result = keychainManager.retrieveString(key: biometricEnabledKey)
        switch result {
        case .success(let value):
            return value == "true"
        case .failure:
            return false
        }
    }
    
    /// Enables biometric authentication for the user
    /// - Parameter enabled: Whether to enable or disable biometric authentication
    /// - Returns: Result indicating success or failure with specific error
    func enableBiometricAuth(_ enabled: Bool) -> Result<Void, BiometricAuthError> {
        // Check if biometric authentication is available
        guard isBiometricAuthAvailable() else {
            return .failure(.biometryNotAvailable)
        }
        
        // Save the enabled state to keychain
        let result = keychainManager.saveString(string: enabled ? "true" : "false", key: biometricEnabledKey)
        
        switch result {
        case .success:
            // If disabling, remove stored credentials
            if !enabled {
                let _ = keychainManager.delete(key: credentialsKey)
            }
            
            Logger.shared.debug("Biometric authentication \(enabled ? "enabled" : "disabled")", category: .authentication)
            return .success(())
        case .failure:
            return .failure(.storageError)
        }
    }
    
    /// Enables biometric authentication for the user using async/await
    /// - Parameter enabled: Whether to enable or disable biometric authentication
    /// - Returns: Void on success, throws error on failure
    @available(iOS 15.0, *)
    func enableBiometricAuthAsync(_ enabled: Bool) async throws {
        // Check if biometric authentication is available
        guard isBiometricAuthAvailable() else {
            throw BiometricAuthError.biometryNotAvailable
        }
        
        // Save the enabled state to keychain
        let result = keychainManager.saveString(string: enabled ? "true" : "false", key: biometricEnabledKey)
        
        switch result {
        case .success:
            // If disabling, remove stored credentials
            if !enabled {
                let _ = keychainManager.delete(key: credentialsKey)
            }
            
            Logger.shared.debug("Biometric authentication \(enabled ? "enabled" : "disabled")", category: .authentication)
        case .failure:
            throw BiometricAuthError.storageError
        }
    }
    
    /// Securely stores user credentials using biometric protection
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - completion: Callback with result indicating success or failure
    func storeCredentialsWithBiometrics(email: String, password: String, completion: @escaping (Result<Void, BiometricAuthError>) -> Void) {
        // Check if biometric authentication is available
        guard isBiometricAuthAvailable() else {
            completion(.failure(.biometryNotAvailable))
            return
        }
        
        // Create credentials dictionary
        let credentials: [String: String] = [
            "email": email,
            "password": password
        ]
        
        // Convert dictionary to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: credentials) else {
            completion(.failure(.storageError))
            return
        }
        
        // Convert data to base64 string for storage
        let base64String = jsonData.base64EncodedString()
        
        // Save to keychain with biometric protection
        let result = keychainManager.saveString(string: base64String, key: credentialsKey, isBiometricProtected: true)
        
        switch result {
        case .success:
            // Enable biometric authentication
            let enableResult = enableBiometricAuth(true)
            
            switch enableResult {
            case .success:
                Logger.shared.debug("Credentials stored securely with biometric protection", category: .authentication)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        case .failure:
            completion(.failure(.storageError))
        }
    }
    
    /// Securely stores user credentials using biometric protection with async/await
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: Void on success, throws error on failure
    @available(iOS 15.0, *)
    func storeCredentialsWithBiometricsAsync(email: String, password: String) async throws {
        // Check if biometric authentication is available
        guard isBiometricAuthAvailable() else {
            throw BiometricAuthError.biometryNotAvailable
        }
        
        // Create credentials dictionary
        let credentials: [String: String] = [
            "email": email,
            "password": password
        ]
        
        // Convert dictionary to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: credentials) else {
            throw BiometricAuthError.storageError
        }
        
        // Convert data to base64 string for storage
        let base64String = jsonData.base64EncodedString()
        
        // Save to keychain with biometric protection
        let result = keychainManager.saveString(string: base64String, key: credentialsKey, isBiometricProtected: true)
        
        switch result {
        case .success:
            // Enable biometric authentication
            try await enableBiometricAuthAsync(true)
            Logger.shared.debug("Credentials stored securely with biometric protection", category: .authentication)
        case .failure:
            throw BiometricAuthError.storageError
        }
    }
    
    /// Retrieves stored credentials after biometric authentication
    /// - Parameter completion: Callback with result containing credentials or error
    func retrieveCredentialsWithBiometrics(completion: @escaping (Result<(email: String, password: String), BiometricAuthError>) -> Void) {
        // Check if biometric authentication is enabled
        guard isBiometricAuthEnabled() else {
            completion(.failure(.biometryNotAvailable))
            return
        }
        
        // Authenticate user with biometrics
        biometricAuthManager.authenticateWithBiometrics(reason: biometricPrompt) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                // Authentication successful, retrieve credentials
                let credentialsResult = self.keychainManager.retrieveString(key: self.credentialsKey)
                
                switch credentialsResult {
                case .success(let base64String):
                    // Decode the base64 string
                    guard let jsonData = Data(base64Encoded: base64String) else {
                        completion(.failure(.credentialsNotFound))
                        return
                    }
                    
                    // Parse JSON data
                    do {
                        guard let credentials = try JSONSerialization.jsonObject(with: jsonData) as? [String: String],
                              let email = credentials["email"],
                              let password = credentials["password"] else {
                            completion(.failure(.credentialsNotFound))
                            return
                        }
                        
                        Logger.shared.debug("Credentials retrieved successfully with biometric authentication", category: .authentication)
                        completion(.success((email: email, password: password)))
                    } catch {
                        completion(.failure(.credentialsNotFound))
                    }
                    
                case .failure:
                    completion(.failure(.credentialsNotFound))
                }
                
            case .failure(let error):
                // Map BiometricError to BiometricAuthError
                switch error {
                case .authenticationFailed:
                    completion(.failure(.authenticationFailed))
                case .userCancelled:
                    completion(.failure(.userCancelled))
                case .biometryNotAvailable, .biometryNotEnrolled:
                    completion(.failure(.biometryNotAvailable))
                default:
                    completion(.failure(.unknown))
                }
            }
        }
    }
    
    /// Retrieves stored credentials after biometric authentication using async/await
    /// - Returns: Tuple containing email and password on success, throws error on failure
    @available(iOS 15.0, *)
    func retrieveCredentialsWithBiometricsAsync() async throws -> (email: String, password: String) {
        // Check if biometric authentication is enabled
        guard isBiometricAuthEnabled() else {
            throw BiometricAuthError.biometryNotAvailable
        }
        
        do {
            // Authenticate user with biometrics
            let authenticated = try await biometricAuthManager.authenticateWithBiometricsAsync(reason: biometricPrompt)
            
            if authenticated {
                // Authentication successful, retrieve credentials
                let credentialsResult = keychainManager.retrieveString(key: credentialsKey)
                
                switch credentialsResult {
                case .success(let base64String):
                    // Decode the base64 string
                    guard let jsonData = Data(base64Encoded: base64String) else {
                        throw BiometricAuthError.credentialsNotFound
                    }
                    
                    // Parse JSON data
                    guard let credentials = try JSONSerialization.jsonObject(with: jsonData) as? [String: String],
                          let email = credentials["email"],
                          let password = credentials["password"] else {
                        throw BiometricAuthError.credentialsNotFound
                    }
                    
                    Logger.shared.debug("Credentials retrieved successfully with biometric authentication", category: .authentication)
                    return (email: email, password: password)
                    
                case .failure:
                    throw BiometricAuthError.credentialsNotFound
                }
            } else {
                throw BiometricAuthError.authenticationFailed
            }
        } catch let biometricError as BiometricError {
            // Map BiometricError to BiometricAuthError
            switch biometricError {
            case .authenticationFailed:
                throw BiometricAuthError.authenticationFailed
            case .userCancelled:
                throw BiometricAuthError.userCancelled
            case .biometryNotAvailable, .biometryNotEnrolled:
                throw BiometricAuthError.biometryNotAvailable
            default:
                throw BiometricAuthError.unknown
            }
        }
    }
    
    /// Removes stored biometric credentials from the keychain
    /// - Returns: Result indicating success or failure with specific error
    func clearStoredCredentials() -> Result<Void, BiometricAuthError> {
        // Delete stored credentials
        let deleteResult = keychainManager.delete(key: credentialsKey)
        
        switch deleteResult {
        case .success:
            // Disable biometric authentication
            let disableResult = enableBiometricAuth(false)
            
            switch disableResult {
            case .success:
                Logger.shared.debug("Biometric credentials cleared successfully", category: .authentication)
                return .success(())
            case .failure(let error):
                return .failure(error)
            }
            
        case .failure:
            return .failure(.storageError)
        }
    }
    
    /// Removes stored biometric credentials from the keychain using async/await
    /// - Returns: Void on success, throws error on failure
    @available(iOS 15.0, *)
    func clearStoredCredentialsAsync() async throws {
        // Delete stored credentials
        let deleteResult = keychainManager.delete(key: credentialsKey)
        
        switch deleteResult {
        case .success:
            // Disable biometric authentication
            try await enableBiometricAuthAsync(false)
            Logger.shared.debug("Biometric credentials cleared successfully", category: .authentication)
        case .failure:
            throw BiometricAuthError.storageError
        }
    }
}