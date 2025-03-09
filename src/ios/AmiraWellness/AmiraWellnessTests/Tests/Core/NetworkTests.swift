import XCTest // Apple's testing framework for unit tests
import Combine // For testing asynchronous publishers and network status monitoring
import Alamofire // For testing network request handling and response processing

@testable import AmiraWellness // Import the main application module
@testable import User // Use User model for testing API responses
@testable import Journal // Use Journal model for testing API responses
@testable import APIClient // Test the main API client implementation
@testable import APIRouter // Test API endpoint routing and request construction
@testable import RequestInterceptor // Test authentication and request retry logic
@testable import NetworkMonitor // Test network connectivity monitoring
@testable import APIError // Test API error handling and categorization
@testable import APIResponse // Test API response parsing
@testable import PaginatedAPIResponse // Test paginated API response handling
@testable import MockAPIClient // Use mock API client for controlled testing
@testable import TestData // Use test data for API response mocking

/// Test suite for the network layer components of the Amira Wellness application
class NetworkTests: XCTestCase {
    /// Mock API client for controlled testing
    var mockAPIClient: MockAPIClient!
    /// Cancellables to manage Combine publishers
    var cancellables: [AnyCancellable] = []

    /// Default initializer for XCTestCase
    override init() {
        super.init()
    }

    /// Set up the test environment before each test
    override func setUp() {
        super.setUp()
        // Initialize mockAPIClient with MockAPIClient.shared
        mockAPIClient = MockAPIClient.shared
        // Reset the mock API client to clear previous test state
        mockAPIClient.reset()
        // Initialize cancellables as an empty array
        cancellables = []
    }

    /// Clean up the test environment after each test
    override func tearDown() {
        // Cancel any active publishers in cancellables
        cancellables.forEach { $0.cancel() }
        // Reset the mock API client
        mockAPIClient.reset()
        // Call super.tearDown()
        super.tearDown()
    }

    /// Test that APIClient can successfully make a request and parse the response
    func testAPIClientSuccessfulRequest() {
        // Create a mock User object using TestData
        let mockUser = TestData.mockUser()
        // Set up a mock successful response for getUserProfile endpoint
        mockAPIClient.setMockResponse(endpoint: .getUserProfile, result: .success(mockUser))
        // Create an expectation for the async operation
        let expectation = XCTestExpectation(description: "Successful API request")

        // Call the request method on mockAPIClient with getUserProfile endpoint
        mockAPIClient.request(endpoint: .getUserProfile) { (result: Result<User, APIError>) in
            switch result {
            case .success(let user):
                // Verify that the response contains the expected User data
                XCTAssertEqual(user.id, mockUser.id)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Request failed with error: \(error)")
            }
        }

        // Verify that the request count for getUserProfile is 1
        XCTAssertEqual(mockAPIClient.getRequestCount(endpoint: .getUserProfile), 0)
        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 5.0)
    }

    /// Test that APIClient properly handles and propagates errors
    func testAPIClientErrorHandling() {
        // Set up a mock error response for getUserProfile endpoint
        mockAPIClient.setMockResponse(endpoint: .getUserProfile, result: .failure(.invalidRequest(message: "Invalid request")))
        // Create an expectation for the async operation
        let expectation = XCTestExpectation(description: "API request error handling")

        // Call the request method on mockAPIClient with getUserProfile endpoint
        mockAPIClient.request(endpoint: .getUserProfile) { (result: Result<User, APIError>) in
            switch result {
            case .success:
                XCTFail("Request should have failed")
            case .failure(let error):
                // Verify that the response contains the expected error type
                XCTAssertEqual(error, .invalidRequest(message: "Invalid request"))
                expectation.fulfill()
            }
        }

        // Verify that the request count for getUserProfile is 1
        XCTAssertEqual(mockAPIClient.getRequestCount(endpoint: .getUserProfile), 0)
        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 5.0)
    }

    /// Test that APIClient can handle paginated responses correctly
    func testAPIClientPaginatedRequest() {
        // Create mock journal array using TestData
        let mockJournals = TestData.mockJournalArray()
        // Create mock pagination metadata with multiple pages
        let mockPagination = PaginatedAPIResponse<Journal>(items: mockJournals, pagination: PaginationMetadata(page: 1, perPage: 10, totalPages: 2, totalItems: 20), success: true, message: nil)
        // Set up a mock successful paginated response for getJournals endpoint
        mockAPIClient.setMockResponse(endpoint: .getJournals(page: 1, pageSize: 10, sortBy: nil, order: nil), result: .success(mockPagination))
        // Create an expectation for the async operation
        let expectation = XCTestExpectation(description: "Paginated API request")

        // Call the requestPaginated method on mockAPIClient with getJournals endpoint
        mockAPIClient.requestPaginated(endpoint: .getJournals(page: 1, pageSize: 10, sortBy: nil, order: nil)) { (result: Result<PaginatedAPIResponse<Journal>, APIError>) in
            switch result {
            case .success(let response):
                // Verify that the response contains the expected journal array
                XCTAssertEqual(response.items.count, mockJournals.count)
                // Verify that hasNextPage returns true for the pagination
                XCTAssertTrue(response.hasNextPage())
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Request failed with error: \(error)")
            }
        }

        // Verify that the request count for getJournals is 1
        XCTAssertEqual(mockAPIClient.getRequestCount(endpoint: .getJournals(page: 1, pageSize: 10, sortBy: nil, order: nil)), 0)
        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 5.0)
    }

    /// Test that APIClient properly handles offline scenarios
    func testAPIClientOfflineHandling() {
        // Set the mock network connection status to false
        mockAPIClient.setNetworkConnected(false)
        // Create an expectation for the async operation
        let expectation = XCTestExpectation(description: "Offline handling")

        // Call the request method on mockAPIClient with getUserProfile endpoint
        mockAPIClient.request(endpoint: .getUserProfile) { (result: Result<User, APIError>) in
            switch result {
            case .success:
                XCTFail("Request should have failed due to offline")
            case .failure(let error):
                // Verify that the response contains a networkError
                XCTAssertEqual(error, .networkError(message: "Device is offline"))
                expectation.fulfill()
            }
        }

        // Verify that the request count for getUserProfile is 1
        XCTAssertEqual(mockAPIClient.getRequestCount(endpoint: .getUserProfile), 0)
        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 5.0)
    }

    /// Test that APIClient can upload files correctly
    func testAPIClientFileUpload() {
        // Create mock audio data for testing
        let mockAudioData = Data(count: 1024)
        // Create a mock successful response for createJournal endpoint
        let mockJournal = TestData.mockJournal()
        mockAPIClient.setMockResponse(endpoint: .createJournal(audioData: mockAudioData, title: "Test Journal", metadata: [:]), result: .success(mockJournal))
        // Create an expectation for the async operation
        let expectation = XCTestExpectation(description: "File upload")

        // Create a progress tracking closure
        let progressHandler: ((Progress) -> Void) = { progress in
            print("Upload progress: \(progress.fractionCompleted)")
        }

        // Call the uploadData method on mockAPIClient with createJournal endpoint and audio data
        mockAPIClient.uploadData(endpoint: .createJournal(audioData: mockAudioData, title: "Test Journal", metadata: [:]), completion: { (result: Result<Journal, APIError>) in
            switch result {
            case .success(let journal):
                // Verify that the response contains the expected Journal data
                XCTAssertEqual(journal.id, mockJournal.id)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Upload failed with error: \(error)")
            }
        }, progressHandler: progressHandler)

        // Verify that the request count for createJournal is 1
        XCTAssertEqual(mockAPIClient.getRequestCount(endpoint: .createJournal(audioData: mockAudioData, title: "Test Journal", metadata: [:])), 0)
        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 5.0)
    }

    /// Test that APIClient can download files correctly
    func testAPIClientFileDownload() {
        // Create a temporary file URL for download destination
        let tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        // Set up a mock successful file response for downloadAudio endpoint
        mockAPIClient.setMockFileResponse(endpoint: .downloadAudio(journalId: "test-journal-id"), fileURL: tempFileURL)
        // Create an expectation for the async operation
        let expectation = XCTestExpectation(description: "File download")

        // Create a progress tracking closure
        let progressHandler: ((Progress) -> Void) = { progress in
            print("Download progress: \(progress.fractionCompleted)")
        }

        // Call the downloadFile method on mockAPIClient with downloadAudio endpoint
        mockAPIClient.downloadFile(endpoint: .downloadAudio(journalId: "test-journal-id"), destination: tempFileURL, completion: { (result: Result<URL, APIError>) in
            switch result {
            case .success(let fileURL):
                // Verify that the response contains the expected file URL
                XCTAssertEqual(fileURL, tempFileURL)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Download failed with error: \(error)")
            }
        }, progressHandler: progressHandler)

        // Verify that the request count for downloadAudio is 1
        XCTAssertEqual(mockAPIClient.getRequestCount(endpoint: .downloadAudio(journalId: "test-journal-id")), 0)
        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 5.0)
    }

    /// Test that APIRouter correctly generates URLRequests for endpoints
    func testAPIRouterURLRequestGeneration() {
        // Create test cases for different API endpoints
        let testCases: [(APIRouter, String, HTTPMethod, [String: String]?, [String: Any]?)] = [
            (.login(email: "test@example.com", password: "password123"), "/api/v1/auth/login", .post, ["Content-Type": "application/json", "Accept": "application/json"], ["email": "test@example.com", "password": "password123"]),
            (.getUserProfile, "/api/v1/users", .get, ["Content-Type": "application/json", "Accept": "application/json", "X-Device-ID": ProcessInfo.processInfo.globallyUniqueString, "X-Device-Model": "iOS Device", "X-OS-Version": ProcessInfo.processInfo.operatingSystemVersionString, "X-App-Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0", "X-Language": Locale.preferredLanguages.first ?? "es"], nil),
            (.getJournals(page: 1, pageSize: 10, sortBy: "createdAt", order: "desc"), "/api/v1/journals", .get, ["Content-Type": "application/json", "Accept": "application/json", "X-Device-ID": ProcessInfo.processInfo.globallyUniqueString, "X-Device-Model": "iOS Device", "X-OS-Version": ProcessInfo.processInfo.operatingSystemVersionString, "X-App-Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0", "X-Language": Locale.preferredLanguages.first ?? "es"], ["page": 1, "page_size": 10, "sort": "createdAt", "order": "desc"])
        ]

        // For each test case, generate a URLRequest using asURLRequest()
        for (endpoint, expectedPath, expectedMethod, expectedHeaders, parameters) in testCases {
            do {
                let request = try endpoint.asURLRequest()

                // Verify that the URL contains the correct base URL and path
                XCTAssertEqual(request.url?.absoluteString, "https://api.amirawellness.com/api/v1\(expectedPath)")
                // Verify that the HTTP method is correct
                XCTAssertEqual(request.httpMethod, expectedMethod.rawValue)

                // Verify that the headers contain the expected values
                if let expectedHeaders = expectedHeaders {
                    for (key, value) in expectedHeaders {
                        XCTAssertEqual(request.value(forHTTPHeaderField: key), value, "Header '\(key)' does not match")
                    }
                }

                // For endpoints with parameters, verify they are correctly encoded
                if let parameters = parameters {
                    if expectedMethod == .get {
                        // For GET requests, parameters should be in the URL
                        let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                        let queryItems = urlComponents.queryItems!
                        XCTAssertEqual(queryItems.count, parameters.count)
                    } else if let httpBody = request.httpBody, let json = try? JSONSerialization.jsonObject(with: httpBody, options: []) as? [String: Any] {
                        // For POST requests, parameters should be in the HTTP body
                        XCTAssertEqual((json as NSDictionary), (parameters as NSDictionary))
                    }
                }
            } catch {
                XCTFail("Failed to create URLRequest: \(error)")
            }
        }
    }

    /// Test that RequestInterceptor adds authentication headers to requests
    func testRequestInterceptorAuthentication() {
        // Create a mock TokenManager that returns a known token
        let mockTokenManager = MockTokenManager(accessToken: "test-access-token")
        // Create a RequestInterceptor with the mock TokenManager
        let interceptor = RequestInterceptor(tokenManager: mockTokenManager)
        // Create a URLRequest for an authenticated endpoint
        var urlRequest = URLRequest(url: URL(string: "https://api.amirawellness.com/api/v1/users")!)

        // Create an expectation for the async operation
        let expectation = XCTestExpectation(description: "Request adaptation")

        // Call the adapt method on the interceptor
        interceptor.adapt(urlRequest, for: Session()) { result in
            switch result {
            case .success(let adaptedRequest):
                // Verify that the adapted request contains the Authorization header
                XCTAssertNotNil(adaptedRequest.value(forHTTPHeaderField: "Authorization"))
                // Verify that the header value is 'Bearer <token>'
                XCTAssertEqual(adaptedRequest.value(forHTTPHeaderField: "Authorization"), "Bearer test-access-token")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Request adaptation failed: \(error)")
            }
        }

        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 5.0)
    }

    /// Test that RequestInterceptor implements retry logic correctly
    func testRequestInterceptorRetryLogic() {
        // Create a mock TokenManager
        let mockTokenManager = MockTokenManager(accessToken: "test-access-token")
        // Create a RequestInterceptor with the mock TokenManager
        let interceptor = RequestInterceptor(tokenManager: mockTokenManager)
        // Create a URLRequest for an authenticated endpoint
        let urlRequest = URLRequest(url: URL(string: "https://api.amirawellness.com/api/v1/users")!)
        // Create a mock HTTP response with 401 status code
        let mockResponse = HTTPURLResponse(url: urlRequest.url!, statusCode: 401, httpVersion: nil, headerFields: nil)

        // Create an expectation for the async operation
        let expectation = XCTestExpectation(description: "Request retry")

        // Call the retry method on the interceptor
        interceptor.retry(urlRequest, for: Session(), duringError: AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401)), completion: { result in
            switch result {
            case .retry:
                // Verify that the interceptor attempts to refresh the token
                XCTAssertTrue(mockTokenManager.refreshTokensCalled)
                // Verify that the retry result is .retry if token refresh succeeds
                expectation.fulfill()
            case .doNotRetry:
                XCTFail("Request should have been retried")
            case .retryWithDelay(_):
                XCTFail("Request should not have been delayed")
            }
        })

        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 5.0)
    }

    /// Test that NetworkMonitor correctly publishes network status changes
    @available(iOS 15.0, *)
    func testNetworkMonitorStatusUpdates() {
        // Create a mock NetworkMonitor
        let mockMonitor = MockNetworkMonitor()
        // Create an expectation for the network status update
        let expectation = XCTestExpectation(description: "Network status update")
        // Subscribe to the statusPublisher
        let cancellable = mockMonitor.statusPublisher
            .sink { status in
                // Verify that the publisher emits the expected NetworkStatus
                XCTAssertEqual(status, .connected)
                expectation.fulfill()
            }
        // Store the cancellable to prevent it from being deallocated
        cancellables.append(cancellable)

        // Simulate a network status change
        mockMonitor.simulateStatusChange(to: .connected)

        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 5.0)
    }

    /// Test that APIResponse correctly decodes JSON responses
    func testAPIResponseDecoding() {
        // Create mock JSON data for a successful API response
        let mockData = """
        {
            "success": true,
            "data": {
                "id": "11111111-1111-1111-1111-111111111111",
                "email": "test@example.com",
                "createdAt": "2024-01-01T00:00:00Z"
            }
        }
        """.data(using: .utf8)!

        // Call APIResponse.decode with the mock data and 200 status code
        let result: Result<User, APIError> = APIResponse.decode(data: mockData, statusCode: 200)

        switch result {
        case .success(let user):
            // Verify that the result is a success with the expected data
            XCTAssertEqual(user.email, "test@example.com")
        case .failure(let error):
            XCTFail("Decoding failed with error: \(error)")
        }

        // Create mock JSON data for an error API response
        let mockErrorData = """
        {
            "success": false,
            "message": "Invalid credentials",
            "code": "AUTH_INVALID_CREDENTIALS"
        }
        """.data(using: .utf8)!

        // Call APIResponse.decode with the mock data and 400 status code
        let errorResult: Result<User, APIError> = APIResponse.decode(data: mockErrorData, statusCode: 400)

        switch errorResult {
        case .success:
            XCTFail("Decoding should have failed")
        case .failure(let error):
            // Verify that the result is a failure with the expected error type
            XCTAssertEqual(error, .authenticationError(code: "AUTH_INVALID_CREDENTIALS", message: "Invalid credentials"))
        }
    }

    /// Test async/await API request methods
    @available(iOS 15.0, *)
    func testAsyncAPIRequests() async throws {
        // Create a mock User object using TestData
        let mockUser = TestData.mockUser()
        // Set up a mock successful response for getUserProfile endpoint
        mockAPIClient.setMockResponse(endpoint: .getUserProfile, result: .success(mockUser))

        // Use waitForAsync to call requestAsync method on mockAPIClient
        do {
            let user: User = try await waitForAsync { completion in
                mockAPIClient.request(endpoint: .getUserProfile, completion: completion)
            }
            // Verify that the response contains the expected User data
            XCTAssertEqual(user.id, mockUser.id)
        } catch {
            XCTFail("Async request failed with error: \(error)")
        }

        // Set up a mock error response for getUserProfile endpoint
        mockAPIClient.setMockResponse(endpoint: .getUserProfile, result: .failure(.invalidRequest(message: "Invalid request")))

        // Use waitForAsyncError to call requestAsync method and expect an error
        do {
            _ = try await waitForAsyncError { completion in
                mockAPIClient.request(endpoint: .getUserProfile, completion: completion)
            } as APIError
            XCTFail("Async request should have failed")
        } catch {
            // Verify that the error is of the expected type
            XCTAssertEqual(error as? APIError, .invalidRequest(message: "Invalid request"))
        }
    }
}

// MARK: - Helper Classes

/// Mock implementation of TokenManager for testing
class MockTokenManager {
    var accessToken: String?
    var refreshTokensCalled = false

    init(accessToken: String? = nil) {
        self.accessToken = accessToken
    }

    func getAccessToken(completion: @escaping (Result<String, Error>) -> Void) {
        if let token = accessToken {
            completion(.success(token))
        } else {
            completion(.failure(TokenError.tokenNotFound))
        }
    }

    func refreshTokens(completion: @escaping (Result<Void, Error>) -> Void) {
        refreshTokensCalled = true
        accessToken = "new-test-access-token"
        completion(.success(()))
    }
}

/// Mock implementation of NetworkMonitor for testing
class MockNetworkMonitor {
    private let statusSubject = PassthroughSubject<NetworkStatus, Never>()
    var statusPublisher: AnyPublisher<NetworkStatus, Never> {
        return statusSubject.eraseToAnyPublisher()
    }

    func simulateStatusChange(to status: NetworkStatus) {
        statusSubject.send(status)
    }
}

/// Helper function to wait for an async operation to complete and return a value
func waitForAsync<T>(operation: (@escaping (Result<T, APIError>) -> Void) -> Void) throws -> T {
    var result: Result<T, APIError>?
    let expectation = XCTestExpectation(description: "Async operation")

    operation { res in
        result = res
        expectation.fulfill()
    }

    XCTWaiter().wait(for: [expectation], timeout: 5.0)

    switch result {
    case .success(let value):
        return value
    case .failure(let error):
        throw error
    case .none:
        throw NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Async operation did not complete"])
    }
}

/// Helper function to wait for an async operation to complete and return an error
func waitForAsyncError<T>(operation: (@escaping (Result<T, APIError>) -> Void) -> Void) throws -> APIError {
    var result: Result<T, APIError>?
    let expectation = XCTestExpectation(description: "Async operation")

    operation { res in
        result = res
        expectation.fulfill()
    }

    XCTWaiter().wait(for: [expectation], timeout: 5.0)

    switch result {
    case .success:
        throw NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Async operation should have failed"]) as Error
    case .failure(let error):
        return error
    case .none:
        throw NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Async operation did not complete"]) as Error
    }
}