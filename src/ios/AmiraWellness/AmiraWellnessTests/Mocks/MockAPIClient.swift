import Foundation // Latest
import Combine // Latest

/// A mock implementation of the APIClient for unit testing purposes. This class mimics the behavior
/// of the real APIClient but allows for controlled responses and error simulation during tests.
class MockAPIClient {
    /// Shared singleton instance
    static let shared = MockAPIClient()
    
    /// Mock responses for each endpoint
    var mockResponses: [APIRouter: Result<Any, APIError>] = [:]
    
    /// Mock data responses for file upload operations
    var mockDataResponses: [APIRouter: Data] = [:]
    
    /// Mock file responses for download operations
    var mockFileResponses: [APIRouter: URL] = [:]
    
    /// Mock progress for upload/download operations
    var mockProgressResponses: [APIRouter: Progress] = [:]
    
    /// Request count for each endpoint for verification
    var requestCount: [APIRouter: Int] = [:]
    
    /// Simulated network connection status
    var isNetworkConnected: Bool = true
    
    /// Mock delay for responses to simulate network latency
    var mockDelay: [APIRouter: TimeInterval] = [:]
    
    /// Mock download responses for specific URLs
    var mockDownloadResponses: [URL: Result<URL, APIError>] = [:]
    
    /// Initializes the MockAPIClient with default values
    init() {
        mockResponses = [:]
        mockDataResponses = [:]
        mockFileResponses = [:]
        mockProgressResponses = [:]
        requestCount = [:]
        isNetworkConnected = true
        mockDelay = [:]
        mockDownloadResponses = [:]
    }
    
    /// Resets all mock responses and counters
    func reset() {
        mockResponses.removeAll()
        mockDataResponses.removeAll()
        mockFileResponses.removeAll()
        mockProgressResponses.removeAll()
        requestCount.removeAll()
        isNetworkConnected = true
        mockDelay.removeAll()
        mockDownloadResponses.removeAll()
    }
    
    /// Sets a mock response for a specific endpoint
    /// - Parameters:
    ///   - endpoint: The API endpoint to mock
    ///   - result: The result to return when the endpoint is called
    func setMockResponse<T: Decodable>(endpoint: APIRouter, result: Result<T, APIError>) {
        mockResponses[endpoint] = result as Result<Any, APIError>
        if requestCount[endpoint] == nil {
            requestCount[endpoint] = 0
        }
    }
    
    /// Sets a mock data response for file upload endpoints
    /// - Parameters:
    ///   - endpoint: The API endpoint to mock
    ///   - data: The data to return when the endpoint is called
    func setMockDataResponse(endpoint: APIRouter, data: Data) {
        mockDataResponses[endpoint] = data
        if requestCount[endpoint] == nil {
            requestCount[endpoint] = 0
        }
    }
    
    /// Sets a mock file response for download endpoints
    /// - Parameters:
    ///   - endpoint: The API endpoint to mock
    ///   - fileURL: The file URL to return when the endpoint is called
    func setMockFileResponse(endpoint: APIRouter, fileURL: URL) {
        mockFileResponses[endpoint] = fileURL
        if requestCount[endpoint] == nil {
            requestCount[endpoint] = 0
        }
    }
    
    /// Sets a mock progress for upload/download operations
    /// - Parameters:
    ///   - endpoint: The API endpoint to mock
    ///   - progress: The progress to return when the endpoint is called
    func setMockProgress(endpoint: APIRouter, progress: Progress) {
        mockProgressResponses[endpoint] = progress
    }
    
    /// Sets a mock delay for a specific endpoint
    /// - Parameters:
    ///   - endpoint: The API endpoint to mock
    ///   - delay: The delay in seconds to simulate
    func setMockDelay(endpoint: APIRouter, delay: TimeInterval) {
        mockDelay[endpoint] = delay
    }
    
    /// Sets the mock network connection status
    /// - Parameter connected: Whether the network is connected
    func setNetworkConnected(_ connected: Bool) {
        isNetworkConnected = connected
    }
    
    /// Sets a mock download response for a specific destination URL
    /// - Parameters:
    ///   - destination: The destination URL
    ///   - result: The result to return when downloading to this URL
    func setMockDownloadResponse(destination: URL, result: Result<URL, APIError>) {
        mockDownloadResponses[destination] = result
    }
    
    /// Gets the number of requests made to a specific endpoint
    /// - Parameter endpoint: The API endpoint
    /// - Returns: Number of requests made to the endpoint
    func getRequestCount(endpoint: APIRouter) -> Int {
        return requestCount[endpoint] ?? 0
    }
    
    /// Mock implementation of the request method
    /// - Parameters:
    ///   - endpoint: The API endpoint
    ///   - completion: The completion handler
    func request<T: Decodable>(endpoint: APIRouter, completion: @escaping (Result<T, APIError>) -> Void) {
        // Increment request count
        requestCount[endpoint, default: 0] += 1
        
        // Check if network is connected
        guard isNetworkConnected else {
            completion(.failure(.networkError(message: "Network connection unavailable")))
            return
        }
        
        // Check if there's a mock delay for this endpoint
        if let delay = mockDelay[endpoint] {
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                self.handleMockResponse(endpoint: endpoint, completion: completion)
            }
        } else {
            handleMockResponse(endpoint: endpoint, completion: completion)
        }
    }
    
    /// Mock implementation of the requestAsync method
    /// - Parameter endpoint: The API endpoint
    /// - Returns: Decoded response data or throws an error
    @available(iOS 15.0, *)
    func requestAsync<T: Decodable>(endpoint: APIRouter) async throws -> T {
        // Increment request count
        requestCount[endpoint, default: 0] += 1
        
        // Check if network is connected
        guard isNetworkConnected else {
            throw APIError.networkError(message: "Network connection unavailable")
        }
        
        // Check if there's a mock delay for this endpoint
        if let delay = mockDelay[endpoint] {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // Check if there's a mock response for this endpoint
        if let mockResult = mockResponses[endpoint] {
            switch mockResult {
            case .success(let value):
                if let typedValue = value as? T {
                    return typedValue
                } else {
                    throw APIError.invalidResponse(message: "Mock response type mismatch")
                }
            case .failure(let error):
                throw error
            }
        } else {
            throw APIError.unknown(message: "No mock response set for endpoint: \(endpoint)")
        }
    }
    
    /// Mock implementation of the requestPaginated method
    /// - Parameters:
    ///   - endpoint: The API endpoint
    ///   - completion: The completion handler
    func requestPaginated<T: Decodable>(endpoint: APIRouter, completion: @escaping (Result<PaginatedAPIResponse<T>, APIError>) -> Void) {
        // Increment request count
        requestCount[endpoint, default: 0] += 1
        
        // Check if network is connected
        guard isNetworkConnected else {
            completion(.failure(.networkError(message: "Network connection unavailable")))
            return
        }
        
        // Check if there's a mock delay for this endpoint
        if let delay = mockDelay[endpoint] {
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                self.handleMockPaginatedResponse(endpoint: endpoint, completion: completion)
            }
        } else {
            handleMockPaginatedResponse(endpoint: endpoint, completion: completion)
        }
    }
    
    /// Mock implementation of the requestPaginatedAsync method
    /// - Parameter endpoint: The API endpoint
    /// - Returns: Decoded paginated response or throws an error
    @available(iOS 15.0, *)
    func requestPaginatedAsync<T: Decodable>(endpoint: APIRouter) async throws -> PaginatedAPIResponse<T> {
        // Increment request count
        requestCount[endpoint, default: 0] += 1
        
        // Check if network is connected
        guard isNetworkConnected else {
            throw APIError.networkError(message: "Network connection unavailable")
        }
        
        // Check if there's a mock delay for this endpoint
        if let delay = mockDelay[endpoint] {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // Check if there's a mock response for this endpoint
        if let mockResult = mockResponses[endpoint] {
            switch mockResult {
            case .success(let value):
                if let typedValue = value as? PaginatedAPIResponse<T> {
                    return typedValue
                } else {
                    throw APIError.invalidResponse(message: "Mock response type mismatch")
                }
            case .failure(let error):
                throw error
            }
        } else {
            throw APIError.unknown(message: "No mock response set for endpoint: \(endpoint)")
        }
    }
    
    /// Mock implementation of the requestEmpty method
    /// - Parameters:
    ///   - endpoint: The API endpoint
    ///   - completion: The completion handler
    func requestEmpty(endpoint: APIRouter, completion: @escaping (Result<Void, APIError>) -> Void) {
        // Increment request count
        requestCount[endpoint, default: 0] += 1
        
        // Check if network is connected
        guard isNetworkConnected else {
            completion(.failure(.networkError(message: "Network connection unavailable")))
            return
        }
        
        // Check if there's a mock delay for this endpoint
        if let delay = mockDelay[endpoint] {
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                self.handleMockEmptyResponse(endpoint: endpoint, completion: completion)
            }
        } else {
            handleMockEmptyResponse(endpoint: endpoint, completion: completion)
        }
    }
    
    /// Mock implementation of the requestEmptyAsync method
    /// - Parameter endpoint: The API endpoint
    /// - Returns: Success or throws an error
    @available(iOS 15.0, *)
    func requestEmptyAsync(endpoint: APIRouter) async throws {
        // Increment request count
        requestCount[endpoint, default: 0] += 1
        
        // Check if network is connected
        guard isNetworkConnected else {
            throw APIError.networkError(message: "Network connection unavailable")
        }
        
        // Check if there's a mock delay for this endpoint
        if let delay = mockDelay[endpoint] {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // Check if there's a mock response for this endpoint
        if let mockResult = mockResponses[endpoint] {
            switch mockResult {
            case .success:
                return
            case .failure(let error):
                throw error
            }
        } else {
            throw APIError.unknown(message: "No mock response set for endpoint: \(endpoint)")
        }
    }
    
    /// Mock implementation of the uploadData method
    /// - Parameters:
    ///   - endpoint: The API endpoint
    ///   - completion: The completion handler
    ///   - progressHandler: Optional handler for upload progress updates
    func uploadData<T: Decodable>(endpoint: APIRouter, completion: @escaping (Result<T, APIError>) -> Void, progressHandler: ((Progress) -> Void)? = nil) {
        // Increment request count
        requestCount[endpoint, default: 0] += 1
        
        // Check if network is connected
        guard isNetworkConnected else {
            completion(.failure(.networkError(message: "Network connection unavailable")))
            return
        }
        
        // Check if there's a mock progress for this endpoint
        if let progress = mockProgressResponses[endpoint], let progressHandler = progressHandler {
            progressHandler(progress)
        }
        
        // Check if there's a mock delay for this endpoint
        if let delay = mockDelay[endpoint] {
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                self.handleMockResponse(endpoint: endpoint, completion: completion)
            }
        } else {
            handleMockResponse(endpoint: endpoint, completion: completion)
        }
    }
    
    /// Mock implementation of the uploadDataAsync method
    /// - Parameters:
    ///   - endpoint: The API endpoint
    ///   - progressHandler: Optional handler for upload progress updates
    /// - Returns: Decoded response data or throws an error
    @available(iOS 15.0, *)
    func uploadDataAsync<T: Decodable>(endpoint: APIRouter, progressHandler: ((Progress) -> Void)? = nil) async throws -> T {
        // Increment request count
        requestCount[endpoint, default: 0] += 1
        
        // Check if network is connected
        guard isNetworkConnected else {
            throw APIError.networkError(message: "Network connection unavailable")
        }
        
        // Check if there's a mock progress for this endpoint
        if let progress = mockProgressResponses[endpoint], let progressHandler = progressHandler {
            progressHandler(progress)
        }
        
        // Check if there's a mock delay for this endpoint
        if let delay = mockDelay[endpoint] {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // Check if there's a mock response for this endpoint
        if let mockResult = mockResponses[endpoint] {
            switch mockResult {
            case .success(let value):
                if let typedValue = value as? T {
                    return typedValue
                } else {
                    throw APIError.invalidResponse(message: "Mock response type mismatch")
                }
            case .failure(let error):
                throw error
            }
        } else {
            throw APIError.unknown(message: "No mock response set for endpoint: \(endpoint)")
        }
    }
    
    /// Mock implementation of the downloadFile method
    /// - Parameters:
    ///   - endpoint: The API endpoint
    ///   - destination: The local URL where the downloaded file should be saved
    ///   - completion: The completion handler
    ///   - progressHandler: Optional handler for download progress updates
    func downloadFile(endpoint: APIRouter, destination: URL, completion: @escaping (Result<URL, APIError>) -> Void, progressHandler: ((Progress) -> Void)? = nil) {
        // Increment request count
        requestCount[endpoint, default: 0] += 1
        
        // Check if network is connected
        guard isNetworkConnected else {
            completion(.failure(.networkError(message: "Network connection unavailable")))
            return
        }
        
        // Check if there's a mock progress for this endpoint
        if let progress = mockProgressResponses[endpoint], let progressHandler = progressHandler {
            progressHandler(progress)
        }
        
        // Check if there's a mock delay for this endpoint
        if let delay = mockDelay[endpoint] {
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                self.handleMockDownload(endpoint: endpoint, destination: destination, completion: completion)
            }
        } else {
            handleMockDownload(endpoint: endpoint, destination: destination, completion: completion)
        }
    }
    
    /// Mock implementation of the downloadFileAsync method
    /// - Parameters:
    ///   - endpoint: The API endpoint
    ///   - destination: The local URL where the downloaded file should be saved
    ///   - progressHandler: Optional handler for download progress updates
    /// - Returns: Downloaded file URL or throws an error
    @available(iOS 15.0, *)
    func downloadFileAsync(endpoint: APIRouter, destination: URL, progressHandler: ((Progress) -> Void)? = nil) async throws -> URL {
        // Increment request count
        requestCount[endpoint, default: 0] += 1
        
        // Check if network is connected
        guard isNetworkConnected else {
            throw APIError.networkError(message: "Network connection unavailable")
        }
        
        // Check if there's a mock progress for this endpoint
        if let progress = mockProgressResponses[endpoint], let progressHandler = progressHandler {
            progressHandler(progress)
        }
        
        // Check if there's a mock delay for this endpoint
        if let delay = mockDelay[endpoint] {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // Check if there's a mock download response for this destination
        if let mockResult = mockDownloadResponses[destination] {
            switch mockResult {
            case .success(let url):
                return url
            case .failure(let error):
                throw error
            }
        }
        
        // Check if there's a mock file response for this endpoint
        if let fileURL = mockFileResponses[endpoint] {
            return fileURL
        } else {
            throw APIError.unknown(message: "No mock file response set for endpoint: \(endpoint)")
        }
    }
    
    /// Mock implementation of the cancelAllRequests method
    func cancelAllRequests() {
        // No operation needed in mock implementation
    }
    
    // MARK: - Private Helper Methods
    
    /// Helper method to handle mock responses for regular requests
    private func handleMockResponse<T: Decodable>(endpoint: APIRouter, completion: @escaping (Result<T, APIError>) -> Void) {
        if let mockResult = mockResponses[endpoint] {
            switch mockResult {
            case .success(let value):
                if let typedValue = value as? T {
                    completion(.success(typedValue))
                } else {
                    completion(.failure(.invalidResponse(message: "Mock response type mismatch")))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        } else {
            completion(.failure(.unknown(message: "No mock response set for endpoint: \(endpoint)")))
        }
    }
    
    /// Helper method to handle mock responses for paginated requests
    private func handleMockPaginatedResponse<T: Decodable>(endpoint: APIRouter, completion: @escaping (Result<PaginatedAPIResponse<T>, APIError>) -> Void) {
        if let mockResult = mockResponses[endpoint] {
            switch mockResult {
            case .success(let value):
                if let typedValue = value as? PaginatedAPIResponse<T> {
                    completion(.success(typedValue))
                } else {
                    completion(.failure(.invalidResponse(message: "Mock response type mismatch")))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        } else {
            completion(.failure(.unknown(message: "No mock response set for endpoint: \(endpoint)")))
        }
    }
    
    /// Helper method to handle mock responses for empty requests
    private func handleMockEmptyResponse(endpoint: APIRouter, completion: @escaping (Result<Void, APIError>) -> Void) {
        if let mockResult = mockResponses[endpoint] {
            switch mockResult {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        } else {
            completion(.failure(.unknown(message: "No mock response set for endpoint: \(endpoint)")))
        }
    }
    
    /// Helper method to handle mock responses for download requests
    private func handleMockDownload(endpoint: APIRouter, destination: URL, completion: @escaping (Result<URL, APIError>) -> Void) {
        // Check if there's a specific mock response for this destination
        if let mockResult = mockDownloadResponses[destination] {
            completion(mockResult)
            return
        }
        
        // Check if there's a mock file response for this endpoint
        if let fileURL = mockFileResponses[endpoint] {
            completion(.success(fileURL))
        } else {
            completion(.failure(.unknown(message: "No mock file response set for endpoint: \(endpoint)")))
        }
    }
}