import XCTest // Latest - Access to Apple's XCTest framework for unit testing
import Combine // Latest - Support for testing asynchronous publishers
import TestData // Access mock data for testing

/// Standard test error type for use in tests
enum TestError: Error, Equatable {
    case testError
    case anotherTestError
}

// MARK: - XCTestCase+Async
extension XCTestCase {
    
    /// Waits for an asynchronous operation to complete and returns its result
    /// - Parameters:
    ///   - description: Description for the expectation
    ///   - timeout: Maximum time to wait for the operation to complete
    ///   - asyncOperation: The async operation to execute
    /// - Returns: The result of the async operation
    @available(iOS 15.0, *)
    func waitForAsync<T>(description: String = "Wait for async operation", timeout: TimeInterval = 10.0, _ asyncOperation: @escaping () async throws -> T) throws -> T {
        let expectation = expectation(description: description)
        
        var result: T?
        var error: Error?
        
        Task {
            do {
                result = try await asyncOperation()
            } catch let caughtError {
                error = caughtError
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
        
        if let error = error {
            throw error
        }
        
        return result!
    }
    
    /// Waits for an asynchronous operation to throw an error
    /// - Parameters:
    ///   - description: Description for the expectation
    ///   - timeout: Maximum time to wait for the operation to complete
    ///   - asyncOperation: The async operation that should throw an error
    /// - Returns: The error thrown by the async operation
    @available(iOS 15.0, *)
    func waitForAsyncError(description: String = "Wait for async error", timeout: TimeInterval = 10.0, _ asyncOperation: @escaping () async throws -> Any) -> Error {
        let expectation = expectation(description: description)
        
        var receivedError: Error?
        
        Task {
            do {
                _ = try await asyncOperation()
                XCTFail("Expected error but got success")
            } catch let caughtError {
                receivedError = caughtError
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
        
        guard let error = receivedError else {
            XCTFail("Expected error was not thrown")
            fatalError("Expected error was not thrown")
        }
        
        return error
    }
    
    /// Waits for a publisher to emit a value or complete with an error
    /// - Parameters:
    ///   - publisher: The publisher to test
    ///   - timeout: Maximum time to wait for the publisher to complete
    /// - Returns: The result of the publisher (success or failure)
    func waitForPublisher<T, E: Error>(_ publisher: AnyPublisher<T, E>, timeout: TimeInterval = 10.0) -> Result<T, E> {
        let expectation = self.expectation(description: "Wait for publisher")
        
        var result: Result<T, E>?
        
        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    result = .failure(error)
                    expectation.fulfill()
                }
            },
            receiveValue: { value in
                result = .success(value)
                expectation.fulfill()
            }
        )
        
        // Make sure the cancellable is retained until the expectation is fulfilled
        _ = cancellable
        
        wait(for: [expectation], timeout: timeout)
        
        guard let finalResult = result else {
            XCTFail("Publisher did not complete")
            fatalError("Publisher did not complete")
        }
        
        return finalResult
    }
}

// MARK: - XCTestCase+Expectations
extension XCTestCase {
    
    /// Creates an expectation for a value to be received
    /// - Parameters:
    ///   - description: Description for the expectation
    ///   - handler: Handler to call when a value is received
    /// - Returns: A closure that fulfills the expectation with the value
    func expectValue<T>(description: String = "Expect value", handler: @escaping (T) -> Void = { _ in }) -> (T) -> Void {
        let expectation = self.expectation(description: description)
        
        return { value in
            handler(value)
            expectation.fulfill()
        }
    }
    
    /// Creates an expectation for an error to be received
    /// - Parameters:
    ///   - description: Description for the expectation
    ///   - handler: Handler to call when an error is received
    /// - Returns: A closure that fulfills the expectation with the error
    func expectError(description: String = "Expect error", handler: @escaping (Error) -> Void = { _ in }) -> (Error) -> Void {
        let expectation = self.expectation(description: description)
        
        return { error in
            handler(error)
            expectation.fulfill()
        }
    }
    
    /// Creates an expectation that no error should occur
    /// - Parameter description: Description for the expectation
    /// - Returns: A closure that fails the test if an error is provided
    func expectNoError(description: String = "Expect no error") -> (Error?) -> Void {
        let expectation = self.expectation(description: description)
        
        return { error in
            if let error = error {
                XCTFail("Unexpected error: \(error)")
            }
            expectation.fulfill()
        }
    }
}

// MARK: - XCTestCase+Combine
extension XCTestCase {
    private var cancellables: [AnyCancellable] = []
    
    /// Waits for a publisher to emit a value or complete with an error
    /// - Parameters:
    ///   - publisher: The publisher to test
    ///   - timeout: Maximum time to wait for the publisher to complete
    /// - Returns: The result of the publisher (success or failure)
    func awaitPublisher<Output, Failure: Error>(_ publisher: AnyPublisher<Output, Failure>, timeout: TimeInterval = 10.0) -> Result<Output, Failure> {
        let expectation = self.expectation(description: "Awaiting publisher")
        
        var result: Result<Output, Failure>?
        
        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    result = .failure(error)
                    expectation.fulfill()
                }
            },
            receiveValue: { value in
                result = .success(value)
                expectation.fulfill()
            }
        )
        
        cancellables.append(cancellable)
        
        wait(for: [expectation], timeout: timeout)
        
        guard let unwrappedResult = result else {
            XCTFail("Publisher did not complete")
            fatalError("Publisher did not complete")
        }
        
        return unwrappedResult
    }
    
    /// Waits for a publisher to complete with an error
    /// - Parameters:
    ///   - publisher: The publisher that should fail
    ///   - timeout: Maximum time to wait for the publisher to fail
    /// - Returns: The error from the publisher
    func awaitFailure<Output, Failure: Error>(_ publisher: AnyPublisher<Output, Failure>, timeout: TimeInterval = 10.0) -> Failure {
        let expectation = self.expectation(description: "Awaiting publisher failure")
        
        var failure: Failure?
        
        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    XCTFail("Expected failure but got successful completion")
                case .failure(let error):
                    failure = error
                    expectation.fulfill()
                }
            },
            receiveValue: { _ in
                XCTFail("Expected failure but got value")
            }
        )
        
        cancellables.append(cancellable)
        
        wait(for: [expectation], timeout: timeout)
        
        guard let error = failure else {
            XCTFail("Publisher did not fail as expected")
            fatalError("Publisher did not fail as expected")
        }
        
        return error
    }
    
    /// Stores a cancellable for automatic cleanup after the test
    /// - Parameter cancellable: The cancellable to track
    func trackCancellable(_ cancellable: AnyCancellable) {
        cancellables.append(cancellable)
    }
}

// MARK: - XCTestCase+Mocks
extension XCTestCase {
    
    /// Creates a configured MockAPIClient for testing
    /// - Returns: A configured mock API client
    func createMockAPIClient() -> MockAPIClient {
        let mockClient = MockAPIClient()
        
        // Configure default responses for common endpoints
        mockClient.mockGetUser(with: .success(TestData.mockUser()))
        mockClient.mockGetJournals(with: .success(TestData.mockJournalArray()))
        mockClient.mockGetTools(with: .success(TestData.mockToolArray()))
        
        return mockClient
    }
    
    /// Creates a mock EncryptionService for testing
    /// - Returns: A configured mock encryption service
    func createMockEncryptionService() -> MockEncryptionService {
        let mockService = MockEncryptionService()
        
        // Configure default behaviors
        mockService.mockEncryptData(returning: .success(Data()))
        mockService.mockDecryptData(returning: .success(Data()))
        
        return mockService
    }
    
    /// Creates a mock AudioRecordingService for testing
    /// - Returns: A configured mock audio recording service
    func createMockAudioRecordingService() -> MockAudioRecordingService {
        let mockService = MockAudioRecordingService()
        
        // Configure default behaviors
        mockService.mockStartRecording(returning: .success(UUID()))
        mockService.mockStopRecording(returning: .success(URL(string: "file:///test/recording.aac")!))
        
        return mockService
    }
}

// MARK: - XCTestCase+Assertions
extension XCTestCase {
    
    /// Asserts that two errors are equal
    /// - Parameters:
    ///   - actual: The actual error value
    ///   - expected: The expected error value
    ///   - message: The assertion message
    ///   - file: The file containing the assertion
    ///   - line: The line containing the assertion
    func assertErrorEqual(_ actual: Error?, _ expected: Error?, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
        if actual == nil && expected == nil {
            return // Both nil, so they're equal
        }
        
        guard let actualError = actual, let expectedError = expected else {
            XCTFail("One error is nil and the other is not: actual=\(String(describing: actual)), expected=\(String(describing: expected))", file: file, line: line)
            return
        }
        
        // Compare the localized descriptions as a basic equality check
        if actualError.localizedDescription != expectedError.localizedDescription {
            XCTFail("\(message): \(actualError) is not equal to \(expectedError)", file: file, line: line)
        }
    }
    
    /// Asserts that a collection contains specific elements
    /// - Parameters:
    ///   - collection: The collection to check
    ///   - elements: The elements that should be in the collection
    ///   - message: The assertion message
    ///   - file: The file containing the assertion
    ///   - line: The line containing the assertion
    func assertContainsElements<Collection: Swift.Collection, Element: Equatable>(_ collection: Collection, _ elements: [Element], _ message: String = "", file: StaticString = #file, line: UInt = #line) where Collection.Element == Element {
        for element in elements {
            if !collection.contains(element) {
                XCTFail("\(message): Collection does not contain \(element)", file: file, line: line)
            }
        }
    }
    
    /// Asserts that two dates are equal within a specified accuracy
    /// - Parameters:
    ///   - actual: The actual date value
    ///   - expected: The expected date value
    ///   - accuracy: The allowed difference in seconds
    ///   - message: The assertion message
    ///   - file: The file containing the assertion
    ///   - line: The line containing the assertion
    func assertDateEqual(_ actual: Date?, _ expected: Date?, accuracy: TimeInterval = 1.0, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
        if actual == nil && expected == nil {
            return // Both nil, so they're equal
        }
        
        guard let actualDate = actual, let expectedDate = expected else {
            XCTFail("One date is nil and the other is not: actual=\(String(describing: actual)), expected=\(String(describing: expected))", file: file, line: line)
            return
        }
        
        let difference = abs(actualDate.timeIntervalSince(expectedDate))
        if difference > accuracy {
            XCTFail("\(message): \(actualDate) is not equal to \(expectedDate) within accuracy of \(accuracy) seconds (actual difference: \(difference))", file: file, line: line)
        }
    }
}