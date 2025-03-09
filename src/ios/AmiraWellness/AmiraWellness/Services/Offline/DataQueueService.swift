//
//  DataQueueService.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // Latest
import Combine // Latest

// Internal imports
import NetworkMonitor
import StorageService
import Logger
import AppConstants

/// Types of operations that can be queued for later execution
enum QueuedOperationType: String, Codable {
    case create
    case update
    case delete
    case upload
    case download
}

/// Possible states of a queued operation
enum QueuedOperationStatus: String, Codable {
    case pending
    case inProgress
    case completed
    case failed
}

/// Priority levels for queued operations, affecting processing order
enum QueuedOperationPriority: Int, Codable, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    
    static func < (lhs: QueuedOperationPriority, rhs: QueuedOperationPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// A model representing an operation that has been queued for later execution when online
class QueuedOperation: Codable, Identifiable, Equatable {
    /// Unique identifier for the queued operation
    let id: UUID
    
    /// Type of operation to be performed
    let type: QueuedOperationType
    
    /// API endpoint for the operation
    let endpoint: String
    
    /// Data to be sent with the request (optional)
    let requestData: Data?
    
    /// HTTP headers for the request (optional)
    let headers: [String: String]?
    
    /// Time when the operation was created
    let createdAt: Date
    
    /// Current status of the operation
    var status: QueuedOperationStatus
    
    /// Number of retry attempts for failed operations
    var retryCount: Int
    
    /// Time of the last retry attempt (if any)
    var lastRetryAt: Date?
    
    /// Priority level for processing the operation
    let priority: QueuedOperationPriority
    
    /// Error message if the operation failed
    var errorMessage: String?
    
    /// Identifier for the associated resource (if applicable)
    let resourceId: String?
    
    /// Type of the associated resource (if applicable)
    let resourceType: String?
    
    /// Initializes a new queued operation
    /// - Parameters:
    ///   - type: Type of operation to perform
    ///   - endpoint: API endpoint for the operation
    ///   - requestData: Data to be sent with the request (optional)
    ///   - priority: Priority level for the operation (default: normal)
    ///   - headers: HTTP headers for the request (optional)
    ///   - resourceId: Identifier for the associated resource (optional)
    ///   - resourceType: Type of the associated resource (optional)
    init(type: QueuedOperationType, 
         endpoint: String, 
         requestData: Data? = nil, 
         priority: QueuedOperationPriority = .normal, 
         headers: [String: String]? = nil, 
         resourceId: String? = nil, 
         resourceType: String? = nil) {
        
        self.id = UUID()
        self.type = type
        self.endpoint = endpoint
        self.requestData = requestData
        self.headers = headers
        self.createdAt = Date()
        self.status = .pending
        self.retryCount = 0
        self.lastRetryAt = nil
        self.priority = priority
        self.errorMessage = nil
        self.resourceId = resourceId
        self.resourceType = resourceType
    }
    
    /// Marks the operation as in progress
    func markInProgress() {
        status = .inProgress
        lastRetryAt = Date()
    }
    
    /// Marks the operation as completed
    func markCompleted() {
        status = .completed
    }
    
    /// Marks the operation as failed with an error message
    /// - Parameter message: Error message describing the failure reason
    func markFailed(message: String? = nil) {
        status = .failed
        errorMessage = message
        retryCount += 1
    }
    
    /// Determines if the operation should be retried based on retry count and time since last retry
    /// - Parameter maxRetries: Maximum number of retry attempts allowed
    /// - Returns: True if the operation should be retried, false otherwise
    func shouldRetry(maxRetries: Int) -> Bool {
        // Only retry failed operations
        guard status == .failed else {
            return false
        }
        
        // Check if we've exceeded the maximum retry count
        guard retryCount < maxRetries else {
            return false
        }
        
        // If no previous retry attempt, we should retry
        guard let lastRetry = lastRetryAt else {
            return true
        }
        
        // Calculate how much time should pass before next retry (exponential backoff)
        let backoffTime = DataQueueService.shared.calculateBackoffTime(retryCount: retryCount)
        let earliestRetryTime = lastRetry.addingTimeInterval(backoffTime)
        
        // Check if enough time has passed since the last retry
        return Date() > earliestRetryTime
    }
    
    // MARK: - Equatable
    
    static func == (lhs: QueuedOperation, rhs: QueuedOperation) -> Bool {
        return lhs.id == rhs.id
    }
}

/// A singleton service that manages the queuing of operations when offline
final class DataQueueService {
    // MARK: - Shared Instance
    
    /// Shared instance of DataQueueService
    static let shared = DataQueueService()
    
    // MARK: - Private Properties
    
    /// Queue of operations pending execution
    private var operationQueue: [QueuedOperation] = []
    
    /// Lock for thread-safe access to the operation queue
    private let queueLock = NSLock()
    
    /// Service for persisting queue between app launches
    private let storageService: StorageService
    
    /// Service for monitoring network connectivity
    private let networkMonitor: NetworkMonitor
    
    /// Logger for queue operations
    private let logger: Logger
    
    /// Maximum number of retry attempts for failed operations
    private let maxRetryCount: Int = 5
    
    /// Key for storing the operation queue in persistent storage
    private let storageKey: String
    
    // MARK: - Public Properties
    
    /// Publisher that emits the current number of queued operations
    public let queueStatusPublisher = CurrentValueSubject<Int, Never>(0)
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private init() {
        // Initialize services
        self.storageService = StorageService.shared
        self.networkMonitor = NetworkMonitor.shared
        self.logger = Logger.shared
        
        // Set storage key for the queue
        self.storageKey = AppConstants.Storage.syncBatchSize > 0 ? 
            "data_queue_operations" : 
            "data_queue_operations_default"
        
        // Load any previously queued operations from storage
        loadQueue()
        
        // Log initialization
        logger.debug("DataQueueService initialized with \(operationQueue.count) queued operations", category: .sync)
        
        // Start monitoring network connectivity
        setupNetworkMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Queues a network request for later execution when online
    /// - Parameters:
    ///   - type: Type of operation to perform
    ///   - endpoint: API endpoint for the operation
    ///   - requestData: Data to be sent with the request (optional)
    ///   - priority: Priority level for the operation (default: normal)
    ///   - headers: HTTP headers for the request (optional)
    ///   - resourceId: Identifier for the associated resource (optional)
    ///   - resourceType: Type of the associated resource (optional)
    /// - Returns: Identifier of the queued operation
    @discardableResult
    func queueRequest(type: QueuedOperationType, 
                      endpoint: String, 
                      requestData: Data? = nil, 
                      priority: QueuedOperationPriority = .normal, 
                      headers: [String: String]? = nil, 
                      resourceId: String? = nil, 
                      resourceType: String? = nil) -> UUID {
        
        // Create a new operation
        let operation = QueuedOperation(
            type: type,
            endpoint: endpoint,
            requestData: requestData,
            priority: priority,
            headers: headers,
            resourceId: resourceId,
            resourceType: resourceType
        )
        
        // Add to queue with thread safety
        queueLock.lock()
        operationQueue.append(operation)
        queueLock.unlock()
        
        // Save the updated queue
        saveQueue()
        
        // Update the queue status publisher
        queueStatusPublisher.send(operationQueue.count)
        
        // Log the queued operation (without including sensitive data)
        logger.info("Queued \(type.rawValue) operation for endpoint: \(endpoint), priority: \(priority), resource type: \(resourceType ?? "none"), ID: \(operation.id)", category: .sync)
        
        return operation.id
    }
    
    /// Processes all queued operations if online
    /// - Parameter completion: Optional callback with counts of success, failure, and remaining operations
    func processQueue(completion: ((Int, Int, Int) -> Void)? = nil) {
        // Check network connectivity
        guard networkMonitor.isConnected() else {
            logger.info("Cannot process queue: Device is offline", category: .sync)
            completion?(0, 0, operationQueue.count)
            return
        }
        
        logger.info("Starting to process operation queue with \(operationQueue.count) operations", category: .sync)
        
        // Get operations that need processing (with thread safety)
        queueLock.lock()
        let operationsToProcess = operationQueue
            .filter { $0.status == .pending || ($0.status == .failed && $0.shouldRetry(maxRetries: maxRetryCount)) }
            .sorted { 
                // Sort by priority (high to low) and then by creation date (oldest first)
                if $0.priority != $1.priority {
                    return $0.priority > $1.priority
                }
                return $0.createdAt < $1.createdAt
            }
        queueLock.unlock()
        
        // If nothing to process, return early
        if operationsToProcess.isEmpty {
            logger.info("No operations to process in queue", category: .sync)
            completion?(0, 0, 0)
            return
        }
        
        // Define batch size for processing
        let batchSize = min(AppConstants.Storage.syncBatchSize, operationsToProcess.count)
        let batchToProcess = Array(operationsToProcess.prefix(batchSize))
        
        logger.info("Processing batch of \(batchToProcess.count) operations", category: .sync)
        
        // Track counts for completion callback
        var successCount = 0
        var failureCount = 0
        
        // Create a dispatch group to track when all operations are complete
        let group = DispatchGroup()
        
        // Process each operation in the batch
        for operation in batchToProcess {
            group.enter()
            
            processOperation(operation) { success in
                if success {
                    successCount += 1
                } else {
                    failureCount += 1
                }
                group.leave()
            }
        }
        
        // When all operations in this batch are complete
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            // Get the remaining count
            let remainingCount = self.getQueueCount(status: .pending) + self.getQueueCount(status: .failed)
            
            // Save the updated queue
            self.saveQueue()
            
            // Update the queue status publisher
            self.queueStatusPublisher.send(self.operationQueue.count)
            
            // Log the results
            self.logger.info("Queue processing completed: \(successCount) succeeded, \(failureCount) failed, \(remainingCount) remaining", category: .sync)
            
            // Call the completion handler if provided
            completion?(successCount, failureCount, remainingCount)
            
            // If there are more operations and we're still online, process the next batch
            if remainingCount > 0 && self.networkMonitor.isConnected() {
                // Use a slight delay to prevent overwhelming the network
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.processQueue(completion: completion)
                }
            }
        }
    }
    
    /// Retrieves a queued operation by its identifier
    /// - Parameter id: Identifier of the queued operation
    /// - Returns: The queued operation if found, nil otherwise
    func getQueuedOperation(id: UUID) -> QueuedOperation? {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        return operationQueue.first { $0.id == id }
    }
    
    /// Removes an operation from the queue
    /// - Parameter id: Identifier of the operation to remove
    /// - Returns: True if operation was removed, false otherwise
    @discardableResult
    func removeOperation(id: UUID) -> Bool {
        queueLock.lock()
        let initialCount = operationQueue.count
        operationQueue.removeAll { $0.id == id }
        let removed = operationQueue.count < initialCount
        queueLock.unlock()
        
        if removed {
            saveQueue()
            queueStatusPublisher.send(operationQueue.count)
            logger.debug("Removed operation with ID: \(id) from queue", category: .sync)
        }
        
        return removed
    }
    
    /// Clears all operations from the queue
    func clearQueue() {
        queueLock.lock()
        operationQueue.removeAll()
        queueLock.unlock()
        
        saveQueue()
        queueStatusPublisher.send(0)
        logger.info("Operation queue cleared", category: .sync)
    }
    
    /// Returns the number of operations in the queue, optionally filtered by status
    /// - Parameter status: Optional status to filter operations
    /// - Returns: Number of operations in the queue
    func getQueueCount(status: QueuedOperationStatus? = nil) -> Int {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        if let status = status {
            return operationQueue.filter { $0.status == status }.count
        } else {
            return operationQueue.count
        }
    }
    
    /// Returns all queued operations, optionally filtered by status
    /// - Parameter status: Optional status to filter operations
    /// - Returns: Array of queued operations
    func getQueuedOperations(status: QueuedOperationStatus? = nil) -> [QueuedOperation] {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        if let status = status {
            return operationQueue.filter { $0.status == status }
        } else {
            return operationQueue
        }
    }
    
    // MARK: - Private Methods
    
    /// Processes a single queued operation
    /// - Parameters:
    ///   - operation: The operation to process
    ///   - completion: Callback with success or failure result
    private func processOperation(_ operation: QueuedOperation, completion: @escaping (Bool) -> Void) {
        // Mark operation as in progress
        operation.markInProgress()
        updateOperation(operation)
        
        logger.debug("Processing operation: \(operation.type.rawValue) for endpoint: \(operation.endpoint)", category: .sync)
        
        // Simulate API request processing
        // In a real implementation, this would make the actual API call
        let urlSession = URLSession.shared
        let baseURL = "https://api.amirawellness.com/v1" // This would come from a configuration
        
        guard let url = URL(string: "\(baseURL)/\(operation.endpoint)") else {
            operation.markFailed(message: "Invalid URL")
            updateOperation(operation)
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        
        // Set HTTP method based on operation type
        switch operation.type {
        case .create:
            request.httpMethod = "POST"
        case .update:
            request.httpMethod = "PUT"
        case .delete:
            request.httpMethod = "DELETE"
        case .upload:
            request.httpMethod = "POST"
        case .download:
            request.httpMethod = "GET"
        }
        
        // Set headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let customHeaders = operation.headers {
            for (key, value) in customHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Set request body
        if let data = operation.requestData {
            request.httpBody = data
        }
        
        // Perform the request
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else {
                completion(false)
                return
            }
            
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? 0
            
            // Check for success (2xx status codes)
            if let error = error {
                // Network error
                operation.markFailed(message: "Network error: \(error.localizedDescription)")
                self.updateOperation(operation)
                self.logger.error("Operation failed: \(error.localizedDescription)", category: .sync)
                completion(false)
            } else if statusCode >= 200 && statusCode < 300 {
                // Success
                operation.markCompleted()
                self.updateOperation(operation)
                self.logger.info("Operation completed successfully: \(operation.id)", category: .sync)
                completion(true)
            } else {
                // Server error
                let errorMessage = "Server error: Status code \(statusCode)"
                operation.markFailed(message: errorMessage)
                self.updateOperation(operation)
                self.logger.error("Operation failed: \(errorMessage)", category: .sync)
                completion(false)
            }
        }
        
        task.resume()
    }
    
    /// Updates an operation in the queue
    /// - Parameter operation: The operation to update
    /// - Returns: True if operation was updated, false otherwise
    @discardableResult
    private func updateOperation(_ operation: QueuedOperation) -> Bool {
        queueLock.lock()
        
        guard let index = operationQueue.firstIndex(where: { $0.id == operation.id }) else {
            queueLock.unlock()
            logger.error("Failed to update operation: Operation not found with ID: \(operation.id)", category: .sync)
            return false
        }
        
        operationQueue[index] = operation
        queueLock.unlock()
        
        // Don't save the queue for every update during batch processing
        // We'll save after the entire batch is processed
        
        return true
    }
    
    /// Saves the operation queue to persistent storage
    private func saveQueue() {
        queueLock.lock()
        let queueToSave = operationQueue
        queueLock.unlock()
        
        let result = storageService.storeCodable(
            queueToSave,
            forKey: storageKey,
            dataType: .preferences, 
            sensitivity: .nonsensitive
        )
        
        switch result {
        case .success:
            logger.debug("Operation queue saved successfully", category: .sync)
        case .failure(let error):
            logger.error("Failed to save operation queue: \(error)", category: .sync)
        }
    }
    
    /// Loads the operation queue from persistent storage
    private func loadQueue() {
        let result: Result<[QueuedOperation], StorageError> = storageService.retrieveCodable(
            forKey: storageKey,
            dataType: .preferences,
            sensitivity: .nonsensitive
        )
        
        switch result {
        case .success(let loadedQueue):
            queueLock.lock()
            operationQueue = loadedQueue
            queueLock.unlock()
            
            // Update the publisher with the initial count
            queueStatusPublisher.send(operationQueue.count)
            
            logger.debug("Loaded \(loadedQueue.count) operations from storage", category: .sync)
            
        case .failure(let error):
            if error != .fileNotFound && error != .dataConversionFailed {
                logger.error("Failed to load operation queue: \(error)", category: .sync)
            }
            
            queueLock.lock()
            operationQueue = []
            queueLock.unlock()
            
            queueStatusPublisher.send(0)
            
            logger.debug("Initialized empty operation queue", category: .sync)
        }
    }
    
    /// Sets up network monitoring to process queue when connectivity is restored
    private func setupNetworkMonitoring() {
        // Subscribe to network status changes
        let _ = networkMonitor.statusPublisher
            .filter { $0 == .connected } // Only interested in when network becomes available
            .sink { [weak self] _ in
                // When network becomes available, process the queue
                self?.logger.info("Network connectivity restored, processing operation queue", category: .sync)
                self?.processQueue()
            }
        
        // Start monitoring if not already monitoring
        if AppConstants.FeatureFlags.defaultFeatureStates[AppConstants.FeatureFlags.offlineMode] == true {
            networkMonitor.startMonitoring()
        }
    }
    
    /// Calculates exponential backoff time based on retry count
    /// - Parameter retryCount: Number of retry attempts so far
    /// - Returns: Backoff time in seconds
    func calculateBackoffTime(retryCount: Int) -> TimeInterval {
        // Base delay in seconds
        let baseDelay: TimeInterval = 1.0
        
        // Exponential backoff: base * 2^retryCount
        var delay = baseDelay * pow(2.0, Double(retryCount))
        
        // Add jitter (±30%) to prevent thundering herd problem
        let jitterPercentage = Double.random(in: -0.3...0.3)
        delay = delay * (1 + jitterPercentage)
        
        // Cap the maximum delay to 5 minutes
        let maxDelay: TimeInterval = 300.0 // 5 minutes
        delay = min(delay, maxDelay)
        
        return delay
    }
}