import Foundation // Version: Latest
import Combine // Version: Latest

// Internal imports
import Tool // src/ios/AmiraWellness/AmiraWellness/Models/Tool.swift
import ToolCategory // src/ios/AmiraWellness/AmiraWellness/Models/ToolCategory.swift
import EmotionType // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalState.swift
import ToolServiceError // src/ios/AmiraWellness/AmiraWellness/Services/Tool/ToolService.swift

/// A mock implementation of the ToolService for unit testing
class MockToolService {
    /// Shared instance of the MockToolService for easy access.
    static let shared = MockToolService()

    /// Mock storage for tools, using UUID as the key.
    var mockTools: [UUID: Tool] = [:]

    /// Mock storage for tools by category.
    var mockToolsByCategory: [ToolCategory: [Tool]] = [:]

    /// Mock storage for recommended tools by emotion type.
    var mockRecommendedTools: [EmotionType: [Tool]] = [:]

    /// Mock results for specific tool IDs, allowing for error simulation.
    var mockToolResults: [String: Result<Tool, ToolServiceError>] = [:]

    /// Mock result for fetching tool categories.
    var mockCategoriesResult: Result<[ToolCategory], ToolServiceError> = .success([])

    /// Mock result for fetching tools.
    var mockToolsResult: Result<[Tool], ToolServiceError> = .success([])

    /// Mock result for fetching favorite tools.
    var mockFavoritesResult: Result<[Tool], ToolServiceError> = .success([])

    /// Mock result for refreshing tool data.
    var mockRefreshResult: Result<Bool, ToolServiceError> = .success(true)

    /// Mock network connection status.
    var isNetworkConnected: Bool = true

    /// Tracks the number of calls to each method for testing purposes.
    var methodCallCount: [String: Int] = [:]

    /// Publisher for tool updates.
    private let toolUpdatedSubject = PassthroughSubject<Tool, Never>()

    /// Publisher for tools loaded events.
    private let toolsLoadedSubject = PassthroughSubject<Void, Never>()

    /// Publisher for categories loaded events.
    private let categoriesLoadedSubject = PassthroughSubject<Void, Never>()

    /// Private initializer for singleton pattern
    private init() {
        mockTools = [:]
        mockToolsByCategory = [:]
        mockRecommendedTools = [:]
        mockToolResults = [:]
        mockCategoriesResult = .success([])
        mockToolsResult = .success([])
        mockFavoritesResult = .success([])
        mockRefreshResult = .success(true)
        isNetworkConnected = true
        methodCallCount = [:]
        toolUpdatedSubject = PassthroughSubject<Tool, Never>()
        toolsLoadedSubject = PassthroughSubject<Void, Never>()
        categoriesLoadedSubject = PassthroughSubject<Void, Never>()
    }

    /// Resets all mock responses and counters
    func reset() {
        mockTools.removeAll()
        mockToolsByCategory.removeAll()
        mockRecommendedTools.removeAll()
        mockToolResults.removeAll()
        mockCategoriesResult = .success([])
        mockToolsResult = .success([])
        mockFavoritesResult = .success([])
        mockRefreshResult = .success(true)
        isNetworkConnected = true
        methodCallCount.removeAll()
    }

    /// Sets a mock tool for a specific ID
    /// - Parameter tool: The tool to be mocked.
    func setMockTool(tool: Tool) {
        mockTools[tool.id] = tool
    }

    /// Sets mock tools for a specific category
    /// - Parameters:
    ///   - category: The category of the tools.
    ///   - tools: The array of tools to be mocked.
    func setMockToolsByCategory(category: ToolCategory, tools: [Tool]) {
        mockToolsByCategory[category] = tools
    }

    /// Sets mock recommended tools for a specific emotion type
    /// - Parameters:
    ///   - emotionType: The emotion type for which tools are recommended.
    ///   - tools: The array of tools to be mocked.
    func setMockRecommendedTools(emotionType: EmotionType, tools: [Tool]) {
        mockRecommendedTools[emotionType] = tools
    }

    /// Sets a mock result for a specific tool ID
    /// - Parameters:
    ///   - id: The ID of the tool.
    ///   - result: The result to be mocked.
    func setMockToolResult(id: String, result: Result<Tool, ToolServiceError>) {
        mockToolResults[id] = result
    }

    /// Sets the mock result for tool categories
    /// - Parameter result: The result to be mocked.
    func setMockCategoriesResult(result: Result<[ToolCategory], ToolServiceError>) {
        mockCategoriesResult = result
    }

    /// Sets the mock result for tools
    /// - Parameter result: The result to be mocked.
    func setMockToolsResult(result: Result<[Tool], ToolServiceError>) {
        mockToolsResult = result
    }

    /// Sets the mock result for favorite tools
    /// - Parameter result: The result to be mocked.
    func setMockFavoritesResult(result: Result<[Tool], ToolServiceError>) {
        mockFavoritesResult = result
    }

    /// Sets the mock result for refreshing tool data
    /// - Parameter result: The result to be mocked.
    func setMockRefreshResult(result: Result<Bool, ToolServiceError>) {
        mockRefreshResult = result
    }

    /// Sets the mock network connection status
    /// - Parameter connected: The network connection status to be mocked.
    func setNetworkConnected(connected: Bool) {
        isNetworkConnected = connected
    }

    /// Gets the number of calls made to a specific method
    /// - Parameter methodName: The name of the method.
    /// - Returns: The number of calls made to the method.
    func getMethodCallCount(methodName: String) -> Int {
        return methodCallCount[methodName] ?? 0
    }

    /// Increments the call count for a specific method
    /// - Parameter methodName: The name of the method.
    private func incrementMethodCallCount(methodName: String) {
        methodCallCount[methodName, default: 0] += 1
    }

    /// Mock implementation of getToolCategories method
    /// - Parameters:
    ///   - forceRefresh: Whether to force a refresh from the API.
    ///   - completion: Completion handler with the result.
    func getToolCategories(forceRefresh: Bool = false, completion: @escaping (Result<[ToolCategory], ToolServiceError>) -> Void) {
        incrementMethodCallCount(methodName: "getToolCategories")
        if !isNetworkConnected && forceRefresh {
            completion(.failure(.networkError))
            return
        }
        completion(mockCategoriesResult)
        if case .success = mockCategoriesResult {
            categoriesLoadedSubject.send()
        }
    }

    /// Mock implementation of getToolCategoriesAsync method
    /// - Parameter forceRefresh: Whether to force a refresh from the API.
    /// - Returns: Array of tool categories or throws an error.
    @available(iOS 15.0, *)
    func getToolCategoriesAsync(forceRefresh: Bool = false) async throws -> [ToolCategory] {
        incrementMethodCallCount(methodName: "getToolCategoriesAsync")
        if !isNetworkConnected && forceRefresh {
            throw ToolServiceError.networkError
        }
        switch mockCategoriesResult {
        case .success(let categories):
            categoriesLoadedSubject.send()
            return categories
        case .failure(let error):
            throw error
        }
    }

    /// Mock implementation of getTools method
    /// - Parameters:
    ///   - category: The category to filter tools by.
    ///   - forceRefresh: Whether to force a refresh from the API.
    ///   - completion: Completion handler with the result.
    func getTools(category: ToolCategory? = nil, forceRefresh: Bool = false, completion: @escaping (Result<[Tool], ToolServiceError>) -> Void) {
        incrementMethodCallCount(methodName: "getTools")
        if !isNetworkConnected && forceRefresh {
            completion(.failure(.networkError))
            return
        }
        if let category = category, let tools = mockToolsByCategory[category] {
            completion(.success(tools))
            return
        }
        completion(mockToolsResult)
        if case .success = mockToolsResult {
            toolsLoadedSubject.send()
        }
    }

    /// Mock implementation of getToolsAsync method
    /// - Parameters:
    ///   - category: The category to filter tools by.
    ///   - forceRefresh: Whether to force a refresh from the API.
    /// - Returns: Array of tools or throws an error.
    @available(iOS 15.0, *)
    func getToolsAsync(category: ToolCategory? = nil, forceRefresh: Bool = false) async throws -> [Tool] {
        incrementMethodCallCount(methodName: "getToolsAsync")
        if !isNetworkConnected && forceRefresh {
            throw ToolServiceError.networkError
        }
        if let category = category, let tools = mockToolsByCategory[category] {
            return tools
        }
        switch mockToolsResult {
        case .success(let tools):
            toolsLoadedSubject.send()
            return tools
        case .failure(let error):
            throw error
        }
    }

    /// Mock implementation of getTool method
    /// - Parameters:
    ///   - id: The ID of the tool.
    ///   - forceRefresh: Whether to force a refresh from the API.
    ///   - completion: Completion handler with the result.
    func getTool(id: String, forceRefresh: Bool = false, completion: @escaping (Result<Tool, ToolServiceError>) -> Void) {
        incrementMethodCallCount(methodName: "getTool")
        if !isNetworkConnected && forceRefresh {
            completion(.failure(.networkError))
            return
        }
        if let result = mockToolResults[id] {
            completion(result)
            return
        }
        if let tool = mockTools[UUID(uuidString: id)] {
            completion(.success(tool))
            toolUpdatedSubject.send(tool)
            return
        }
        completion(.failure(.notFound))
    }

    /// Mock implementation of getToolAsync method
    /// - Parameters:
    ///   - id: The ID of the tool.
    ///   - forceRefresh: Whether to force a refresh from the API.
    /// - Returns: The requested tool or throws an error.
    @available(iOS 15.0, *)
    func getToolAsync(id: String, forceRefresh: Bool = false) async throws -> Tool {
        incrementMethodCallCount(methodName: "getToolAsync")
        if !isNetworkConnected && forceRefresh {
            throw ToolServiceError.networkError
        }
        if let result = mockToolResults[id] {
            switch result {
            case .success(let tool):
                toolUpdatedSubject.send(tool)
                return tool
            case .failure(let error):
                throw error
            }
        }
        if let tool = mockTools[UUID(uuidString: id)] {
            toolUpdatedSubject.send(tool)
            return tool
        }
        throw ToolServiceError.notFound
    }

    /// Mock implementation of getFavoriteTools method
    /// - Parameters:
    ///   - forceRefresh: Whether to force a refresh from the API.
    ///   - completion: Completion handler with the result.
    func getFavoriteTools(forceRefresh: Bool = false, completion: @escaping (Result<[Tool], ToolServiceError>) -> Void) {
        incrementMethodCallCount(methodName: "getFavoriteTools")
        if !isNetworkConnected && forceRefresh {
            completion(.failure(.networkError))
            return
        }
        completion(mockFavoritesResult)
        if case .success = mockFavoritesResult {
            toolsLoadedSubject.send()
        }
    }

    /// Mock implementation of getFavoriteToolsAsync method
    /// - Parameter forceRefresh: Whether to force a refresh from the API.
    /// - Returns: Array of favorite tools or throws an error.
    @available(iOS 15.0, *)
    func getFavoriteToolsAsync(forceRefresh: Bool = false) async throws -> [Tool] {
        incrementMethodCallCount(methodName: "getFavoriteToolsAsync")
        if !isNetworkConnected && forceRefresh {
            throw ToolServiceError.networkError
        }
        switch mockFavoritesResult {
        case .success(let tools):
            toolsLoadedSubject.send()
            return tools
        case .failure(let error):
            throw error
        }
    }

    /// Mock implementation of getRecommendedTools method
    /// - Parameters:
    ///   - emotionType: The emotion type.
    ///   - limit: The limit of tools to return.
    ///   - forceRefresh: Whether to force a refresh from the API.
    ///   - completion: Completion handler with the result.
    func getRecommendedTools(emotionType: EmotionType, limit: Int? = nil, forceRefresh: Bool = false, completion: @escaping (Result<[Tool], ToolServiceError>) -> Void) {
        incrementMethodCallCount(methodName: "getRecommendedTools")
        if !isNetworkConnected && forceRefresh {
            completion(.failure(.networkError))
            return
        }
        if let tools = mockRecommendedTools[emotionType] {
            let limitedTools = limit != nil ? Array(tools.prefix(limit!)) : tools
            completion(.success(limitedTools))
        } else {
            completion(.success([]))
        }
    }

    /// Mock implementation of getRecommendedToolsAsync method
    /// - Parameters:
    ///   - emotionType: The emotion type.
    ///   - limit: The limit of tools to return.
    ///   - forceRefresh: Whether to force a refresh from the API.
    /// - Returns: Array of recommended tools or throws an error.
    @available(iOS 15.0, *)
    func getRecommendedToolsAsync(emotionType: EmotionType, limit: Int? = nil, forceRefresh: Bool = false) async throws -> [Tool] {
        incrementMethodCallCount(methodName: "getRecommendedToolsAsync")
        if !isNetworkConnected && forceRefresh {
            throw ToolServiceError.networkError
        }
        if let tools = mockRecommendedTools[emotionType] {
            let limitedTools = limit != nil ? Array(tools.prefix(limit!)) : tools
            return limitedTools
        } else {
            return []
        }
    }

    /// Mock implementation of toggleFavorite method
    /// - Parameters:
    ///   - tool: The tool to toggle favorite status.
    ///   - completion: Completion handler with the result.
    func toggleFavorite(tool: Tool, completion: @escaping (Result<Tool, ToolServiceError>) -> Void) {
        incrementMethodCallCount(methodName: "toggleFavorite")
        if !isNetworkConnected {
            completion(.failure(.networkError))
            return
        }
        let updatedTool = tool.toggleFavorite()
        mockTools[tool.id] = updatedTool
        completion(.success(updatedTool))
        toolUpdatedSubject.send(updatedTool)
    }

    /// Mock implementation of toggleFavoriteAsync method
    /// - Parameter tool: The tool to toggle favorite status.
    /// - Returns: Updated tool with toggled favorite status or throws an error.
    @available(iOS 15.0, *)
    func toggleFavoriteAsync(tool: Tool) async throws -> Tool {
        incrementMethodCallCount(methodName: "toggleFavoriteAsync")
        if !isNetworkConnected {
            throw ToolServiceError.networkError
        }
        let updatedTool = tool.toggleFavorite()
        mockTools[tool.id] = updatedTool
        toolUpdatedSubject.send(updatedTool)
        return updatedTool
    }

    /// Mock implementation of trackToolUsage method
    /// - Parameters:
    ///   - tool: The tool to track usage.
    ///   - durationSeconds: The duration of the tool usage.
    ///   - completion: Completion handler with the result.
    func trackToolUsage(tool: Tool, durationSeconds: Int, completion: @escaping (Result<Tool, ToolServiceError>) -> Void) {
        incrementMethodCallCount(methodName: "trackToolUsage")
        if !isNetworkConnected {
            completion(.failure(.networkError))
            return
        }
        let updatedTool = tool.incrementUsageCount()
        mockTools[tool.id] = updatedTool
        completion(.success(updatedTool))
        toolUpdatedSubject.send(updatedTool)
    }

    /// Mock implementation of trackToolUsageAsync method
    /// - Parameters:
    ///   - tool: The tool to track usage.
    ///   - durationSeconds: The duration of the tool usage.
    /// - Returns: Updated tool with incremented usage count or throws an error.
    @available(iOS 15.0, *)
    func trackToolUsageAsync(tool: Tool, durationSeconds: Int) async throws -> Tool {
        incrementMethodCallCount(methodName: "trackToolUsageAsync")
        if !isNetworkConnected {
            throw ToolServiceError.networkError
        }
        let updatedTool = tool.incrementUsageCount()
        mockTools[tool.id] = updatedTool
        toolUpdatedSubject.send(updatedTool)
        return updatedTool
    }

    /// Mock implementation of refreshToolData method
    /// - Parameter completion: Completion handler with the result.
    func refreshToolData(completion: @escaping (Result<Bool, ToolServiceError>) -> Void) {
        incrementMethodCallCount(methodName: "refreshToolData")
        if !isNetworkConnected {
            completion(.failure(.networkError))
            return
        }
        completion(mockRefreshResult)
        if case .success = mockRefreshResult {
            toolsLoadedSubject.send()
            categoriesLoadedSubject.send()
        }
    }

    /// Mock implementation of refreshToolDataAsync method
    /// - Returns: True if refresh was successful or throws an error.
    @available(iOS 15.0, *)
    func refreshToolDataAsync() async throws -> Bool {
        incrementMethodCallCount(methodName: "refreshToolDataAsync")
        if !isNetworkConnected {
            throw ToolServiceError.networkError
        }
        switch mockRefreshResult {
        case .success(let result):
            toolsLoadedSubject.send()
            categoriesLoadedSubject.send()
            return result
        case .failure(let error):
            throw error
        }
    }

    /// Returns a publisher that emits when a tool is updated
    /// - Returns: Publisher for tool updates
    func getToolUpdatedPublisher() -> AnyPublisher<Tool, Never> {
        incrementMethodCallCount(methodName: "getToolUpdatedPublisher")
        return toolUpdatedSubject.eraseToAnyPublisher()
    }

    /// Returns a publisher that emits when tools are loaded
    /// - Returns: Publisher for tools loaded events
    func getToolsLoadedPublisher() -> AnyPublisher<Void, Never> {
        incrementMethodCallCount(methodName: "getToolsLoadedPublisher")
        return toolsLoadedSubject.eraseToAnyPublisher()
    }

    /// Returns a publisher that emits when categories are loaded
    /// - Returns: Publisher for categories loaded events
    func getCategoriesLoadedPublisher() -> AnyPublisher<Void, Never> {
        incrementMethodCallCount(methodName: "getCategoriesLoadedPublisher")
        return categoriesLoadedSubject.eraseToAnyPublisher()
    }
}