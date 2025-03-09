//
//  ApiConstants.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // iOS SDK

/// Defines API-related constants for the Amira Wellness application
struct ApiConstants {
    
    /// Constants related to API base URLs and environment-specific configurations
    struct BaseURL {
        /// The complete base URL for API requests
        static var fullURL: String = ""
        
        /// The API path component
        static let apiPath: String = "api"
        
        /// The API version to use
        static var version: String = ""
        
        /// Updates the base URL and version based on the current environment
        static func updateBaseURL() {
            let environment = EnvironmentConfig.getCurrentEnvironment()
            let baseURL = EnvironmentConfig.getAPIBaseURL(environment: environment)
            version = EnvironmentConfig.getAPIVersion(environment: environment)
            
            // Ensure base URL ends with a trailing slash
            var formattedBaseURL = baseURL
            if !formattedBaseURL.hasSuffix("/") {
                formattedBaseURL += "/"
            }
            
            // Construct the full URL: baseURL + apiPath + version
            fullURL = "\(formattedBaseURL)\(apiPath)/\(version)/"
        }
    }
    
    /// API endpoint paths for different features of the application
    struct Endpoints {
        // Authentication endpoints
        static let auth: String = "auth"
        static let login: String = "login"
        static let register: String = "register"
        static let refreshToken: String = "refresh-token"
        static let logout: String = "logout"
        
        // User related endpoints
        static let users: String = "users"
        
        // Voice journaling endpoints
        static let journals: String = "journals"
        static let audio: String = "audio"
        
        // Emotional tracking endpoints
        static let emotions: String = "emotions"
        static let emotionalHistory: String = "emotional-history"
        static let emotionalTrends: String = "emotional-trends"
        
        // Tool library endpoints
        static let tools: String = "tools"
        static let toolCategories: String = "tool-categories"
        static let recommendedTools: String = "recommended-tools"
        static let favoriteTools: String = "favorite-tools"
        static let toolUsage: String = "tool-usage"
        
        // Progress tracking endpoints
        static let progress: String = "progress"
        static let streaks: String = "streaks"
        static let achievements: String = "achievements"
        static let insights: String = "insights"
        
        // Device and notification endpoints
        static let devices: String = "devices"
        static let notifications: String = "notifications"
        
        // Miscellaneous endpoints
        static let export: String = "export"
        static let health: String = "health"
    }
    
    /// HTTP headers used in API requests
    struct Headers {
        // Header keys
        static let contentType: String = "Content-Type"
        static let accept: String = "Accept"
        static let authorization: String = "Authorization"
        static let deviceId: String = "X-Device-ID"
        static let deviceModel: String = "X-Device-Model"
        static let osVersion: String = "X-OS-Version"
        static let appVersion: String = "X-App-Version"
        static let language: String = "X-Language"
        
        // Header values
        static let contentTypeJSON: String = "application/json"
        static let contentTypeMultipart: String = "multipart/form-data"
        static let acceptJSON: String = "application/json"
        static let bearerToken: String = "Bearer"
        
        /// Creates an authorization header with the provided token
        ///
        /// - Parameter token: The authentication token
        /// - Returns: The formatted authorization header value
        static func authorizationHeader(token: String) -> String {
            return "\(bearerToken) \(token)"
        }
        
        /// Returns a dictionary of default headers for API requests
        ///
        /// - Returns: Dictionary of default headers
        static func defaultHeaders() -> [String: String] {
            var headers: [String: String] = [
                contentType: contentTypeJSON,
                accept: acceptJSON
            ]
            
            // Add device information using Foundation APIs
            headers[deviceId] = ProcessInfo.processInfo.globallyUniqueString
            headers[deviceModel] = "iOS Device"
            headers[osVersion] = ProcessInfo.processInfo.operatingSystemVersionString
            
            // Add app version
            if let appVersionValue = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                headers[appVersion] = appVersionValue
            }
            
            // Add language (default to Spanish as per requirements)
            headers[language] = Locale.preferredLanguages.first ?? "es"
            
            return headers
        }
    }
    
    /// Common parameter keys used in API requests
    struct Parameters {
        // Authentication parameters
        static let email: String = "email"
        static let password: String = "password"
        static let refreshToken: String = "refresh_token"
        
        // User parameters
        static let userId: String = "user_id"
        
        // Journal parameters
        static let journalId: String = "journal_id"
        static let audioData: String = "audio_data"
        static let title: String = "title"
        
        // Emotion parameters
        static let emotionType: String = "emotion_type"
        static let intensity: String = "intensity"
        static let notes: String = "notes"
        static let context: String = "context"
        
        // Date range parameters
        static let startDate: String = "start_date"
        static let endDate: String = "end_date"
        
        // Tool parameters
        static let categoryId: String = "category_id"
        static let toolId: String = "tool_id"
        static let isFavorite: String = "is_favorite"
        static let duration: String = "duration"
        
        // Pagination parameters
        static let page: String = "page"
        static let pageSize: String = "page_size"
        static let sort: String = "sort"
        static let order: String = "order"
        
        // Device parameters
        static let deviceToken: String = "device_token"
        static let deviceType: String = "device_type"
        
        // Notification parameters
        static let notificationId: String = "notification_id"
        static let enabled: String = "enabled"
    }
    
    /// Error codes returned by the API for different error scenarios
    struct ErrorCodes {
        static let invalidCredentials: String = "invalid_credentials"
        static let accountLocked: String = "account_locked"
        static let emailAlreadyExists: String = "email_already_exists"
        static let invalidToken: String = "invalid_token"
        static let tokenExpired: String = "token_expired"
        static let unauthorized: String = "unauthorized"
        static let resourceNotFound: String = "resource_not_found"
        static let validationError: String = "validation_error"
        static let serverError: String = "server_error"
        static let networkError: String = "network_error"
        static let rateLimitExceeded: String = "rate_limit_exceeded"
        static let encryptionError: String = "encryption_error"
        static let storageError: String = "storage_error"
        static let externalServiceError: String = "external_service_error"
    }
    
    /// Timeout values for different types of network requests
    struct Timeouts {
        static let `default`: Double = 30.0  // Default timeout in seconds
        static let upload: Double = 60.0     // Timeout for uploading data
        static let download: Double = 60.0   // Timeout for downloading data
        static let longOperation: Double = 120.0  // Timeout for long operations
    }
}