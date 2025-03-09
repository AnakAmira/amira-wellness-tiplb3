package com.amirawellness.core.utils

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.activity.ComponentActivity

/**
 * Utility class providing helper methods for handling Android runtime permissions
 * in the Amira Wellness application, with a focus on privacy-sensitive permissions
 * like audio recording that are essential for the voice journaling feature.
 */
object PermissionUtils {
    private const val TAG = "PermissionUtils"
    
    /**
     * Checks if the app has been granted audio recording permission
     *
     * @param context The context to use for checking permissions
     * @return True if permission is granted, false otherwise
     */
    fun hasAudioRecordingPermission(context: Context): Boolean {
        val hasPermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
        
        LogUtils.d(TAG, "Audio recording permission status: $hasPermission")
        return hasPermission
    }
    
    /**
     * Checks if the app has been granted storage permissions based on Android version
     *
     * @param context The context to use for checking permissions
     * @return True if permission is granted, false otherwise
     */
    fun hasStoragePermission(context: Context): Boolean {
        // Android 10+ (API 29+) uses scoped storage, so explicit permissions are not needed
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            LogUtils.d(TAG, "Storage permission not required (using scoped storage)")
            return true
        }
        
        // For older Android versions, check READ_EXTERNAL_STORAGE and WRITE_EXTERNAL_STORAGE
        val readPermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.READ_EXTERNAL_STORAGE
        ) == PackageManager.PERMISSION_GRANTED
        
        val writePermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
        ) == PackageManager.PERMISSION_GRANTED
        
        val hasPermission = readPermission && writePermission
        LogUtils.d(TAG, "Storage permission status: $hasPermission")
        return hasPermission
    }
    
    /**
     * Checks if the app has been granted notification permission (for Android 13+)
     *
     * @param context The context to use for checking permissions
     * @return True if permission is granted, false otherwise
     */
    fun hasNotificationPermission(context: Context): Boolean {
        // POST_NOTIFICATIONS permission was introduced in Android 13 (API 33)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val hasPermission = ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
            
            LogUtils.d(TAG, "Notification permission status: $hasPermission")
            return hasPermission
        }
        
        // Prior to Android 13, notification permission was granted by default
        LogUtils.d(TAG, "Notification permission not required for this Android version")
        return true
    }
    
    /**
     * Checks if the app has been granted biometric authentication permission
     *
     * @param context The context to use for checking permissions
     * @return True if permission is granted, false otherwise
     */
    fun hasBiometricPermission(context: Context): Boolean {
        val hasPermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.USE_BIOMETRIC
        ) == PackageManager.PERMISSION_GRANTED
        
        LogUtils.d(TAG, "Biometric permission status: $hasPermission")
        return hasPermission
    }
    
    /**
     * Checks if the app should show a rationale for requesting audio permission
     *
     * @param activity The activity to use for checking rationale status
     * @return True if rationale should be shown, false otherwise
     */
    fun shouldShowAudioPermissionRationale(activity: ComponentActivity): Boolean {
        return activity.shouldShowRequestPermissionRationale(Manifest.permission.RECORD_AUDIO)
    }
    
    /**
     * Checks if the app should show a rationale for requesting audio permission (Fragment version)
     *
     * @param fragment The fragment to use for checking rationale status
     * @return True if rationale should be shown, false otherwise
     */
    fun shouldShowAudioPermissionRationale(fragment: Fragment): Boolean {
        return fragment.shouldShowRequestPermissionRationale(Manifest.permission.RECORD_AUDIO)
    }
    
    /**
     * Checks if the app should show a rationale for requesting notification permission
     *
     * @param activity The activity to use for checking rationale status
     * @return True if rationale should be shown, false otherwise
     */
    fun shouldShowNotificationPermissionRationale(activity: ComponentActivity): Boolean {
        // POST_NOTIFICATIONS permission was introduced in Android 13 (API 33)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return activity.shouldShowRequestPermissionRationale(Manifest.permission.POST_NOTIFICATIONS)
        }
        
        // Prior to Android 13, notification permission was granted by default
        return false
    }
    
    /**
     * Checks if the app should show a rationale for requesting notification permission (Fragment version)
     *
     * @param fragment The fragment to use for checking rationale status
     * @return True if rationale should be shown, false otherwise
     */
    fun shouldShowNotificationPermissionRationale(fragment: Fragment): Boolean {
        // POST_NOTIFICATIONS permission was introduced in Android 13 (API 33)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return fragment.shouldShowRequestPermissionRationale(Manifest.permission.POST_NOTIFICATIONS)
        }
        
        // Prior to Android 13, notification permission was granted by default
        return false
    }
    
    /**
     * Gets an array of all permissions required by the app based on Android version
     *
     * @return Array of permission strings
     */
    fun getRequiredPermissions(): Array<String> {
        val permissions = mutableListOf<String>()
        
        // Audio recording permission - critical for voice journaling feature
        permissions.add(Manifest.permission.RECORD_AUDIO)
        
        // Biometric permission for secure access to sensitive data
        permissions.add(Manifest.permission.USE_BIOMETRIC)
        
        // Add notification permission for Android 13+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }
        
        // Add storage permissions for Android versions below 10 (API 29)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            permissions.add(Manifest.permission.READ_EXTERNAL_STORAGE)
            permissions.add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
        }
        
        return permissions.toTypedArray()
    }
    
    /**
     * Creates a callback function for handling permission request results
     *
     * @param onPermissionResult Callback to invoke with the permission result
     * @return Callback function for permission results
     */
    fun createPermissionResultCallback(onPermissionResult: (Boolean) -> Unit): (Map<String, Boolean>) -> Unit {
        return { permissions: Map<String, Boolean> ->
            // Check if all requested permissions were granted
            val allGranted = permissions.all { it.value }
            
            // Log the result
            if (allGranted) {
                LogUtils.d(TAG, "All permissions were granted")
            } else {
                val denied = permissions.filterNot { it.value }.keys.joinToString(", ")
                LogUtils.e(TAG, "Some permissions were denied: $denied")
            }
            
            // Invoke the callback with the result
            onPermissionResult(allGranted)
        }
    }
}