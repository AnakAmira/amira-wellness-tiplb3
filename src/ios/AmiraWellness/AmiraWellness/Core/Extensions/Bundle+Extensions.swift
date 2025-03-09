//
//  Bundle+Extensions.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // iOS SDK

// MARK: - Bundle Extension
extension Bundle {
    // MARK: - App Information Properties
    
    /// Returns the display name of the application
    public static var appName: String {
        return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ??
            Bundle.main.infoDictionary?["CFBundleName"] as? String ??
            AppConstants.App.name
    }
    
    /// Returns the marketing version of the application
    public static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ??
            AppConstants.App.version
    }
    
    /// Returns the build number of the application
    public static var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ??
            AppConstants.App.build
    }
    
    /// Returns the bundle identifier of the application
    public static var bundleIdentifier: String {
        return Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ??
            AppConstants.App.bundleIdentifier
    }
    
    /// Returns the combined version and build number string
    public var versionAndBuild: String {
        return "v\(Bundle.appVersion) (\(Bundle.buildNumber))"
    }
    
    // MARK: - Localization
    
    /// Returns a localized string for the given key and optional table name
    /// - Parameters:
    ///   - key: The key for the string in the strings file
    ///   - tableName: The name of the strings file (without extension)
    ///   - value: The value to return if the key is not found
    ///   - bundle: The bundle containing the strings file
    /// - Returns: The localized string or the default value if not found
    public func localizedString(for key: String, tableName: String? = nil, value: String? = nil, bundle: Bundle? = nil) -> String {
        let result = NSLocalizedString(key, tableName: tableName, bundle: bundle ?? self, value: value ?? key, comment: "")
        
        // If the string wasn't found, log a warning and return the fallback value
        if result == key && value != key {
            Logger.shared.error("Missing localization for key: \(key)")
            return value ?? key
        }
        
        return result
    }
    
    // MARK: - Resource Loading
    
    /// Decodes a JSON file from the bundle into the specified Decodable type
    /// - Parameters:
    ///   - type: The Decodable type to decode into
    ///   - filename: The name of the JSON file (without extension)
    ///   - extension: The file extension (default: "json")
    /// - Returns: The decoded object or nil if decoding fails
    public func decode<T: Decodable>(_ type: T.Type, from filename: String, extension: String? = "json") -> T? {
        guard let url = self.url(forResource: filename, withExtension: `extension`) else {
            Logger.shared.error("Failed to find \(filename).\(`extension` ?? "json") in bundle")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            
            return try decoder.decode(T.self, from: data)
        } catch {
            Logger.shared.error("Failed to decode \(filename).\(`extension` ?? "json"): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Returns the path for a resource in the bundle
    /// - Parameters:
    ///   - name: The resource name
    ///   - extension: The resource extension
    ///   - subdirectory: The optional subdirectory containing the resource
    /// - Returns: The path to the resource or nil if not found
    public func path(forResource name: String, ofType extension: String? = nil, inDirectory subdirectory: String? = nil) -> String? {
        return path(forResource: name, ofType: `extension`, inDirectory: subdirectory)
    }
    
    /// Returns the URL for a resource in the bundle
    /// - Parameters:
    ///   - name: The resource name
    ///   - extension: The resource extension
    ///   - subdirectory: The optional subdirectory containing the resource
    /// - Returns: The URL to the resource or nil if not found
    public func url(forResource name: String, withExtension extension: String? = nil, subdirectory: String? = nil) -> URL? {
        return url(forResource: name, withExtension: `extension`, subdirectory: subdirectory)
    }
}