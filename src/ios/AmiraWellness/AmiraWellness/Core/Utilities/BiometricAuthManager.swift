//
//  BiometricAuthManager.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // Latest
import LocalAuthentication // Latest

/// Enum representing the types of biometric authentication available on the device
public enum BiometricType {
    /// No biometric authentication available
    case none
    /// Touch ID is available
    case touchID
    /// Face ID is available
    case faceID
}

/// Enum representing possible errors that can occur during biometric authentication
public enum BiometricError: Error {
    /// Authentication was not successful
    case authenticationFailed
    /// Biometry is not available on this device
    case biometryNotAvailable
    /// No biometrics are enrolled on this device
    case biometryNotEnrolled
    /// User cancelled the authentication
    case userCancelled
    /// Passcode is not set on the device
    case passcodeNotSet
    /// System cancelled authentication
    case systemCancel
    /// App cancelled authentication
    case appCancel
    /// Invalid context
    case invalidContext
    /// Not interactive
    case notInteractive
    /// Unknown error
    case unknown
}

/// A manager class that provides a wrapper around the LocalAuthentication framework
/// to handle biometric authentication (Face ID and Touch ID) in the Amira Wellness app
public final class BiometricAuthManager {
    
    /// Shared instance for singleton access
    public static let shared = BiometricAuthManager()
    
    /// LAContext instance for biometric authentication
    private var context: LAContext
    
    /// Flag indicating if biometric authentication is enabled via feature flags
    private let isFeatureEnabled: Bool
    
    /// Private initializer to enforce singleton pattern
    private init() {
        context = LAContext()
        isFeatureEnabled = UserDefaults.standard.bool(
            forKey: AppConstants.FeatureFlags.biometricAuthentication
        ) || AppConstants.FeatureFlags.defaultFeatureStates[AppConstants.FeatureFlags.biometricAuthentication] ?? true
    }
    
    /// Determines the type of biometric authentication available on the device
    /// - Returns: The type of biometric authentication (none, touchID, or faceID)
    public func biometricType() -> BiometricType {
        guard canAuthenticate() else {
            return .none
        }
        
        switch context.biometryType {
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        default:
            return .none
        }
    }
    
    /// Checks if biometric authentication is available and can be used
    /// - Returns: True if biometric authentication is available and can be used
    public func canAuthenticate() -> Bool {
        // Return false if the feature is disabled
        guard isFeatureEnabled else {
            return false
        }
        
        // Create a fresh context for this check
        let context = LAContext()
        var error: NSError?
        
        // Check if the device supports biometric authentication
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        return canEvaluate
    }
    
    /// Authenticates the user using biometric authentication
    /// - Parameters:
    ///   - reason: The reason for requesting authentication, displayed to the user
    ///   - completion: Completion handler called with the result of authentication
    public func authenticateWithBiometrics(reason: String, completion: @escaping (Result<Bool, BiometricError>) -> Void) {
        // Check if biometric auth is available
        guard canAuthenticate() else {
            completion(.failure(.biometryNotAvailable))
            return
        }
        
        // Reset context to ensure a fresh state
        resetContext()
        
        // Set the reason for authentication
        let localizedReason = reason.isEmpty ? 
            AppConstants.Security.biometricAuthenticationReason : 
            reason
        
        // Perform authentication
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: localizedReason) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(.success(true))
                } else if let error = error {
                    let mappedError = self.mapLAErrorToBiometricError(error: error)
                    completion(.failure(mappedError))
                } else {
                    completion(.failure(.unknown))
                }
            }
        }
    }
    
    /// Asynchronously authenticates the user using biometric authentication
    /// - Parameter reason: The reason for requesting authentication, displayed to the user
    /// - Returns: True if authentication was successful
    /// - Throws: BiometricError if authentication fails
    @available(iOS 15.0, *)
    public func authenticateWithBiometricsAsync(reason: String) async throws -> Bool {
        // Check if biometric auth is available
        guard canAuthenticate() else {
            throw BiometricError.biometryNotAvailable
        }
        
        // Reset context to ensure a fresh state
        resetContext()
        
        // Set the reason for authentication
        let localizedReason = reason.isEmpty ? 
            AppConstants.Security.biometricAuthenticationReason : 
            reason
        
        do {
            // Perform authentication with async/await
            return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: localizedReason)
        } catch {
            // Map LA error to our BiometricError
            throw mapLAErrorToBiometricError(error: error)
        }
    }
    
    /// Provides a user-friendly description for biometric authentication errors
    /// - Parameter error: The BiometricError to describe
    /// - Returns: A user-friendly error description
    public func getBiometricErrorDescription(error: BiometricError) -> String {
        let biometricType = self.biometricType()
        let biometricName = biometricType == .faceID ? "Face ID" : "Touch ID"
        
        switch error {
        case .authenticationFailed:
            return "\(biometricName) no reconoció tu identidad. Por favor, intenta de nuevo."
        case .biometryNotAvailable:
            return "\(biometricName) no está disponible en este dispositivo."
        case .biometryNotEnrolled:
            return "No tienes \(biometricName) configurado en este dispositivo. Por favor, configúralo en los ajustes."
        case .passcodeNotSet:
            return "Necesitas configurar un código de acceso para usar \(biometricName)."
        case .userCancelled:
            return "Autenticación cancelada."
        case .systemCancel:
            return "El sistema canceló la autenticación."
        case .appCancel:
            return "La aplicación canceló la autenticación."
        case .invalidContext:
            return "Error de autenticación: Contexto inválido."
        case .notInteractive:
            return "La autenticación requiere interacción del usuario."
        case .unknown:
            return "Ocurrió un error desconocido durante la autenticación."
        }
    }
    
    /// Maps LAError to BiometricError for consistent error handling
    /// - Parameter error: The error from Local Authentication framework
    /// - Returns: The corresponding BiometricError
    private func mapLAErrorToBiometricError(error: Error) -> BiometricError {
        guard let laError = error as? LAError else {
            return .unknown
        }
        
        switch laError.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancelled
        case .userFallback:
            return .userCancelled
        case .systemCancel:
            return .systemCancel
        case .appCancel:
            return .appCancel
        case .invalidContext:
            return .invalidContext
        case .notInteractive:
            return .notInteractive
        case .biometryNotAvailable:
            return .biometryNotAvailable
        case .biometryNotEnrolled:
            return .biometryNotEnrolled
        case .passcodeNotSet:
            return .passcodeNotSet
        default:
            return .unknown
        }
    }
    
    /// Resets the LAContext to ensure a fresh state for authentication
    private func resetContext() {
        context = LAContext()
    }
}