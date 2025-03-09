//
//  EnvironmentConfig.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // iOS SDK

/// Defines the available environments for the application
enum Environment {
    /// Development environment for local testing and development
    case development
    /// Staging environment for pre-production testing
    case staging
    /// Production environment for release
    case production
}

/// Manages environment-specific configuration settings for the Amira Wellness application
struct EnvironmentConfig {
    
    /// Determines the current environment based on build configuration and bundle identifier
    ///
    /// - Returns: The current environment (development, staging, or production)
    static func getCurrentEnvironment() -> Environment {
        // Check for environment override in UserDefaults (for testing)
        if let overrideValue = UserDefaults.standard.string(forKey: "environment_override") {
            switch overrideValue {
            case "development":
                return .development
            case "staging":
                return .staging
            case "production":
                return .production
            default:
                break
            }
        }
        
        // Check the bundle identifier suffix for environment indicators
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
        
        if bundleIdentifier.hasSuffix(".dev") {
            return .development
        } else if bundleIdentifier.hasSuffix(".staging") {
            return .staging
        } else if bundleIdentifier.hasSuffix(".prod") || bundleIdentifier == "com.amirawellness.app" {
            return .production
        }
        
        // Check for DEBUG compiler flag
        #if DEBUG
        return .development
        #else
        // Default to production for App Store builds
        return .production
        #endif
    }
    
    /// Returns the base URL for API requests based on the environment
    ///
    /// - Parameter environment: The environment to get the API base URL for (defaults to current environment)
    /// - Returns: The API base URL for the specified environment
    static func getAPIBaseURL(environment: Environment = getCurrentEnvironment()) -> String {
        switch environment {
        case .development:
            return EnvironmentKeys.development.apiBaseURL
        case .staging:
            return EnvironmentKeys.staging.apiBaseURL
        case .production:
            return EnvironmentKeys.production.apiBaseURL
        }
    }
    
    /// Returns the S3 bucket name for audio storage based on the environment
    ///
    /// - Parameter environment: The environment to get the S3 bucket name for (defaults to current environment)
    /// - Returns: The S3 bucket name for the specified environment
    static func getS3BucketName(environment: Environment = getCurrentEnvironment()) -> String {
        switch environment {
        case .development:
            return EnvironmentKeys.development.s3BucketName
        case .staging:
            return EnvironmentKeys.staging.s3BucketName
        case .production:
            return EnvironmentKeys.production.s3BucketName
        }
    }
    
    /// Returns the AWS region for services based on the environment
    ///
    /// - Parameter environment: The environment to get the AWS region for (defaults to current environment)
    /// - Returns: The AWS region for the specified environment
    static func getAWSRegion(environment: Environment = getCurrentEnvironment()) -> String {
        switch environment {
        case .development:
            return EnvironmentKeys.development.awsRegion
        case .staging:
            return EnvironmentKeys.staging.awsRegion
        case .production:
            return EnvironmentKeys.production.awsRegion
        }
    }
    
    /// Returns the API version to use for requests based on the environment
    ///
    /// - Parameter environment: The environment to get the API version for (defaults to current environment)
    /// - Returns: The API version string for the specified environment
    static func getAPIVersion(environment: Environment = getCurrentEnvironment()) -> String {
        switch environment {
        case .development:
            return EnvironmentKeys.development.apiVersion
        case .staging:
            return EnvironmentKeys.staging.apiVersion
        case .production:
            return EnvironmentKeys.production.apiVersion
        }
    }
    
    /// Returns the expiration time for access tokens in minutes based on the environment
    ///
    /// - Parameter environment: The environment to get the token expiration for (defaults to current environment)
    /// - Returns: Access token expiration in minutes
    static func getAccessTokenExpirationMinutes(environment: Environment = getCurrentEnvironment()) -> Int {
        switch environment {
        case .development:
            return EnvironmentKeys.development.accessTokenExpirationMinutes
        case .staging:
            return EnvironmentKeys.staging.accessTokenExpirationMinutes
        case .production:
            return EnvironmentKeys.production.accessTokenExpirationMinutes
        }
    }
    
    /// Returns the expiration time for refresh tokens in days based on the environment
    ///
    /// - Parameter environment: The environment to get the token expiration for (defaults to current environment)
    /// - Returns: Refresh token expiration in days
    static func getRefreshTokenExpirationDays(environment: Environment = getCurrentEnvironment()) -> Int {
        switch environment {
        case .development:
            return EnvironmentKeys.development.refreshTokenExpirationDays
        case .staging:
            return EnvironmentKeys.staging.refreshTokenExpirationDays
        case .production:
            return EnvironmentKeys.production.refreshTokenExpirationDays
        }
    }
    
    /// Returns the identifier for encryption keys based on the environment
    ///
    /// - Parameter environment: The environment to get the encryption key identifier for (defaults to current environment)
    /// - Returns: The encryption key identifier
    static func getEncryptionKeyIdentifier(environment: Environment = getCurrentEnvironment()) -> String {
        switch environment {
        case .development:
            return EnvironmentKeys.development.encryptionKeyIdentifier
        case .staging:
            return EnvironmentKeys.staging.encryptionKeyIdentifier
        case .production:
            return EnvironmentKeys.production.encryptionKeyIdentifier
        }
    }
    
    /// Returns whether to use AWS KMS for key management based on the environment
    ///
    /// - Parameter environment: The environment to check AWS KMS usage for (defaults to current environment)
    /// - Returns: True if AWS KMS should be used
    static func shouldUseAWSKMS(environment: Environment = getCurrentEnvironment()) -> Bool {
        switch environment {
        case .development:
            return EnvironmentKeys.development.useAWSKMS
        case .staging:
            return EnvironmentKeys.staging.useAWSKMS
        case .production:
            return EnvironmentKeys.production.useAWSKMS
        }
    }
    
    /// Returns the API rate limit per minute based on the environment
    ///
    /// - Parameter environment: The environment to get the rate limit for (defaults to current environment)
    /// - Returns: The rate limit per minute
    static func getRateLimitPerMinute(environment: Environment = getCurrentEnvironment()) -> Int {
        switch environment {
        case .development:
            return EnvironmentKeys.development.rateLimitPerMinute
        case .staging:
            return EnvironmentKeys.staging.rateLimitPerMinute
        case .production:
            return EnvironmentKeys.production.rateLimitPerMinute
        }
    }
    
    /// Returns the logging level for the application based on the environment
    ///
    /// - Parameter environment: The environment to get the log level for (defaults to current environment)
    /// - Returns: The log level (debug, info, warning, error)
    static func getLogLevel(environment: Environment = getCurrentEnvironment()) -> String {
        switch environment {
        case .development:
            return EnvironmentKeys.development.logLevel
        case .staging:
            return EnvironmentKeys.staging.logLevel
        case .production:
            return EnvironmentKeys.production.logLevel
        }
    }
}

/// Stores environment-specific configuration values
struct EnvironmentKeys {
    /// Configuration values specific to the development environment
    struct development {
        static let apiBaseURL = "https://dev-api.amirawellness.com"
        static let s3BucketName = "amira-wellness-dev-audio"
        static let awsRegion = "us-east-1"
        static let apiVersion = "v1"
        static let accessTokenExpirationMinutes = 60
        static let refreshTokenExpirationDays = 30
        static let encryptionKeyIdentifier = "dev_encryption_key"
        static let useAWSKMS = false
        static let rateLimitPerMinute = 1000
        static let logLevel = "debug"
    }
    
    /// Configuration values specific to the staging environment
    struct staging {
        static let apiBaseURL = "https://staging-api.amirawellness.com"
        static let s3BucketName = "amira-wellness-staging-audio"
        static let awsRegion = "us-east-1"
        static let apiVersion = "v1"
        static let accessTokenExpirationMinutes = 30
        static let refreshTokenExpirationDays = 14
        static let encryptionKeyIdentifier = "staging_encryption_key"
        static let useAWSKMS = true
        static let rateLimitPerMinute = 300
        static let logLevel = "info"
    }
    
    /// Configuration values specific to the production environment
    struct production {
        static let apiBaseURL = "https://api.amirawellness.com"
        static let s3BucketName = "amira-wellness-production-audio"
        static let awsRegion = "us-east-1"
        static let apiVersion = "v1"
        static let accessTokenExpirationMinutes = 15
        static let refreshTokenExpirationDays = 7
        static let encryptionKeyIdentifier = "production_encryption_key"
        static let useAWSKMS = true
        static let rateLimitPerMinute = 100
        static let logLevel = "warning"
    }
}