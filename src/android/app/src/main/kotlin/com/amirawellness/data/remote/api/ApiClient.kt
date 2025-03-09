package com.amirawellness.data.remote.api

import android.content.Context
import retrofit2.Retrofit // retrofit2 version: 2.9.0
import retrofit2.converter.gson.GsonConverterFactory // retrofit2 version: 2.9.0
import okhttp3.OkHttpClient // okhttp3 version: 4.10.0
import okhttp3.logging.HttpLoggingInterceptor // okhttp3 version: 4.10.0
import java.util.concurrent.TimeUnit // standard library
import kotlinx.coroutines.Dispatchers // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.withContext // kotlinx.coroutines version: 1.6.4
import com.amirawellness.core.constants.ApiConstants
import com.amirawellness.config.EnvironmentConfig
import com.amirawellness.core.utils.LogUtils
import com.amirawellness.data.models.ApiResponse

/**
 * Provides a configured Retrofit client for making API requests to the backend.
 * This class centralizes network configuration, authentication, and error handling
 * to ensure consistent API communication throughout the application.
 *
 * @param context Android application context
 */
class ApiClient(private val context: Context) {
    private val TAG = "ApiClient"
    private val retrofit: Retrofit
    private val apiService: ApiService
    private val networkMonitor: NetworkMonitor
    private val errorHandler: ErrorHandler

    init {
        networkMonitor = NetworkMonitorProvider.getInstance(context)
        errorHandler = ErrorHandlerProvider.getInstance(context)
        retrofit = createRetrofit()
        apiService = retrofit.create(ApiService::class.java)
        LogUtils.logDebug(TAG, "ApiClient initialized")
    }

    /**
     * Creates and configures a Retrofit instance with the appropriate URL, converters and client.
     *
     * @return Configured Retrofit instance
     */
    private fun createRetrofit(): Retrofit {
        val baseUrl = EnvironmentConfigProvider.getInstance().getApiBaseUrl()
        val okHttpClient = createOkHttpClient()

        return Retrofit.Builder()
            .baseUrl(baseUrl)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }

    /**
     * Creates and configures an OkHttpClient with appropriate interceptors and timeouts.
     *
     * @return Configured OkHttpClient instance
     */
    private fun createOkHttpClient(): OkHttpClient {
        val loggingInterceptor = HttpLoggingInterceptor().apply {
            level = if (EnvironmentConfigProvider.getInstance().isDevelopmentEnvironment()) {
                HttpLoggingInterceptor.Level.BODY
            } else {
                HttpLoggingInterceptor.Level.BASIC
            }
        }

        val authInterceptor = AuthInterceptorProvider.getInstance(context)

        return OkHttpClient.Builder()
            .addInterceptor(loggingInterceptor)
            .addInterceptor(authInterceptor)
            .connectTimeout(ApiConstants.Timeouts.CONNECT_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .readTimeout(ApiConstants.Timeouts.READ_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .writeTimeout(ApiConstants.Timeouts.WRITE_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .callTimeout(ApiConstants.Timeouts.CALL_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .build()
    }

    /**
     * Checks if network connectivity is available.
     *
     * @return True if network is available, false otherwise
     */
    fun isNetworkAvailable(): Boolean {
        return networkMonitor.isNetworkAvailable()
    }

    /**
     * Makes a safe API call with error handling and network checks.
     * This suspending function wraps API calls with proper error handling,
     * network connectivity checks, and standardized response processing.
     *
     * @param apiCall The API call function to execute
     * @return ApiResponse object containing either success or error
     */
    suspend fun <T> safeApiCall(apiCall: suspend () -> T): ApiResponse<T> {
        return try {
            // Check network connectivity first
            if (!isNetworkAvailable()) {
                LogUtils.logError(TAG, "Network not available")
                return ApiResponse.Error(
                    errorHandler.createNetworkError("No network connection available")
                )
            }

            // Execute the API call on IO dispatcher
            val response = withContext(Dispatchers.IO) {
                apiCall()
            }
            ApiResponse.Success(response)
        } catch (throwable: Throwable) {
            LogUtils.logError(TAG, "API call failed", throwable)
            // Use error handler to create standardized error
            val error = errorHandler.handleException(throwable)
            ApiResponse.Error(error)
        }
    }

    /**
     * Gets the configured API service interface.
     *
     * @return The API service interface for making requests
     */
    fun getApiService(): ApiService {
        return apiService
    }
}

/**
 * Singleton provider for ApiClient instance. Ensures only one
 * instance is created and provides access to it throughout the app.
 */
object ApiClientProvider {
    private var instance: ApiClient? = null

    /**
     * Gets or creates the singleton ApiClient instance.
     *
     * @param context Application context
     * @return The singleton ApiClient instance
     */
    fun getInstance(context: Context): ApiClient {
        return instance ?: synchronized(this) {
            instance ?: ApiClient(context.applicationContext).also { instance = it }
        }
    }

    /**
     * Resets the singleton instance (for testing purposes).
     */
    fun resetInstance() {
        instance = null
    }
}