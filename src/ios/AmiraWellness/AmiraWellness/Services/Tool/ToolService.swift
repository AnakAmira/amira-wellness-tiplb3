import Foundation // Version: standard library
import Combine // Version: Latest

// Internal imports
import Logger // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift
import Tool // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift
import ToolCategory // src/ios/AmiraWellness/AmiraWellness/Models/ToolCategory.swift
import EmotionType // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalState.swift
import StorageService // src/ios/AmiraWellness/AmiraWellness/Services/Storage/StorageService.swift
import APIClient // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIClient.swift
import APIRouter // src/ios/AmiraWellness/AmiraWellness/Services/Network/APIRouter.swift
import NetworkMonitor // src/ios/AmiraWellness/AmiraWellness/Services/Network/NetworkMonitor.swift

/// Errors that can occur during tool service operations
enum ToolServiceError: Error, Equatable {
    case networkError
    case notFound
    case serverError
    case invalidData
    case cacheError
}

/// A singleton service that manages the retrieval and manipulation of tools in the Amira Wellness application
final class ToolService {
    
    // MARK: - Public Properties
    
    /// Shared instance of the ToolService
    static let shared = ToolService()
    
    // MARK: - Private Properties
    
    /// API client for network requests
    private let apiClient: APIClient
    /// Cache service for tool data
    private let cacheService: ToolCacheService
    /// Logger for service operations
    private let logger: Logger
    
    /// Publisher for tool updates
    private let toolUpdatedSubject = PassthroughSubject<Tool, Never>()
    /// Publisher for tools loaded events
    private let toolsLoadedSubject = PassthroughSubject<Void, Never>()
    /// Publisher for categories loaded events
    private let categoriesLoadedSubject = PassthroughSubject<Void, Never>()
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private init() {
        self.apiClient = APIClient.shared
        self.cacheService = ToolCacheService.shared
        self.logger = Logger.shared
        self.toolUpdatedSubject = PassthroughSubject<Tool, Never>()
        self.toolsLoadedSubject = PassthroughSubject<Void, Never>()
        self.categoriesLoadedSubject = PassthroughSubject<Void, Never>()
    }
    
    // MARK: - Public Methods
    
    /// Retrieves all tool categories, using cache when available
    /// - Parameters:
    ///   - forceRefresh: Whether to force a refresh from the API
    ///   - completion: Completion handler with the result
    func getToolCategories(forceRefresh: Bool = false, completion: @escaping (Result<[ToolCategory], ToolServiceError>) -> Void) {
        if !forceRefresh, let cachedCategories = cacheService.getCachedCategories(), !cachedCategories.isEmpty {
            logger.debug("Returning cached tool categories", category: .database)
            completion(.success(cachedCategories))
            return
        }
        
        cacheService.refreshCache { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                let categories = self.cacheService.getCachedCategories()
                self.logger.debug("Successfully refreshed tool categories from cache", category: .database)
                completion(.success(categories))
                self.categoriesLoadedSubject.send()
            case .failure(let error):
                self.logger.error("Failed to refresh tool categories: \(error)", category: .database)
                completion(.failure(self.mapCacheError(error)))
            }
        }
    }
    
    /// Retrieves all tool categories using async/await
    /// - Parameter forceRefresh: Whether to force a refresh from the API
    /// - Returns: Array of tool categories
    @available(iOS 15.0, *)
    func getToolCategoriesAsync(forceRefresh: Bool = false) async throws -> [ToolCategory] {
        if !forceRefresh, let cachedCategories = cacheService.getCachedCategories(), !cachedCategories.isEmpty {
            logger.debug("Returning cached tool categories", category: .database)
            return cachedCategories
        }
        
        do {
            let _ = try await cacheService.refreshCacheAsync()
            let categories = self.cacheService.getCachedCategories()
            self.logger.debug("Successfully refreshed tool categories from cache", category: .database)
            self.categoriesLoadedSubject.send()
            return categories
        } catch {
            self.logger.error("Failed to refresh tool categories: \(error)", category: .database)
            throw mapCacheError(error as! ToolCacheError)
        }
    }
    
    /// Retrieves tools, optionally filtered by category
    /// - Parameters:
    ///   - category: The category to filter tools by
    ///   - forceRefresh: Whether to force a refresh from the API
    ///   - completion: Completion handler with the result
    func getTools(category: ToolCategory? = nil, forceRefresh: Bool = false, completion: @escaping (Result<[Tool], ToolServiceError>) -> Void) {
        if !forceRefresh, let cachedTools = cacheService.getCachedTools(category: category), !cachedTools.isEmpty {
            logger.debug("Returning cached tools", category: .database)
            completion(.success(cachedTools))
            return
        }
        
        cacheService.refreshCache { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                let tools = self.cacheService.getCachedTools(category: category)
                self.logger.debug("Successfully refreshed tools from cache", category: .database)
                completion(.success(tools))
                self.toolsLoadedSubject.send()
            case .failure(let error):
                self.logger.error("Failed to refresh tools: \(error)", category: .database)
                completion(.failure(self.mapCacheError(error)))
            }
        }
    }
    
    /// Retrieves tools using async/await, optionally filtered by category
    /// - Parameters:
    ///   - category: The category to filter tools by
    ///   - forceRefresh: Whether to force a refresh from the API
    /// - Returns: Array of tools
    @available(iOS 15.0, *)
    func getToolsAsync(category: ToolCategory? = nil, forceRefresh: Bool = false) async throws -> [Tool] {
        if !forceRefresh, let cachedTools = cacheService.getCachedTools(category: category), !cachedTools.isEmpty {
            logger.debug("Returning cached tools", category: .database)
            return cachedTools
        }
        
        do {
            let _ = try await cacheService.refreshCacheAsync()
            let tools = self.cacheService.getCachedTools(category: category)
            self.logger.debug("Successfully refreshed tools from cache", category: .database)
            self.toolsLoadedSubject.send()
            return tools
        } catch {
            self.logger.error("Failed to refresh tools: \(error)", category: .database)
            throw mapCacheError(error as! ToolCacheError)
        }
    }
    
    /// Retrieves a specific tool by ID
    /// - Parameters:
    ///   - id: The ID of the tool to retrieve
    ///   - forceRefresh: Whether to force a refresh from the API
    ///   - completion: Completion handler with the result
    func getTool(id: String, forceRefresh: Bool = false, completion: @escaping (Result<Tool, ToolServiceError>) -> Void) {
        if !forceRefresh, let cachedTool = cacheService.getCachedTool(id: id) {
            logger.debug("Returning cached tool with ID: \(id)", category: .database)
            completion(.success(cachedTool))
            return
        }
        
        apiClient.request(endpoint: .getTool(toolId: id)) { [weak self] (result: Result<Tool, APIError>) in
            guard let self = self else { return }
            switch result {
            case .success(let tool):
                self.logger.debug("Successfully fetched tool with ID: \(id) from API", category: .database)
                let _ = self.cacheService.updateToolInCache(tool: tool)
                completion(.success(tool))
                self.toolUpdatedSubject.send(tool)
            case .failure(let error):
                self.logger.error("Failed to fetch tool with ID: \(id) from API: \(error)", category: .database)
                completion(.failure(self.mapAPIError(error)))
            }
        }
    }
    
    /// Retrieves a specific tool by ID using async/await
    /// - Parameters:
    ///   - id: The ID of the tool to retrieve
    ///   - forceRefresh: Whether to force a refresh from the API
    /// - Returns: The requested tool
    @available(iOS 15.0, *)
    func getToolAsync(id: String, forceRefresh: Bool = false) async throws -> Tool {
        if !forceRefresh, let cachedTool = cacheService.getCachedTool(id: id) {
            logger.debug("Returning cached tool with ID: \(id)", category: .database)
            return cachedTool
        }
        
        do {
            let tool: Tool = try await apiClient.requestAsync(endpoint: .getTool(toolId: id))
            self.logger.debug("Successfully fetched tool with ID: \(id) from API", category: .database)
            let _ = self.cacheService.updateToolInCache(tool: tool)
            self.toolUpdatedSubject.send(tool)
            return tool
        } catch {
            self.logger.error("Failed to fetch tool with ID: \(id) from API: \(error)", category: .database)
            throw mapAPIError(error as! APIError)
        }
    }
    
    /// Retrieves all favorite tools
    /// - Parameters:
    ///   - forceRefresh: Whether to force a refresh from the API
    ///   - completion: Completion handler with the result
    func getFavoriteTools(forceRefresh: Bool = false, completion: @escaping (Result<[Tool], ToolServiceError>) -> Void) {
        if !forceRefresh, let cachedFavorites = cacheService.getCachedFavorites(), !cachedFavorites.isEmpty {
            logger.debug("Returning cached favorite tools", category: .database)
            completion(.success(cachedFavorites))
            return
        }
        
        apiClient.request(endpoint: .getFavoriteTools(page: nil, pageSize: nil)) { [weak self] (result: Result<[Tool], APIError>) in
            guard let self = self else { return }
            switch result {
            case .success(let tools):
                self.logger.debug("Successfully fetched favorite tools from API", category: .database)
                self.cachedFavorites = tools
                let _ = self.cacheService.saveCachedData()
                completion(.success(tools))
                self.toolsLoadedSubject.send()
            case .failure(let error):
                self.logger.error("Failed to fetch favorite tools from API: \(error)", category: .database)
                completion(.failure(self.mapAPIError(error)))
            }
        }
    }
    
    /// Retrieves all favorite tools using async/await
    /// - Parameter forceRefresh: Whether to force a refresh from the API
    /// - Returns: Array of favorite tools
    @available(iOS 15.0, *)
    func getFavoriteToolsAsync(forceRefresh: Bool = false) async throws -> [Tool] {
        if !forceRefresh, let cachedFavorites = cacheService.getCachedFavorites(), !cachedFavorites.isEmpty {
            logger.debug("Returning cached favorite tools", category: .database)
            return cachedFavorites
        }
        
        do {
            let tools: [Tool] = try await apiClient.requestAsync(endpoint: .getFavoriteTools(page: nil, pageSize: nil))
            self.logger.debug("Successfully fetched favorite tools from API", category: .database)
            self.cachedFavorites = tools
            let _ = self.cacheService.saveCachedData()
            self.toolsLoadedSubject.send()
            return tools
        } catch {
            self.logger.error("Failed to fetch favorite tools from API: \(error)", category: .database)
            throw mapAPIError(error as! APIError)
        }
    }
    
    /// Retrieves tools recommended for a specific emotion type
    /// - Parameters:
    ///   - emotionType: The emotion type to get recommendations for
    ///   - limit: The maximum number of recommendations to return
    ///   - forceRefresh: Whether to force a refresh from the API
    ///   - completion: Completion handler with the result
    func getRecommendedTools(emotionType: EmotionType, limit: Int? = nil, forceRefresh: Bool = false, completion: @escaping (Result<[Tool], ToolServiceError>) -> Void) {
        if !NetworkMonitor.shared.isConnected() && forceRefresh {
            completion(.failure(.networkError))
            return
        }
        
        if !NetworkMonitor.shared.isConnected() {
            let filteredTools = cacheService.getCachedTools().filter { $0.targetEmotions.contains(emotionType) }
            completion(.success(filteredTools))
            return
        }
        
        apiClient.request(endpoint: .getRecommendedTools(emotionType: emotionType.rawValue, limit: limit)) { [weak self] (result: Result<[Tool], APIError>) in
            guard let self = self else { return }
            switch result {
            case .success(let tools):
                self.logger.debug("Successfully fetched recommended tools from API", category: .database)
                let _ = self.cacheService.saveCachedData()
                completion(.success(tools))
            case .failure(let error):
                self.logger.error("Failed to fetch recommended tools from API: \(error)", category: .database)
                completion(.failure(self.mapAPIError(error)))
            }
        }
    }
    
    /// Retrieves tools recommended for a specific emotion type using async/await
    /// - Parameters:
    ///   - emotionType: The emotion type to get recommendations for
    ///   - limit: The maximum number of recommendations to return
    ///   - forceRefresh: Whether to force a refresh from the API
    /// - Returns: Array of recommended tools
    @available(iOS 15.0, *)
    func getRecommendedToolsAsync(emotionType: EmotionType, limit: Int? = nil, forceRefresh: Bool = false) async throws -> [Tool] {
        if !NetworkMonitor.shared.isConnected() && forceRefresh {
            throw ToolServiceError.networkError
        }
        
        if !NetworkMonitor.shared.isConnected() {
            let filteredTools = cacheService.getCachedTools().filter { $0.targetEmotions.contains(emotionType) }
            return filteredTools
        }
        
        do {
            let tools: [Tool] = try await apiClient.requestAsync(endpoint: .getRecommendedTools(emotionType: emotionType.rawValue, limit: limit))
            self.logger.debug("Successfully fetched recommended tools from API", category: .database)
            let _ = self.cacheService.saveCachedData()
            return tools
        } catch {
            self.logger.error("Failed to fetch recommended tools from API: \(error)", category: .database)
            throw mapAPIError(error as! APIError)
        }
    }
    
    /// Toggles the favorite status of a tool
    /// - Parameters:
    ///   - tool: The tool to toggle the favorite status for
    ///   - completion: Completion handler with the result
    func toggleFavorite(tool: Tool, completion: @escaping (Result<Tool, ToolServiceError>) -> Void) {
        let updatedTool = tool.toggleFavorite()
        
        apiClient.request(endpoint: .toggleToolFavorite(toolId: tool.id.uuidString, isFavorite: updatedTool.isFavorite)) { [weak self] (result: Result<Tool, APIError>) in
            guard let self = self else { return }
            switch result {
            case .success(let updatedTool):
                self.logger.debug("Successfully toggled favorite status for tool: \(tool.name)", category: .database)
                let _ = self.cacheService.updateToolInCache(tool: updatedTool)
                completion(.success(updatedTool))
                self.toolUpdatedSubject.send(updatedTool)
            case .failure(let error):
                self.logger.error("Failed to toggle favorite status for tool: \(tool.name) from API: \(error)", category: .database)
                completion(.failure(self.mapAPIError(error)))
            }
        }
    }
    
    /// Toggles the favorite status of a tool using async/await
    /// - Parameter tool: The tool to toggle the favorite status for
    /// - Returns: Updated tool with toggled favorite status
    @available(iOS 15.0, *)
    func toggleFavoriteAsync(tool: Tool) async throws -> Tool {
        let updatedTool = tool.toggleFavorite()
        
        do {
            let toggledTool: Tool = try await apiClient.requestAsync(endpoint: .toggleToolFavorite(toolId: tool.id.uuidString, isFavorite: updatedTool.isFavorite))
            self.logger.debug("Successfully toggled favorite status for tool: \(tool.name)", category: .database)
            let _ = self.cacheService.updateToolInCache(tool: toggledTool)
            self.toolUpdatedSubject.send(toggledTool)
            return toggledTool
        } catch {
            self.logger.error("Failed to toggle favorite status for tool: \(tool.name) from API: \(error)", category: .database)
            throw mapAPIError(error as! APIError)
        }
    }
    
    /// Tracks the usage of a tool and increments its usage count
    /// - Parameters:
    ///   - tool: The tool to track usage for
    ///   - durationSeconds: The duration of the tool usage in seconds
    ///   - completion: Completion handler with the result
    func trackToolUsage(tool: Tool, durationSeconds: Int, completion: @escaping (Result<Tool, ToolServiceError>) -> Void) {
        let updatedTool = tool.incrementUsageCount()
        
        apiClient.request(endpoint: .trackToolUsage(toolId: tool.id.uuidString, durationSeconds: durationSeconds)) { [weak self] (result: Result<Tool, APIError>) in
            guard let self = self else { return }
            switch result {
            case .success(let updatedTool):
                self.logger.debug("Successfully tracked usage for tool: \(tool.name)", category: .database)
                let _ = self.cacheService.updateToolInCache(tool: updatedTool)
                completion(.success(updatedTool))
                self.toolUpdatedSubject.send(updatedTool)
            case .failure(let error):
                self.logger.error("Failed to track usage for tool: \(tool.name) from API: \(error)", category: .database)
                completion(.failure(self.mapAPIError(error)))
            }
        }
    }
    
    /// Tracks the usage of a tool using async/await
    /// - Parameters:
    ///   - tool: The tool to track usage for
    ///   - durationSeconds: The duration of the tool usage in seconds
    /// - Returns: Updated tool with incremented usage count
    @available(iOS 15.0, *)
    func trackToolUsageAsync(tool: Tool, durationSeconds: Int) async throws -> Tool {
        let updatedTool = tool.incrementUsageCount()
        
        do {
            let usedTool: Tool = try await apiClient.requestAsync(endpoint: .trackToolUsage(toolId: tool.id.uuidString, durationSeconds: durationSeconds))
            self.logger.debug("Successfully tracked usage for tool: \(tool.name)", category: .database)
            let _ = self.cacheService.updateToolInCache(tool: usedTool)
            self.toolUpdatedSubject.send(usedTool)
            return usedTool
        } catch {
            self.logger.error("Failed to track usage for tool: \(tool.name) from API: \(error)", category: .database)
            throw mapAPIError(error as! APIError)
        }
    }
    
    /// Refreshes all tool data from the server
    /// - Parameter completion: Completion handler with the result
    func refreshToolData(completion: @escaping (Result<Bool, ToolServiceError>) -> Void) {
        cacheService.refreshCache { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.toolsLoadedSubject.send()
                self.categoriesLoadedSubject.send()
                completion(.success(true))
            case .failure(let error):
                completion(.failure(self.mapCacheError(error)))
            }
        }
    }
    
    /// Refreshes all tool data from the server using async/await
    /// - Returns: True if refresh was successful
    @available(iOS 15.0, *)
    func refreshToolDataAsync() async throws -> Bool {
        do {
            let _ = try await cacheService.refreshCacheAsync()
            self.toolsLoadedSubject.send()
            self.categoriesLoadedSubject.send()
            return true
        } catch {
            throw mapCacheError(error as! ToolCacheError)
        }
    }
    
    /// Returns a publisher that emits when a tool is updated
    /// - Returns: Publisher for tool updates
    func getToolUpdatedPublisher() -> AnyPublisher<Tool, Never> {
        return toolUpdatedSubject.eraseToAnyPublisher()
    }
    
    /// Returns a publisher that emits when tools are loaded
    /// - Returns: Publisher for tools loaded events
    func getToolsLoadedPublisher() -> AnyPublisher<Void, Never> {
        return toolsLoadedSubject.eraseToAnyPublisher()
    }
    
    /// Returns a publisher that emits when categories are loaded
    /// - Returns: Publisher for categories loaded events
    func getCategoriesLoadedPublisher() -> AnyPublisher<Void, Never> {
        return categoriesLoadedSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    /// Maps a ToolCacheError to a ToolServiceError
    /// - Parameter error: The ToolCacheError to map
    /// - Returns: Mapped service error
    private func mapCacheError(_ error: ToolCacheError) -> ToolServiceError {
        switch error {
        case .networkError:
            return .networkError
        case .notFound:
            return .notFound
        default:
            return .cacheError
        }
    }
    
    /// Maps an APIError to a ToolServiceError
    /// - Parameter error: The APIError to map
    /// - Returns: Mapped service error
    private func mapAPIError(_ error: APIError) -> ToolServiceError {
        switch error {
        case .networkError:
            return .networkError
        case .resourceNotFound:
            return .notFound
        case .serverError:
            return .serverError
        case .invalidResponse:
            return .invalidData
        default:
            return .networkError
        }
    }
}