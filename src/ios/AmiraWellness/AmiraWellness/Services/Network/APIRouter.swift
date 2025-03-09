//
//  APIRouter.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // Latest
import Alamofire // ~> 5.6

/// Defines the API endpoints and request configuration for the Amira Wellness application
enum APIRouter: URLRequestConvertible {
    // MARK: - Authentication Cases
    /// Health check endpoint to verify API connectivity
    case healthCheck
    
    /// Login with email and password
    case login(email: String, password: String)
    
    /// Register a new user account
    case register(email: String, password: String, name: String)
    
    /// Refresh the authentication token
    case refreshToken(refreshToken: String)
    
    /// Logout the current user
    case logout
    
    // MARK: - User Profile Cases
    /// Get the current user's profile
    case getUserProfile
    
    /// Update the current user's profile
    case updateUserProfile(profileData: [String: Any])
    
    // MARK: - Voice Journal Cases
    /// Create a new voice journal entry
    case createJournal(audioData: Data, title: String?, metadata: [String: Any])
    
    /// Get a paginated list of journal entries
    case getJournals(page: Int?, pageSize: Int?, sortBy: String?, order: String?)
    
    /// Get a specific journal entry by ID
    case getJournal(journalId: String)
    
    /// Update a journal entry
    case updateJournal(journalId: String, journalData: [String: Any])
    
    /// Delete a journal entry
    case deleteJournal(journalId: String)
    
    /// Download the audio file for a journal entry
    case downloadAudio(journalId: String)
    
    // MARK: - Emotional Tracking Cases
    /// Record an emotional state
    case recordEmotionalState(emotionType: String, intensity: Int, notes: String?, context: String)
    
    /// Get the emotional state history
    case getEmotionalHistory(startDate: Date?, endDate: Date?, page: Int?, pageSize: Int?)
    
    /// Get emotional trends for analysis
    case getEmotionalTrends(startDate: Date, endDate: Date)
    
    // MARK: - Tool Library Cases
    /// Get all tool categories
    case getToolCategories
    
    /// Get tools, optionally filtered by category
    case getTools(categoryId: String?, page: Int?, pageSize: Int?)
    
    /// Get a specific tool by ID
    case getTool(toolId: String)
    
    /// Get recommended tools based on emotion type
    case getRecommendedTools(emotionType: String?, limit: Int?)
    
    /// Toggle favorite status for a tool
    case toggleToolFavorite(toolId: String, isFavorite: Bool)
    
    /// Get favorite tools
    case getFavoriteTools(page: Int?, pageSize: Int?)
    
    /// Track tool usage
    case trackToolUsage(toolId: String, durationSeconds: Int)
    
    // MARK: - Progress Tracking Cases
    /// Get streak information
    case getStreakInfo
    
    /// Get achievements
    case getAchievements
    
    /// Get progress insights
    case getProgressInsights
    
    // MARK: - Device and Notification Cases
    /// Register a device for push notifications
    case registerDevice(deviceToken: String, deviceType: String)
    
    /// Unregister a device from push notifications
    case unregisterDevice(deviceToken: String)
    
    /// Update notification settings
    case updateNotificationSettings(settings: [String: Any])
    
    // MARK: - Data Export Cases
    /// Export user data
    case exportData(dataTypes: [String])
    
    // MARK: - URLRequestConvertible Properties
    
    /// The base URL for the API
    var baseURL: URL {
        return URL(string: ApiConstants.BaseURL.fullURL)!
    }
    
    /// The path component of the URL for this endpoint
    var path: String {
        switch self {
        // Authentication paths
        case .healthCheck:
            return ApiConstants.Endpoints.health
            
        case .login:
            return "\(ApiConstants.Endpoints.auth)/\(ApiConstants.Endpoints.login)"
            
        case .register:
            return "\(ApiConstants.Endpoints.auth)/\(ApiConstants.Endpoints.register)"
            
        case .refreshToken:
            return "\(ApiConstants.Endpoints.auth)/\(ApiConstants.Endpoints.refreshToken)"
            
        case .logout:
            return "\(ApiConstants.Endpoints.auth)/\(ApiConstants.Endpoints.logout)"
            
        // User profile paths
        case .getUserProfile:
            return ApiConstants.Endpoints.users
            
        case .updateUserProfile:
            return ApiConstants.Endpoints.users
            
        // Voice journal paths
        case .createJournal:
            return ApiConstants.Endpoints.journals
            
        case .getJournals:
            return ApiConstants.Endpoints.journals
            
        case .getJournal(let journalId):
            return "\(ApiConstants.Endpoints.journals)/\(journalId)"
            
        case .updateJournal(let journalId, _):
            return "\(ApiConstants.Endpoints.journals)/\(journalId)"
            
        case .deleteJournal(let journalId):
            return "\(ApiConstants.Endpoints.journals)/\(journalId)"
            
        case .downloadAudio(let journalId):
            return "\(ApiConstants.Endpoints.journals)/\(journalId)/\(ApiConstants.Endpoints.audio)"
            
        // Emotional tracking paths
        case .recordEmotionalState:
            return ApiConstants.Endpoints.emotions
            
        case .getEmotionalHistory:
            return "\(ApiConstants.Endpoints.emotions)/\(ApiConstants.Endpoints.emotionalHistory)"
            
        case .getEmotionalTrends:
            return "\(ApiConstants.Endpoints.emotions)/\(ApiConstants.Endpoints.emotionalTrends)"
            
        // Tool library paths
        case .getToolCategories:
            return ApiConstants.Endpoints.toolCategories
            
        case .getTools:
            return ApiConstants.Endpoints.tools
            
        case .getTool(let toolId):
            return "\(ApiConstants.Endpoints.tools)/\(toolId)"
            
        case .getRecommendedTools:
            return "\(ApiConstants.Endpoints.tools)/\(ApiConstants.Endpoints.recommendedTools)"
            
        case .toggleToolFavorite(let toolId, _):
            return "\(ApiConstants.Endpoints.tools)/\(toolId)/\(ApiConstants.Endpoints.favoriteTools)"
            
        case .getFavoriteTools:
            return "\(ApiConstants.Endpoints.tools)/\(ApiConstants.Endpoints.favoriteTools)"
            
        case .trackToolUsage:
            return "\(ApiConstants.Endpoints.tools)/\(ApiConstants.Endpoints.toolUsage)"
            
        // Progress tracking paths
        case .getStreakInfo:
            return "\(ApiConstants.Endpoints.progress)/\(ApiConstants.Endpoints.streaks)"
            
        case .getAchievements:
            return "\(ApiConstants.Endpoints.progress)/\(ApiConstants.Endpoints.achievements)"
            
        case .getProgressInsights:
            return "\(ApiConstants.Endpoints.progress)/\(ApiConstants.Endpoints.insights)"
            
        // Device and notification paths
        case .registerDevice:
            return ApiConstants.Endpoints.devices
            
        case .unregisterDevice(let deviceToken):
            return "\(ApiConstants.Endpoints.devices)/\(deviceToken)"
            
        case .updateNotificationSettings:
            return ApiConstants.Endpoints.notifications
            
        // Data export paths
        case .exportData:
            return ApiConstants.Endpoints.export
        }
    }
    
    /// The HTTP method for this endpoint
    var method: HTTPMethod {
        switch self {
        // GET methods
        case .healthCheck, .getUserProfile, .getJournals, .getJournal, .downloadAudio,
             .getEmotionalHistory, .getEmotionalTrends, .getToolCategories, .getTools,
             .getTool, .getRecommendedTools, .getFavoriteTools, .getStreakInfo,
             .getAchievements, .getProgressInsights:
            return .get
            
        // POST methods
        case .login, .register, .refreshToken, .createJournal, .recordEmotionalState,
             .trackToolUsage, .registerDevice, .exportData:
            return .post
            
        // PUT methods
        case .updateUserProfile, .updateJournal, .updateNotificationSettings:
            return .put
            
        // PATCH methods
        case .toggleToolFavorite:
            return .patch
            
        // DELETE methods
        case .logout, .deleteJournal, .unregisterDevice:
            return .delete
        }
    }
    
    /// The HTTP headers for this endpoint
    var headers: [String: String] {
        var defaultHeaders = ApiConstants.Headers.defaultHeaders()
        
        // Add Authorization header for endpoints that require authentication
        switch self {
        case .healthCheck, .login, .register, .refreshToken:
            // These endpoints don't require authentication
            break
            
        case .createJournal, .updateJournal:
            // Set content type to multipart/form-data for file uploads
            defaultHeaders[ApiConstants.Headers.contentType] = ApiConstants.Headers.contentTypeMultipart
            
            // Add authentication token if available
            if let token = UserDefaults.standard.string(forKey: "access_token") {
                defaultHeaders[ApiConstants.Headers.authorization] = ApiConstants.Headers.authorizationHeader(token: token)
            }
            
        default:
            // Add authentication token for all other endpoints
            if let token = UserDefaults.standard.string(forKey: "access_token") {
                defaultHeaders[ApiConstants.Headers.authorization] = ApiConstants.Headers.authorizationHeader(token: token)
            }
        }
        
        return defaultHeaders
    }
    
    /// The parameters for this endpoint
    var parameters: [String: Any]? {
        switch self {
        // Authentication parameters
        case .login(let email, let password):
            return [
                ApiConstants.Parameters.email: email,
                ApiConstants.Parameters.password: password
            ]
            
        case .register(let email, let password, let name):
            return [
                ApiConstants.Parameters.email: email,
                ApiConstants.Parameters.password: password,
                "name": name
            ]
            
        case .refreshToken(let refreshToken):
            return [
                ApiConstants.Parameters.refreshToken: refreshToken
            ]
            
        // User profile parameters
        case .updateUserProfile(let profileData):
            return profileData
            
        // Journal parameters (excluding file uploads which use multipart)
        case .getJournals(let page, let pageSize, let sortBy, let order):
            var params: [String: Any] = [:]
            
            if let page = page {
                params[ApiConstants.Parameters.page] = page
            }
            
            if let pageSize = pageSize {
                params[ApiConstants.Parameters.pageSize] = pageSize
            }
            
            if let sortBy = sortBy {
                params[ApiConstants.Parameters.sort] = sortBy
            }
            
            if let order = order {
                params[ApiConstants.Parameters.order] = order
            }
            
            return params.isEmpty ? nil : params
            
        case .updateJournal(_, let journalData):
            return journalData
            
        // Emotional tracking parameters
        case .recordEmotionalState(let emotionType, let intensity, let notes, let context):
            var params: [String: Any] = [
                ApiConstants.Parameters.emotionType: emotionType,
                ApiConstants.Parameters.intensity: intensity,
                ApiConstants.Parameters.context: context
            ]
            
            if let notes = notes {
                params[ApiConstants.Parameters.notes] = notes
            }
            
            return params
            
        case .getEmotionalHistory(let startDate, let endDate, let page, let pageSize):
            var params: [String: Any] = [:]
            
            if let startDate = startDate {
                params[ApiConstants.Parameters.startDate] = APIRouter.formatDateParameter(date: startDate)
            }
            
            if let endDate = endDate {
                params[ApiConstants.Parameters.endDate] = APIRouter.formatDateParameter(date: endDate)
            }
            
            if let page = page {
                params[ApiConstants.Parameters.page] = page
            }
            
            if let pageSize = pageSize {
                params[ApiConstants.Parameters.pageSize] = pageSize
            }
            
            return params.isEmpty ? nil : params
            
        case .getEmotionalTrends(let startDate, let endDate):
            return [
                ApiConstants.Parameters.startDate: APIRouter.formatDateParameter(date: startDate),
                ApiConstants.Parameters.endDate: APIRouter.formatDateParameter(date: endDate)
            ]
            
        // Tool library parameters
        case .getTools(let categoryId, let page, let pageSize):
            var params: [String: Any] = [:]
            
            if let categoryId = categoryId {
                params[ApiConstants.Parameters.categoryId] = categoryId
            }
            
            if let page = page {
                params[ApiConstants.Parameters.page] = page
            }
            
            if let pageSize = pageSize {
                params[ApiConstants.Parameters.pageSize] = pageSize
            }
            
            return params.isEmpty ? nil : params
            
        case .getRecommendedTools(let emotionType, let limit):
            var params: [String: Any] = [:]
            
            if let emotionType = emotionType {
                params[ApiConstants.Parameters.emotionType] = emotionType
            }
            
            if let limit = limit {
                params["limit"] = limit
            }
            
            return params.isEmpty ? nil : params
            
        case .toggleToolFavorite(_, let isFavorite):
            return [
                ApiConstants.Parameters.isFavorite: isFavorite
            ]
            
        case .getFavoriteTools(let page, let pageSize):
            var params: [String: Any] = [:]
            
            if let page = page {
                params[ApiConstants.Parameters.page] = page
            }
            
            if let pageSize = pageSize {
                params[ApiConstants.Parameters.pageSize] = pageSize
            }
            
            return params.isEmpty ? nil : params
            
        case .trackToolUsage(let toolId, let durationSeconds):
            return [
                ApiConstants.Parameters.toolId: toolId,
                ApiConstants.Parameters.duration: durationSeconds
            ]
            
        // Device and notification parameters
        case .registerDevice(let deviceToken, let deviceType):
            return [
                ApiConstants.Parameters.deviceToken: deviceToken,
                ApiConstants.Parameters.deviceType: deviceType
            ]
            
        case .updateNotificationSettings(let settings):
            return settings
            
        // Data export parameters
        case .exportData(let dataTypes):
            return [
                "data_types": dataTypes
            ]
            
        // No parameters for these endpoints
        case .healthCheck, .logout, .getUserProfile, .getJournal,
             .deleteJournal, .downloadAudio, .getToolCategories,
             .getTool, .getStreakInfo, .getAchievements,
             .getProgressInsights, .unregisterDevice, .createJournal:
            return nil
        }
    }
    
    /// The parameter encoding method for this endpoint
    var encoding: ParameterEncoding {
        switch method {
        case .get, .delete:
            return URLEncoding.default
        default:
            return JSONEncoding.default
        }
    }
    
    /// The multipart form data for file upload endpoints
    var multipartFormData: MultipartFormData? {
        switch self {
        case .createJournal(let audioData, let title, let metadata):
            let formData = MultipartFormData()
            
            // Add the audio file
            formData.append(audioData, withName: ApiConstants.Parameters.audioData, fileName: "voice_journal.m4a", mimeType: "audio/m4a")
            
            // Add title if available
            if let title = title {
                formData.append(title.data(using: .utf8)!, withName: ApiConstants.Parameters.title)
            }
            
            // Add all metadata fields
            for (key, value) in metadata {
                if let stringValue = value as? String, let data = stringValue.data(using: .utf8) {
                    formData.append(data, withName: key)
                } else if let jsonData = try? JSONSerialization.data(withJSONObject: value) {
                    formData.append(jsonData, withName: key)
                }
            }
            
            return formData
            
        default:
            return nil
        }
    }
    
    // MARK: - URLRequestConvertible Implementation
    
    /// Creates a URLRequest for this endpoint according to the URLRequestConvertible protocol
    /// - Returns: A URLRequest configured for this endpoint
    /// - Throws: Error if the request cannot be created
    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.method = method
        
        // Add headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Handle multipart form data for file uploads
        if let multipartFormData = multipartFormData {
            request.setValue(multipartFormData.contentType, forHTTPHeaderField: ApiConstants.Headers.contentType)
            request.httpBody = try multipartFormData.encode()
        } else if let parameters = parameters {
            // Encode parameters based on HTTP method
            request = try encoding.encode(request, with: parameters)
        }
        
        return request
    }
    
    /// Formats a date for use as a parameter in API requests
    /// - Parameter date: The date to format
    /// - Returns: A formatted date string
    private static func formatDateParameter(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter.string(from: date)
    }
}