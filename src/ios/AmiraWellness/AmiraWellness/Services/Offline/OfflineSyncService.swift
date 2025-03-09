import Foundation // Latest
import Combine // Latest

// Internal imports
import DataQueueService // src/ios/AmiraWellness/AmiraWellness/Services/Offline/DataQueueService.swift
import NetworkMonitor // src/ios/AmiraWellness/AmiraWellness/Services/Network/NetworkMonitor.swift
import APIClient // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIClient.swift
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift
import AppConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/AppConstants.swift

/// Defines possible errors that can occur during synchronization
enum SyncError: Error {
    case networkUnavailable
    case syncInProgress
    case queueEmpty
    case maxRetriesExceeded
    case unknown
}

/// Represents the possible states of the synchronization process
enum SyncStatus {
    case idle
    case inProgress
    case completed
    case failed
}

/// Contains the results of a synchronization operation
struct SyncResult {
    let successCount: Int
    let failureCount: Int
    let remainingCount: Int
}

/// A singleton service that manages the synchronization of offline data with the backend server
final class OfflineSyncService {
    // MARK: - Shared Instance
    
    /// Shared instance of the OfflineSyncService
    static let shared = OfflineSyncService()
    
    // MARK: - Private Properties
    
    /// Data queue service for managing offline operations
    private let dataQueueService: DataQueueService
    
    /// Network monitor for checking connectivity status
    private let networkMonitor: NetworkMonitor
    
    /// API client for making network requests
    private let apiClient: APIClient
    
    /// Logger for sync operations
    private let logger: Logger
    
    /// Current synchronization status
    private var syncStatus: SyncStatus = .idle
    
    /// Subject for publishing synchronization status changes
    private let statusSubject = CurrentValueSubject<SyncStatus, Never>(.idle)
    
    /// Subject for publishing synchronization results
    private let resultSubject = PassthroughSubject<SyncResult, Never>()
    
    /// Task for ongoing synchronization (used for cancellation)
    private var syncTask: Task<Void, Never>?
    
    /// Set of Combine cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Lock for thread-safe access to sync-related properties
    private let syncLock = NSLock()
    
    /// Maximum number of retry attempts for failed operations
    private let maxRetryCount: Int
    
    /// Minimum interval between automatic synchronization attempts
    private let minSyncInterval: TimeInterval
    
    /// Time of the last synchronization attempt
    private var lastSyncTime: Date
    
    /// Flag indicating if automatic synchronization is enabled
    private var autoSyncEnabled: Bool
    
    // MARK: - Public Properties
    
    /// Publisher for synchronization status changes
    public var statusPublisher: AnyPublisher<SyncStatus, Never> {
        return statusSubject.eraseToAnyPublisher()
    }
    
    /// Publisher for synchronization results
    public var resultPublisher: AnyPublisher<SyncResult, Never> {
        return resultSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private init() {
        // Initialize dependencies
        self.dataQueueService = DataQueueService.shared
        self.networkMonitor = NetworkMonitor.shared
        self.apiClient = APIClient.shared
        self.logger = Logger.shared
        
        // Set initial sync status
        self.syncStatus = .idle
        
        // Initialize subjects and publishers
        self.statusSubject = CurrentValueSubject<SyncStatus, Never>(.idle)
        self.resultSubject = PassthroughSubject<SyncResult, Never>()
        
        // Initialize sync task
        self.syncTask = nil
        
        // Initialize cancellables
        self.cancellables = Set<AnyCancellable>()
        
        // Initialize sync lock
        self.syncLock = NSLock()
        
        // Set max retry count and min sync interval from AppConstants
        self.maxRetryCount = AppConstants.Sync.maxRetryCount
        self.minSyncInterval = AppConstants.Sync.minSyncInterval
        
        // Set last sync time to distant past
        self.lastSyncTime = Date.distantPast
        
        // Set auto sync enabled to true
        self.autoSyncEnabled = true
        
        // Subscribe to network status changes to trigger auto-sync
        networkMonitor.statusPublisher
            .sink { [weak self] status in
                self?.handleNetworkStatusChange(status: status)
            }
            .store(in: &cancellables)
        
        logger.debug("OfflineSyncService initialized", category: .sync)
    }
    
    // MARK: - Public Methods
    
    /// Initiates synchronization of offline data with the backend server
    /// - Parameter completion: Optional completion handler called after sync completes
    /// - Returns: Result indicating success or failure with specific error
    func sync(completion: ((SyncResult) -> Void)? = nil) -> Result<Void, SyncError> {
        // Check if network is connected
        guard networkMonitor.isConnected() else {
            logger.info("Sync aborted: Device is offline", category: .sync)
            return .failure(.networkUnavailable)
        }
        
        // Acquire sync lock to ensure thread safety
        syncLock.lock()
        defer { syncLock.unlock() }
        
        // Check if sync is already in progress
        guard syncStatus != .inProgress else {
            logger.warning("Sync already in progress", category: .sync)
            return .failure(.syncInProgress)
        }
        
        // Check if queue is empty
        guard dataQueueService.getQueueCount() > 0 else {
            logger.info("Sync aborted: Queue is empty", category: .sync)
            return .failure(.queueEmpty)
        }
        
        // Check if minimum sync interval has elapsed
        if shouldThrottleSync() {
            let timeSinceLastSync = Date().timeIntervalSince(lastSyncTime)
            let remainingTime = minSyncInterval - timeSinceLastSync
            logger.info("Sync throttled: Minimum sync interval not elapsed, waiting \(remainingTime) seconds", category: .sync)
            
            // Wait until minimum interval has passed
            Thread.sleep(forTimeInterval: remainingTime)
        }
        
        // Set sync status to in progress and publish the status
        updateSyncStatus(status: .inProgress)
        
        // Process the queue
        dataQueueService.processQueue { [weak self] successCount, failureCount, remainingCount in
            guard let self = self else { return }
            
            // Update sync status based on result
            let newStatus: SyncStatus = (failureCount == 0 && remainingCount == 0) ? .completed : .failed
            self.updateSyncStatus(status: newStatus)
            
            // Update last sync time
            self.lastSyncTime = Date()
            
            // Create and publish SyncResult
            let syncResult = SyncResult(successCount: successCount, failureCount: failureCount, remainingCount: remainingCount)
            self.resultSubject.send(syncResult)
            
            // Call completion handler if provided
            completion?(syncResult)
            
            logger.info("Sync completed: \(successCount) succeeded, \(failureCount) failed, \(remainingCount) remaining", category: .sync)
        }
        
        return .success(())
    }
    
    /// Initiates synchronization using async/await pattern
    /// - Returns: Synchronization result or throws an error
    @available(iOS 15.0, *)
    func syncAsync() async throws -> SyncResult {
        // Check if network is connected
        guard networkMonitor.isConnected() else {
            logger.info("Async Sync aborted: Device is offline", category: .sync)
            throw SyncError.networkUnavailable
        }
        
        // Acquire sync lock to ensure thread safety
        syncLock.lock()
        defer { syncLock.unlock() }
        
        // Check if sync is already in progress
        guard syncStatus != .inProgress else {
            logger.warning("Async Sync already in progress", category: .sync)
            throw SyncError.syncInProgress
        }
        
        // Check if queue is empty
        guard dataQueueService.getQueueCount() > 0 else {
            logger.info("Async Sync aborted: Queue is empty", category: .sync)
            throw SyncError.queueEmpty
        }
        
        // Check if minimum sync interval has elapsed
        if shouldThrottleSync() {
            let timeSinceLastSync = Date().timeIntervalSince(lastSyncTime)
            let remainingTime = minSyncInterval - timeSinceLastSync
            logger.info("Async Sync throttled: Minimum sync interval not elapsed, waiting \(remainingTime) seconds", category: .sync)
            
            // Wait until minimum interval has passed
            try await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
        }
        
        // Set sync status to in progress and publish the status
        updateSyncStatus(status: .inProgress)
        
        // Process the queue using async/await
        let (successCount, failureCount, remainingCount) = await withCheckedContinuation { continuation in
            dataQueueService.processQueue { successCount, failureCount, remainingCount in
                continuation.resume(returning: (successCount, failureCount, remainingCount))
            }
        }
        
        // Update sync status based on result
        let newStatus: SyncStatus = (failureCount == 0 && remainingCount == 0) ? .completed : .failed
        updateSyncStatus(status: newStatus)
        
        // Update last sync time
        lastSyncTime = Date()
        
        // Create SyncResult
        let syncResult = SyncResult(successCount: successCount, failureCount: failureCount, remainingCount: remainingCount)
        
        // Publish the result
        resultSubject.send(syncResult)
        
        logger.info("Async Sync completed: \(successCount) succeeded, \(failureCount) failed, \(remainingCount) remaining", category: .sync)
        
        return syncResult
    }
    
    /// Cancels an ongoing synchronization operation
    func cancelSync() {
        // Acquire sync lock to ensure thread safety
        syncLock.lock()
        defer { syncLock.unlock() }
        
        // Check if syncStatus is .inProgress
        guard syncStatus == .inProgress else {
            logger.warning("Cancel sync requested but sync is not in progress", category: .sync)
            return
        }
        
        // Cancel the sync task
        syncTask?.cancel()
        
        // Set sync status to idle and publish the status
        updateSyncStatus(status: .idle)
        
        logger.info("Sync cancelled", category: .sync)
    }
    
    /// Enables or disables automatic synchronization when network becomes available
    /// - Parameter enabled: A boolean value indicating whether auto-sync should be enabled
    func setAutoSync(enabled: Bool) {
        autoSyncEnabled = enabled
        logger.info("Auto-sync set to \(enabled)", category: .sync)
    }
    
    /// Returns the current synchronization status
    /// - Returns: Current synchronization status
    func getSyncStatus() -> SyncStatus {
        return syncStatus
    }
    
    /// Returns the number of operations pending synchronization
    /// - Returns: Number of pending operations
    func getPendingOperationsCount() -> Int {
        return dataQueueService.getQueueCount()
    }
    
    // MARK: - Private Methods
    
    /// Handles changes in network connectivity status
    /// - Parameter status: The new network status
    private func handleNetworkStatusChange(status: NetworkStatus) {
        // Check if status is .connected and autoSyncEnabled is true
        guard status == .connected, autoSyncEnabled else {
            return
        }
        
        // Check if there are pending operations
        guard dataQueueService.getQueueCount() > 0 else {
            return
        }
        
        // Initiate synchronization
        logger.info("Network connectivity restored, initiating sync", category: .sync)
        _ = sync()
    }
    
    /// Updates the synchronization status and publishes the change
    /// - Parameter status: The new synchronization status
    private func updateSyncStatus(status: SyncStatus) {
        syncStatus = status
        statusSubject.send(status)
        logger.debug("Sync status updated to \(status)", category: .sync)
    }
    
    /// Determines if synchronization should be throttled based on last sync time
    /// - Returns: True if sync should be throttled, false otherwise
    private func shouldThrottleSync() -> Bool {
        let timeSinceLastSync = Date().timeIntervalSince(lastSyncTime)
        return timeSinceLastSync < minSyncInterval
    }
}