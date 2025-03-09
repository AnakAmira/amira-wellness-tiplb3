package com.amirawellness.data.remote.api

import com.amirawellness.core.constants.ApiConstants.Endpoints
import com.amirawellness.data.remote.dto.*
import retrofit2.http.*  // version: 2.9.0
import okhttp3.MultipartBody  // version: 4.10.0
import okhttp3.ResponseBody  // version: 4.10.0
import retrofit2.Call

/**
 * Defines the API interface for the Amira Wellness Android application using Retrofit.
 * This interface declares all the API endpoints for communication with the backend services,
 * including authentication, voice journaling, emotional check-ins, tool library, and progress
 * tracking features.
 *
 * Each method is annotated with the appropriate HTTP method (GET, POST, PUT, DELETE) and
 * endpoint path. The interface uses suspend functions to support Kotlin coroutines for
 * asynchronous communication, while still returning Retrofit's Call type for maximum flexibility.
 */
interface ApiService {
    // Authentication endpoints
    @POST(Endpoints.AUTH.LOGIN)
    suspend fun login(@Body request: LoginRequestDto): Call<AuthResponseDto>

    @POST(Endpoints.AUTH.REGISTER)
    suspend fun register(@Body request: RegisterRequestDto): Call<AuthResponseDto>

    @POST(Endpoints.AUTH.REFRESH)
    suspend fun refreshToken(@Body refreshToken: String): Call<TokenResponseDto>

    @POST(Endpoints.AUTH.LOGOUT)
    suspend fun logout(): Call<Unit>

    @POST(Endpoints.AUTH.RESET_PASSWORD)
    suspend fun resetPassword(@Body email: String): Call<Unit>

    // User endpoints
    @GET(Endpoints.USERS.ME)
    suspend fun getCurrentUser(): Call<UserDto>

    @GET(Endpoints.USERS.PROFILE)
    suspend fun getUserProfile(): Call<UserProfileDto>

    @PUT(Endpoints.USERS.PROFILE)
    suspend fun updateUserProfile(@Body user: UserDto): Call<UserDto>

    // Journal endpoints
    @GET(Endpoints.JOURNALS.BASE)
    suspend fun getJournals(@Query("page") page: Int, @Query("pageSize") pageSize: Int): Call<List<JournalDto>>

    @GET(Endpoints.JOURNALS.DETAIL)
    suspend fun getJournal(@Path("id") id: String): Call<JournalDto>

    @POST(Endpoints.JOURNALS.BASE)
    suspend fun createJournal(@Body journal: JournalDto): Call<JournalDto>

    @PUT(Endpoints.JOURNALS.DETAIL)
    suspend fun updateJournal(@Path("id") id: String, @Body journal: JournalDto): Call<JournalDto>

    @DELETE(Endpoints.JOURNALS.DETAIL)
    suspend fun deleteJournal(@Path("id") id: String): Call<Unit>

    @Multipart
    @POST(Endpoints.JOURNALS.AUDIO)
    suspend fun uploadJournalAudio(@Path("journalId") journalId: String, @Part audio: MultipartBody.Part): Call<JournalDto>

    @Streaming
    @GET(Endpoints.JOURNALS.AUDIO)
    suspend fun downloadJournalAudio(@Path("journalId") journalId: String): Call<ResponseBody>

    @POST(Endpoints.JOURNALS.FAVORITE)
    suspend fun toggleJournalFavorite(@Path("id") id: String): Call<JournalDto>

    @GET(Endpoints.JOURNALS.EMOTIONAL_SHIFT)
    suspend fun getEmotionalShift(@Path("journalId") journalId: String): Call<Map<String, Any>>

    // Emotion endpoints
    @POST(Endpoints.EMOTIONS.BASE)
    suspend fun recordEmotionalState(@Body emotionalState: EmotionalStateDto): Call<EmotionalStateDto>

    @GET(Endpoints.EMOTIONS.BASE)
    suspend fun getEmotionalStates(
        @Query("startDate") startDate: String?,
        @Query("endDate") endDate: String?,
        @Query("page") page: Int,
        @Query("pageSize") pageSize: Int
    ): Call<List<EmotionalStateDto>>

    @GET(Endpoints.EMOTIONS.TRENDS)
    suspend fun getEmotionalTrends(
        @Query("startDate") startDate: String?,
        @Query("endDate") endDate: String?
    ): Call<Map<String, Any>>

    @GET(Endpoints.EMOTIONS.INSIGHTS)
    suspend fun getEmotionalInsights(): Call<Map<String, Any>>

    @GET(Endpoints.EMOTIONS.RECOMMENDATIONS)
    suspend fun getToolRecommendations(
        @Query("emotionType") emotionType: String,
        @Query("intensity") intensity: Int
    ): Call<List<ToolDto>>

    // Tool endpoints
    @GET(Endpoints.TOOLS.BASE)
    suspend fun getToolCategories(): Call<List<ToolCategoryDto>>

    @GET(Endpoints.TOOLS.BASE)
    suspend fun getToolsByCategory(@Query("categoryId") categoryId: String): Call<List<ToolDto>>

    @GET(Endpoints.TOOLS.DETAIL)
    suspend fun getTool(@Path("id") id: String): Call<ToolDto>

    @GET(Endpoints.TOOLS.FAVORITES)
    suspend fun getFavoriteTools(): Call<List<ToolDto>>

    @POST(Endpoints.TOOLS.FAVORITE_STATUS)
    suspend fun toggleToolFavorite(@Path("id") id: String): Call<ToolDto>

    @POST(Endpoints.TOOLS.USAGE)
    suspend fun trackToolUsage(
        @Path("id") id: String,
        @Query("durationSeconds") durationSeconds: Int
    ): Call<ToolDto>

    // Progress endpoints
    @GET(Endpoints.PROGRESS.STREAK)
    suspend fun getStreakInfo(): Call<StreakDto>

    @GET(Endpoints.PROGRESS.ACHIEVEMENTS)
    suspend fun getAchievements(): Call<List<AchievementDto>>

    @GET(Endpoints.PROGRESS.STATISTICS)
    suspend fun getProgressStatistics(): Call<Map<String, Any>>

    @GET(Endpoints.PROGRESS.DASHBOARD)
    suspend fun getProgressDashboard(): Call<Map<String, Any>>

    // Notification endpoints
    @POST(Endpoints.NOTIFICATIONS.REGISTER)
    suspend fun registerDevice(
        @Query("deviceId") deviceId: String,
        @Query("fcmToken") fcmToken: String
    ): Call<Unit>

    @PUT(Endpoints.NOTIFICATIONS.SETTINGS)
    suspend fun updateNotificationSettings(@Body settings: Map<String, Boolean>): Call<Map<String, Boolean>>

    @GET(Endpoints.NOTIFICATIONS.HISTORY)
    suspend fun getNotificationHistory(
        @Query("page") page: Int,
        @Query("pageSize") pageSize: Int
    ): Call<List<Map<String, Any>>>

    @POST(Endpoints.NOTIFICATIONS.READ)
    suspend fun markNotificationAsRead(@Path("id") id: String): Call<Unit>

    // Health endpoint
    @GET(Endpoints.HEALTH)
    suspend fun checkHealth(): Call<Map<String, Any>>
}