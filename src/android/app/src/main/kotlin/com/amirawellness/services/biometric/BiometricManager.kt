package com.amirawellness.services.biometric

import android.content.Context
import android.content.pm.PackageManager
import androidx.biometric.BiometricManager as AndroidXBiometricManager
import androidx.biometric.BiometricPrompt
import androidx.fragment.app.FragmentActivity
import androidx.core.content.ContextCompat
import com.amirawellness.core.constants.AppConstants
import com.amirawellness.core.utils.LogUtils
import java.util.concurrent.Executor

private const val TAG = "BiometricManager"

/**
 * Represents errors that can occur during biometric authentication.
 * This sealed class provides a type-safe way to handle different error scenarios.
 */
sealed class BiometricError : Exception() {
    data class AuthenticationFailed(override val message: String? = null) : BiometricError()
    data class BiometryNotAvailable(override val message: String? = null) : BiometricError()
    data class BiometryNotEnrolled(override val message: String? = null) : BiometricError()
    data class UserCancelled(override val message: String? = null) : BiometricError()
    data class HardwareUnavailable(override val message: String? = null) : BiometricError()
    data class SecurityUpdateRequired(override val message: String? = null) : BiometricError()
    data class Timeout(override val message: String? = null) : BiometricError()
    data class LockoutPermanent(override val message: String? = null) : BiometricError()
    data class LockoutTemporary(override val message: String? = null) : BiometricError()
    data class NoDeviceCredential(override val message: String? = null) : BiometricError()
    data class Unknown(override val message: String? = null) : BiometricError()
}

/**
 * Represents the types of biometric authentication available on the device.
 */
enum class BiometricType {
    NONE,
    FINGERPRINT,
    FACE,
    IRIS,
    MULTIPLE
}

/**
 * Manages biometric authentication operations using AndroidX Biometric library.
 * This class follows the singleton pattern to ensure consistent state across the app.
 */
class BiometricManager private constructor(private val context: Context) {
    private val biometricManager = AndroidXBiometricManager.from(context)
    private val isFeatureEnabled = AppConstants.ENCRYPTION_SETTINGS.BIOMETRIC_ENCRYPTION_ENABLED

    companion object {
        @Volatile
        private var instance: BiometricManager? = null

        /**
         * Gets the singleton instance of BiometricManager.
         *
         * @param context The application context
         * @return The BiometricManager instance
         */
        @JvmStatic
        fun getInstance(context: Context): BiometricManager {
            return instance ?: synchronized(this) {
                instance ?: BiometricManager(context.applicationContext).also { instance = it }
            }
        }
    }

    /**
     * Checks if biometric authentication is available and can be used.
     *
     * @return True if biometric authentication is available and can be used
     */
    fun canAuthenticate(): Boolean {
        if (!isFeatureEnabled) {
            LogUtils.d(TAG, "Biometric authentication is disabled in app settings")
            return false
        }

        val result = biometricManager.canAuthenticate(AndroidXBiometricManager.Authenticators.BIOMETRIC_STRONG)
        val canAuthenticate = result == AndroidXBiometricManager.BIOMETRIC_SUCCESS

        LogUtils.d(TAG, "Can authenticate with biometrics: $canAuthenticate (result code: $result)")
        return canAuthenticate
    }

    /**
     * Determines the type of biometric authentication available on the device.
     *
     * @return The type of biometric authentication available
     */
    fun getBiometricType(): BiometricType {
        if (!canAuthenticate()) {
            return BiometricType.NONE
        }

        val packageManager = context.packageManager
        
        val hasFingerprintHardware = packageManager.hasSystemFeature(PackageManager.FEATURE_FINGERPRINT)
        val hasFaceHardware = packageManager.hasSystemFeature(PackageManager.FEATURE_FACE)
        val hasIrisHardware = packageManager.hasSystemFeature(PackageManager.FEATURE_IRIS)
        
        return when {
            hasFingerprintHardware && (hasFaceHardware || hasIrisHardware) -> BiometricType.MULTIPLE
            hasFingerprintHardware -> BiometricType.FINGERPRINT
            hasFaceHardware -> BiometricType.FACE
            hasIrisHardware -> BiometricType.IRIS
            else -> BiometricType.NONE
        }
    }

    /**
     * Authenticates the user using biometric authentication.
     *
     * @param activity The activity context for the biometric prompt
     * @param title The title for the biometric prompt
     * @param subtitle The subtitle for the biometric prompt
     * @param description The description for the biometric prompt
     * @param negativeButtonText The text for the negative button
     * @param callback The callback to receive the authentication result
     */
    fun authenticate(
        activity: FragmentActivity,
        title: String,
        subtitle: String,
        description: String,
        negativeButtonText: String,
        callback: (Result<Boolean>) -> Unit
    ) {
        if (!canAuthenticate()) {
            callback(Result.failure(BiometricError.BiometryNotAvailable("Biometric authentication is not available on this device")))
            return
        }

        val executor = ContextCompat.getMainExecutor(activity)
        
        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle(title)
            .setSubtitle(subtitle)
            .setDescription(description)
            .setNegativeButtonText(negativeButtonText)
            .setAllowedAuthenticators(AndroidXBiometricManager.Authenticators.BIOMETRIC_STRONG)
            .build()
        
        val biometricPrompt = BiometricPrompt(activity, executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(result)
                    LogUtils.d(TAG, "Authentication succeeded")
                    callback(Result.success(true))
                }
                
                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    LogUtils.e(TAG, "Authentication error: $errorCode - $errString")
                    val error = mapErrorCodeToBiometricError(errorCode)
                    callback(Result.failure(error))
                }
                
                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                    LogUtils.e(TAG, "Authentication failed")
                    callback(Result.failure(BiometricError.AuthenticationFailed("Authentication failed")))
                }
            })
        
        biometricPrompt.authenticate(promptInfo)
    }

    /**
     * Authenticates the user using biometric authentication with default UI text.
     *
     * @param activity The activity context for the biometric prompt
     * @param callback The callback to receive the authentication result
     */
    fun authenticate(
        activity: FragmentActivity,
        callback: (Result<Boolean>) -> Unit
    ) {
        authenticate(
            activity = activity,
            title = "Autenticación Biométrica",
            subtitle = "Confirma tu identidad",
            description = "Utiliza tu biometría para acceder a información sensible",
            negativeButtonText = "Cancelar",
            callback = callback
        )
    }

    /**
     * Gets a user-friendly error message for biometric authentication errors.
     *
     * @param error The BiometricError to get a message for
     * @return A user-friendly error message
     */
    fun getErrorMessage(error: BiometricError): String {
        return when (error) {
            is BiometricError.AuthenticationFailed -> "La autenticación biométrica falló. Por favor, inténtalo de nuevo."
            is BiometricError.BiometryNotAvailable -> "La autenticación biométrica no está disponible en este dispositivo."
            is BiometricError.BiometryNotEnrolled -> "No hay datos biométricos registrados. Por favor, configura tu biometría en los ajustes del dispositivo."
            is BiometricError.UserCancelled -> "Autenticación cancelada por el usuario."
            is BiometricError.HardwareUnavailable -> "El hardware biométrico no está disponible actualmente."
            is BiometricError.SecurityUpdateRequired -> "Se requiere una actualización de seguridad para usar la autenticación biométrica."
            is BiometricError.Timeout -> "La autenticación biométrica ha expirado. Por favor, inténtalo de nuevo."
            is BiometricError.LockoutPermanent -> "Biometría bloqueada debido a demasiados intentos fallidos. Utiliza tu contraseña para desbloquear."
            is BiometricError.LockoutTemporary -> "Biometría temporalmente bloqueada debido a demasiados intentos fallidos. Inténtalo más tarde."
            is BiometricError.NoDeviceCredential -> "No hay credenciales de dispositivo configuradas. Establece un PIN, patrón o contraseña."
            is BiometricError.Unknown -> "Error desconocido en la autenticación biométrica: ${error.message}"
        }
    }

    /**
     * Maps BiometricPrompt error codes to BiometricError for consistent error handling.
     *
     * @param errorCode The BiometricPrompt error code
     * @return The mapped BiometricError
     */
    private fun mapErrorCodeToBiometricError(errorCode: Int): BiometricError {
        return when (errorCode) {
            BiometricPrompt.ERROR_HW_UNAVAILABLE -> BiometricError.HardwareUnavailable("Hardware not available")
            BiometricPrompt.ERROR_UNABLE_TO_PROCESS -> BiometricError.Unknown("Unable to process the request")
            BiometricPrompt.ERROR_TIMEOUT -> BiometricError.Timeout("Authentication timed out")
            BiometricPrompt.ERROR_NO_SPACE -> BiometricError.Unknown("Not enough storage")
            BiometricPrompt.ERROR_CANCELED -> BiometricError.UserCancelled("Authentication was canceled")
            BiometricPrompt.ERROR_LOCKOUT -> BiometricError.LockoutTemporary("Too many attempts, try again later")
            BiometricPrompt.ERROR_LOCKOUT_PERMANENT -> BiometricError.LockoutPermanent("Too many attempts, biometric is disabled")
            BiometricPrompt.ERROR_VENDOR -> BiometricError.Unknown("Vendor specific error")
            BiometricPrompt.ERROR_NO_BIOMETRICS -> BiometricError.BiometryNotEnrolled("No biometric enrollments")
            BiometricPrompt.ERROR_HW_NOT_PRESENT -> BiometricError.HardwareUnavailable("Device doesn't have biometric hardware")
            BiometricPrompt.ERROR_NEGATIVE_BUTTON -> BiometricError.UserCancelled("User canceled by tapping negative button")
            BiometricPrompt.ERROR_NO_DEVICE_CREDENTIAL -> BiometricError.NoDeviceCredential("No device credentials (PIN/pattern/password) set")
            BiometricPrompt.ERROR_SECURITY_UPDATE_REQUIRED -> BiometricError.SecurityUpdateRequired("Security update required")
            else -> BiometricError.Unknown("Unknown error: $errorCode")
        }
    }
}