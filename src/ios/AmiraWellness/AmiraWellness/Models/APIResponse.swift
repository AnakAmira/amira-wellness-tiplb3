//
// APIResponse.swift
// AmiraWellness
//
// Standard response models for API communication
//

import Foundation // Latest

/// A generic structure for standard API responses
struct APIResponse<T: Decodable>: Decodable {
    /// The response data
    let data: T
    /// Indicates if the request was successful
    let success: Bool
    /// Optional message from the server
    let message: String?
    
    /// Initializes an APIResponse with the provided parameters
    /// - Parameters:
    ///   - data: The response data
    ///   - success: Whether the request was successful
    ///   - message: Optional message from the server
    init(data: T, success: Bool, message: String? = nil) {
        self.data = data
        self.success = success
        self.message = message
    }
    
    /// Decodes an API response from JSON data
    /// - Parameters:
    ///   - data: The JSON data to decode
    ///   - statusCode: The HTTP status code of the response
    /// - Returns: A result containing either the decoded data or an error
    static func decode(data: Data, statusCode: Int) -> Result<T, APIError> {
        // Check if status code is in the success range (200-299)
        guard (200..<300).contains(statusCode) else {
            // Try to decode error response
            do {
                let decoder = JSONDecoder()
                let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
                return .failure(APIError.fromErrorResponse([
                    "code": errorResponse.code ?? "UNKNOWN",
                    "message": errorResponse.message,
                    "details": errorResponse.details ?? [:]
                ]))
            } catch {
                // If error decoding fails, return a generic error based on status code
                return .failure(APIError.fromResponseStatusCode(statusCode))
            }
        }
        
        // Decode the successful response
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(APIResponse<T>.self, from: data)
            return .success(response.data)
        } catch {
            return .failure(APIError.invalidResponse(message: "Failed to decode response: \(error.localizedDescription)"))
        }
    }
}

/// A generic structure for paginated API responses
struct PaginatedAPIResponse<T: Decodable>: Decodable {
    /// Array of items in the current page
    let items: [T]
    /// Pagination metadata
    let pagination: PaginationMetadata
    /// Indicates if the request was successful
    let success: Bool
    /// Optional message from the server
    let message: String?
    
    /// Initializes a PaginatedAPIResponse with the provided parameters
    /// - Parameters:
    ///   - items: Array of items in the current page
    ///   - pagination: Pagination metadata
    ///   - success: Whether the request was successful
    ///   - message: Optional message from the server
    init(items: [T], pagination: PaginationMetadata, success: Bool, message: String? = nil) {
        self.items = items
        self.pagination = pagination
        self.success = success
        self.message = message
    }
    
    /// Decodes a paginated API response from JSON data
    /// - Parameters:
    ///   - data: The JSON data to decode
    ///   - statusCode: The HTTP status code of the response
    /// - Returns: A result containing either the decoded paginated data or an error
    static func decode(data: Data, statusCode: Int) -> Result<PaginatedAPIResponse<T>, APIError> {
        // Check if status code is in the success range (200-299)
        guard (200..<300).contains(statusCode) else {
            // Try to decode error response
            do {
                let decoder = JSONDecoder()
                let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
                return .failure(APIError.fromErrorResponse([
                    "code": errorResponse.code ?? "UNKNOWN",
                    "message": errorResponse.message,
                    "details": errorResponse.details ?? [:]
                ]))
            } catch {
                // If error decoding fails, return a generic error based on status code
                return .failure(APIError.fromResponseStatusCode(statusCode))
            }
        }
        
        // Decode the successful response
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(PaginatedAPIResponse<T>.self, from: data)
            return .success(response)
        } catch {
            return .failure(APIError.invalidResponse(message: "Failed to decode paginated response: \(error.localizedDescription)"))
        }
    }
    
    /// Determines if there are more pages of data available
    /// - Returns: True if there are more pages, false otherwise
    func hasNextPage() -> Bool {
        return pagination.page < pagination.totalPages
    }
    
    /// Determines if there are previous pages of data available
    /// - Returns: True if there are previous pages, false otherwise
    func hasPreviousPage() -> Bool {
        return pagination.page > 1
    }
}

/// Structure containing pagination metadata for paginated responses
struct PaginationMetadata: Decodable {
    /// Current page number
    let page: Int
    /// Number of items per page
    let perPage: Int
    /// Total number of pages
    let totalPages: Int
    /// Total number of items across all pages
    let totalItems: Int
    
    /// Initializes a PaginationMetadata with the provided parameters
    /// - Parameters:
    ///   - page: Current page number
    ///   - perPage: Number of items per page
    ///   - totalPages: Total number of pages
    ///   - totalItems: Total number of items across all pages
    init(page: Int, perPage: Int, totalPages: Int, totalItems: Int) {
        self.page = page
        self.perPage = perPage
        self.totalPages = totalPages
        self.totalItems = totalItems
    }
}

/// A structure for API responses that don't return data
struct EmptyResponse: Decodable {
    /// Indicates if the request was successful
    let success: Bool
    /// Optional message from the server
    let message: String?
    
    /// Initializes an EmptyResponse with the provided parameters
    /// - Parameters:
    ///   - success: Whether the request was successful
    ///   - message: Optional message from the server
    init(success: Bool, message: String? = nil) {
        self.success = success
        self.message = message
    }
    
    /// Decodes an empty API response from JSON data
    /// - Parameters:
    ///   - data: The JSON data to decode
    ///   - statusCode: The HTTP status code of the response
    /// - Returns: A result containing either the empty response or an error
    static func decode(data: Data, statusCode: Int) -> Result<EmptyResponse, APIError> {
        // Check if status code is in the success range (200-299)
        guard (200..<300).contains(statusCode) else {
            // Try to decode error response
            do {
                let decoder = JSONDecoder()
                let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
                return .failure(APIError.fromErrorResponse([
                    "code": errorResponse.code ?? "UNKNOWN",
                    "message": errorResponse.message,
                    "details": errorResponse.details ?? [:]
                ]))
            } catch {
                // If error decoding fails, return a generic error based on status code
                return .failure(APIError.fromResponseStatusCode(statusCode))
            }
        }
        
        // Decode the successful response
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(EmptyResponse.self, from: data)
            return .success(response)
        } catch {
            return .failure(APIError.invalidResponse(message: "Failed to decode empty response: \(error.localizedDescription)"))
        }
    }
}

/// A structure for API error responses
struct ErrorResponse: Decodable {
    /// Indicates the request failed (typically false)
    let success: Bool
    /// Error message from the server
    let message: String
    /// Optional error code
    let code: String?
    /// Optional additional error details
    let details: [String: Any]?
    
    /// Initializes an ErrorResponse with the provided parameters
    /// - Parameters:
    ///   - success: Whether the request was successful (typically false)
    ///   - message: Error message from the server
    ///   - code: Optional error code
    ///   - details: Optional additional error details
    init(success: Bool, message: String, code: String? = nil, details: [String: Any]? = nil) {
        self.success = success
        self.message = message
        self.code = code
        self.details = details
    }
    
    private enum CodingKeys: String, CodingKey {
        case success, message, code, details
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        message = try container.decode(String.self, forKey: .message)
        code = try container.decodeIfPresent(String.self, forKey: .code)
        
        // Handle details as a generic dictionary
        if let detailsData = try container.decodeIfPresent(Data.self, forKey: .details) {
            details = try JSONSerialization.jsonObject(with: detailsData) as? [String: Any]
        } else {
            details = nil
        }
    }
}