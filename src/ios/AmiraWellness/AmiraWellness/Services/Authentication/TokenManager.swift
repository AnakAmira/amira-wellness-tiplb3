//
//  TokenManager.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // Latest
import JWTDecode // ~> 3.0
import Combine // Latest

/// Errors that can occur during token operations
enum TokenError: Error {
    /// Token not found in secure storage
    case tokenNotFound
    /// Token has expired and refresh failed
    case tokenExpired
    /// Token format is invalid
    case invalidToken
    /// Token refresh operation failed
    case refreshFailed
    /// Error occurred while storing or retrieving tokens
    case storageError
}

/// Response structure for token refresh operations
struct TokenResponse: Decodable {
    /// JWT access token for API authentication
    let accessToken: String
    /// Refresh token for obtaining new access tokens
    let refreshToken: String
    /// Token validity period in seconds
    let expiresIn: Int
}

/// Protocol for token refresh operations
protocol TokenRefreshService {
    /// Refreshes the authentication tokens using the refresh token
    /// - Parameters:
    ///   - refreshToken: The current refresh token
    ///   - completion: Completion handler with result containing new tokens or error
    func refreshToken(with refreshToken: String, completion: @escaping (Result<TokenResponse, Error>) -> Void)
    
    /// Refreshes the authentication tokens using the refresh token (async version)
    /// - Parameter refreshToken: The current refresh token
    /// - Returns: New token response or throws an error
    @available(iOS 15.0, *)
    func refreshTokenAsync(with refreshToken: String) async throws -> TokenResponse
}

/// A singleton manager class that handles authentication tokens for the application
class TokenManager {
    /// Shared instance for token management
    static let shared = TokenManager()
    
    // MARK: - Private Properties
    
    /// Keychain manager for secure storage
    private let keychainManager: KeychainManager
    
    /// Service for refreshing tokens
    private var tokenRefreshService: TokenRefreshService?
    
    /// Key for storing access token in keychain
    private let accessTokenKey: String
    
    /// Key for storing refresh token in keychain
    private let refreshTokenKey: String
    
    /// Buffer time in seconds before expiration to trigger token refresh
    private let tokenExpirationBufferSeconds: TimeInterval
    
    /// Flag indicating if token refresh is in progress
    private var refreshInProgress: Bool = false
    
    /// Subject for notifying about token refresh completion
    private var refreshSubject = PassthroughSubject<Result<Void, TokenError>, Never>()
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private init() {
        self.keychainManager = KeychainManager.shared
        self.tokenRefreshService = nil
        self.accessTokenKey = AppConstants.Keychain.accessToken
        self.refreshTokenKey = AppConstants.Keychain.refreshToken
        self.tokenExpirationBufferSeconds = 60 // Refresh token 60 seconds before expiration
        
        Logger.shared.debug("TokenManager initialized", category: .authentication)
    }
    
    // MARK: - Public Methods
    
    /// Sets the service used for token refresh operations
    /// - Parameter service: Service implementing TokenRefreshService protocol
    func setTokenRefreshService(_ service: TokenRefreshService) {
        self.tokenRefreshService = service
        Logger.shared.debug("Token refresh service configured", category: .authentication)
    }
    
    /// Saves access and refresh tokens to secure storage
    /// - Parameters:
    ///   - accessToken: The access token to save
    ///   - refreshToken: The refresh token to save
    /// - Returns: Result indicating success or specific error
    func saveTokens(accessToken: String, refreshToken: String) -> Result<Void, TokenError> {
        Logger.shared.debug("Saving authentication tokens", category: .authentication)
        
        // Save access token
        let accessTokenResult = keychainManager.saveString(string: accessToken, key: accessTokenKey)
        if case .failure = accessTokenResult {
            Logger.shared.error("Failed to save access token", category: .authentication)
            return .failure(.storageError)
        }
        
        // Save refresh token
        let refreshTokenResult = keychainManager.saveString(string: refreshToken, key: refreshTokenKey)
        if case .failure = refreshTokenResult {
            Logger.shared.error("Failed to save refresh token", category: .authentication)
            return .failure(.storageError)
        }
        
        Logger.shared.debug("Tokens saved successfully", category: .authentication)
        return .success(())
    }
    
    /// Retrieves the current access token, refreshing if necessary
    /// - Parameter completion: Completion handler with result containing token or error
    func getAccessToken(completion: @escaping (Result<String, TokenError>) -> Void) {
        // Attempt to retrieve the token from keychain
        let tokenResult = keychainManager.retrieveString(key: accessTokenKey)
        
        switch tokenResult {
        case .success(let token):
            // Check if token is expired or will expire soon
            if isTokenExpired(token) {
                Logger.shared.debug("Access token expired or expiring soon, attempting refresh", category: .authentication)
                // Refresh the token
                refreshTokens { result in
                    switch result {
                    case .success:
                        // After refresh, get the new token
                        let newTokenResult = self.keychainManager.retrieveString(key: self.accessTokenKey)
                        switch newTokenResult {
                        case .success(let newToken):
                            completion(.success(newToken))
                        case .failure:
                            completion(.failure(.tokenNotFound))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            } else {
                // Token is still valid
                Logger.shared.debug("Using existing valid access token", category: .authentication)
                completion(.success(token))
            }
        case .failure:
            Logger.shared.error("Access token not found in keychain", category: .authentication)
            completion(.failure(.tokenNotFound))
        }
    }
    
    /// Retrieves the current access token using async/await, refreshing if necessary
    /// - Returns: Access token or throws an error
    @available(iOS 15.0, *)
    func getAccessTokenAsync() async throws -> String {
        // Attempt to retrieve the token from keychain
        let tokenResult = keychainManager.retrieveString(key: accessTokenKey)
        
        switch tokenResult {
        case .success(let token):
            // Check if token is expired or will expire soon
            if isTokenExpired(token) {
                Logger.shared.debug("Access token expired or expiring soon, attempting refresh", category: .authentication)
                // Refresh the token
                try await refreshTokensAsync()
                
                // After refresh, get the new token
                let newTokenResult = keychainManager.retrieveString(key: accessTokenKey)
                switch newTokenResult {
                case .success(let newToken):
                    return newToken
                case .failure:
                    throw TokenError.tokenNotFound
                }
            } else {
                // Token is still valid
                Logger.shared.debug("Using existing valid access token", category: .authentication)
                return token
            }
        case .failure:
            Logger.shared.error("Access token not found in keychain", category: .authentication)
            throw TokenError.tokenNotFound
        }
    }
    
    /// Retrieves the current refresh token
    /// - Returns: Result containing refresh token or error
    func getRefreshToken() -> Result<String, TokenError> {
        let tokenResult = keychainManager.retrieveString(key: refreshTokenKey)
        
        switch tokenResult {
        case .success(let token):
            return .success(token)
        case .failure:
            Logger.shared.error("Refresh token not found in keychain", category: .authentication)
            return .failure(.tokenNotFound)
        }
    }
    
    /// Refreshes the access and refresh tokens using the current refresh token
    /// - Parameter completion: Completion handler with result indicating success or error
    func refreshTokens(completion: @escaping (Result<Void, TokenError>) -> Void) {
        // Ensure refresh service is configured
        guard let refreshService = tokenRefreshService else {
            Logger.shared.error("Token refresh service not configured", category: .authentication)
            completion(.failure(.refreshFailed))
            return
        }
        
        // If already refreshing, wait for the current refresh to complete
        if refreshInProgress {
            Logger.shared.debug("Token refresh already in progress, waiting for completion", category: .authentication)
            // Subscribe to refresh subject to be notified when the refresh completes
            let cancellable = refreshSubject.sink { result in
                completion(result)
            }
            
            // Store cancellable if needed to prevent it from being deallocated
            // This is a simplified example; in a real app, you would manage the cancellable
            _ = cancellable
            return
        }
        
        // Set flag to indicate refresh is in progress
        refreshInProgress = true
        
        // Get the current refresh token
        let refreshTokenResult = getRefreshToken()
        switch refreshTokenResult {
        case .success(let refreshToken):
            Logger.shared.debug("Starting token refresh process", category: .authentication)
            
            // Call the refresh service
            refreshService.refreshToken(with: refreshToken) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let tokenResponse):
                    Logger.shared.debug("Token refresh successful", category: .authentication)
                    
                    // Save the new tokens
                    let saveResult = self.saveTokens(accessToken: tokenResponse.accessToken, refreshToken: tokenResponse.refreshToken)
                    
                    // Reset refresh in progress flag
                    self.refreshInProgress = false
                    
                    // Notify waiting subscribers
                    self.refreshSubject.send(saveResult)
                    
                    // Call completion handler
                    completion(saveResult)
                    
                case .failure(let error):
                    Logger.shared.error("Token refresh failed: \(error.localizedDescription)", category: .authentication)
                    
                    // Reset refresh in progress flag
                    self.refreshInProgress = false
                    
                    // Notify waiting subscribers
                    self.refreshSubject.send(.failure(.refreshFailed))
                    
                    // Call completion handler
                    completion(.failure(.refreshFailed))
                }
            }
            
        case .failure(let error):
            // Reset refresh in progress flag
            refreshInProgress = false
            
            // Notify waiting subscribers
            refreshSubject.send(.failure(error))
            
            // Call completion handler
            completion(.failure(error))
        }
    }
    
    /// Refreshes the access and refresh tokens using async/await
    /// - Returns: Success or throws an error
    @available(iOS 15.0, *)
    func refreshTokensAsync() async throws {
        // Ensure refresh service is configured
        guard let refreshService = tokenRefreshService else {
            Logger.shared.error("Token refresh service not configured", category: .authentication)
            throw TokenError.refreshFailed
        }
        
        // If already refreshing, wait for the current refresh to complete
        if refreshInProgress {
            Logger.shared.debug("Token refresh already in progress, waiting for completion", category: .authentication)
            // Wait for the current refresh to complete
            let result = await refreshSubject.first()
            if case .failure(let error) = result {
                throw error
            }
            return
        }
        
        // Set flag to indicate refresh is in progress
        refreshInProgress = true
        
        do {
            // Get the current refresh token
            let refreshTokenResult = getRefreshToken()
            
            let refreshToken: String
            switch refreshTokenResult {
            case .success(let token):
                refreshToken = token
            case .failure(let error):
                // Reset flag and propagate error
                refreshInProgress = false
                refreshSubject.send(.failure(error))
                throw error
            }
            
            Logger.shared.debug("Starting token refresh process", category: .authentication)
            
            // Call the refresh service
            let tokenResponse = try await refreshService.refreshTokenAsync(with: refreshToken)
            
            Logger.shared.debug("Token refresh successful", category: .authentication)
            
            // Save the new tokens
            let saveResult = saveTokens(accessToken: tokenResponse.accessToken, refreshToken: tokenResponse.refreshToken)
            
            // Reset refresh in progress flag
            refreshInProgress = false
            
            // Handle save result
            switch saveResult {
            case .success:
                refreshSubject.send(.success(()))
                return
            case .failure(let error):
                refreshSubject.send(.failure(error))
                throw error
            }
            
        } catch {
            // Reset refresh in progress flag
            refreshInProgress = false
            
            // Notify waiting subscribers
            refreshSubject.send(.failure(.refreshFailed))
            
            // Propagate error
            if let tokenError = error as? TokenError {
                throw tokenError
            } else {
                throw TokenError.refreshFailed
            }
        }
    }
    
    /// Removes all authentication tokens from secure storage
    /// - Returns: Result indicating success or specific error
    func clearTokens() -> Result<Void, TokenError> {
        Logger.shared.debug("Clearing authentication tokens", category: .authentication)
        
        // Delete access token
        let accessTokenResult = keychainManager.delete(key: accessTokenKey)
        
        // Delete refresh token
        let refreshTokenResult = keychainManager.delete(key: refreshTokenKey)
        
        // Check if either operation failed
        if case .failure = accessTokenResult, case .failure = refreshTokenResult {
            Logger.shared.error("Failed to clear authentication tokens", category: .authentication)
            return .failure(.storageError)
        }
        
        Logger.shared.debug("Authentication tokens cleared successfully", category: .authentication)
        return .success(())
    }
    
    /// Checks if a JWT token is expired or will expire soon
    /// - Parameter token: The JWT token to check
    /// - Returns: True if token is expired or expiring soon, false otherwise
    func isTokenExpired(_ token: String) -> Bool {
        do {
            // Decode the JWT token
            let jwt = try decode(jwt: token)
            
            // Get the expiration date
            guard let expirationDate = jwt.expiresAt else {
                Logger.shared.error("Token does not contain expiration date", category: .authentication)
                return true
            }
            
            // Calculate buffer time (current time + buffer)
            let bufferDate = Date().addingTimeInterval(tokenExpirationBufferSeconds)
            
            // Token is expired if expiration date is before buffer date
            let isExpiring = expirationDate < bufferDate
            
            if isExpiring {
                Logger.shared.debug("Token is expiring soon or already expired", category: .authentication)
            }
            
            return isExpiring
            
        } catch {
            Logger.shared.error("Failed to decode JWT token: \(error.localizedDescription)", category: .authentication)
            return true
        }
    }
    
    /// Extracts the user ID from the access token
    /// - Returns: Result containing user ID or error
    func getUserIdFromToken() -> Result<String, TokenError> {
        // Get access token
        let tokenResult = keychainManager.retrieveString(key: accessTokenKey)
        
        switch tokenResult {
        case .success(let token):
            do {
                // Decode the JWT token
                let jwt = try decode(jwt: token)
                
                // Extract the subject claim (user ID)
                if let subject = jwt.subject {
                    return .success(subject)
                } else {
                    Logger.shared.error("Token does not contain subject (user ID)", category: .authentication)
                    return .failure(.invalidToken)
                }
                
            } catch {
                Logger.shared.error("Failed to decode JWT token: \(error.localizedDescription)", category: .authentication)
                return .failure(.invalidToken)
            }
            
        case .failure:
            Logger.shared.error("Access token not found in keychain", category: .authentication)
            return .failure(.tokenNotFound)
        }
    }
    
    /// Extracts the user ID from the access token using async/await
    /// - Returns: User ID or throws an error
    @available(iOS 15.0, *)
    func getUserIdFromTokenAsync() async throws -> String {
        // Get access token
        let token = try await getAccessTokenAsync()
        
        do {
            // Decode the JWT token
            let jwt = try decode(jwt: token)
            
            // Extract the subject claim (user ID)
            if let subject = jwt.subject {
                return subject
            } else {
                Logger.shared.error("Token does not contain subject (user ID)", category: .authentication)
                throw TokenError.invalidToken
            }
            
        } catch {
            Logger.shared.error("Failed to decode JWT token: \(error.localizedDescription)", category: .authentication)
            if let tokenError = error as? TokenError {
                throw tokenError
            } else {
                throw TokenError.invalidToken
            }
        }
    }
    
    /// Gets the expiration date of the current access token
    /// - Returns: Result containing expiration date or error
    func getTokenExpirationDate() -> Result<Date, TokenError> {
        // Get access token
        let tokenResult = keychainManager.retrieveString(key: accessTokenKey)
        
        switch tokenResult {
        case .success(let token):
            do {
                // Decode the JWT token
                let jwt = try decode(jwt: token)
                
                // Get the expiration date
                guard let expirationDate = jwt.expiresAt else {
                    Logger.shared.error("Token does not contain expiration date", category: .authentication)
                    return .failure(.invalidToken)
                }
                
                return .success(expirationDate)
                
            } catch {
                Logger.shared.error("Failed to decode JWT token: \(error.localizedDescription)", category: .authentication)
                return .failure(.invalidToken)
            }
            
        case .failure:
            Logger.shared.error("Access token not found in keychain", category: .authentication)
            return .failure(.tokenNotFound)
        }
    }
    
    /// Checks if the user has valid authentication tokens
    /// - Returns: True if valid tokens exist, false otherwise
    func hasValidTokens() -> Bool {
        // Check for access token
        let tokenResult = keychainManager.retrieveString(key: accessTokenKey)
        
        switch tokenResult {
        case .success(let token):
            // Check if token is not expired
            if !isTokenExpired(token) {
                return true
            }
            
            // If expired, check if we have a refresh token
            let refreshTokenResult = keychainManager.retrieveString(key: refreshTokenKey)
            return refreshTokenResult.isSuccess
            
        case .failure:
            // No access token found
            return false
        }
    }
    
    /// Formats an access token for use in Authorization header
    /// - Parameter token: The raw access token
    /// - Returns: Formatted authorization header value
    func formatAuthorizationHeader(token: String) -> String {
        return "\(ApiConstants.Headers.bearerToken) \(token)"
    }
}