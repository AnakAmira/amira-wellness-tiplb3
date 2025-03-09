package com.amirawellness.di

import com.amirawellness.services.encryption.KeyStoreManager
import com.amirawellness.services.encryption.EncryptionManager
import org.koin.dsl.module
import org.koin.core.module.Module
import org.koin.core.qualifier.named
import org.koin.dsl.bind
import org.koin.dsl.binds
import org.koin.android.ext.koin.androidContext

/**
 * Dependency injection module that provides encryption-related dependencies for the
 * Amira Wellness Android application. This module is responsible for providing 
 * singleton instances of KeyStoreManager and EncryptionManager that are used 
 * throughout the application for secure encryption of sensitive user data, 
 * particularly voice recordings.
 *
 * The encryption implementation uses AES-256-GCM for strong end-to-end encryption
 * with user-controlled keys, supporting the privacy-first approach of the application.
 * KeyStoreManager provides secure key management using Android's KeyStore system,
 * while EncryptionManager handles the actual encryption and decryption operations.
 */
val encryptionModule = module {
    // Provide KeyStoreManager singleton using the application context
    single { KeyStoreManager.getInstance(androidContext()) }
    
    // Provide EncryptionManager singleton using the application context
    single { EncryptionManager.getInstance(androidContext()) }
}