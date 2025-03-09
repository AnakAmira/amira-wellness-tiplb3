# src/ios/AmiraWellness/AmiraWellness/Services/Network/APIClient.swift
import Foundation // Latest
import Alamofire // ~> 5.6
import Combine // Latest

// Internal imports
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift
import APIRouter // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIRouter.swift
import APIError // src/ios/AmiraWellness/AmiraWellness/Models/APIError.swift
import APIResponse // src/ios/AmiraWellness/AmiraWellness/Models/APIResponse.swift
import ApiConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ApiConstants.swift
import RequestInterceptor // src/ios/AmiraWellness/AmiraWellness/Services/Network/RequestInterceptor.swift
import NetworkMonitor // src/ios/AmiraWellness/AmiraWellness/Services/Network/NetworkMonitor.swift
import DataQueueService // src/ios/AmiraWellness/AmiraWellness/Services/Offline/DataQueueService.swift

/// A singleton class that handles network requests for the application
final class APIClient {
    /// Shared instance of the APIClient
    static let shared = APIClient()
    
    // MARK: - Private Properties
    
    /// Alamofire session for handling network requests
    private let session: Session
    
    /// Interceptor for handling authentication and request retries
    private let interceptor: RequestInterceptor
    
    /// Network monitor for checking connectivity status
    private let networkMonitor: NetworkMonitor
    
    /// Data queue service for handling offline requests
    private let dataQueueService: DataQueueService
    
    /// Cancellable for network status subscription
    private var networkCancellable: AnyCancellable?
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private init() {
        // Initialize RequestInterceptor for authentication handling
        self.interceptor = RequestInterceptor()
        
        // Configure Alamofire Session with interceptor and default timeouts
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = ApiConstants.Timeouts.default
        configuration.timeoutIntervalForResource = ApiConstants.Timeouts.default
        self.session = Session(configuration: configuration, interceptor: interceptor)
        
        // Get shared instance of NetworkMonitor
        self.networkMonitor = NetworkMonitor.shared
        
        // Get shared instance of DataQueueService
        self.dataQueueService = DataQueueService.shared
        
        // Subscribe to network status changes to process queued requests when connectivity is restored
        networkCancellable = networkMonitor.statusPublisher
            .sink { [weak self] status in
                self?.handleNetworkStatusChange(status: status)
            }
        
        Logger.shared.debug("APIClient initialized", category: .network)
    }
    
    // MARK: - Request Methods
    
    /// Performs a network request with the specified endpoint and handles response parsing
    /// - Parameters:
    ///   - endpoint: The API endpoint to request
    ///   - completion: Completion handler with the result
    func request<T: Decodable>(endpoint: APIRouter, completion: @escaping (Result<T, APIError>) -> Void) {
        // Check if network is connected
        guard networkMonitor.isConnected() else {
            Logger.shared.logNetwork("Device is offline, queuing request for endpoint: \(endpoint)", level: .warning)
            dataQueueService.queueRequest(
                type: .create, // Assuming all requests are create operations when offline
                endpoint: endpoint.path,
                requestData: nil, // No data to queue for now
                priority: .normal,
                headers: endpoint.headers
            )
            completion(.failure(.networkError(message: "Device is offline")))
            return
        }
        
        // Log the request details (without sensitive information)
        Logger.shared.logNetwork("Requesting endpoint: \(endpoint.path), method: \(endpoint.method)", level: .debug)
        
        // Perform the request using Alamofire session
        session.request(endpoint)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    // Validate the response status code
                    guard let statusCode = response.response?.statusCode else {
                        let error = APIError.invalidResponse(message: "Missing status code")
                        Logger.shared.error("Request failed: \(error.localizedDescription)", error: error, category: .network)
                        completion(.failure(error))
                        return
                    }
                    
                    // Parse the response data using APIResponse.decode
                    let result: Result<T, APIError> = APIResponse.decode(data: data, statusCode: statusCode)
                    
                    switch result {
                    case .success(let decodedData):
                        Logger.shared.logNetwork("Request successful for endpoint: \(endpoint.path)", level: .info)
                        completion(.success(decodedData))
                    case .failure(let error):
                        Logger.shared.error("Request failed: \(error.localizedDescription)", error: error, category: .network)
                        completion(.failure(error))
                    }
                    
                case .failure(let error):
                    // Handle error and create APIError
                    let apiError = self.handleError(error: error, response: response.response, data: response.data)
                    Logger.shared.error("Request failed: \(apiError.localizedDescription)", error: error, category: .network)
                    completion(.failure(apiError))
                }
            }
    }
    
    /// Performs a network request with the specified endpoint using async/await
    /// - Parameter endpoint: The API endpoint to request
    /// - Returns: Decoded response data or throws an error
    @available(iOS 15.0, *)
    func requestAsync<T: Decodable>(endpoint: APIRouter) async throws -> T {
        // Check if network is connected
        guard networkMonitor.isConnected() else {
            Logger.shared.logNetwork("Device is offline, throwing network error for endpoint: \(endpoint)", level: .warning)
            throw APIError.networkError(message: "Device is offline")
        }
        
        // Log the request details (without sensitive information)
        Logger.shared.logNetwork("Requesting endpoint: \(endpoint.path), method: \(endpoint.method)", level: .debug)
        
        return try await withCheckedThrowingContinuation { continuation in
            session.request(endpoint)
                .validate()
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        // Validate the response status code
                        guard let statusCode = response.response?.statusCode else {
                            let error = APIError.invalidResponse(message: "Missing status code")
                            Logger.shared.error("Request failed: \(error.localizedDescription)", error: error, category: .network)
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        // Parse the response data using APIResponse.decode
                        let result: Result<T, APIError> = APIResponse.decode(data: data, statusCode: statusCode)
                        
                        switch result {
                        case .success(let decodedData):
                            Logger.shared.logNetwork("Request successful for endpoint: \(endpoint.path)", level: .info)
                            continuation.resume(returning: decodedData)
                        case .failure(let error):
                            Logger.shared.error("Request failed: \(error.localizedDescription)", error: error, category: .network)
                            continuation.resume(throwing: error)
                        }
                        
                    case .failure(let error):
                        // Handle error and create APIError
                        let apiError = self.handleError(error: error, response: response.response, data: response.data)
                        Logger.shared.error("Request failed: \(apiError.localizedDescription)", error: error, category: .network)
                        continuation.resume(throwing: apiError)
                    }
                }
        }
    }
    
    /// Performs a network request for paginated data with the specified endpoint
    /// - Parameters:
    ///   - endpoint: The API endpoint to request
    ///   - completion: Completion handler with the result
    func requestPaginated<T: Decodable>(endpoint: APIRouter, completion: @escaping (Result<PaginatedAPIResponse<T>, APIError>) -> Void) {
        // Check if network is connected
        guard networkMonitor.isConnected() else {
            Logger.shared.logNetwork("Device is offline, queuing paginated request for endpoint: \(endpoint)", level: .warning)
            dataQueueService.queueRequest(
                type: .create, // Assuming all requests are create operations when offline
                endpoint: endpoint.path,
                requestData: nil, // No data to queue for now
                priority: .normal,
                headers: endpoint.headers
            )
            completion(.failure(.networkError(message: "Device is offline")))
            return
        }
        
        // Log the request details (without sensitive information)
        Logger.shared.logNetwork("Requesting paginated endpoint: \(endpoint.path), method: \(endpoint.method)", level: .debug)
        
        // Perform the request using Alamofire session
        session.request(endpoint)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    // Validate the response status code
                    guard let statusCode = response.response?.statusCode else {
                        let error = APIError.invalidResponse(message: "Missing status code")
                        Logger.shared.error("Request failed: \(error.localizedDescription)", error: error, category: .network)
                        completion(.failure(error))
                        return
                    }
                    
                    // Parse the response data using PaginatedAPIResponse.decode
                    let result: Result<PaginatedAPIResponse<T>, APIError> = PaginatedAPIResponse.decode(data: data, statusCode: statusCode)
                    
                    switch result {
                    case .success(let decodedData):
                        Logger.shared.logNetwork("Request successful for paginated endpoint: \(endpoint.path)", level: .info)
                        completion(.success(decodedData))
                    case .failure(let error):
                        Logger.shared.error("Request failed: \(error.localizedDescription)", error: error, category: .network)
                        completion(.failure(error))
                    }
                    
                case .failure(let error):
                    // Handle error and create APIError
                    let apiError = self.handleError(error: error, response: response.response, data: response.data)
                    Logger.shared.error("Request failed: \(apiError.localizedDescription)", error: error, category: .network)
                    completion(.failure(apiError))
                }
            }
    }
    
    /// Performs a network request for paginated data using async/await
    /// - Parameter endpoint: The API endpoint to request
    /// - Returns: Decoded paginated response or throws an error
    @available(iOS 15.0, *)
    func requestPaginatedAsync<T: Decodable>(endpoint: APIRouter) async throws -> PaginatedAPIResponse<T> {
        // Check if network is connected
        guard networkMonitor.isConnected() else {
            Logger.shared.logNetwork("Device is offline, throwing network error for paginated endpoint: \(endpoint)", level: .warning)
            throw APIError.networkError(message: "Device is offline")
        }
        
        // Log the request details (without sensitive information)
        Logger.shared.logNetwork("Requesting paginated endpoint: \(endpoint.path), method: \(endpoint.method)", level: .debug)
        
        return try await withCheckedThrowingContinuation { continuation in
            session.request(endpoint)
                .validate()
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        // Validate the response status code
                        guard let statusCode = response.response?.statusCode else {
                            let error = APIError.invalidResponse(message: "Missing status code")
                            Logger.shared.error("Request failed: \(error.localizedDescription)", error: error, category: .network)
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        // Parse the response data using PaginatedAPIResponse.decode
                        let result: Result<PaginatedAPIResponse<T>, APIError> = PaginatedAPIResponse.decode(data: data, statusCode: statusCode)
                        
                        switch result {
                        case .success(let decodedData):
                            Logger.shared.logNetwork("Request successful for paginated endpoint: \(endpoint.path)", level: .info)
                            continuation.resume(returning: decodedData)
                        case .failure(let error):
                            Logger.shared.error("Request failed: \(error.localizedDescription)", error: error, category: .network)
                            continuation.resume(throwing: error)
                        }
                        
                    case .failure(let error):
                        // Handle error and create APIError
                        let apiError = self.handleError(error: error, response: response.response, data: response.data)
                        Logger.shared.error("Request failed: \(apiError.localizedDescription)", error: error, category: .network)
                        continuation.resume(throwing: apiError)
                    }
                }
        }
    }
    
    /// Performs a network request that doesn't return data (like DELETE operations)
    /// - Parameters:
    ///   - endpoint: The API endpoint to request
    ///   - completion: Completion handler with the result
    func requestEmpty(endpoint: APIRouter, completion: @escaping (Result<Void, APIError>) -> Void) {
        // Check if network is connected
        guard networkMonitor.isConnected() else {
            Logger.shared.logNetwork("Device is offline, queuing empty request for endpoint: \(endpoint)", level: .warning)
            dataQueueService.queueRequest(
                type: .delete, // Assuming all requests are delete operations when offline
                endpoint: endpoint.path,
                requestData: nil, // No data to queue for now
                priority: .normal,
                headers: endpoint.headers
            )
            completion(.failure(.networkError(message: "Device is offline")))
            return
        }
        
        // Log the request details (without sensitive information)
        Logger.shared.logNetwork("Requesting empty endpoint: \(endpoint.path), method: \(endpoint.method)", level: .debug)
        
        // Perform the request using Alamofire session
        session.request(endpoint)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    // Validate the response status code
                    guard let statusCode = response.response?.statusCode else {
                        let error = APIError.invalidResponse(message: "Missing status code")
                        Logger.shared.error("Request failed: \(error.localizedDescription)", error: error, category: .network)
                        completion(.failure(error))
                        return
                    }
                    
                    // Parse the response using EmptyResponse.decode
                    let result: Result<Void, APIError> = EmptyResponse.decode(data: data, statusCode: statusCode).map { _ in }
                    
                    switch result {
                    case .success:
                        Logger.shared.logNetwork("Request successful for empty endpoint: \(endpoint.path)", level: .info)
                        completion(.success(()))
                    case .failure(let error):
                        Logger.shared.error("Request failed: \(error.localizedDescription)", error: error, category: .network)
                        completion(.failure(error))
                    }
                    
                case .failure(let error):
                    // Handle error and create APIError
                    let apiError = self.handleError(error: error, response: response.response, data: response.data)
                    Logger.shared.error("Request failed: \(apiError.localizedDescription)", error: error, category: .network)
                    completion(.failure(apiError))
                }
            }
    }
    
    /// Performs a network request that doesn't return data using async/await
    /// - Parameter endpoint: The API endpoint to request
    /// - Returns: Success or throws an error
    @available(iOS 15.0, *)
    func requestEmptyAsync(endpoint: APIRouter) async throws -> Void {
        // Check if network is connected
        guard networkMonitor.isConnected() else {
            Logger.shared.logNetwork("Device is offline, throwing network error for empty endpoint: \(endpoint)", level: .warning)
            throw APIError.networkError(message: "Device is offline")
        }
        
        // Log the request details (without sensitive information)
        Logger.shared.logNetwork("Requesting empty endpoint: \(endpoint.path), method: \(endpoint.method)", level: .debug)
        
        return try await withCheckedThrowingContinuation { continuation in
            session.request(endpoint)
                .validate()
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        // Validate the response status code
                        guard let statusCode = response.response?.statusCode else {
                            let error = APIError.invalidResponse(message: "Missing status code")
                            Logger.shared.error("Request failed: \(error.localizedDescription)", error: error, category: .network)
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        // Parse the response using EmptyResponse.decode
                        let result: Result<Void, APIError> = EmptyResponse.decode(data: data, statusCode: statusCode).map { _ in }
                        
                        switch result {
                        case .success:
                            Logger.shared.logNetwork("Request successful for empty endpoint: \(endpoint.path)", level: .info)
                            continuation.resume()
                        case .failure(let error):
                            Logger.shared.error("Request failed: \(error.localizedDescription)", error: error, category: .network)
                            continuation.resume(throwing: error)
                        }
                        
                    case .failure(let error):
                        // Handle error and create APIError
                        let apiError = self.handleError(error: error, response: response.response, data: response.data)
                        Logger.shared.error("Request failed: \(apiError.localizedDescription)", error: error, category: .network)
                        continuation.resume(throwing: apiError)
                    }
                }
        }
    }
    
    /// Uploads data (like audio recordings) to the specified endpoint
    /// - Parameters:
    ///   - endpoint: The API endpoint to upload to
    ///   - completion: Completion handler with the result
    ///   - progressHandler: Optional handler to track upload progress
    func uploadData<T: Decodable>(endpoint: APIRouter, completion: @escaping (Result<T, APIError>) -> Void, progressHandler: ((Progress) -> Void)? = nil) {
        // Check if network is connected
        guard networkMonitor.isConnected() else {
            Logger.shared.logNetwork("Device is offline, queuing upload for endpoint: \(endpoint)", level: .warning)
            dataQueueService.queueRequest(
                type: .upload,
                endpoint: endpoint.path,
                requestData: nil, // No data to queue for now
                priority: .high,
                headers: endpoint.headers
            )
            completion(.failure(.networkError(message: "Device is offline")))
            return
        }
        
        // Log the upload request details (without sensitive information)
        Logger.shared.logNetwork("Uploading data to endpoint: \(endpoint.path), method: \(endpoint.method)", level: .debug)
        
        // Create the upload request with multipart form data
        session.upload(multipartFormData: endpoint.multipartFormData!, with: endpoint)
            .uploadProgress { progress in
                // Configure progress tracking if progressHandler is provided
                progressHandler?(progress)
            }
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    // Validate the response status code
                    guard let statusCode = response.response?.statusCode else {
                        let error = APIError.invalidResponse(message: "Missing status code")
                        Logger.shared.error("Upload failed: \(error.localizedDescription)", error: error, category: .network)
                        completion(.failure(error))
                        return
                    }
                    
                    // Parse the response data using APIResponse.decode
                    let result: Result<T, APIError> = APIResponse.decode(data: data, statusCode: statusCode)
                    
                    switch result {
                    case .success(let decodedData):
                        Logger.shared.logNetwork("Upload successful for endpoint: \(endpoint.path)", level: .info)
                        completion(.success(decodedData))
                    case .failure(let error):
                        Logger.shared.error("Upload failed: \(error.localizedDescription)", error: error, category: .network)
                        completion(.failure(error))
                    }
                    
                case .failure(let error):
                    // Handle error and create APIError
                    let apiError = self.handleError(error: error, response: response.response, data: response.data)
                    Logger.shared.error("Upload failed: \(apiError.localizedDescription)", error: error, category: .network)
                    completion(.failure(apiError))
                }
            }
    }
    
    /// Uploads data using async/await with progress tracking
    /// - Parameters:
    ///   - endpoint: The API endpoint to upload to
    ///   - progressHandler: Optional handler to track upload progress
    /// - Returns: Decoded response data or throws an error
    @available(iOS 15.0, *)
    func uploadDataAsync<T: Decodable>(endpoint: APIRouter, progressHandler: ((Progress) -> Void)? = nil) async throws -> T {
        // Check if network is connected
        guard networkMonitor.isConnected() else {
            Logger.shared.logNetwork("Device is offline, throwing network error for upload to endpoint: \(endpoint)", level: .warning)
            throw APIError.networkError(message: "Device is offline")
        }
        
        // Log the upload request details (without sensitive information)
        Logger.shared.logNetwork("Uploading data to endpoint: \(endpoint.path), method: \(endpoint.method)", level: .debug)
        
        return try await withCheckedThrowingContinuation { continuation in
            session.upload(multipartFormData: endpoint.multipartFormData!, with: endpoint)
                .uploadProgress { progress in
                    // Configure progress tracking if progressHandler is provided
                    progressHandler?(progress)
                }
                .validate()
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        // Validate the response status code
                        guard let statusCode = response.response?.statusCode else {
                            let error = APIError.invalidResponse(message: "Missing status code")
                            Logger.shared.error("Upload failed: \(error.localizedDescription)", error: error, category: .network)
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        // Parse the response data using APIResponse.decode
                        let result: Result<T, APIError> = APIResponse.decode(data: data, statusCode: statusCode)
                        
                        switch result {
                        case .success(let decodedData):
                            Logger.shared.logNetwork("Upload successful for endpoint: \(endpoint.path)", level: .info)
                            continuation.resume(returning: decodedData)
                        case .failure(let error):
                            Logger.shared.error("Upload failed: \(error.localizedDescription)", error: error, category: .network)
                            continuation.resume(throwing: error)
                        }
                        
                    case .failure(let error):
                        // Handle error and create APIError
                        let apiError = self.handleError(error: error, response: response.response, data: response.data)
                        Logger.shared.error("Upload failed: \(apiError.localizedDescription)", error: error, category: .network)
                        continuation.resume(throwing: apiError)
                    }
                }
        }
    }
    
    /// Downloads a file from the specified endpoint
    /// - Parameters:
    ///   - endpoint: The API endpoint to download from
    ///   - destination: The URL to save the downloaded file to
    ///   - completion: Completion handler with the result (file URL or error)
    ///   - progressHandler: Optional handler to track download progress
    func downloadFile(endpoint: APIRouter, destination: URL, completion: @escaping (Result<URL, APIError>) -> Void, progressHandler: ((Progress) -> Void)? = nil) {
        // Check if network is connected
        guard networkMonitor.isConnected() else {
            Logger.shared.logNetwork("Device is offline, cannot download file from endpoint: \(endpoint)", level: .warning)
            completion(.failure(.networkError(message: "Device is offline")))
            return
        }
        
        // Log the download request details
        Logger.shared.logNetwork("Downloading file from endpoint: \(endpoint.path), method: \(endpoint.method)", level: .debug)
        
        // Create the download request
        session.download(endpoint, to: { _, _ in
            // Set the destination file URL
            return (.moveTo(destination), [.removePreviousFile, .createIntermediateDirectories])
        })
            .downloadProgress { progress in
                // Configure progress tracking if progressHandler is provided
                progressHandler?(progress)
            }
            .validate()
            .responseData { response in
                switch response.result {
                case .success:
                    // Validate the response status code
                    guard let statusCode = response.response?.statusCode else {
                        let error = APIError.invalidResponse(message: "Missing status code")
                        Logger.shared.error("Download failed: \(error.localizedDescription)", error: error, category: .network)
                        completion(.failure(error))
                        return
                    }
                    
                    if (200..<300).contains(statusCode) {
                        Logger.shared.logNetwork("Download successful for endpoint: \(endpoint.path)", level: .info)
                        completion(.success(destination))
                    } else {
                        let error = APIError.fromResponseStatusCode(statusCode)
                        Logger.shared.error("Download failed: \(error.localizedDescription)", error: error, category: .network)
                        completion(.failure(error))
                    }
                    
                case .failure(let error):
                    // Handle error and create APIError
                    let apiError = self.handleError(error: error, response: response.response, data: response.data)
                    Logger.shared.error("Download failed: \(apiError.localizedDescription)", error: error, category: .network)
                    completion(.failure(apiError))
                }
            }
    }
    
    /// Downloads a file using async/await with progress tracking
    /// - Parameters:
    ///   - endpoint: The API endpoint to download from
    ///   - destination: The URL to save the downloaded file to
    ///   - progressHandler: Optional handler to track download progress
    /// - Returns: Downloaded file URL or throws an error
    @available(iOS 15.0, *)
    func downloadFileAsync(endpoint: APIRouter, destination: URL, progressHandler: ((Progress) -> Void)? = nil) async throws -> URL {
        // Check if network is connected
        guard networkMonitor.isConnected() else {
            Logger.shared.logNetwork("Device is offline, throwing network error for download from endpoint: \(endpoint)", level: .warning)
            throw APIError.networkError(message: "Device is offline")
        }
        
        // Log the download request details
        Logger.shared.logNetwork("Downloading file from endpoint: \(endpoint.path), method: \(endpoint.method)", level: .debug)
        
        return try await withCheckedThrowingContinuation { continuation in
            session.download(endpoint, to: { _, _ in
                // Set the destination file URL
                return (.moveTo(destination), [.removePreviousFile, .createIntermediateDirectories])
            })
                .downloadProgress { progress in
                    // Configure progress tracking if progressHandler is provided
                    progressHandler?(progress)
                }
                .validate()
                .responseData { response in
                    switch response.result {
                    case .success:
                        // Validate the response status code
                        guard let statusCode = response.response?.statusCode else {
                            let error = APIError.invalidResponse(message: "Missing status code")
                            Logger.shared.error("Download failed: \(error.localizedDescription)", error: error, category: .network)
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        if (200..<300).contains(statusCode) {
                            Logger.shared.logNetwork("Download successful for endpoint: \(endpoint.path)", level: .info)
                            continuation.resume(returning: destination)
                        } else {
                            let error = APIError.fromResponseStatusCode(statusCode)
                            Logger.shared.error("Download failed: \(error.localizedDescription)", error: error, category: .network)
                            continuation.resume(throwing: error)
                        }
                        
                    case .failure(let error):
                        // Handle error and create APIError
                        let apiError = self.handleError(error: error, response: response.response, data: response.data)
                        Logger.shared.error("Download failed: \(apiError.localizedDescription)", error: error, category: .network)
                        continuation.resume(throwing: apiError)
                    }
                }
        }
    }
    
    /// Cancels all ongoing network requests
    func cancelAllRequests() {
        session.cancelAllRequests()
        Logger.shared.logNetwork("All ongoing requests cancelled", level: .info)
    }
    
    // MARK: - Private Methods
    
    /// Handles changes in network connectivity status
    /// - Parameter status: The new network status
    private func handleNetworkStatusChange(status: NetworkStatus) {
        guard status == .connected else {
            return
        }
        
        // Process any queued requests using dataQueueService
        Logger.shared.logNetwork("Network connectivity restored, processing queued requests", level: .info)
        dataQueueService.processQueue()
    }
    
    /// Processes and standardizes error responses
    /// - Parameters:
    ///   - error: The Alamofire error
    ///   - response: The HTTPURLResponse (optional)
    ///   - data: The response data (optional)
    /// - Returns: A standardized APIError
    private func handleError(error: AFError, response: HTTPURLResponse?, data: Data?) -> APIError {
        // Determine the error type based on AFError and response
        if let underlyingError = error.underlyingError {
            // Handle network connection errors
            let nsError = underlyingError as NSError
            if nsError.domain == NSURLErrorDomain {
                return .networkError(message: nsError.localizedDescription)
            }
        }
        
        // For response serialization errors, attempt to parse error response
        if error.isResponseSerializationError, let response = response, let data = data {
            return parseErrorResponse(data: data, response: response)
        }
        
        // For response validation errors, create error from status code
        if let statusCode = response?.statusCode {
            return APIError.fromResponseStatusCode(statusCode)
        }
        
        // For other errors, return a generic unknown error
        return APIError.unknown(message: error.localizedDescription)
    }
    
    /// Attempts to parse an error response from the server
    /// - Parameters:
    ///   - data: The response data
    ///   - response: The HTTPURLResponse
    /// - Returns: A parsed APIError or a generic error if parsing fails
    private func parseErrorResponse(data: Data, response: HTTPURLResponse) -> APIError {
        do {
            // Attempt to decode the error response JSON
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            // If successful, create APIError from the error response
            if let errorResponse = json {
                return APIError.fromErrorResponse(errorResponse)
            } else {
                // If decoding fails, create APIError from status code
                return APIError.fromResponseStatusCode(response.statusCode)
            }
        } catch {
            // If decoding fails, create APIError from status code
            return APIError.fromResponseStatusCode(response.statusCode)
        }
    }
}