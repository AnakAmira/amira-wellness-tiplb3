package com.amirawellness.services.analytics

import android.content.Context
import android.os.Bundle
import android.util.Log
import com.google.firebase.analytics.FirebaseAnalytics // com.google.firebase:firebase-analytics-ktx:21.3.0
import com.google.firebase.analytics.ktx.analytics // com.google.firebase:firebase-analytics-ktx:21.3.0
import com.google.firebase.ktx.Firebase // com.google.firebase:firebase-analytics-ktx:21.3.0
import kotlinx.coroutines.CoroutineScope // kotlinx.coroutines:1.7.3
import kotlinx.coroutines.Dispatchers // kotlinx.coroutines:1.7.3
import kotlinx.coroutines.launch // kotlinx.coroutines:1.7.3
import javax.inject.Inject // javax.inject:1
import javax.inject.Singleton // javax.inject:1
import com.amirawellness.services.analytics.AnalyticsTrackers.EventName
import com.amirawellness.services.analytics.AnalyticsTrackers.UserProperty
import com.amirawellness.services.analytics.AnalyticsTrackers.ParameterKey
import com.amirawellness.services.analytics.AnalyticsTrackers.ScreenName
import com.amirawellness.services.analytics.AnalyticsTrackers.FeatureName
import com.amirawellness.config.AppConfig
import com.amirawellness.config.AppConfigProvider
import com.amirawellness.data.repositories.UserRepository

private const val TAG = "AnalyticsManager"

/**
 * Manages analytics tracking for the Amira Wellness application with a privacy-focused approach.
 * This class serves as a facade for Firebase Analytics integration, standardizing event tracking
 * across the application and ensuring consistent analytics implementation while respecting user
 * privacy preferences.
 */
@Singleton
class AnalyticsManager @Inject constructor(
    private val context: Context,
    private val userRepository: UserRepository
) {
    private val firebaseAnalytics: FirebaseAnalytics = Firebase.analytics
    private val coroutineScope = CoroutineScope(Dispatchers.IO)
    private var isEnabled: Boolean = AppConfigProvider.getInstance().isAnalyticsEnabled

    init {
        // Initialize analytics if enabled based on app configuration
        if (isEnabled) {
            initialize()
        }
        Log.d(TAG, "AnalyticsManager initialized with analytics enabled: $isEnabled")
    }

    /**
     * Initializes analytics tracking with user properties.
     * This method sets up analytics tracking and fetches initial user properties
     * when analytics is enabled.
     */
    fun initialize() {
        if (!isEnabled) return

        Log.d(TAG, "Initializing analytics")
        // Log app open event
        logEvent(EventName.APP_OPEN)
        // Update user properties asynchronously
        updateUserProperties()
    }

    /**
     * Enables or disables analytics tracking.
     * This allows users to opt in or out of analytics tracking at runtime.
     *
     * @param enabled Whether analytics tracking should be enabled
     */
    fun setEnabled(enabled: Boolean) {
        Log.d(TAG, "Setting analytics enabled: $enabled")
        isEnabled = enabled

        if (enabled) {
            initialize()
        } else {
            clearAnalyticsData()
        }
    }

    /**
     * Logs an analytics event with parameters.
     *
     * @param eventName The name of the event
     * @param params Optional bundle of parameters
     */
    fun logEvent(eventName: String, params: Bundle? = null) {
        if (!isEnabled) return

        firebaseAnalytics.logEvent(eventName, params)
        Log.d(TAG, "Logged event: $eventName, params: $params")
    }

    /**
     * Logs an analytics event with standardized event name.
     *
     * @param eventName The standardized event name
     * @param params Optional bundle of parameters
     */
    fun logEvent(eventName: EventName, params: Bundle? = null) {
        logEvent(eventName.toString(), params)
    }

    /**
     * Logs an analytics event with map of parameters.
     *
     * @param eventName The name of the event
     * @param params Optional map of parameters
     */
    fun logEvent(eventName: String, params: Map<String, Any>?) {
        if (params == null) {
            logEvent(eventName, null as Bundle?)
            return
        }

        val bundle = createBundle(params)
        logEvent(eventName, bundle)
    }

    /**
     * Logs an analytics event with standardized event name and map of parameters.
     *
     * @param eventName The standardized event name
     * @param params Optional map of parameters
     */
    fun logEvent(eventName: EventName, params: Map<String, Any>?) {
        logEvent(eventName.toString(), params)
    }

    /**
     * Logs a screen view event.
     * This tracks when users navigate to different screens in the app.
     *
     * @param screenName The name of the screen
     * @param screenClass Optional class name of the screen
     */
    fun logScreenView(screenName: String, screenClass: String? = null) {
        val params = mutableMapOf<String, Any>(
            ParameterKey.SCREEN_NAME.toString() to screenName
        )

        if (screenClass != null) {
            params[ParameterKey.SCREEN_CLASS.toString()] = screenClass
        }

        logEvent(EventName.SCREEN_VIEW, params)
    }

    /**
     * Logs a screen view event with standardized screen name.
     *
     * @param screenName The standardized screen name
     * @param screenClass Optional class name of the screen
     */
    fun logScreenView(screenName: ScreenName, screenClass: String? = null) {
        logScreenView(screenName.toString(), screenClass)
    }

    /**
     * Logs a feature usage event.
     * This tracks when users interact with specific features in the app.
     *
     * @param featureName The name of the feature
     * @param additionalParams Optional additional parameters
     */
    fun logFeatureUsage(featureName: String, additionalParams: Map<String, Any>? = null) {
        val params = mutableMapOf<String, Any>(
            ParameterKey.FEATURE_NAME.toString() to featureName
        )

        additionalParams?.forEach { (key, value) ->
            params[key] = value
        }

        logEvent(EventName.FEATURE_USED, params)
    }

    /**
     * Logs a feature usage event with standardized feature name.
     *
     * @param featureName The standardized feature name
     * @param additionalParams Optional additional parameters
     */
    fun logFeatureUsage(featureName: FeatureName, additionalParams: Map<String, Any>? = null) {
        logFeatureUsage(featureName.toString(), additionalParams)
    }

    /**
     * Sets a user property for analytics segmentation.
     * User properties help segment users in analytics reports without tracking
     * personally identifiable information.
     *
     * @param name The name of the property
     * @param value The value of the property
     */
    fun setUserProperty(name: String, value: String?) {
        if (!isEnabled) return

        firebaseAnalytics.setUserProperty(name, value)
        Log.d(TAG, "Set user property: $name = $value")
    }

    /**
     * Sets a user property with standardized property name.
     *
     * @param property The standardized property name
     * @param value The value of the property
     */
    fun setUserProperty(property: UserProperty, value: String?) {
        setUserProperty(property.toString(), value)
    }

    /**
     * Updates user properties based on current user data.
     * This fetches the latest user data and updates analytics properties accordingly.
     */
    fun updateUserProperties() {
        if (!isEnabled) return

        coroutineScope.launch {
            try {
                // Get current user data
                userRepository.getCurrentUser().collect { user ->
                    user?.let {
                        // Set user properties based on user data
                        setUserProperty(UserProperty.SUBSCRIPTION_TIER, it.subscriptionTier)
                        setUserProperty(UserProperty.LANGUAGE_PREFERENCE, it.languagePreference)
                        
                        // Calculate days since install based on user creation date
                        val daysSinceInstall = ((System.currentTimeMillis() - it.createdAt.time) / (1000 * 60 * 60 * 24)).toString()
                        setUserProperty(UserProperty.DAYS_SINCE_INSTALL, daysSinceInstall)
                        
                        Log.d(TAG, "Updated user properties for user ${it.id}")
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error updating user properties", e)
            }
        }
    }

    /**
     * Creates a Bundle from a map of parameters.
     * This utility method converts a Map to a Bundle for Firebase Analytics compatibility.
     *
     * @param params The map of parameters
     * @return A Bundle containing the parameters
     */
    private fun createBundle(params: Map<String, Any>): Bundle {
        val bundle = Bundle()

        params.forEach { (key, value) ->
            when (value) {
                is String -> bundle.putString(key, value)
                is Int -> bundle.putInt(key, value)
                is Long -> bundle.putLong(key, value)
                is Double -> bundle.putDouble(key, value)
                is Boolean -> bundle.putBoolean(key, value)
                is Float -> bundle.putFloat(key, value)
                is Array<*> -> {
                    if (value.isArrayOf<String>()) {
                        bundle.putStringArray(key, value as Array<String>)
                    }
                }
                else -> bundle.putString(key, value.toString())
            }
        }

        return bundle
    }

    /**
     * Clears all analytics data when user opts out.
     * This ensures user privacy when analytics is disabled.
     */
    fun clearAnalyticsData() {
        firebaseAnalytics.resetAnalyticsData()
        Log.d(TAG, "Cleared analytics data")
    }
}