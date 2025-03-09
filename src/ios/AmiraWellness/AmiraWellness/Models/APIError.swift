import Foundation // Latest

/// An enumeration representing various API error types that can occur during network operations
/// in the Amira Wellness application. This provides a standardized way to handle errors
/// from the backend API and present appropriate feedback to the user.
enum APIError: Error, Equatable {
    /// The request was invalid (HTTP 400)
    case invalidRequest(message: String)
    
    /// The server response could not be parsed or was otherwise invalid
    case invalidResponse(message: String)
    
    /// A network-related error occurred (connectivity issues, timeouts)
    case networkError(message: String?)
    
    /// Authentication failed (HTTP 401)
    case authenticationError(code: String, message: String)
    
    /// The user is not authorized to perform the requested action (HTTP 403)
    case authorizationError(code: String, message: String)
    
    /// The requested resource was not found (HTTP 404)
    case resourceNotFound(resourceType: String, resourceId: String, message: String)
    
    /// The request contained invalid data (HTTP 422)
    case validationError(field: String, message: String)
    
    /// An error occurred on the server (HTTP 500, 502, 503, 504)
    case serverError(code: String, message: String)
    
    /// An error related to encryption/decryption operations
    case encryptionError(code: String, message: String)
    
    /// The client has sent too many requests (HTTP 429)
    case rateLimitExceeded(retryAfter: Int, message: String)
    
    /// An unknown or unexpected error occurred
    case unknown(message: String?)
    
    /// Returns a user-friendly localized description of the error
    var localizedDescription: String {
        switch self {
        case .invalidRequest(let message):
            return NSLocalizedString("The request was invalid: \(message)", comment: "Invalid request error")
        case .invalidResponse(let message):
            return NSLocalizedString("The server response was invalid: \(message)", comment: "Invalid response error")
        case .networkError(let message):
            let defaultMessage = NSLocalizedString("A network error occurred. Please check your internet connection and try again.", comment: "Network error")
            return message.map { NSLocalizedString("Network error: \($0)", comment: "Specific network error") } ?? defaultMessage
        case .authenticationError(_, let message):
            return NSLocalizedString("Authentication error: \(message)", comment: "Authentication error")
        case .authorizationError(_, let message):
            return NSLocalizedString("Authorization error: \(message)", comment: "Authorization error")
        case .resourceNotFound(let resourceType, let resourceId, _):
            return NSLocalizedString("The requested \(resourceType) (\(resourceId)) could not be found.", comment: "Resource not found error")
        case .validationError(let field, let message):
            return NSLocalizedString("Validation error for \(field): \(message)", comment: "Validation error")
        case .serverError(_, let message):
            return NSLocalizedString("Server error: \(message)", comment: "Server error")
        case .encryptionError(_, let message):
            return NSLocalizedString("Encryption error: \(message)", comment: "Encryption error")
        case .rateLimitExceeded(let retryAfter, _):
            return NSLocalizedString("Too many requests. Please try again in \(retryAfter) seconds.", comment: "Rate limit exceeded error")
        case .unknown(let message):
            let defaultMessage = NSLocalizedString("An unknown error occurred.", comment: "Unknown error")
            return message.map { NSLocalizedString("Error: \($0)", comment: "Specific unknown error") } ?? defaultMessage
        }
    }
    
    /// Returns the error code associated with this error
    var errorCode: String {
        switch self {
        case .invalidRequest:
            return "AMIRA_INVALID_REQUEST"
        case .invalidResponse:
            return "AMIRA_INVALID_RESPONSE"
        case .networkError:
            return "AMIRA_NETWORK_ERROR"
        case .authenticationError(let code, _):
            return "AMIRA_AUTH_\(code)"
        case .authorizationError(let code, _):
            return "AMIRA_PERM_\(code)"
        case .resourceNotFound:
            return "AMIRA_RESOURCE_NOT_FOUND"
        case .validationError(let field, _):
            return "AMIRA_VALIDATION_\(field.uppercased())"
        case .serverError(let code, _):
            return "AMIRA_SERVER_\(code)"
        case .encryptionError(let code, _):
            return "AMIRA_ENCRYPTION_\(code)"
        case .rateLimitExceeded:
            return "AMIRA_RATE_LIMIT_EXCEEDED"
        case .unknown:
            return "AMIRA_UNKNOWN_ERROR"
        }
    }
    
    /// Creates an APIError from a JSON error response from the server
    ///
    /// - Parameter errorResponse: The error response dictionary from the server
    /// - Returns: An appropriate APIError case based on the error response
    static func fromErrorResponse(_ errorResponse: [String: Any]) -> APIError {
        // Extract error details from the response
        let code = (errorResponse["code"] as? String) ?? "UNKNOWN"
        let message = (errorResponse["message"] as? String) ?? "An unknown error occurred"
        let details = errorResponse["details"] as? [String: Any]
        
        // Determine the error type based on the error code prefix
        if code.starts(with: "AUTH_") {
            return .authenticationError(code: code, message: message)
        } else if code.starts(with: "PERM_") {
            return .authorizationError(code: code, message: message)
        } else if code.starts(with: "VAL_") {
            let field = (details?["field"] as? String) ?? "unknown"
            return .validationError(field: field, message: message)
        } else if code.starts(with: "RES_") {
            let resourceType = (details?["resourceType"] as? String) ?? "resource"
            let resourceId = (details?["resourceId"] as? String) ?? "unknown"
            return .resourceNotFound(resourceType: resourceType, resourceId: resourceId, message: message)
        } else if code.starts(with: "BUS_") {
            return .invalidRequest(message: message)
        } else if code.starts(with: "SYS_") {
            return .serverError(code: code, message: message)
        } else if code.starts(with: "ENC_") {
            return .encryptionError(code: code, message: message)
        } else if code == "RATE_LIMIT_EXCEEDED" {
            let retryAfter = (details?["retryAfter"] as? Int) ?? 60
            return .rateLimitExceeded(retryAfter: retryAfter, message: message)
        } else {
            return .unknown(message: message)
        }
    }
    
    /// Creates an APIError from an HTTP status code
    ///
    /// - Parameters:
    ///   - statusCode: The HTTP status code
    ///   - message: Optional error message
    /// - Returns: An appropriate APIError case based on the HTTP status code
    static func fromResponseStatusCode(_ statusCode: Int, message: String? = nil) -> APIError {
        let defaultMessage = message ?? "HTTP Error \(statusCode)"
        
        switch statusCode {
        case 400:
            return .invalidRequest(message: defaultMessage)
        case 401:
            return .authenticationError(code: "UNAUTHORIZED", message: defaultMessage)
        case 403:
            return .authorizationError(code: "FORBIDDEN", message: defaultMessage)
        case 404:
            return .resourceNotFound(resourceType: "resource", resourceId: "unknown", message: defaultMessage)
        case 422:
            return .validationError(field: "unknown", message: defaultMessage)
        case 429:
            return .rateLimitExceeded(retryAfter: 60, message: defaultMessage)
        case 500, 502, 503, 504:
            return .serverError(code: "SERVER_ERROR", message: defaultMessage)
        default:
            return .unknown(message: defaultMessage)
        }
    }
}