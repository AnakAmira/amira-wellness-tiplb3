//
//  PermissionManager.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // iOS SDK
import AVFoundation // iOS SDK
import Photos // iOS SDK
import UserNotifications // iOS SDK
import Combine // iOS SDK
import UIKit // iOS SDK
import CoreLocation // iOS SDK

/// Defines the types of device permissions that can be requested
enum PermissionType: String, CaseIterable {
    case microphone
    case camera
    case photoLibrary
    case notification
    case locationWhenInUse
    case locationAlways
}

/// Represents the current status of a permission
enum PermissionStatus {
    case authorized
    case denied
    case notDetermined
    case restricted
    case limited
}

/// Errors that can occur during permission requests
enum PermissionError: Error {
    case notAvailable
    case requestFailed
    case alreadyDenied
    case systemError
}

/// A singleton manager class that handles permission requests and status checking for various device capabilities
class PermissionManager {
    /// Shared instance of PermissionManager (singleton)
    static let shared = PermissionManager()
    
    /// Private logger instance
    private let logger = Logger.shared
    
    /// UserDefaultsManager for tracking permission request history
    private let userDefaultsManager = UserDefaultsManager.shared
    
    /// Dictionary of subjects for publishing permission status updates
    private var permissionSubjects: [PermissionType: PassthroughSubject<PermissionStatus, Never>] = [:]
    
    /// Private initializer for singleton pattern
    private init() {
        logger.debug("PermissionManager initialized", category: .general)
    }
    
    // MARK: - Public Methods
    
    /// Requests a specific permission from the user
    ///
    /// - Parameters:
    ///   - permissionType: The type of permission to request
    ///   - completion: Callback with the result of the permission request
    func requestPermission(permissionType: PermissionType, completion: @escaping (Result<PermissionStatus, PermissionError>) -> Void) {
        checkPermissionStatus(permissionType: permissionType) { status in
            if status == .authorized {
                self.logger.info("Permission \(permissionType.rawValue) already granted", category: .general)
                completion(.success(status))
                return
            }
            
            if status == .denied || status == .restricted {
                self.logger.info("Permission \(permissionType.rawValue) already denied or restricted", category: .general)
                completion(.failure(.alreadyDenied))
                return
            }
            
            switch permissionType {
            case .microphone:
                self.requestMicrophonePermission(completion: completion)
            case .camera:
                self.requestCameraPermission(completion: completion)
            case .photoLibrary:
                self.requestPhotoLibraryPermission(completion: completion)
            case .notification:
                self.requestNotificationPermission(completion: completion)
            case .locationWhenInUse:
                self.requestLocationWhenInUsePermission(completion: completion)
            case .locationAlways:
                self.requestLocationAlwaysPermission(completion: completion)
            }
            
            self.logger.info("Requested permission: \(permissionType.rawValue)", category: .general)
        }
    }
    
    /// Checks the current status of a specific permission
    ///
    /// - Parameters:
    ///   - permissionType: The type of permission to check
    ///   - completion: Callback with the current permission status
    func checkPermissionStatus(permissionType: PermissionType, completion: @escaping (PermissionStatus) -> Void) {
        switch permissionType {
        case .microphone:
            checkMicrophonePermission(completion: completion)
        case .camera:
            checkCameraPermission(completion: completion)
        case .photoLibrary:
            checkPhotoLibraryPermission(completion: completion)
        case .notification:
            checkNotificationPermission(completion: completion)
        case .locationWhenInUse:
            checkLocationWhenInUsePermission(completion: completion)
        case .locationAlways:
            checkLocationAlwaysPermission(completion: completion)
        }
        
        logger.debug("Checking permission status: \(permissionType.rawValue)", category: .general)
    }
    
    /// Returns a publisher that emits permission status updates for a specific permission type
    ///
    /// - Parameter permissionType: The type of permission to monitor
    /// - Returns: A publisher that emits permission status updates
    func permissionStatusPublisher(permissionType: PermissionType) -> AnyPublisher<PermissionStatus, Never> {
        if let subject = permissionSubjects[permissionType] {
            return subject.eraseToAnyPublisher()
        }
        
        let subject = PassthroughSubject<PermissionStatus, Never>()
        permissionSubjects[permissionType] = subject
        
        // Initialize with current status
        checkPermissionStatus(permissionType: permissionType) { status in
            subject.send(status)
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    /// Determines if the app should show a rationale for requesting a permission
    ///
    /// - Parameter permissionType: The type of permission
    /// - Returns: True if rationale should be shown, false otherwise
    func shouldShowPermissionRationale(permissionType: PermissionType) -> Bool {
        let hasRequested = hasRequestedPermission(permissionType: permissionType)
        
        if !hasRequested {
            return false
        }
        
        var isDenied = false
        
        let semaphore = DispatchSemaphore(value: 0)
        checkPermissionStatus(permissionType: permissionType) { status in
            isDenied = (status == .denied)
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 0.1)
        
        return hasRequested && isDenied
    }
    
    /// Opens the app settings page in the Settings app
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            logger.error("Could not create settings URL", category: .general)
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
            logger.info("Opening app settings", category: .general)
        }
    }
    
    // MARK: - Private Methods - Microphone Permission
    
    /// Requests microphone permission from the user
    ///
    /// - Parameter completion: Callback with the result of the permission request
    private func requestMicrophonePermission(completion: @escaping (Result<PermissionStatus, PermissionError>) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            self.markPermissionRequested(permissionType: .microphone)
            
            DispatchQueue.main.async {
                if granted {
                    self.permissionSubjects[.microphone]?.send(.authorized)
                    self.logger.info("Microphone permission granted", category: .audio)
                    completion(.success(.authorized))
                } else {
                    self.permissionSubjects[.microphone]?.send(.denied)
                    self.logger.info("Microphone permission denied", category: .audio)
                    completion(.failure(.requestFailed))
                }
            }
        }
    }
    
    /// Checks the current status of microphone permission
    ///
    /// - Parameter completion: Callback with the current permission status
    private func checkMicrophonePermission(completion: @escaping (PermissionStatus) -> Void) {
        let status: PermissionStatus
        
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            status = .authorized
        case .denied:
            status = .denied
        case .undetermined:
            status = .notDetermined
        @unknown default:
            status = .notDetermined
        }
        
        DispatchQueue.main.async {
            self.logger.debug("Microphone permission status: \(status)", category: .audio)
            completion(status)
        }
    }
    
    // MARK: - Private Methods - Camera Permission
    
    /// Requests camera permission from the user
    ///
    /// - Parameter completion: Callback with the result of the permission request
    private func requestCameraPermission(completion: @escaping (Result<PermissionStatus, PermissionError>) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            self.markPermissionRequested(permissionType: .camera)
            
            DispatchQueue.main.async {
                if granted {
                    self.permissionSubjects[.camera]?.send(.authorized)
                    self.logger.info("Camera permission granted", category: .general)
                    completion(.success(.authorized))
                } else {
                    self.permissionSubjects[.camera]?.send(.denied)
                    self.logger.info("Camera permission denied", category: .general)
                    completion(.failure(.requestFailed))
                }
            }
        }
    }
    
    /// Checks the current status of camera permission
    ///
    /// - Parameter completion: Callback with the current permission status
    private func checkCameraPermission(completion: @escaping (PermissionStatus) -> Void) {
        let status: PermissionStatus
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            status = .authorized
        case .denied:
            status = .denied
        case .notDetermined:
            status = .notDetermined
        case .restricted:
            status = .restricted
        @unknown default:
            status = .notDetermined
        }
        
        DispatchQueue.main.async {
            self.logger.debug("Camera permission status: \(status)", category: .general)
            completion(status)
        }
    }
    
    // MARK: - Private Methods - Photo Library Permission
    
    /// Requests photo library permission from the user
    ///
    /// - Parameter completion: Callback with the result of the permission request
    private func requestPhotoLibraryPermission(completion: @escaping (Result<PermissionStatus, PermissionError>) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            self.markPermissionRequested(permissionType: .photoLibrary)
            
            DispatchQueue.main.async {
                let permissionStatus = self.convertPhotoAuthorizationStatus(status)
                self.permissionSubjects[.photoLibrary]?.send(permissionStatus)
                
                if permissionStatus == .authorized || permissionStatus == .limited {
                    self.logger.info("Photo library permission granted: \(permissionStatus)", category: .general)
                    completion(.success(permissionStatus))
                } else {
                    self.logger.info("Photo library permission denied: \(permissionStatus)", category: .general)
                    completion(.failure(.requestFailed))
                }
            }
        }
    }
    
    /// Checks the current status of photo library permission
    ///
    /// - Parameter completion: Callback with the current permission status
    private func checkPhotoLibraryPermission(completion: @escaping (PermissionStatus) -> Void) {
        let status = convertPhotoAuthorizationStatus(PHPhotoLibrary.authorizationStatus())
        
        DispatchQueue.main.async {
            self.logger.debug("Photo library permission status: \(status)", category: .general)
            completion(status)
        }
    }
    
    private func convertPhotoAuthorizationStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .limited:
            return .limited
        @unknown default:
            return .notDetermined
        }
    }
    
    // MARK: - Private Methods - Notification Permission
    
    /// Requests notification permission from the user
    ///
    /// - Parameter completion: Callback with the result of the permission request
    private func requestNotificationPermission(completion: @escaping (Result<PermissionStatus, PermissionError>) -> Void) {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            self.markPermissionRequested(permissionType: .notification)
            
            DispatchQueue.main.async {
                if let error = error {
                    self.logger.error("Notification permission request error", error: error, category: .general)
                    completion(.failure(.systemError))
                    return
                }
                
                if granted {
                    self.permissionSubjects[.notification]?.send(.authorized)
                    self.logger.info("Notification permission granted", category: .general)
                    completion(.success(.authorized))
                } else {
                    self.permissionSubjects[.notification]?.send(.denied)
                    self.logger.info("Notification permission denied", category: .general)
                    completion(.failure(.requestFailed))
                }
            }
        }
    }
    
    /// Checks the current status of notification permission
    ///
    /// - Parameter completion: Callback with the current permission status
    private func checkNotificationPermission(completion: @escaping (PermissionStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let status: PermissionStatus
            
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                status = .authorized
            case .denied:
                status = .denied
            case .notDetermined:
                status = .notDetermined
            @unknown default:
                status = .notDetermined
            }
            
            DispatchQueue.main.async {
                self.logger.debug("Notification permission status: \(status)", category: .general)
                completion(status)
            }
        }
    }
    
    // MARK: - Private Methods - Location Permission
    
    /// Requests location when in use permission from the user
    ///
    /// - Parameter completion: Callback with the result of the permission request
    private func requestLocationWhenInUsePermission(completion: @escaping (Result<PermissionStatus, PermissionError>) -> Void) {
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        
        markPermissionRequested(permissionType: .locationWhenInUse)
        
        // Location permission happens asynchronously, so we'll check after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkLocationWhenInUsePermission { status in
                self.permissionSubjects[.locationWhenInUse]?.send(status)
                
                if status == .authorized {
                    self.logger.info("Location when in use permission granted", category: .general)
                    completion(.success(status))
                } else if status == .denied || status == .restricted {
                    self.logger.info("Location when in use permission denied", category: .general)
                    completion(.failure(.requestFailed))
                } else {
                    self.logger.info("Location when in use permission status: \(status)", category: .general)
                    completion(.failure(.requestFailed))
                }
            }
        }
    }
    
    /// Checks the current status of location when in use permission
    ///
    /// - Parameter completion: Callback with the current permission status
    private func checkLocationWhenInUsePermission(completion: @escaping (PermissionStatus) -> Void) {
        let status: PermissionStatus
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            status = .authorized
        case .denied:
            status = .denied
        case .notDetermined:
            status = .notDetermined
        case .restricted:
            status = .restricted
        @unknown default:
            status = .notDetermined
        }
        
        DispatchQueue.main.async {
            self.logger.debug("Location when in use permission status: \(status)", category: .general)
            completion(status)
        }
    }
    
    /// Requests location always permission from the user
    ///
    /// - Parameter completion: Callback with the result of the permission request
    private func requestLocationAlwaysPermission(completion: @escaping (Result<PermissionStatus, PermissionError>) -> Void) {
        let locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        
        markPermissionRequested(permissionType: .locationAlways)
        
        // Location permission happens asynchronously, so we'll check after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkLocationAlwaysPermission { status in
                self.permissionSubjects[.locationAlways]?.send(status)
                
                if status == .authorized {
                    self.logger.info("Location always permission granted", category: .general)
                    completion(.success(status))
                } else if status == .denied || status == .restricted {
                    self.logger.info("Location always permission denied", category: .general)
                    completion(.failure(.requestFailed))
                } else {
                    self.logger.info("Location always permission status: \(status)", category: .general)
                    completion(.failure(.requestFailed))
                }
            }
        }
    }
    
    /// Checks the current status of location always permission
    ///
    /// - Parameter completion: Callback with the current permission status
    private func checkLocationAlwaysPermission(completion: @escaping (PermissionStatus) -> Void) {
        let status: PermissionStatus
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            status = .authorized
        case .authorizedWhenInUse:
            status = .limited // Using limited to indicate "when in use" instead of "always"
        case .denied:
            status = .denied
        case .notDetermined:
            status = .notDetermined
        case .restricted:
            status = .restricted
        @unknown default:
            status = .notDetermined
        }
        
        DispatchQueue.main.async {
            self.logger.debug("Location always permission status: \(status)", category: .general)
            completion(status)
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Marks a permission as having been requested
    ///
    /// - Parameter permissionType: The type of permission
    private func markPermissionRequested(permissionType: PermissionType) {
        let key = "permission_requested_\(permissionType.rawValue)"
        userDefaultsManager.setBool(true, forKey: key)
        logger.debug("Marked permission as requested: \(permissionType.rawValue)", category: .general)
    }
    
    /// Checks if a permission has been requested before
    ///
    /// - Parameter permissionType: The type of permission
    /// - Returns: True if the permission has been requested, false otherwise
    private func hasRequestedPermission(permissionType: PermissionType) -> Bool {
        let key = "permission_requested_\(permissionType.rawValue)"
        return userDefaultsManager.getBool(forKey: key, defaultValue: false)
    }
}