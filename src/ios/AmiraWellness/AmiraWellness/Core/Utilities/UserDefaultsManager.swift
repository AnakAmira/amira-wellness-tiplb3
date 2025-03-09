//
//  UserDefaultsManager.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // Latest

/// Errors that can occur during UserDefaults operations
enum UserDefaultsError: Error {
    case decodingError
    case encodingError
}

/// A singleton manager class that provides a convenient interface for storing and retrieving
/// user preferences and settings using UserDefaults
class UserDefaultsManager {
    /// Shared instance of UserDefaultsManager (singleton)
    static let shared = UserDefaultsManager()
    
    /// Reference to UserDefaults standard
    private let userDefaults: UserDefaults
    
    /// Private initializer for singleton pattern
    private init() {
        userDefaults = UserDefaults.standard
    }
    
    // MARK: - Boolean Methods
    
    /// Saves a boolean value to UserDefaults for a specific key
    /// - Parameters:
    ///   - value: The boolean value to save
    ///   - key: The key to associate with the value
    func setBool(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: key)
        Logger.shared.debug("Set bool \(value) for key \(key)")
    }
    
    /// Retrieves a boolean value from UserDefaults for a specific key
    /// - Parameters:
    ///   - key: The key associated with the value
    ///   - defaultValue: The default value to return if the key is not found
    /// - Returns: The retrieved boolean value or default value if not found
    func getBool(forKey key: String, defaultValue: Bool = false) -> Bool {
        if !containsKey(key) {
            Logger.shared.debug("Key \(key) not found, returning default bool value: \(defaultValue)")
            return defaultValue
        }
        let value = userDefaults.bool(forKey: key)
        Logger.shared.debug("Retrieved bool for key \(key): \(value)")
        return value
    }
    
    // MARK: - Integer Methods
    
    /// Saves an integer value to UserDefaults for a specific key
    /// - Parameters:
    ///   - value: The integer value to save
    ///   - key: The key to associate with the value
    func setInt(_ value: Int, forKey key: String) {
        userDefaults.set(value, forKey: key)
        Logger.shared.debug("Set int \(value) for key \(key)")
    }
    
    /// Retrieves an integer value from UserDefaults for a specific key
    /// - Parameters:
    ///   - key: The key associated with the value
    ///   - defaultValue: The default value to return if the key is not found
    /// - Returns: The retrieved integer value or default value if not found
    func getInt(forKey key: String, defaultValue: Int = 0) -> Int {
        if !containsKey(key) {
            Logger.shared.debug("Key \(key) not found, returning default int value: \(defaultValue)")
            return defaultValue
        }
        let value = userDefaults.integer(forKey: key)
        Logger.shared.debug("Retrieved int for key \(key): \(value)")
        return value
    }
    
    // MARK: - Double Methods
    
    /// Saves a double value to UserDefaults for a specific key
    /// - Parameters:
    ///   - value: The double value to save
    ///   - key: The key to associate with the value
    func setDouble(_ value: Double, forKey key: String) {
        userDefaults.set(value, forKey: key)
        Logger.shared.debug("Set double \(value) for key \(key)")
    }
    
    /// Retrieves a double value from UserDefaults for a specific key
    /// - Parameters:
    ///   - key: The key associated with the value
    ///   - defaultValue: The default value to return if the key is not found
    /// - Returns: The retrieved double value or default value if not found
    func getDouble(forKey key: String, defaultValue: Double = 0.0) -> Double {
        if !containsKey(key) {
            Logger.shared.debug("Key \(key) not found, returning default double value: \(defaultValue)")
            return defaultValue
        }
        let value = userDefaults.double(forKey: key)
        Logger.shared.debug("Retrieved double for key \(key): \(value)")
        return value
    }
    
    // MARK: - String Methods
    
    /// Saves a string value to UserDefaults for a specific key
    /// - Parameters:
    ///   - value: The string value to save
    ///   - key: The key to associate with the value
    func setString(_ value: String, forKey key: String) {
        userDefaults.set(value, forKey: key)
        Logger.shared.debug("Set string for key \(key)")
    }
    
    /// Retrieves a string value from UserDefaults for a specific key
    /// - Parameters:
    ///   - key: The key associated with the value
    ///   - defaultValue: The default value to return if the key is not found
    /// - Returns: The retrieved string value or default value if not found
    func getString(forKey key: String, defaultValue: String = "") -> String {
        guard let value = userDefaults.string(forKey: key) else {
            Logger.shared.debug("Key \(key) not found, returning default string value")
            return defaultValue
        }
        Logger.shared.debug("Retrieved string for key \(key)")
        return value
    }
    
    // MARK: - Date Methods
    
    /// Saves a date value to UserDefaults for a specific key
    /// - Parameters:
    ///   - value: The date value to save
    ///   - key: The key to associate with the value
    func setDate(_ value: Date, forKey key: String) {
        userDefaults.set(value, forKey: key)
        Logger.shared.debug("Set date for key \(key)")
    }
    
    /// Retrieves a date value from UserDefaults for a specific key
    /// - Parameters:
    ///   - key: The key associated with the value
    ///   - defaultValue: The default value to return if the key is not found
    /// - Returns: The retrieved date value or default value if not found
    func getDate(forKey key: String, defaultValue: Date = Date()) -> Date {
        guard let value = userDefaults.object(forKey: key) as? Date else {
            Logger.shared.debug("Key \(key) not found, returning default date value")
            return defaultValue
        }
        Logger.shared.debug("Retrieved date for key \(key)")
        return value
    }
    
    // MARK: - Array Methods
    
    /// Saves an array to UserDefaults for a specific key
    /// - Parameters:
    ///   - value: The array to save
    ///   - key: The key to associate with the value
    func setArray(_ value: [Any], forKey key: String) {
        userDefaults.set(value, forKey: key)
        Logger.shared.debug("Set array for key \(key)")
    }
    
    /// Retrieves an array from UserDefaults for a specific key
    /// - Parameters:
    ///   - key: The key associated with the value
    ///   - defaultValue: The default value to return if the key is not found
    /// - Returns: The retrieved array or default value if not found
    func getArray(forKey key: String, defaultValue: [Any] = []) -> [Any] {
        guard let value = userDefaults.array(forKey: key) else {
            Logger.shared.debug("Key \(key) not found, returning default array value")
            return defaultValue
        }
        Logger.shared.debug("Retrieved array for key \(key)")
        return value
    }
    
    // MARK: - Dictionary Methods
    
    /// Saves a dictionary to UserDefaults for a specific key
    /// - Parameters:
    ///   - value: The dictionary to save
    ///   - key: The key to associate with the value
    func setDictionary(_ value: [String: Any], forKey key: String) {
        userDefaults.set(value, forKey: key)
        Logger.shared.debug("Set dictionary for key \(key)")
    }
    
    /// Retrieves a dictionary from UserDefaults for a specific key
    /// - Parameters:
    ///   - key: The key associated with the value
    ///   - defaultValue: The default value to return if the key is not found
    /// - Returns: The retrieved dictionary or default value if not found
    func getDictionary(forKey key: String, defaultValue: [String: Any] = [:]) -> [String: Any] {
        guard let value = userDefaults.dictionary(forKey: key) else {
            Logger.shared.debug("Key \(key) not found, returning default dictionary value")
            return defaultValue
        }
        Logger.shared.debug("Retrieved dictionary for key \(key)")
        return value
    }
    
    // MARK: - Codable Methods
    
    /// Saves a Codable object to UserDefaults for a specific key
    /// - Parameters:
    ///   - value: The Codable object to save
    ///   - key: The key to associate with the value
    /// - Returns: A Result indicating success or failure with a specific error
    func setCodable<T: Encodable>(_ value: T, forKey key: String) -> Result<Void, UserDefaultsError> {
        do {
            let data = try JSONEncoder().encode(value)
            userDefaults.set(data, forKey: key)
            Logger.shared.debug("Set Codable object for key \(key)")
            return .success(())
        } catch {
            Logger.shared.error("Failed to encode Codable object for key \(key)", error: error)
            return .failure(.encodingError)
        }
    }
    
    /// Retrieves a Codable object from UserDefaults for a specific key
    /// - Parameters:
    ///   - key: The key associated with the value
    ///   - defaultValue: The default value to return if the key is not found or decoding fails
    /// - Returns: A Result containing the retrieved object or an error
    func getCodable<T: Decodable>(forKey key: String, defaultValue: T? = nil) -> Result<T, UserDefaultsError> {
        guard let data = userDefaults.data(forKey: key) else {
            if let defaultValue = defaultValue {
                Logger.shared.debug("Key \(key) not found, returning default Codable value")
                return .success(defaultValue)
            } else {
                Logger.shared.error("Key \(key) not found and no default value provided")
                return .failure(.decodingError)
            }
        }
        
        do {
            let value = try JSONDecoder().decode(T.self, from: data)
            Logger.shared.debug("Retrieved and decoded Codable object for key \(key)")
            return .success(value)
        } catch {
            Logger.shared.error("Failed to decode Codable object for key \(key)", error: error)
            if let defaultValue = defaultValue {
                return .success(defaultValue)
            } else {
                return .failure(.decodingError)
            }
        }
    }
    
    // MARK: - Utility Methods
    
    /// Removes a value from UserDefaults for a specific key
    /// - Parameter key: The key to remove
    func removeObject(forKey key: String) {
        userDefaults.removeObject(forKey: key)
        Logger.shared.debug("Removed object for key \(key)")
    }
    
    /// Checks if a key exists in UserDefaults
    /// - Parameter key: The key to check
    /// - Returns: True if the key exists, false otherwise
    func containsKey(_ key: String) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }
    
    /// Removes all values from UserDefaults for this app
    func clearAll() {
        let dictionary = userDefaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            userDefaults.removeObject(forKey: key)
        }
        Logger.shared.debug("Cleared all UserDefaults values")
    }
    
    /// Forces any pending changes to be written to disk
    /// - Returns: True if the operation was successful, false otherwise
    @discardableResult
    func synchronize() -> Bool {
        let result = userDefaults.synchronize()
        Logger.shared.debug("Synchronized UserDefaults, result: \(result)")
        return result
    }
    
    /// Registers default values for UserDefaults keys
    /// - Parameter defaults: A dictionary containing the default values
    func registerDefaults(_ defaults: [String: Any]) {
        userDefaults.register(defaults: defaults)
        Logger.shared.debug("Registered default values for UserDefaults")
    }
}