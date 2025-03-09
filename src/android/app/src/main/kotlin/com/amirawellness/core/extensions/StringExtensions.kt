package com.amirawellness.core.extensions

import android.text.TextUtils // android version: latest
import android.util.Patterns // android version: latest
import com.amirawellness.core.utils.LogUtils.d
import java.text.Normalizer // java version: latest
import java.text.SimpleDateFormat // java version: latest
import java.util.Date // java version: latest
import java.util.Locale // java version: latest
import java.util.regex.Pattern // java version: latest

/**
 * Extension functions for the String class to provide common string manipulation,
 * validation, and formatting utilities for the Amira Wellness Android application.
 * These extensions support various features including input validation, text formatting,
 * and privacy-focused data handling.
 */

private val EMAIL_PATTERN = Patterns.EMAIL_ADDRESS
private val PASSWORD_PATTERN = Pattern.compile("^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*[@#$%^&+=])(?=\\S+$).{8,}$")
private val SENSITIVE_DATA_PATTERN = Pattern.compile("(password|token|key|secret|auth|credential)")
private val DIACRITICS_PATTERN = Pattern.compile("\\p{InCombiningDiacriticalMarks}+")

/**
 * Checks if the string is a valid email address.
 *
 * @return True if the string is a valid email address, false otherwise
 */
fun String.isValidEmail(): Boolean {
    if (this.isNullOrEmpty()) return false
    return EMAIL_PATTERN.matcher(this).matches()
}

/**
 * Checks if the string is a valid password according to security requirements.
 * Password must contain at least:
 * - 8 characters
 * - One digit
 * - One lowercase letter
 * - One uppercase letter
 * - One special character
 * - No whitespace
 *
 * @return True if the string meets password requirements, false otherwise
 */
fun String.isValidPassword(): Boolean {
    if (this.isNullOrEmpty()) return false
    return PASSWORD_PATTERN.matcher(this).matches()
}

/**
 * Checks if the string is null or empty (convenience wrapper around TextUtils).
 *
 * @return True if the string is null or empty, false otherwise
 */
fun String?.isNullOrEmpty(): Boolean {
    return TextUtils.isEmpty(this)
}

/**
 * Checks if the string is not null and not empty.
 *
 * @return True if the string is not null and not empty, false otherwise
 */
fun String?.isNotNullOrEmpty(): Boolean {
    return !this.isNullOrEmpty()
}

/**
 * Capitalizes the first letter of each word in the string.
 *
 * @return String with each word capitalized
 */
fun String.capitalizeWords(): String {
    if (this.isNullOrEmpty()) return this
    return split(" ").joinToString(" ") { word ->
        if (word.isNotEmpty()) word[0].uppercase() + word.substring(1) else word
    }
}

/**
 * Converts the string to title case (first letter of each word capitalized, rest lowercase).
 *
 * @return String in title case
 */
fun String.toTitleCase(): String {
    if (this.isNullOrEmpty()) return this
    return split(" ").joinToString(" ") { word ->
        if (word.isNotEmpty()) word[0].uppercase() + word.substring(1).lowercase() else word
    }
}

/**
 * Removes diacritical marks (accents) from the string, useful for Spanish text.
 *
 * @return String without diacritical marks
 */
fun String.removeDiacritics(): String {
    if (this.isNullOrEmpty()) return this
    val normalized = Normalizer.normalize(this, Normalizer.Form.NFD)
    return DIACRITICS_PATTERN.matcher(normalized).replaceAll("")
}

/**
 * Truncates the string to the specified length and adds ellipsis if needed.
 *
 * @param maxLength Maximum length of the resulting string including ellipsis
 * @param ellipsis String to append if truncated, defaults to "..."
 * @return Truncated string with ellipsis if truncated
 */
fun String.truncate(maxLength: Int, ellipsis: String = "..."): String {
    if (this.isNullOrEmpty() || length <= maxLength) return this
    val truncatedLength = maxLength - ellipsis.length
    if (truncatedLength <= 0) return ellipsis.substring(0, maxLength)
    return substring(0, truncatedLength) + ellipsis
}

/**
 * Masks sensitive data in the string for privacy protection.
 * Identifies potentially sensitive data like passwords, tokens, keys, etc.
 *
 * @return String with sensitive data masked
 */
fun String.maskSensitiveData(): String {
    if (this.isNullOrEmpty()) return this
    
    var result = this
    
    // Handle JSON-like patterns: "password": "secret"
    val jsonPattern = "\"(password|token|key|secret|auth|credential)\"\\s*:\\s*\"([^\"]*)\"".toRegex()
    result = result.replace(jsonPattern) { matchResult ->
        val key = matchResult.groupValues[1]
        val valueLength = matchResult.groupValues[2].length
        "\"$key\": \"${"*".repeat(valueLength)}\""
    }
    
    // Handle URL/query parameters: password=secret
    val urlPattern = "(password|token|key|secret|auth|credential)=([^&]*)".toRegex(RegexOption.IGNORE_CASE)
    result = result.replace(urlPattern) { matchResult ->
        val key = matchResult.groupValues[1]
        "${key}=[REDACTED]"
    }
    
    // Handle key-value assignment: password = "secret"
    val assignmentPattern = "(password|token|key|secret|auth|credential)\\s*=\\s*\"([^\"]*)\"".toRegex(RegexOption.IGNORE_CASE)
    result = result.replace(assignmentPattern) { matchResult ->
        val key = matchResult.groupValues[1]
        "$key = \"[REDACTED]\""
    }
    
    return result
}

/**
 * Extracts initials from the string (e.g., 'John Doe' -> 'JD').
 *
 * @param maxInitials Maximum number of initials to return
 * @return Initials extracted from the string
 */
fun String.toInitials(maxInitials: Int = Int.MAX_VALUE): String {
    if (this.isNullOrEmpty()) return this
    
    val initials = split(" ")
        .filter { it.isNotEmpty() }
        .map { it[0].uppercase() }
        .take(maxInitials)
        .joinToString("")
    
    return initials
}

/**
 * Checks if the string contains the specified substring, ignoring case.
 *
 * @param substring The substring to search for
 * @return True if the string contains the substring (ignoring case), false otherwise
 */
fun String.containsIgnoreCase(substring: String): Boolean {
    if (this.isNullOrEmpty() || substring.isNullOrEmpty()) return false
    return this.lowercase().contains(substring.lowercase())
}

/**
 * Converts the string to a URL-friendly slug.
 *
 * @return URL-friendly slug
 */
fun String.toSlug(): String {
    if (this.isNullOrEmpty()) return this
    
    return this.lowercase()
        .removeDiacritics()
        .replace(" ", "-")
        .replace(Regex("[^a-z0-9-]"), "")
}

/**
 * Attempts to parse the string as an ISO 8601 date.
 *
 * @return Parsed Date object or null if parsing fails
 */
fun String.parseIsoDate(): Date? {
    if (this.isNullOrEmpty()) return null
    
    val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
    return try {
        isoFormat.parse(this)
    } catch (e: Exception) {
        try {
            // Try alternative ISO format
            SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).parse(this)
        } catch (e: Exception) {
            d("StringExtensions", "Failed to parse ISO date: $this", e)
            null
        }
    }
}

/**
 * Formats a phone number string according to the specified locale.
 *
 * @param locale Locale to use for formatting, defaults to current locale
 * @return Formatted phone number string
 */
fun String.formatPhoneNumber(locale: Locale? = null): String {
    if (this.isNullOrEmpty()) return this
    
    // Remove any non-digit characters
    val digitsOnly = this.replace(Regex("\\D"), "")
    
    val currentLocale = locale ?: Locale.getDefault()
    
    // Format based on locale and length
    return when (currentLocale.country) {
        "US", "CA" -> { // North American format: (XXX) XXX-XXXX
            when (digitsOnly.length) {
                10 -> "(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}"
                11 -> if (digitsOnly.startsWith("1")) {
                    "1 (${digitsOnly.substring(1, 4)}) ${digitsOnly.substring(4, 7)}-${digitsOnly.substring(7)}"
                } else {
                    digitsOnly
                }
                else -> digitsOnly
            }
        }
        "ES" -> { // Spanish format: XXX XXX XXX
            when (digitsOnly.length) {
                9 -> "${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3, 6)} ${digitsOnly.substring(6)}"
                else -> digitsOnly
            }
        }
        else -> digitsOnly
    }
}

/**
 * Counts the number of words in the string.
 *
 * @return Number of words in the string
 */
fun String.countWords(): Int {
    if (this.isNullOrEmpty()) return 0
    val trimmed = this.trim()
    if (trimmed.isEmpty()) return 0
    return trimmed.split(Regex("\\s+")).size
}

/**
 * Ellipsizes the string in the middle if it exceeds the specified length.
 * For example, "abcdefghijk" with maxLength=8 becomes "abc...jk".
 *
 * @param maxLength Maximum length of the resulting string including ellipsis
 * @return Ellipsized string if too long, original string otherwise
 */
fun String.ellipsize(maxLength: Int): String {
    if (this.isNullOrEmpty() || length <= maxLength) return this
    
    val ellipsis = "..."
    if (maxLength <= ellipsis.length) return ellipsis.substring(0, maxLength)
    
    val charsToShow = maxLength - ellipsis.length
    val frontChars = charsToShow / 2 + charsToShow % 2
    val backChars = charsToShow / 2
    
    return substring(0, frontChars) + ellipsis + substring(length - backChars)
}

/**
 * Checks if the string is a valid URL.
 *
 * @return True if the string is a valid URL, false otherwise
 */
fun String.isValidUrl(): Boolean {
    if (this.isNullOrEmpty()) return false
    return Patterns.WEB_URL.matcher(this).matches()
}