package com.amirawellness.di

import android.app.Application
import android.content.Context
import org.koin.android.ext.koin.androidContext // Koin version: 3.3.0
import org.koin.android.ext.koin.androidLogger // Koin version: 3.3.0
import org.koin.core.context.startKoin // Koin version: 3.3.0
import org.koin.core.logger.Level // Koin version: 3.3.0
import org.koin.dsl.module // Koin version: 3.3.0
import com.amirawellness.di.NetworkModule.networkModule // internal import
import com.amirawellness.di.StorageModule.storageModule // internal import
import com.amirawellness.di.EncryptionModule.encryptionModule // internal import
import com.amirawellness.di.ServiceModule.serviceModule // internal import
import com.amirawellness.di.ViewModelModule.viewModelModule // internal import
import com.amirawellness.config.AppConfig // internal import
import com.amirawellness.core.utils.LogUtils // internal import

/**
 * Main dependency injection module for the Amira Wellness Android application.
 * This module initializes Koin and combines all other modules to provide a complete dependency graph for the application.
 * It serves as the entry point for the dependency injection system.
 */
val appModule = module {
    // Provide application-level dependencies here if needed
}

/**
 * Initializes Koin dependency injection framework with all required modules
 *
 * @param application The application instance
 */
fun initKoin(application: Application) {
    // Log the start of Koin initialization
    LogUtils.logInfo("AppModule", "Starting Koin initialization")

    // Call startKoin to initialize the Koin framework
    startKoin {
        // Configure androidLogger with appropriate log level
        androidLogger(if (AppConfig.DEBUG) Level.DEBUG else Level.INFO)

        // Set androidContext with the application instance
        androidContext(application)

        // Register all modules (appModule, networkModule, storageModule, encryptionModule, serviceModule, viewModelModule)
        modules(
            appModule,
            networkModule,
            storageModule,
            encryptionModule,
            serviceModule,
            viewModelModule
        )
    }

    // Log successful Koin initialization
    LogUtils.logInfo("AppModule", "Koin initialization completed successfully")
}