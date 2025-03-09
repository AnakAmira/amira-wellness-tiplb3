package com.amirawellness.data.remote.api

import android.content.Context // android version: latest
import okhttp3.Interceptor // okhttp3 version: 4.10.0
import okhttp3.Request // okhttp3 version: 4.10.0
import okhttp3.Response // okhttp3 version: 4.10.0
import com.amirawellness.core.constants.ApiConstants.Headers
import com.amirawellness.core.constants.PreferenceConstants.Keys
import com.amirawellness.data.local.preferences.PreferenceManager
import com.amirawellness.data.local.preferences.EncryptedPreferenceManagerFactory
import com.amirawellness.core.utils.LogUtils

private const val TAG = "AuthInterceptor"

/**
 * OkHttp interceptor that adds authentication headers to API requests.
 * Retrieves authentication tokens from secure storage and adds them to
 * request headers for secure API access.
 *
 * @param context The application context used to create secure preferences
 */
class AuthInterceptor(context: Context) : Interceptor {
    
    private val authPreferences: PreferenceManager = EncryptedPreferenceManagerFactory.createAuthPreferences(context)
    
    /**
     * Intercepts HTTP requests and adds authentication headers if token is available.
     *
     * @param chain The interceptor chain
     * @return The HTTP response from the chain
     */
    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()
        
        // Get the access token from secure preferences
        val token = authPreferences.getString(Keys.ACCESS_TOKEN)
        
        // Create a new request with auth headers if token is available
        val request = if (!token.isNullOrEmpty()) {
            LogUtils.logDebug(TAG, "Adding authorization header to request")
            
            // Add the bearer token to the request headers
            originalRequest.newBuilder()
                .header(Headers.AUTHORIZATION, "${Headers.BEARER_PREFIX}$token")
                .build()
        } else {
            LogUtils.logDebug(TAG, "No authorization token available, proceeding without authentication")
            originalRequest
        }
        
        // Proceed with the chain using the potentially modified request
        return chain.proceed(request)
    }
}

/**
 * Singleton provider for AuthInterceptor instance. Ensures only one
 * instance is created and provides access to it throughout the app.
 */
object AuthInterceptorProvider {
    
    private var instance: AuthInterceptor? = null
    
    /**
     * Gets or creates the singleton AuthInterceptor instance.
     *
     * @param context Application context used to create the interceptor
     * @return The singleton AuthInterceptor instance
     */
    fun getInstance(context: Context): AuthInterceptor {
        return instance ?: synchronized(this) {
            instance ?: AuthInterceptor(context.applicationContext).also { instance = it }
        }
    }
    
    /**
     * Resets the singleton instance (for testing purposes).
     */
    fun resetInstance() {
        instance = null
    }
}