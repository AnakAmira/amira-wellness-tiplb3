# src/android/app/src/main/kotlin/com/amirawellness/di/ServiceModule.kt
```kotlin
package com.amirawellness.di

import android.content.Context
import com.amirawellness.data.local.preferences.PreferenceManager
import com.amirawellness.data.repositories.EmotionalStateRepository
import com.amirawellness.data.repositories.JournalRepository
import com.amirawellness.data.repositories.NotificationRepository
import com.amirawellness.data.repositories.ProgressRepository
import com.amirawellness.data.repositories.ToolRepository
import com.amirawellness.data.repositories.UserRepository
import com.amirawellness.data.remote.api.NetworkMonitor
import com.amirawellness.services.analytics.AnalyticsManager
import com.amirawellness.services.audio.AudioPlaybackService
import com.amirawellness.services.audio.AudioRecordingService
import com.amirawellness.services.biometric.BiometricManager
import com.amirawellness.services.notification.NotificationManager
import com.amirawellness.services.notification.NotificationScheduler
import com.amirawellness.services.sync.DataQueueManager
import com.amirawellness.services.sync.OfflineDataManager
import com.amirawellness.services.sync.SyncManager
import kotlinx.coroutines.CoroutineScope // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.Dispatchers // kotlinx.coroutines version: 1.6.4
import kotlinx.coroutines.SupervisorJob // kotlinx.coroutines version: 1.6.4
import org.koin.android.ext.koin.androidContext // org.koin version: 3.3.0
import org.koin.core.qualifier.named // org.koin version: 3.3.0
import org.koin.dsl.module // org.koin version: 3.3.0

// Koin module for service-related dependencies
val serviceModule = module {

    // Provides a coroutine scope for services that need to perform asynchronous operations
    single {
        CoroutineScope(Dispatchers.IO + SupervisorJob())
    }

    // Provides a singleton instance of the AudioRecordingService
    single {
        AudioRecordingService(androidContext())
    }

    // Provides a singleton instance of the AudioPlaybackService
    single {
        AudioPlaybackService(androidContext())
    }

    // Provides a singleton instance of the NotificationManager
    single {
        NotificationManager(androidContext(), get(), get())
    }

    // Provides a singleton instance of the NotificationScheduler
    single {
        NotificationScheduler(androidContext(), get(), get(), get(), get())
    }

    // Provides a singleton instance of the BiometricManager
    single {
        BiometricManager(androidContext())
    }

    // Provides a singleton instance of the DataQueueManager
    single {
        DataQueueManager(get(), get(), get())
    }

    // Provides a singleton instance of the OfflineDataManager
    single {
        OfflineDataManager(get(), get(), get(), get(), get())
    }

    // Provides a singleton instance of the SyncManager
    single {
        SyncManager(get(), get(), get(), get(), get(), get(), get(), get(), get())
    }

    // Provides a singleton instance of the AnalyticsManager
    single {
        AnalyticsManager(androidContext(), get())
    }
}