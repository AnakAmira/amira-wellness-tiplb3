package com.amirawellness.di

import android.content.Context
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import com.google.gson.Gson
import org.koin.android.ext.koin.androidContext
import org.koin.dsl.module
import java.util.concurrent.TimeUnit
import com.amirawellness.data.remote.api.ApiClient
import com.amirawellness.data.remote.api.ApiService
import com.amirawellness.data.remote.api.AuthInterceptor
import com.amirawellness.data.remote.api.NetworkMonitor
import com.amirawellness.data.remote.api.ErrorHandler
import com.amirawellness.core.constants.ApiConstants
import com.amirawellness.config.EnvironmentConfig
import com.amirawellness.config.EnvironmentConfigProvider

/**
 * Koin module providing network-related dependencies for the application.
 * This module includes API client, network monitoring, authentication, and error handling
 * components required by the Amira Wellness application.
 */
val networkModule = module {
    // Provide OkHttpClient with appropriate configuration
    single { provideOkHttpClient(androidContext(), EnvironmentConfigProvider.getInstance().isDevelopmentEnvironment()) }
    
    // Provide Retrofit instance for API communication
    single { provideRetrofit(get()) }
    
    // Provide ApiService interface implementation
    single { provideApiService(get()) }
    
    // Provide Gson for JSON serialization/deserialization
    single { provideGson() }
    
    // Provide NetworkMonitor for detecting network connectivity
    single { provideNetworkMonitor(androidContext()) }
    
    // Provide ErrorHandler for centralized API error handling
    single { provideErrorHandler(androidContext()) }
    
    // Provide ApiClient for making API requests
    single { provideApiClient(androidContext(), get(), get(), get()) }
}

/**
 * Provides a configured OkHttpClient instance with appropriate interceptors and timeouts.
 *
 * @param context Android application context
 * @param isDebug Whether the app is running in debug mode
 * @return Configured OkHttpClient instance
 */
private fun provideOkHttpClient(context: Context, isDebug: Boolean): OkHttpClient {
    val loggingInterceptor = HttpLoggingInterceptor().apply {
        level = if (isDebug) {
            HttpLoggingInterceptor.Level.BODY
        } else {
            HttpLoggingInterceptor.Level.BASIC
        }
    }
    
    return OkHttpClient.Builder()
        .apply {
            if (isDebug) {
                addInterceptor(loggingInterceptor)
            }
        }
        .addInterceptor(AuthInterceptor(context))
        .connectTimeout(ApiConstants.Timeouts.CONNECT_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .readTimeout(ApiConstants.Timeouts.READ_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .writeTimeout(ApiConstants.Timeouts.WRITE_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .callTimeout(ApiConstants.Timeouts.CALL_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .build()
}

/**
 * Provides a configured Retrofit instance for API communication.
 *
 * @param okHttpClient The OkHttpClient to use for requests
 * @return Configured Retrofit instance
 */
private fun provideRetrofit(okHttpClient: OkHttpClient): Retrofit {
    val baseUrl = EnvironmentConfigProvider.getInstance().getApiBaseUrl()
    
    return Retrofit.Builder()
        .baseUrl(baseUrl)
        .client(okHttpClient)
        .addConverterFactory(GsonConverterFactory.create())
        .build()
}

/**
 * Provides the API service interface implementation.
 *
 * @param retrofit The Retrofit instance to create the service
 * @return API service interface implementation
 */
private fun provideApiService(retrofit: Retrofit): ApiService {
    return retrofit.create(ApiService::class.java)
}

/**
 * Provides a Gson instance for JSON serialization/deserialization.
 *
 * @return Gson instance
 */
private fun provideGson(): Gson {
    return Gson()
}

/**
 * Provides a NetworkMonitor instance for monitoring network connectivity.
 *
 * @param context Android application context
 * @return NetworkMonitor instance
 */
private fun provideNetworkMonitor(context: Context): NetworkMonitor {
    return NetworkMonitor(context)
}

/**
 * Provides an ErrorHandler instance for handling API errors.
 *
 * @param context Android application context
 * @return ErrorHandler instance
 */
private fun provideErrorHandler(context: Context): ErrorHandler {
    return ErrorHandler(context)
}

/**
 * Provides an ApiClient instance for making API requests.
 *
 * @param context Android application context
 * @param apiService The API service interface
 * @param networkMonitor The network monitor
 * @param errorHandler The error handler
 * @return ApiClient instance
 */
private fun provideApiClient(
    context: Context,
    apiService: ApiService,
    networkMonitor: NetworkMonitor,
    errorHandler: ErrorHandler
): ApiClient {
    // This method follows the specification for proper dependency injection
    // Currently, the ApiClient implementation only accepts context parameter
    return ApiClient(context)
}