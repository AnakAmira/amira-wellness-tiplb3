package com.amirawellness.core.utils

import android.content.Context // android version: latest
import android.content.res.Configuration // android version: latest
import android.content.res.Resources // android version: latest
import android.os.Build // android version: latest
import androidx.appcompat.app.AppCompatActivity // androidx.appcompat version: 1.6.1
import androidx.core.os.ConfigurationCompat // androidx.core version: 1.10.1
import java.util.Locale // java.util version: latest
import com.amirawellness.core.constants.AppConstants
import com.amirawellness.core.constants.PreferenceConstants

/**
 * Utility object for managing locale and language settings in the Amira Wellness application.
 * 
 * Provides functions to get and set application locale, retrieve available languages,
 * and apply locale changes throughout the application.
 */
object LocaleUtils {
    
    // Language code constants
    const val LANGUAGE_SPANISH = "es"
    const val LANGUAGE_ENGLISH = "en"
    
    /**
     * Returns a map of available language codes and their display names
     *
     * @param context Application context
     * @return Map of language codes to display names
     */
    fun getAvailableLanguages(context: Context): Map<String, String> {
        val languages = mutableMapOf<String, String>()
        
        // Add Spanish as primary language
        languages[LANGUAGE_SPANISH] = getDisplayLanguage(context, LANGUAGE_SPANISH)
        
        // English will be added in future phases
        // languages[LANGUAGE_ENGLISH] = getDisplayLanguage(context, LANGUAGE_ENGLISH)
        
        return languages
    }
    
    /**
     * Gets the current locale from the device configuration
     *
     * @param context Application context
     * @return Current locale
     */
    fun getCurrentLocale(context: Context): Locale {
        return ConfigurationCompat.getLocales(context.resources.configuration)[0]
    }
    
    /**
     * Sets the application locale based on the provided language code
     *
     * @param context Application context
     * @param languageCode Language code to set (e.g., "es" or "es-MX")
     * @return Updated context with new locale
     */
    fun setLocale(context: Context, languageCode: String): Context {
        val locale = getLocaleFromLanguageCode(languageCode)
        Locale.setDefault(locale)
        
        val configuration = Configuration(context.resources.configuration)
        applyLocaleToConfiguration(configuration, locale)
        
        return context.createConfigurationContext(configuration)
    }
    
    /**
     * Converts a language code string to a Locale object
     *
     * @param languageCode Language code (e.g., "es" or "es-MX")
     * @return Locale object for the language code
     */
    fun getLocaleFromLanguageCode(languageCode: String): Locale {
        val parts = languageCode.split("-", "_")
        return if (parts.size > 1) {
            Locale(parts[0], parts[1])
        } else {
            Locale(languageCode)
        }
    }
    
    /**
     * Gets the localized display name for a language code
     *
     * @param context Application context
     * @param languageCode Language code to get display name for
     * @return Localized display name for the language
     */
    fun getDisplayLanguage(context: Context, languageCode: String): String {
        val locale = getLocaleFromLanguageCode(languageCode)
        return locale.getDisplayLanguage(locale)
    }
    
    /**
     * Applies the stored language preference to a context
     *
     * @param context Application context
     * @return Updated context with the preferred locale
     */
    fun applyLocaleToContext(context: Context): Context {
        val languageCode = getStoredLanguageCode(context)
        return setLocale(context, languageCode)
    }
    
    /**
     * Applies the stored language preference to an activity
     *
     * @param activity AppCompatActivity to apply locale to
     */
    fun applyLocaleToActivity(activity: AppCompatActivity) {
        val languageCode = getStoredLanguageCode(activity)
        val locale = getLocaleFromLanguageCode(languageCode)
        
        val configuration = Configuration(activity.resources.configuration)
        applyLocaleToConfiguration(configuration, locale)
        
        activity.resources.updateConfiguration(configuration, activity.resources.displayMetrics)
        
        // Recreate activity to apply changes if needed
        // activity.recreate()
    }
    
    /**
     * Applies a locale to a configuration object
     *
     * @param configuration Configuration to update
     * @param locale Locale to apply
     * @return Updated configuration with the new locale
     */
    fun applyLocaleToConfiguration(configuration: Configuration, locale: Locale): Configuration {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            configuration.setLocales(android.os.LocaleList(locale))
        } else {
            @Suppress("DEPRECATION")
            configuration.locale = locale
        }
        return configuration
    }
    
    /**
     * Gets the stored language preference from SharedPreferences
     *
     * @param context Application context
     * @return Stored language code or default language
     */
    private fun getStoredLanguageCode(context: Context): String {
        val preferences = context.getSharedPreferences(
            PreferenceConstants.PREFERENCE_FILES.USER_PREFS, 
            Context.MODE_PRIVATE
        )
        
        return preferences.getString(
            PreferenceConstants.USER_PREFERENCES.LANGUAGE,
            AppConstants.DEFAULT_LANGUAGE
        ) ?: AppConstants.DEFAULT_LANGUAGE
    }
}