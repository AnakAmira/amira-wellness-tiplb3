//
//  KeychainManager.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // Latest
import Security // Latest

/// Error types that can occur during keychain operations
enum KeychainError: Error {
    case itemNotFound
    case duplicateItem
    case authFailed
    case unhandledError(status: OSStatus)
    case encodingError
    case decodingError
}

/// Accessibility options for keychain items
enum KeychainAccessibility {
    case whenUnlocked
    case afterFirstUnlock
    case whenUnlockedThisDeviceOnly
    case afterFirstUnlockThisDeviceOnly
    case whenPasscodeSetThisDeviceOnly
}

/// A singleton manager class that provides a secure interface for storing and retrieving sensitive data in the iOS Keychain
class KeychainManager {
    /// Shared instance of the KeychainManager
    static let shared = KeychainManager()
    
    // MARK: - Private Properties
    
    private let serviceName: String
    private let accessGroup: String?
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private init() {
        self.serviceName = AppConstants.Security.keychainServiceName
        self.accessGroup = AppConstants.Security.keychainAccessGroup
    }
    
    // MARK: - Public Methods
    
    /// Saves data to the keychain for a specific key
    /// - Parameters:
    ///   - data: The data to save
    ///   - key: The key to associate with the data
    ///   - accessibility: The accessibility level for the keychain item
    ///   - isBiometricProtected: Whether to protect the item with biometric authentication
    /// - Returns: Result with success or a specific error
    func save(data: Data, key: String, accessibility: KeychainAccessibility = .whenUnlocked, isBiometricProtected: Bool = false) -> Result<Void, KeychainError> {
        // Create a query dictionary with the base attributes
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        // Add access group if specified
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        // Add accessibility attribute
        query[kSecAttrAccessible as String] = getAccessibilityValue(accessibility)
        
        // Add biometric protection if requested
        if isBiometricProtected {
            var accessControlFlags: SecAccessControlCreateFlags = .userPresence
            
            if #available(iOS 11.3, *) {
                accessControlFlags = .biometryAny
            }
            
            guard let accessControl = SecAccessControlCreateWithFlags(
                nil,
                getAccessibilityValue(accessibility),
                accessControlFlags,
                nil
            ) else {
                Logger.shared.error("Failed to create access control for keychain item", category: .encryption)
                return .failure(.unhandledError(status: errSecParam))
            }
            
            query[kSecAttrAccessControl as String] = accessControl
        }
        
        // Check if the item already exists
        var status = SecItemCopyMatching(query as CFDictionary, nil)
        
        if status == errSecSuccess || status == errSecInteractionNotAllowed {
            // Item exists, update it
            let updateQuery: [String: Any] = [kSecValueData as String: data]
            status = SecItemUpdate(query as CFDictionary, updateQuery as CFDictionary)
        } else if status == errSecItemNotFound {
            // Item doesn't exist, add it
            query[kSecValueData as String] = data
            status = SecItemAdd(query as CFDictionary, nil)
        }
        
        // Handle the result
        switch status {
        case errSecSuccess:
            Logger.shared.debug("Successfully saved data for key: \(key)", category: .encryption)
            return .success(())
        case errSecDuplicateItem:
            Logger.shared.error("Failed to save to keychain: duplicate item for key: \(key)", category: .encryption)
            return .failure(.duplicateItem)
        case errSecAuthFailed:
            Logger.shared.error("Failed to save to keychain: authentication failed for key: \(key)", category: .encryption)
            return .failure(.authFailed)
        default:
            Logger.shared.error("Failed to save to keychain: unhandled error status: \(status) for key: \(key)", category: .encryption)
            return .failure(.unhandledError(status: status))
        }
    }
    
    /// Retrieves data from the keychain for a specific key
    /// - Parameter key: The key associated with the data
    /// - Returns: Result with the retrieved data or a specific error
    func retrieve(key: String) -> Result<Data, KeychainError> {
        // Create a query dictionary
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        // Add access group if specified
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        // Query the keychain
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        // Handle the result
        switch status {
        case errSecSuccess:
            if let data = item as? Data {
                Logger.shared.debug("Successfully retrieved data for key: \(key)", category: .encryption)
                return .success(data)
            } else {
                Logger.shared.error("Failed to retrieve from keychain: unexpected data type for key: \(key)", category: .encryption)
                return .failure(.decodingError)
            }
        case errSecItemNotFound:
            Logger.shared.error("Failed to retrieve from keychain: item not found for key: \(key)", category: .encryption)
            return .failure(.itemNotFound)
        case errSecAuthFailed:
            Logger.shared.error("Failed to retrieve from keychain: authentication failed for key: \(key)", category: .encryption)
            return .failure(.authFailed)
        default:
            Logger.shared.error("Failed to retrieve from keychain: unhandled error status: \(status) for key: \(key)", category: .encryption)
            return .failure(.unhandledError(status: status))
        }
    }
    
    /// Deletes an item from the keychain for a specific key
    /// - Parameter key: The key associated with the item to delete
    /// - Returns: Result with success or a specific error
    func delete(key: String) -> Result<Void, KeychainError> {
        // Create a query dictionary
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        // Add access group if specified
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        // Delete the item
        let status = SecItemDelete(query as CFDictionary)
        
        // Handle the result
        switch status {
        case errSecSuccess, errSecItemNotFound:
            // It's not an error if the item doesn't exist
            Logger.shared.debug("Successfully deleted keychain item for key: \(key)", category: .encryption)
            return .success(())
        case errSecAuthFailed:
            Logger.shared.error("Failed to delete from keychain: authentication failed for key: \(key)", category: .encryption)
            return .failure(.authFailed)
        default:
            Logger.shared.error("Failed to delete from keychain: unhandled error status: \(status) for key: \(key)", category: .encryption)
            return .failure(.unhandledError(status: status))
        }
    }
    
    /// Convenience method to save a string value to the keychain
    /// - Parameters:
    ///   - string: The string to save
    ///   - key: The key to associate with the string
    ///   - accessibility: The accessibility level for the keychain item
    ///   - isBiometricProtected: Whether to protect the item with biometric authentication
    /// - Returns: Result with success or a specific error
    func saveString(string: String, key: String, accessibility: KeychainAccessibility = .whenUnlocked, isBiometricProtected: Bool = false) -> Result<Void, KeychainError> {
        guard let data = string.data(using: .utf8) else {
            Logger.shared.error("Failed to convert string to data for key: \(key)", category: .encryption)
            return .failure(.encodingError)
        }
        
        return save(data: data, key: key, accessibility: accessibility, isBiometricProtected: isBiometricProtected)
    }
    
    /// Convenience method to retrieve a string value from the keychain
    /// - Parameter key: The key associated with the string
    /// - Returns: Result with the retrieved string or a specific error
    func retrieveString(key: String) -> Result<String, KeychainError> {
        let result = retrieve(key: key)
        
        switch result {
        case .success(let data):
            guard let string = String(data: data, encoding: .utf8) else {
                Logger.shared.error("Failed to convert data to string for key: \(key)", category: .encryption)
                return .failure(.decodingError)
            }
            return .success(string)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Saves a Codable object to the keychain
    /// - Parameters:
    ///   - object: The Codable object to save
    ///   - key: The key to associate with the object
    ///   - accessibility: The accessibility level for the keychain item
    ///   - isBiometricProtected: Whether to protect the item with biometric authentication
    /// - Returns: Result with success or a specific error
    func saveCodable<T: Encodable>(_ object: T, key: String, accessibility: KeychainAccessibility = .whenUnlocked, isBiometricProtected: Bool = false) -> Result<Void, KeychainError> {
        let encoder = JSONEncoder()
        
        do {
            let data = try encoder.encode(object)
            return save(data: data, key: key, accessibility: accessibility, isBiometricProtected: isBiometricProtected)
        } catch {
            Logger.shared.error("Failed to encode object for key: \(key)", error: error, category: .encryption)
            return .failure(.encodingError)
        }
    }
    
    /// Retrieves a Codable object from the keychain
    /// - Parameter key: The key associated with the object
    /// - Returns: Result with the retrieved object or a specific error
    func retrieveCodable<T: Decodable>(key: String) -> Result<T, KeychainError> {
        let result = retrieve(key: key)
        
        switch result {
        case .success(let data):
            let decoder = JSONDecoder()
            
            do {
                let object = try decoder.decode(T.self, from: data)
                return .success(object)
            } catch {
                Logger.shared.error("Failed to decode object for key: \(key)", error: error, category: .encryption)
                return .failure(.decodingError)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    /// Checks if a key exists in the keychain
    /// - Parameter key: The key to check
    /// - Returns: True if the key exists, false otherwise
    func contains(key: String) -> Bool {
        // Create a query dictionary
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false
        ]
        
        // Add access group if specified
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        // Check if the item exists
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Removes all keychain items for this service
    /// - Returns: Result with success or a specific error
    func clearAll() -> Result<Void, KeychainError> {
        // Create a query dictionary for all items with this service
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        // Add access group if specified
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        // Delete all matching items
        let status = SecItemDelete(query as CFDictionary)
        
        // Handle the result
        switch status {
        case errSecSuccess, errSecItemNotFound:
            // It's not an error if no items exist
            Logger.shared.debug("Successfully cleared all keychain items for service: \(serviceName)", category: .encryption)
            return .success(())
        case errSecAuthFailed:
            Logger.shared.error("Failed to clear keychain: authentication failed", category: .encryption)
            return .failure(.authFailed)
        default:
            Logger.shared.error("Failed to clear keychain: unhandled error status: \(status)", category: .encryption)
            return .failure(.unhandledError(status: status))
        }
    }
    
    // MARK: - Private Methods
    
    /// Converts KeychainAccessibility enum to CFString value
    /// - Parameter accessibility: The KeychainAccessibility enum value
    /// - Returns: The corresponding CFString value for Security framework
    private func getAccessibilityValue(_ accessibility: KeychainAccessibility) -> CFString {
        switch accessibility {
        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked
        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock
        case .whenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .whenPasscodeSetThisDeviceOnly:
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        }
    }
}