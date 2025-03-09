//
//  RequestInterceptor.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // Latest
import Alamofire // ~> 5.6

/// A class that implements Alamofire's RequestInterceptor protocol to handle authentication and retry logic for network requests
class RequestInterceptor: Alamofire.RequestInterceptor {
    private let tokenManager: TokenManager
    private let networkMonitor: NetworkMonitor
    private let maxRetryCount: Int
    private let retryableStatusCodes: Set<Int>
    private let retryableHTTPMethods: Set<HTTPMethod>
    private let nonAuthenticatedEndpoints: [String]
    
    // Track retry counts for requests using a URL string as key
    private var retryCounters = [String: Int]()
    
    /// Initializes the RequestInterceptor with dependencies and configuration
    /// - Parameters:
    ///   - tokenManager: The TokenManager instance for managing authentication tokens
    ///   - networkMonitor: The NetworkMonitor instance for checking network connectivity
    ///   - maxRetryCount: The maximum number of retry attempts (default: 3)
    init(tokenManager: TokenManager? = nil, networkMonitor: NetworkMonitor? = nil, maxRetryCount: Int? = nil) {
        self.tokenManager = tokenManager ?? TokenManager.shared
        self.networkMonitor = networkMonitor ?? NetworkMonitor.shared
        self.maxRetryCount = maxRetryCount ?? 3
        
        // Initialize retryable status codes with server error codes
        self.retryableStatusCodes = [500, 502, 503, 504]
        
        // Initialize retryable HTTP methods with idempotent methods
        self.retryableHTTPMethods = [.get, .head, .put, .delete, .options, .trace]
        
        // Initialize non-authenticated endpoints
        self.nonAuthenticatedEndpoints = [
            ApiConstants.Endpoints.health,
            "\(ApiConstants.Endpoints.auth)/\(ApiConstants.Endpoints.login)",
            "\(ApiConstants.Endpoints.auth)/\(ApiConstants.Endpoints.register)",
            "\(ApiConstants.Endpoints.auth)/\(ApiConstants.Endpoints.refreshToken)"
        ]
    }
    
    // MARK: - RequestAdapter
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        // Check if this is a non-authenticated endpoint
        if isNonAuthenticatedEndpoint(urlRequest) {
            // Non-authenticated endpoint, no adaptation needed
            completion(.success(urlRequest))
            return
        }
        
        // Get the access token from TokenManager
        tokenManager.getAccessToken { [weak self] result in
            guard let self = self else {
                completion(.success(urlRequest))
                return
            }
            
            switch result {
            case .success(let token):
                var adaptedRequest = urlRequest
                
                // Add Authorization header with Bearer token
                adaptedRequest.setValue("\(ApiConstants.Headers.bearerToken) \(token)", forHTTPHeaderField: ApiConstants.Headers.authorization)
                
                // Log the request adaptation (without sensitive data)
                Logger.shared.logNetwork("Adapted request with authentication token: \(adaptedRequest.url?.absoluteString ?? "unknown URL")", level: .debug)
                
                completion(.success(adaptedRequest))
                
            case .failure(let error):
                // Token retrieval failed
                Logger.shared.logNetwork("Failed to adapt request with authentication token: \(error.localizedDescription)", level: .error)
                completion(.failure(APIError.authenticationError(code: "TOKEN_RETRIEVAL_FAILED", message: error.localizedDescription)))
            }
        }
    }
    
    // MARK: - RequestRetrier
    
    func retry(_ request: URLRequest, for session: Session, duringError error: Error, completion: @escaping (RetryResult) -> Void) {
        // Check if network is connected
        guard networkMonitor.isConnected() else {
            Logger.shared.logNetwork("Retry aborted: No network connection", level: .warning)
            completion(.doNotRetry)
            return
        }
        
        // Create a key for tracking this request's retry count
        guard let requestUrl = request.url?.absoluteString else {
            completion(.doNotRetry)
            return
        }
        let requestKey = "\(request.httpMethod ?? "GET"):\(requestUrl)"
        
        // Get current retry count and increment it
        let retryCount = retryCounters[requestKey, default: 0]
        retryCounters[requestKey] = retryCount + 1
        
        // Check if retry count exceeds max retry count
        guard retryCount < maxRetryCount else {
            Logger.shared.logNetwork("Retry aborted: Maximum retry count (\(maxRetryCount)) exceeded", level: .warning)
            // Clean up the counter for this request
            retryCounters[requestKey] = nil
            completion(.doNotRetry)
            return
        }
        
        // Get the response from the error
        let response = getResponse(from: error)
        
        // Check if the error is an authentication error
        if isAuthenticationError(error, response: response) {
            // Token expired or invalid, attempt to refresh
            Logger.shared.logNetwork("Authentication error detected, attempting token refresh", level: .info)
            
            tokenManager.refreshTokens { [weak self] result in
                guard let self = self else {
                    completion(.doNotRetry)
                    return
                }
                
                switch result {
                case .success:
                    // Token refresh successful, retry the request
                    Logger.shared.logNetwork("Token refresh successful, retrying request", level: .info)
                    completion(.retry)
                    
                case .failure(let error):
                    // Token refresh failed
                    Logger.shared.logNetwork("Token refresh failed: \(error.localizedDescription), not retrying", level: .error)
                    // Clean up the counter for this request
                    self.retryCounters[requestKey] = nil
                    completion(.doNotRetry)
                }
            }
        }
        // Check if this is a retryable error based on status code and HTTP method
        else if shouldRetry(request: request, response: response, error: error, retryCount: retryCount) {
            // Calculate retry delay using exponential backoff
            let delay = calculateRetryDelay(retryCount: retryCount)
            
            Logger.shared.logNetwork("Request failed with retryable error, will retry in \(delay) seconds (attempt \(retryCount + 1)/\(maxRetryCount))", level: .info)
            completion(.retryWithDelay(delay))
        } else {
            // Not a retryable error or condition
            Logger.shared.logNetwork("Request failed with non-retryable error: \(error.localizedDescription)", level: .warning)
            // Clean up the counter for this request
            retryCounters[requestKey] = nil
            completion(.doNotRetry)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Extracts the HTTPURLResponse from an error
    /// - Parameter error: The error that might contain a response
    /// - Returns: The HTTPURLResponse if available, nil otherwise
    private func getResponse(from error: Error) -> HTTPURLResponse? {
        // Handle Alamofire errors
        if let afError = error as? AFError {
            return afError.response
        }
        
        // Try to find a response in the userInfo dictionary for other error types
        let nsError = error as NSError
        for (_, value) in nsError.userInfo where value is HTTPURLResponse {
            return value as? HTTPURLResponse
        }
        
        return nil
    }
    
    /// Determines if a request should be retried based on status code and HTTP method
    /// - Parameters:
    ///   - request: The URLRequest that failed
    ///   - response: The HTTP response
    ///   - error: The error that occurred
    ///   - retryCount: The current retry count
    /// - Returns: True if the request should be retried, false otherwise
    private func shouldRetry(request: URLRequest, response: HTTPURLResponse?, error: Error, retryCount: Int) -> Bool {
        // Check retry count
        guard retryCount < maxRetryCount else {
            return false
        }
        
        // Check if the response status code is in retryableStatusCodes
        if let statusCode = response?.statusCode, retryableStatusCodes.contains(statusCode) {
            // Check if the request HTTP method is in retryableHTTPMethods
            if let httpMethod = request.httpMethod, let method = HTTPMethod(rawValue: httpMethod) {
                return retryableHTTPMethods.contains(method)
            }
        }
        
        // Check for specific error types that should be retried
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet, .dnsLookupFailed, .cannotConnectToHost:
                return true
            default:
                break
            }
        }
        
        return false
    }
    
    /// Calculates the delay before retrying a request using exponential backoff
    /// - Parameter retryCount: The current retry count
    /// - Returns: The delay in seconds before retrying
    private func calculateRetryDelay(retryCount: Int) -> TimeInterval {
        // Calculate base delay using exponential formula (2^retryCount)
        let baseDelay = pow(2.0, Double(retryCount))
        
        // Add jitter by multiplying by a random factor between 0.5 and 1.5
        let jitter = Double.random(in: 0.5...1.5)
        let delay = baseDelay * jitter
        
        // Ensure the delay doesn't exceed a maximum value (e.g., 10 seconds)
        return min(delay, 10.0)
    }
    
    /// Determines if an error is an authentication error
    /// - Parameters:
    ///   - error: The error to check
    ///   - response: The HTTP response
    /// - Returns: True if the error is an authentication error, false otherwise
    private func isAuthenticationError(_ error: Error, response: HTTPURLResponse?) -> Bool {
        // Check if it's an APIError.authenticationError
        if let apiError = error as? APIError {
            if case .authenticationError = apiError {
                return true
            }
        }
        
        // Check if it's an AFError with 401 status code
        if let afError = error as? AFError, afError.responseCode == 401 {
            return true
        }
        
        // Check if the response status code is 401 Unauthorized
        if let statusCode = response?.statusCode, statusCode == 401 {
            return true
        }
        
        return false
    }
    
    /// Determines if a request is for an endpoint that doesn't require authentication
    /// - Parameter request: The URLRequest to check
    /// - Returns: True if the endpoint doesn't require authentication, false otherwise
    private func isNonAuthenticatedEndpoint(_ request: URLRequest) -> Bool {
        guard let url = request.url?.absoluteString else {
            return false
        }
        
        // Check if this is the health check endpoint
        if url.contains(ApiConstants.Endpoints.health) {
            return true
        }
        
        // Check for auth-related endpoints that don't require authentication
        for endpoint in [ApiConstants.Endpoints.login, ApiConstants.Endpoints.register, ApiConstants.Endpoints.refreshToken] {
            if url.contains("\(ApiConstants.Endpoints.auth)/\(endpoint)") {
                return true
            }
        }
        
        return false
    }
}