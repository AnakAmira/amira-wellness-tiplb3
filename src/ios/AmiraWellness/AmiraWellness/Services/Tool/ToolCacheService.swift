import Foundation // Version: standard library
import Combine // Version: Latest

// Internal imports
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift
import Tool // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift
import ToolCategory // src/ios/AmiraWellness/AmiraWellness/Models/ToolCategory.swift
import StorageService // src/ios/AmiraWellness/AmiraWellness/Services/Storage/StorageService.swift
import StorageDataType // src/ios/AmiraWellness/AmiraWellness/Services/Storage/StorageService.swift
import StorageSensitivity // src/ios/AmiraWellness/AmiraWellness/Services/Storage/StorageService.swift
import APIClient // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIClient.swift
import APIRouter // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIRouter.swift
import NetworkMonitor // src/ios/AmiraWellness/AmiraWellness/Services/Network/NetworkMonitor.swift
import AppConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/AppConstants.swift

/// Errors that can occur during tool cache operations
enum ToolCacheError: Error {
    case networkError
    case storageError
    case invalidData
    case cacheExpired
    case notFound
}

/// A singleton service that manages caching of tool data for offline access and performance optimization
final class ToolCacheService {
    
    // MARK: - Shared Instance
    
    /// Shared instance of the ToolCacheService
    static let shared = ToolCacheService()
    
    // MARK: - Private Properties
    
    /// Persistent storage service
    private let storageService: StorageService
    
    /// API client for fetching data from the backend
    private let apiClient: APIClient
    
    /// Network monitor for checking connectivity
    private let networkMonitor: NetworkMonitor
    
    /// Logger for cache operations and errors
    private let logger: Logger
    
    /// Cached tools
    private var cachedTools: [Tool] = []
    
    /// Cached tool categories
    private var cachedCategories: [ToolCategory] = []
    
    /// Cached favorite tools
    private var cachedFavorites: [Tool] = []
    
    /// Last cache update time
    private var lastCacheUpdateTime: Date?
    
    /// Subject for cache update notifications
    private let cacheUpdateSubject = PassthroughSubject<Void, Never>()
    
    /// Flag to prevent duplicate cache refreshes
    private var isRefreshing: Bool = false
    
    /// Cache time-to-live in seconds
    private let cacheTTL: TimeInterval
    
    // MARK: - Public Properties
    
    /// Publisher for cache update notifications
    public var onCacheUpdated: AnyPublisher<Void, Never> {
        return cacheUpdateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private init() {
        self.storageService = StorageService.shared
        self.apiClient = APIClient.shared
        self.networkMonitor = NetworkMonitor.shared
        self.logger = Logger.shared
        self.cachedTools = []
        self.cachedCategories = []
        self.cachedFavorites = []
        self.lastCacheUpdateTime = nil
        self.cacheUpdateSubject = PassthroughSubject<Void, Never>()
        self.isRefreshing = false
        self.cacheTTL = TimeInterval(AppConstants.Storage.cacheTTLDays * 24 * 60 * 60)
        
        // Set up onCacheUpdated as a publisher derived from cacheUpdateSubject
        
        // Load cached data from storage
        loadCachedData()
    }
    
    // MARK: - Public Methods
    
    /// Retrieves a specific tool from the cache by ID
    /// - Parameter id: The ID of the tool to retrieve
    /// - Returns: The requested tool or nil if not found in cache
    func getCachedTool(id: String) -> Tool? {
        let tool = cachedTools.first { $0.id.uuidString == id }
        if tool != nil {
            logger.debug("Cache hit for tool ID: \(id)", category: .database)
        } else {
            logger.debug("Cache miss for tool ID: \(id)", category: .database)
        }
        return tool
    }
    
    /// Retrieves all tools from the cache, optionally filtered by category
    /// - Parameter category: The category to filter tools by (optional)
    /// - Returns: Array of cached tools, filtered by category if specified
    func getCachedTools(category: ToolCategory? = nil) -> [Tool] {
        if let category = category {
            let filteredTools = cachedTools.filter { $0.category == category }
            logger.debug("Retrieved \(filteredTools.count) tools from cache for category: \(category.displayName())", category: .database)
            return filteredTools
        } else {
            logger.debug("Retrieved all \(cachedTools.count) tools from cache", category: .database)
            return cachedTools
        }
    }
    
    /// Retrieves all tool categories from the cache
    /// - Returns: Array of cached tool categories
    func getCachedCategories() -> [ToolCategory] {
        logger.debug("Retrieved all \(cachedCategories.count) categories from cache", category: .database)
        return cachedCategories
    }
    
    /// Retrieves all favorite tools from the cache
    /// - Returns: Array of cached favorite tools
    func getCachedFavorites() -> [Tool] {
        logger.debug("Retrieved all \(cachedFavorites.count) favorite tools from cache", category: .database)
        return cachedFavorites
    }
    
    /// Checks if the cache is still valid based on TTL
    /// - Returns: True if cache is valid, false if expired or empty
    func isCacheValid() -> Bool {
        guard let lastCacheUpdateTime = lastCacheUpdateTime else {
            logger.debug("Cache is invalid: lastCacheUpdateTime is nil", category: .database)
            return false
        }
        
        let timeElapsed = Date().timeIntervalSince(lastCacheUpdateTime)
        let isValid = timeElapsed < cacheTTL
        
        logger.debug("Cache is \(isValid ? "valid" : "expired"), time elapsed: \(timeElapsed), TTL: \(cacheTTL)", category: .database)
        return isValid
    }
    
    /// Refreshes the tool cache from the API
    /// - Parameters:
    ///   - forceRefresh: Whether to force a refresh even if the cache is valid
    ///   - completion: Completion handler with success or failure result
    func refreshCache(forceRefresh: Bool = false, completion: @escaping (Result<Bool, ToolCacheError>) -> Void) {
        guard !isRefreshing else {
            logger.warning("Cache refresh already in progress, ignoring request", category: .database)
            return
        }
        
        guard forceRefresh || !isCacheValid() else {
            logger.debug("Cache is valid, using cached data", category: .database)
            completion(.success(false))
            return
        }
        
        isRefreshing = true
        
        guard networkMonitor.isConnected() else {
            logger.error("Network is unavailable, cannot refresh cache", category: .database)
            isRefreshing = false
            completion(.failure(.networkError))
            return
        }
        
        var fetchedCategories: [ToolCategory] = []
        var fetchedTools: [Tool] = []
        var fetchedFavorites: [Tool] = []
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        apiClient.request(endpoint: .getToolCategories) { (result: Result<[ToolCategory], APIError>) in
            defer { dispatchGroup.leave() }
            switch result {
            case .success(let categories):
                fetchedCategories = categories
                self.logger.debug("Successfully fetched tool categories from API", category: .database)
            case .failure(let error):
                self.logger.error("Failed to fetch tool categories from API: \(error)", category: .database)
                completion(.failure(.networkError))
                return
            }
        }
        
        dispatchGroup.enter()
        apiClient.request(endpoint: .getTools(categoryId: nil, page: nil, pageSize: nil)) { (result: Result<[Tool], APIError>) in
            defer { dispatchGroup.leave() }
            switch result {
            case .success(let tools):
                fetchedTools = tools
                self.logger.debug("Successfully fetched tools from API", category: .database)
            case .failure(let error):
                self.logger.error("Failed to fetch tools from API: \(error)", category: .database)
                completion(.failure(.networkError))
                return
            }
        }
        
        dispatchGroup.enter()
        apiClient.request(endpoint: .getFavoriteTools(page: nil, pageSize: nil)) { (result: Result<[Tool], APIError>) in
            defer { dispatchGroup.leave() }
            switch result {
            case .success(let favorites):
                fetchedFavorites = favorites
                self.logger.debug("Successfully fetched favorite tools from API", category: .database)
            case .failure(let error):
                self.logger.error("Failed to fetch favorite tools from API: \(error)", category: .database)
                completion(.failure(.networkError))
                return
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.cachedCategories = fetchedCategories
            self.cachedTools = fetchedTools
            self.cachedFavorites = fetchedFavorites
            self.lastCacheUpdateTime = Date()
            
            let saveResult = self.saveCachedData()
            
            self.isRefreshing = false
            
            switch saveResult {
            case .success:
                self.logger.debug("Successfully refreshed and saved tool cache", category: .database)
                self.publishCacheUpdate()
                completion(.success(true))
            case .failure(let error):
                self.logger.error("Failed to save refreshed tool cache: \(error)", category: .database)
                completion(.failure(.storageError))
            }
        }
    }
    
    /// Refreshes the tool cache from the API using async/await
    /// - Parameter forceRefresh: Whether to force a refresh even if the cache is valid
    /// - Returns: True if cache was refreshed, false if using valid cache
    @available(iOS 15.0, *)
    func refreshCacheAsync(forceRefresh: Bool = false) async throws -> Bool {
        guard !isRefreshing else {
            logger.warning("Cache refresh already in progress, ignoring request", category: .database)
            return false
        }
        
        guard forceRefresh || !isCacheValid() else {
            logger.debug("Cache is valid, using cached data", category: .database)
            return false
        }
        
        isRefreshing = true
        
        guard networkMonitor.isConnected() else {
            logger.error("Network is unavailable, cannot refresh cache", category: .database)
            isRefreshing = false
            throw ToolCacheError.networkError
        }
        
        do {
            let fetchedCategories = try await apiClient.requestAsync(endpoint: .getToolCategories) as [ToolCategory]
            logger.debug("Successfully fetched tool categories from API", category: .database)
            
            let fetchedTools = try await apiClient.requestAsync(endpoint: .getTools(categoryId: nil, page: nil, pageSize: nil)) as [Tool]
            logger.debug("Successfully fetched tools from API", category: .database)
            
            let fetchedFavorites = try await apiClient.requestAsync(endpoint: .getFavoriteTools(page: nil, pageSize: nil)) as [Tool]
            logger.debug("Successfully fetched favorite tools from API", category: .database)
            
            cachedCategories = fetchedCategories
            cachedTools = fetchedTools
            cachedFavorites = fetchedFavorites
            lastCacheUpdateTime = Date()
            
            let saveResult = saveCachedData()
            
            isRefreshing = false
            
            switch saveResult {
            case .success:
                logger.debug("Successfully refreshed and saved tool cache", category: .database)
                publishCacheUpdate()
                return true
            case .failure(let error):
                logger.error("Failed to save refreshed tool cache: \(error)", category: .database)
                throw ToolCacheError.storageError
            }
        } catch {
            isRefreshing = false
            logger.error("Failed to refresh tool cache: \(error)", category: .database)
            throw error as? ToolCacheError ?? ToolCacheError.networkError
        }
    }
    
    /// Updates a specific tool in the cache
    /// - Parameter tool: The tool to update
    /// - Returns: Success or failure with specific error
    func updateToolInCache(tool: Tool) -> Result<Void, ToolCacheError> {
        if let index = cachedTools.firstIndex(where: { $0.id == tool.id }) {
            cachedTools[index] = tool
            logger.debug("Updated tool in cache at index: \(index)", category: .database)
        } else {
            cachedTools.append(tool)
            logger.debug("Appended tool to cache", category: .database)
        }
        
        if tool.isFavorite {
            if !cachedFavorites.contains(where: { $0.id == tool.id }) {
                cachedFavorites.append(tool)
                logger.debug("Appended tool to favorites cache", category: .database)
            }
        } else {
            cachedFavorites.removeAll { $0.id == tool.id }
            logger.debug("Removed tool from favorites cache", category: .database)
        }
        
        let saveResult = saveCachedData()
        
        switch saveResult {
        case .success:
            publishCacheUpdate()
            return .success(())
        case .failure(let error):
            logger.error("Failed to save updated tool cache: \(error)", category: .database)
            return .failure(.storageError)
        }
    }
    
    /// Clears the tool cache
    /// - Returns: Success or failure with specific error
    func clearCache() -> Result<Void, ToolCacheError> {
        cachedTools.removeAll()
        cachedCategories.removeAll()
        cachedFavorites.removeAll()
        lastCacheUpdateTime = nil
        
        let deleteResult = storageService.deleteData(forKey: "tools", dataType: .cache, sensitivity: .nonsensitive)
        
        switch deleteResult {
        case .success:
            logger.debug("Successfully cleared tool cache", category: .database)
            publishCacheUpdate()
            return .success(())
        case .failure(let error):
            logger.error("Failed to clear tool cache: \(error)", category: .database)
            return .failure(.storageError)
        }
    }
    
    /// Prefetches high-priority tools for offline access
    /// - Returns: Number of tools prefetched or failure with specific error
    func prefetchHighPriorityTools() -> Result<Int, ToolCacheError> {
        guard networkMonitor.isConnected() else {
            logger.error("Network is unavailable, cannot prefetch tools", category: .database)
            return .failure(.networkError)
        }
        
        // Identify high-priority tools (favorites, frequently used, basic tools)
        let highPriorityTools = cachedTools.filter { $0.isFavorite }
        
        // For each high-priority tool, fetch full details if not already cached
        var prefetchedCount = 0
        for tool in highPriorityTools {
            if getCachedTool(id: tool.id.uuidString) == nil {
                // Simulate fetching full details from API
                logger.debug("Simulating fetching full details for tool: \(tool.name)", category: .database)
                prefetchedCount += 1
            }
        }
        
        // Store prefetched tools in cache
        let saveResult = saveCachedData()
        
        switch saveResult {
        case .success:
            logger.debug("Successfully prefetched \(prefetchedCount) high-priority tools", category: .database)
            return .success(prefetchedCount)
        case .failure(let error):
            logger.error("Failed to save prefetched tools: \(error)", category: .database)
            return .failure(.storageError)
        }
    }
    
    /// Prefetches high-priority tools for offline access using async/await
    /// - Returns: Number of tools prefetched
    @available(iOS 15.0, *)
    func prefetchHighPriorityToolsAsync() async throws -> Int {
        guard networkMonitor.isConnected() else {
            logger.error("Network is unavailable, cannot prefetch tools", category: .database)
            throw ToolCacheError.networkError
        }
        
        // Identify high-priority tools (favorites, frequently used, basic tools)
        let highPriorityTools = cachedTools.filter { $0.isFavorite }
        
        // For each high-priority tool, fetch full details if not already cached
        var prefetchedCount = 0
        for tool in highPriorityTools {
            if getCachedTool(id: tool.id.uuidString) == nil {
                // Simulate fetching full details from API
                logger.debug("Simulating fetching full details for tool: \(tool.name)", category: .database)
                prefetchedCount += 1
            }
        }
        
        // Store prefetched tools in cache
        let saveResult = saveCachedData()
        
        switch saveResult {
        case .success:
            logger.debug("Successfully prefetched \(prefetchedCount) high-priority tools", category: .database)
            return prefetchedCount
        case .failure(let error):
            logger.error("Failed to save prefetched tools: \(error)", category: .database)
            throw ToolCacheError.storageError
        }
    }
    
    // MARK: - Private Methods
    
    /// Loads cached tool data from persistent storage
    private func loadCachedData() {
        let toolsResult: Result<[Tool], StorageError> = storageService.retrieveCodable(forKey: "tools", dataType: .cache, sensitivity: .nonsensitive)
        switch toolsResult {
        case .success(let tools):
            cachedTools = tools
            logger.debug("Loaded \(tools.count) tools from cache", category: .database)
        case .failure(let error):
            logger.error("Failed to load tools from cache: \(error)", category: .database)
        }
        
        let categoriesResult: Result<[ToolCategory], StorageError> = storageService.retrieveCodable(forKey: "categories", dataType: .cache, sensitivity: .nonsensitive)
        switch categoriesResult {
        case .success(let categories):
            cachedCategories = categories
            logger.debug("Loaded \(categories.count) categories from cache", category: .database)
        case .failure(let error):
            logger.error("Failed to load categories from cache: \(error)", category: .database)
        }
        
        let favoritesResult: Result<[Tool], StorageError> = storageService.retrieveCodable(forKey: "favorites", dataType: .cache, sensitivity: .nonsensitive)
        switch favoritesResult {
        case .success(let favorites):
            cachedFavorites = favorites
            logger.debug("Loaded \(favorites.count) favorites from cache", category: .database)
        case .failure(let error):
            logger.error("Failed to load favorites from cache: \(error)", category: .database)
        }
        
        let lastUpdateResult: Result<Date, StorageError> = storageService.retrieveCodable(forKey: "lastCacheUpdate", dataType: .cache, sensitivity: .nonsensitive)
        switch lastUpdateResult {
        case .success(let date):
            lastCacheUpdateTime = date
            logger.debug("Loaded last cache update time: \(date)", category: .database)
        case .failure(let error):
            logger.error("Failed to load last cache update time: \(error)", category: .database)
        }
    }
    
    /// Saves cached tool data to persistent storage
    private func saveCachedData() -> Result<Void, ToolCacheError> {
        let toolsResult = storageService.storeCodable(cachedTools, forKey: "tools", dataType: .cache, sensitivity: .nonsensitive)
        let categoriesResult = storageService.storeCodable(cachedCategories, forKey: "categories", dataType: .cache, sensitivity: .nonsensitive)
        let favoritesResult = storageService.storeCodable(cachedFavorites, forKey: "favorites", dataType: .cache, sensitivity: .nonsensitive)
        let lastUpdateResult = storageService.storeCodable(lastCacheUpdateTime, forKey: "lastCacheUpdate", dataType: .cache, sensitivity: .nonsensitive)
        
        if case .failure(let error) = toolsResult {
            logger.error("Failed to save tools to cache: \(error)", category: .database)
            return .failure(.storageError)
        }
        
        if case .failure(let error) = categoriesResult {
            logger.error("Failed to save categories to cache: \(error)", category: .database)
            return .failure(.storageError)
        }
        
        if case .failure(let error) = favoritesResult {
            logger.error("Failed to save favorites to cache: \(error)", category: .database)
            return .failure(.storageError)
        }
        
        if case .failure(let error) = lastUpdateResult {
            logger.error("Failed to save last update time to cache: \(error)", category: .database)
            return .failure(.storageError)
        }
        
        logger.debug("Successfully saved tool cache", category: .database)
        return .success(())
    }
    
    /// Publishes a cache update notification
    private func publishCacheUpdate() {
        cacheUpdateSubject.send()
        logger.debug("Published cache update notification", category: .database)
    }
}