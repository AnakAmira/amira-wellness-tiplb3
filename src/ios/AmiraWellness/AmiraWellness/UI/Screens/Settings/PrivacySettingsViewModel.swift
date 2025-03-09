# <file_path>
```swift
import Foundation // iOS SDK - Latest
import Combine // iOS SDK - Latest
import SwiftUI // iOS SDK - Latest

// Internal imports
import '../../../Services/Encryption/EncryptionService' // src/ios/AmiraWellness/AmiraWellness/Services/Encryption/EncryptionService.swift
import '../../../Services/Encryption/KeyManagementService' // src/ios/AmiraWellness/AmiraWellness/Services/Encryption/KeyManagementService.swift
import '../../../Services/Storage/SecureStorageService' // src/ios/AmiraWellness/AmiraWellness/Services/Storage/SecureStorageService.swift
import '../../../Services/Storage/StorageService' // src/ios/AmiraWellness/AmiraWellness/Services/Storage/StorageService.swift
import '../../../Core/Utilities/BiometricAuthManager' // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/BiometricAuthManager.swift
import '../../../Core/Utilities/UserDefaultsManager' // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/UserDefaultsManager.swift
import '../../../Services/Authentication/AuthService' // src/ios/AmiraWellness/AmiraWellness/Services/Authentication/AuthService.swift
import '../../../Core/Constants/AppConstants' // src/ios/AmiraWellness/AmiraWellness/Core/Constants/AppConstants.swift
import '../../../Core/Utilities/Logger' // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Logger.swift

/// Defines possible errors that can occur during privacy settings operations
enum PrivacySettingsError: Error {
    case biometricEnableFailed
    case biometricDisableFailed
    case encryptionKeyGenerationFailed
    case dataDeleteFailed
    case accountDeleteFailed
}

/// Defines the types of data that can be deleted from the application
enum DataDeletionType: String, CaseIterable {
    case journals
    case emotionalData
    case toolUsage
    case progress
    case all
}

/// A view model that manages privacy settings for the Amira Wellness application
@ObservableObject
class PrivacySettingsViewModel {
    /// Indicates if biometric authentication is available on the device
    @Published var isBiometricAuthAvailable: Bool

    /// The type of biometric authentication available (e.g., Face ID, Touch ID)
    @Published var biometricType: BiometricAuthManager.BiometricType

    /// Indicates if biometric authentication is enabled for encryption
    @Published var isBiometricAuthEnabled: Bool

    /// Indicates if encryption is enabled for sensitive data
    @Published var isEncryptionEnabled: Bool

    /// The selected type of data to delete
    @Published var selectedDataDeletionType: DataDeletionType = .journals

    /// Indicates if the data deletion confirmation dialog is shown
    @Published var showDeleteConfirmation: Bool = false

    /// Indicates if the account deletion confirmation dialog is shown
    @Published var showAccountDeletionConfirmation: Bool = false

    /// Indicates if a background process is currently running
    @Published var isProcessing: Bool = false

    /// Indicates if an error alert should be shown
    @Published var showErrorAlert: Bool = false

    /// The error message to display in the error alert
    @Published var errorMessage: String = ""

    /// Indicates if a success alert should be shown
    @Published var showSuccessAlert: Bool = false

    /// The success message to display in the success alert
    @Published var successMessage: String = ""

    /// Service for encryption and decryption operations
    private let encryptionService: EncryptionService

    /// Service for managing encryption keys
    private let keyManagementService: KeyManagementService

    /// Service for managing secure storage operations
    private let secureStorageService: SecureStorageService

    /// Service for managing general storage operations
    private let storageService: StorageService

    /// Manager for biometric authentication
    private let biometricAuthManager: BiometricAuthManager

    /// Manager for UserDefaults storage
    private let userDefaultsManager: UserDefaultsManager

    /// Service for handling account deletion
    private let authService: AuthService

    /// Logger for privacy-related operations
    private let logger: Logger

    /// Set to store Combine cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()

    /// Initializes the privacy settings view model with dependencies
    /// - Parameters:
    ///   - encryptionService: Encryption service (optional, defaults to shared instance)
    ///   - keyManagementService: Key management service (optional, defaults to shared instance)
    ///   - secureStorageService: Secure storage service (optional, defaults to shared instance)
    ///   - storageService: Storage service (optional, defaults to shared instance)
    ///   - biometricAuthManager: Biometric authentication manager (optional, defaults to shared instance)
    ///   - userDefaultsManager: UserDefaults manager (optional, defaults to shared instance)
    ///   - authService: Authentication service (optional, defaults to shared instance)
    ///   - logger: Logger (optional, defaults to shared instance)
    init(
        encryptionService: EncryptionService? = nil,
        keyManagementService: KeyManagementService? = nil,
        secureStorageService: SecureStorageService? = nil,
        storageService: StorageService? = nil,
        biometricAuthManager: BiometricAuthManager? = nil,
        userDefaultsManager: UserDefaultsManager? = nil,
        authService: AuthService? = nil,
        logger: Logger? = nil
    ) {
        // Initialize encryptionService with provided service or EncryptionService.shared
        self.encryptionService = encryptionService ?? EncryptionService.shared

        // Initialize keyManagementService with provided service or KeyManagementService.shared
        self.keyManagementService = keyManagementService ?? KeyManagementService.shared

        // Initialize secureStorageService with provided service or SecureStorageService.shared
        self.secureStorageService = secureStorageService ?? SecureStorageService.shared

        // Initialize storageService with provided service or StorageService.shared
        self.storageService = storageService ?? StorageService.shared

        // Initialize biometricAuthManager with provided manager or BiometricAuthManager.shared
        self.biometricAuthManager = biometricAuthManager ?? BiometricAuthManager.shared

        // Initialize userDefaultsManager with provided manager or UserDefaultsManager.shared
        self.userDefaultsManager = userDefaultsManager ?? UserDefaultsManager.shared

        // Initialize authService with provided service or AuthService.shared
        self.authService = authService ?? AuthService.shared

        // Initialize logger with provided logger or Logger.shared
        self.logger = logger ?? Logger.shared

        // Initialize cancellables as empty Set<AnyCancellable>()
        self.cancellables = Set<AnyCancellable>()

        // Initialize isBiometricAuthAvailable with biometricAuthManager.canAuthenticate()
        self.isBiometricAuthAvailable = biometricAuthManager?.canAuthenticate() ?? false

        // Initialize biometricType with biometricAuthManager.biometricType()
        self.biometricType = biometricAuthManager?.biometricType() ?? .none

        // Initialize isBiometricAuthEnabled with keyManagementService.isBiometricProtectionEnabled(KeyType.master, AppConstants.Security.encryptionKeyIdentifier)
        self.isBiometricAuthEnabled = keyManagementService?.isBiometricProtectionEnabled(KeyType.master, identifier: AppConstants.Security.encryptionKeyIdentifier) ?? false

        // Initialize isEncryptionEnabled with userDefaultsManager.getBool(AppConstants.UserDefaults.encryptionEnabled, true)
        self.isEncryptionEnabled = userDefaultsManager?.getBool(forKey: AppConstants.UserDefaults.encryptionEnabled, defaultValue: true) ?? true

        // Initialize selectedDataDeletionType with .journals
        self.selectedDataDeletionType = .journals

        // Initialize showDeleteConfirmation with false
        self.showDeleteConfirmation = false

        // Initialize showAccountDeletionConfirmation with false
        self.showAccountDeletionConfirmation = false

        // Initialize isProcessing with false
        self.isProcessing = false

        // Initialize showErrorAlert with false
        self.showErrorAlert = false

        // Initialize errorMessage with empty string
        self.errorMessage = ""

        // Initialize showSuccessAlert with false
        self.showSuccessAlert = false

        // Initialize successMessage with empty string
        self.successMessage = ""
    }

    /// Called when the privacy settings view appears
    func onAppear() {
        // Check biometric authentication availability
        isBiometricAuthAvailable = biometricAuthManager.canAuthenticate()

        // Get current biometric type
        biometricType = biometricAuthManager.biometricType()

        // Check if biometric authentication is enabled for encryption
        isBiometricAuthEnabled = keyManagementService.isBiometricProtectionEnabled(KeyType.master, identifier: AppConstants.Security.encryptionKeyIdentifier)

        // Check if encryption is enabled
        isEncryptionEnabled = userDefaultsManager.getBool(forKey: AppConstants.UserDefaults.encryptionEnabled, defaultValue: true)

        // Log privacy settings screen appearance
        logger.logUserAction("Privacy settings screen appeared")
    }

    /// Toggles biometric authentication for encryption
    func toggleBiometricAuth() {
        // Set isProcessing to true
        isProcessing = true

        // If toggling on, call keyManagementService.enableBiometricProtection
        if isBiometricAuthEnabled {
            keyManagementService.disableBiometricProtection(keyType: .master, identifier: AppConstants.Security.encryptionKeyIdentifier)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    switch completion {
                    case .finished:
                        // Handle success by updating isBiometricAuthEnabled
                        self.isBiometricAuthEnabled = false
                        self.successMessage = "Biometric authentication disabled successfully"
                        self.showSuccessAlert = true
                    case .failure(let error):
                        // Handle error by showing error alert
                        self.errorMessage = "Failed to disable biometric authentication: \(error.localizedDescription)"
                        self.showErrorAlert = true
                    }
                    // Set isProcessing to false
                    self.isProcessing = false
                    // Log biometric authentication toggle result
                    self.logger.logEncryption("Biometric authentication disabled: \(completion)")
                }, receiveValue: { _ in })
                .store(in: &cancellables)
        } else {
            keyManagementService.enableBiometricProtection(keyType: .master, identifier: AppConstants.Security.encryptionKeyIdentifier)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    switch completion {
                    case .finished:
                        // Handle success by updating isBiometricAuthEnabled
                        self.isBiometricAuthEnabled = true
                        self.successMessage = "Biometric authentication enabled successfully"
                        self.showSuccessAlert = true
                    case .failure(let error):
                        // Handle error by showing error alert
                        self.errorMessage = "Failed to enable biometric authentication: \(error.localizedDescription)"
                        self.showErrorAlert = true
                    }
                    // Set isProcessing to false
                    self.isProcessing = false
                    // Log biometric authentication toggle result
                    self.logger.logEncryption("Biometric authentication enabled: \(completion)")
                }, receiveValue: { _ in })
                .store(in: &cancellables)
        }
    }

    /// Toggles encryption for sensitive data
    func toggleEncryption() {
        // Set isProcessing to true
        isProcessing = true

        // If toggling on, generate encryption keys
        if !isEncryptionEnabled {
            generateEncryptionKeys()
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    switch completion {
                    case .finished:
                        // Update isEncryptionEnabled in UserDefaults
                        self.userDefaultsManager.setBool(true, forKey: AppConstants.UserDefaults.encryptionEnabled)
                        self.isEncryptionEnabled = true
                        // Set isProcessing to false
                        self.isProcessing = false
                        // Show success message
                        self.successMessage = "Encryption enabled successfully"
                        self.showSuccessAlert = true
                        // Log encryption toggle result
                        self.logger.logEncryption("Encryption enabled successfully")
                    case .failure(let error):
                        // Set isProcessing to false
                        self.isProcessing = false
                        // Show error alert
                        self.errorMessage = "Failed to enable encryption: \(error.localizedDescription)"
                        self.showErrorAlert = true
                        // Log encryption toggle result
                        self.logger.logEncryption("Failed to enable encryption: \(error.localizedDescription)")
                    }
                }, receiveValue: { _ in })
                .store(in: &cancellables)
        } else {
            // If toggling off, show warning that data will remain encrypted but new data won't be
            // Update isEncryptionEnabled in UserDefaults
            userDefaultsManager.setBool(false, forKey: AppConstants.UserDefaults.encryptionEnabled)
            isEncryptionEnabled = false
            // Set isProcessing to false
            isProcessing = false
            // Show success message
            successMessage = "Encryption disabled. New data will not be encrypted."
            showSuccessAlert = true
            // Log encryption toggle result
            logger.logEncryption("Encryption disabled")
        }
    }

    /// Generates encryption keys for the application
    /// - Returns: Success or error
    func generateEncryptionKeys() -> Future<Void, PrivacySettingsError> {
        return Future { promise in
            // Call encryptionService.generateEncryptionKey with appropriate parameters
            self.encryptionService.generateEncryptionKey(keyIdentifier: AppConstants.Security.encryptionKeyIdentifier)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        // Return success if key generation succeeds
                        promise(.success(()))
                    case .failure:
                        // If key generation fails, return PrivacySettingsError.encryptionKeyGenerationFailed
                        promise(.failure(.encryptionKeyGenerationFailed))
                    }
                }, receiveValue: { _ in })
                .store(in: &cancellables)
            // Log key generation result
            self.logger.logEncryption("Encryption key generation requested")
        }
    }

    /// Shows confirmation dialog for data deletion
    func confirmDataDeletion() {
        // Set showDeleteConfirmation to true
        showDeleteConfirmation = true

        // Log data deletion confirmation shown
        logger.logUserAction("Data deletion confirmation shown")
    }

    /// Deletes selected data type after confirmation
    func deleteData() {
        // Set isProcessing to true
        isProcessing = true

        // Set showDeleteConfirmation to false
        showDeleteConfirmation = false

        // Switch on selectedDataDeletionType to determine what to delete
        switch selectedDataDeletionType {
        case .journals:
            // For journals, clear storage of journal data
            storageService.clearStorage(dataType: .journals)
                .sink(receiveCompletion: deletionCompletionHandler, receiveValue: { _ in })
                .store(in: &cancellables)
        case .emotionalData:
            // For emotionalData, clear storage of emotional data
            storageService.clearStorage(dataType: .emotions)
                .sink(receiveCompletion: deletionCompletionHandler, receiveValue: { _ in })
                .store(in: &cancellables)
        case .toolUsage:
            // For toolUsage, clear storage of tool usage data
            storageService.clearStorage(dataType: .tools)
                .sink(receiveCompletion: deletionCompletionHandler, receiveValue: { _ in })
                .store(in: &cancellables)
        case .progress:
            // For progress, clear storage of progress data
            storageService.clearStorage(dataType: .progress)
                .sink(receiveCompletion: deletionCompletionHandler, receiveValue: { _ in })
                .store(in: &cancellables)
        case .all:
            // For all, clear all user data except account information
            clearAllLocalData()
            deletionCompletionHandler(.finished)
        }
    }

    /// Shows confirmation dialog for account deletion
    func confirmAccountDeletion() {
        // Set showAccountDeletionConfirmation to true
        showAccountDeletionConfirmation = true

        // Log account deletion confirmation shown
        logger.logUserAction("Account deletion confirmation shown")
    }

    /// Deletes user account after confirmation
    func deleteAccount() {
        // Set isProcessing to true
        isProcessing = true

        // Set showAccountDeletionConfirmation to false
        showAccountDeletionConfirmation = false

        // Call authService.deleteAccount
        authService.deleteAccount { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                // Handle success by clearing all local data
                self.clearAllLocalData()
                // Post notification for account deletion completion
                NotificationCenter.default.post(name: .accountDeleted, object: nil)
                // Set isProcessing to false
                self.isProcessing = false
                // Log account deletion result
                self.logger.logUserAction("Account deletion successful")
            case .failure(let error):
                // Handle error by showing error alert
                self.errorMessage = "Failed to delete account: \(error.localizedDescription)"
                self.showErrorAlert = true
                // Set isProcessing to false
                self.isProcessing = false
                // Log account deletion result
                self.logger.error("Account deletion failed: \(error.localizedDescription)")
            }
        }
    }

    /// Clears all local data after account deletion
    func clearAllLocalData() {
        // Clear all storage types using storageService.clearStorage
        storageService.clearStorage(dataType: .journals)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        storageService.clearStorage(dataType: .emotions)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        storageService.clearStorage(dataType: .tools)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        storageService.clearStorage(dataType: .progress)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        storageService.clearStorage(dataType: .preferences)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)

        // Clear user defaults using userDefaultsManager.clearAll
        userDefaultsManager.clearAll()

        // Log local data clearing completion
        logger.logUserAction("Local data cleared after account deletion")
    }

    /// Prepares for navigation to data export screen
    func navigateToDataExport() {
        // Log navigation to data export screen
        logger.logUserAction("Navigated to data export screen")
    }

    /// Gets the display text for the current biometric type
    /// - Returns: Localized biometric type name
    func getBiometricTypeText() -> String {
        // Switch on biometricType to determine appropriate text
        switch biometricType {
        case .faceID:
            // For .faceID, return 'Face ID'
            return "Face ID"
        case .touchID:
            // For .touchID, return 'Touch ID'
            return "Touch ID"
        case .none:
            // For .none, return 'None'
            return "None"
        }
    }

    /// Gets the display text for a data deletion type
    /// - Parameter type: type
    /// - Returns: Localized data deletion type name
    func getDataDeletionTypeText(type: DataDeletionType) -> String {
        // Switch on type to determine appropriate text
        switch type {
        case .journals:
            // For .journals, return 'Voice Journals'
            return "Voice Journals"
        case .emotionalData:
            // For .emotionalData, return 'Emotional Check-ins'
            return "Emotional Check-ins"
        case .toolUsage:
            // For .toolUsage, return 'Tool Usage History'
            return "Tool Usage History"
        case .progress:
            // For .progress, return 'Progress Data'
            return "Progress Data"
        case .all:
            // For .all, return 'All Data'
            return "All Data"
        }
    }

    // MARK: - Private Helpers

    /// Handles the completion of a data deletion operation
    private var deletionCompletionHandler: (Subscribers.Completion<StorageError>) -> Void = { completion in
        switch completion {
        case .finished:
            // Set isProcessing to false
            // Show success message
            // Log data deletion result
            break
        case .failure(let error):
            // Set isProcessing to false
            // Show error alert
            // Log data deletion result
            break
        }
    }
}

// MARK: - Extensions

extension Notification.Name {
    static let accountDeleted = Notification.Name("accountDeleted")
}