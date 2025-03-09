package com.amirawellness

import android.app.Application // android version: latest
import androidx.lifecycle.ProcessLifecycleOwner // androidx.lifecycle:lifecycle-runtime-ktx:2.6.1
import androidx.lifecycle.DefaultLifecycleObserver // androidx.lifecycle:lifecycle-runtime-ktx:2.6.1
import androidx.lifecycle.LifecycleOwner // androidx.lifecycle:lifecycle-runtime-ktx:2.6.1
import kotlinx.coroutines.CoroutineScope // kotlinx.coroutines:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.Dispatchers // kotlinx.coroutines:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.SupervisorJob // kotlinx.coroutines:kotlinx-coroutines-core:1.6.4
import kotlinx.coroutines.launch // kotlinx.coroutines:kotlinx-coroutines-core:1.6.4
import org.koin.android.ext.android.inject // org.koin:koin-android:3.3.0
import org.koin.android.ext.koin.androidContext // org.koin:koin-android:3.3.0
import org.koin.android.ext.koin.androidLogger // org.koin:koin-android:3.3.0
import com.amirawellness.di.AppModule.initKoin // Internal import
import com.amirawellness.config.AppConfigProvider // Internal import
import com.amirawellness.data.local.AppDatabase // Internal import
import com.amirawellness.core.utils.LogUtils // Internal import

/**
 * Main application class that initializes core components and services
 */
class AmiraApplication : Application() {

    private val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val analyticsManager: com.amirawellness.services.analytics.AnalyticsManager by inject()
    private val syncManager: com.amirawellness.services.sync.SyncManager by inject()
    private val notificationManager: com.amirawellness.services.notification.NotificationManager by inject()

    /**
     * Called when the application is first created
     */
    override fun onCreate() {
        super.onCreate()

        LogUtils.i(TAG, "AmiraApplication is being created")

        // Initialize Koin dependency injection
        initKoin(this)

        // Initialize application configuration
        AppConfigProvider.initialize(this)

        // Register lifecycle observer
        registerLifecycleObserver()

        // Initialize core services and components
        initializeServices()
    }

    /**
     * Initializes core services and components
     */
    private fun initializeServices() {
        LogUtils.i(TAG, "Initializing core services")

        applicationScope.launch {
            // Initialize analytics manager
            analyticsManager.initialize()

            // Initialize notification manager
            notificationManager.initialize()

            // Initialize sync manager when user is authenticated
            // TODO: Start sync manager only when user is authenticated
            syncManager.initialize("test_user_id") // Replace with actual user ID

            LogUtils.i(TAG, "Core services initialized successfully")
        }
    }

    /**
     * Registers a lifecycle observer to monitor application lifecycle events
     */
    private fun registerLifecycleObserver() {
        val lifecycleObserver = object : DefaultLifecycleObserver {
            override fun onStart(owner: LifecycleOwner) {
                super.onStart(owner)
                LogUtils.d(TAG, "App is in foreground")
                // Track app foreground events
            }

            override fun onStop(owner: LifecycleOwner) {
                super.onStop(owner)
                LogUtils.d(TAG, "App is in background")
                // Track app background events
            }
        }

        ProcessLifecycleOwner.get().lifecycle.addObserver(lifecycleObserver)
    }

    /**
     * Called when the application is terminating
     */
    override fun onTerminate() {
        super.onTerminate()

        LogUtils.i(TAG, "AmiraApplication is terminating")

        // Perform cleanup operations
        syncManager.shutdown()

        // Cancel applicationScope to stop all coroutines
        applicationScope.cancel()
    }

    /**
     * Called when the system is running low on memory
     */
    override fun onLowMemory() {
        super.onLowMemory()

        LogUtils.w(TAG, "System is running low on memory")

        // Clear non-essential caches and resources
    }

    /**
     * Called when the system needs to trim memory
     */
    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)

        LogUtils.w(TAG, "System is requesting to trim memory, level: $level")

        // Perform appropriate memory cleanup based on level
    }

    companion object {
        private const val TAG = "AmiraApplication"
    }
}