package com.amirawellness.core.constants

/**
 * Defines API-related constants for the Amira Wellness Android application.
 * This file serves as a centralized location for all API-related configuration
 * to ensure consistency across the application.
 */
object ApiConstants {
    // Base URL for API requests, should be used with EnvironmentConfig to get environment-specific URLs
    const val BASE_URL = "https://api.amirawellness.com"
    const val API_VERSION = "v1"

    /**
     * Contains all API endpoint paths organized by feature
     */
    object Endpoints {
        // Authentication-related endpoints
        object AUTH {
            const val BASE = "/auth"
            const val LOGIN = "$BASE/login"
            const val REGISTER = "$BASE/register"
            const val REFRESH = "$BASE/refresh"
            const val LOGOUT = "$BASE/logout"
            const val RESET_PASSWORD = "$BASE/reset-password"
        }

        // User-related endpoints
        object USERS {
            const val BASE = "/users"
            const val ME = "$BASE/me"
            const val PROFILE = "$BASE/profile"
        }

        // Voice journal-related endpoints
        object JOURNALS {
            const val BASE = "/journals"
            const val DETAIL = "$BASE/{id}"
            const val AUDIO = "$BASE/{journalId}/audio"
            const val FAVORITE = "$BASE/{id}/favorite"
            const val EMOTIONAL_SHIFT = "$BASE/{journalId}/emotional-shift"
        }

        // Emotional check-in related endpoints
        object EMOTIONS {
            const val BASE = "/emotions"
            const val TRENDS = "$BASE/trends"
            const val INSIGHTS = "$BASE/insights"
            const val RECOMMENDATIONS = "$BASE/recommendations"
        }

        // Tool library related endpoints
        object TOOLS {
            const val BASE = "/tools"
            const val DETAIL = "$BASE/{id}"
            const val FAVORITES = "$BASE/favorites"
            const val FAVORITE_STATUS = "$BASE/{id}/favorite"
            const val USAGE = "$BASE/{id}/usage"
        }

        // Progress tracking related endpoints
        object PROGRESS {
            const val BASE = "/progress"
            const val STREAK = "$BASE/streak"
            const val ACHIEVEMENTS = "$BASE/achievements"
            const val STATISTICS = "$BASE/statistics"
            const val DASHBOARD = "$BASE/dashboard"
        }

        // Notification related endpoints
        object NOTIFICATIONS {
            const val BASE = "/notifications"
            const val REGISTER = "$BASE/register-device"
            const val SETTINGS = "$BASE/settings"
            const val HISTORY = "$BASE/history"
            const val READ = "$BASE/{id}/read"
        }

        // API health check endpoint
        const val HEALTH = "/health"
    }

    /**
     * HTTP header constants used in API requests
     */
    object Headers {
        const val AUTHORIZATION = "Authorization"
        const val BEARER_PREFIX = "Bearer "
        const val CONTENT_TYPE = "Content-Type"
        const val ACCEPT = "Accept"
        const val JSON_CONTENT_TYPE = "application/json"
        const val DEVICE_ID = "X-Device-ID"
        const val APP_VERSION = "X-App-Version"
        const val PLATFORM = "X-Platform"
        const val PLATFORM_VALUE = "Android"
        const val LANGUAGE = "X-Language"
    }

    /**
     * Timeout configurations for API requests
     */
    object Timeouts {
        const val CONNECT_TIMEOUT_SECONDS = 30L
        const val READ_TIMEOUT_SECONDS = 30L
        const val WRITE_TIMEOUT_SECONDS = 30L
        const val CALL_TIMEOUT_SECONDS = 60L
        const val UPLOAD_TIMEOUT_SECONDS = 120L // Longer timeout for audio uploads
    }

    /**
     * API error code constants
     */
    object ErrorCodes {
        const val BAD_REQUEST = 400
        const val UNAUTHORIZED = 401
        const val FORBIDDEN = 403
        const val NOT_FOUND = 404
        const val CONFLICT = 409
        const val INTERNAL_SERVER_ERROR = 500
        const val SERVICE_UNAVAILABLE = 503
        
        // Custom error codes for client-side issues
        const val NETWORK_ERROR = 1000
        const val TIMEOUT_ERROR = 1001
        const val UNKNOWN_ERROR = 1002
    }
}