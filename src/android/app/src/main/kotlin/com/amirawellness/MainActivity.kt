package com.amirawellness

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.core.view.WindowCompat
import androidx.navigation.compose.rememberNavController
import com.amirawellness.ui.navigation.AmiraNavHost
import com.amirawellness.ui.navigation.NavActions
import com.amirawellness.ui.navigation.Screen
import com.amirawellness.ui.navigation.rememberNavActions
import com.amirawellness.ui.theme.AmiraWellnessTheme
import android.Manifest // android.os
import androidx.activity.result.contract.ActivityResultContracts // androidx.activity.result.contract:1.7.0
import org.koin.android.ext.android.inject // org.koin.android.ext.android:3.3.0
import com.amirawellness.core.utils.LogUtils
import com.amirawellness.core.utils.PermissionUtils
import com.amirawellness.core.utils.createPermissionResultCallback
import com.amirawellness.core.utils.getRequiredPermissions

class MainActivity : ComponentActivity() {
    private const val TAG = "MainActivity"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        LogUtils.i(TAG, "Activity created")

        // LD1: Configure edge-to-edge display
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // LD1: Request necessary permissions
        requestPermissions()

        // LD1: Set up the Compose UI
        setContent {
            // LD1: Apply AmiraWellnessTheme to the entire UI
            AmiraWellnessTheme {
                // LD1: Create a Surface container with background color from MaterialTheme
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colors.background
                ) {
                    // LD1: Create and remember a NavController for navigation
                    val navController = rememberNavController()

                    // LD1: Create NavActions using rememberNavActions
                    val navActions = rememberNavActions(navController)

                    // LD1: Determine the start destination based on authentication status
                    val startDestination = getStartDestination()

                    // LD1: Set up AmiraNavHost with the NavController and startDestination
                    AmiraNavHost(
                        navController = navController,
                        startDestination = startDestination
                    )
                }
            }
        }
    }

    private fun requestPermissions() {
        val requiredPermissions = PermissionUtils.getRequiredPermissions()

        val permissionLauncher = registerForActivityResult(
            ActivityResultContracts.RequestMultiplePermissions()
        ) { permissions ->
            val allGranted = permissions.all { it.value }
            if (allGranted) {
                LogUtils.i(TAG, "All required permissions granted")
            } else {
                LogUtils.e(TAG, "Not all required permissions granted")
            }
        }

        permissionLauncher.launch(requiredPermissions)
    }

    private fun isUserAuthenticated(): Boolean {
        // TODO: Implement authentication check logic
        return false
    }

    private fun getStartDestination(): String {
        return if (isUserAuthenticated()) {
            Screen.Main.route
        } else {
            Screen.Login.route
        }
    }
}