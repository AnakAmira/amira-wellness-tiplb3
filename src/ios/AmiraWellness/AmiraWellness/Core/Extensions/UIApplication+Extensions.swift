//
//  UIApplication+Extensions.swift
//  AmiraWellness
//
//  Created for Amira Wellness app
//  Copyright © 2023 Amira Wellness. All rights reserved.
//

import UIKit // Version: iOS SDK
import SwiftUI // Version: iOS SDK

extension UIApplication {
    
    /// Dismisses the keyboard by resigning first responder
    /// This is a convenient method to dismiss the keyboard from anywhere in the app
    static func dismissKeyboard() {
        // Get the key window and send the resignFirstResponder action
        // This will cause any active text field or view to resign first responder and dismiss the keyboard
        guard let window = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first else { return }
        window.endEditing(true)
    }
    
    /// Opens the app's settings page in the Settings app
    /// - Parameter completion: Callback that indicates whether the settings page was successfully opened
    static func openAppSettings(completion: @escaping (Bool) -> Void) {
        // Create a URL using the settings URL string
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            completion(false)
            return
        }
        
        // Check if the URL can be opened
        if UIApplication.shared.canOpenURL(settingsURL) {
            // Open the settings URL and call the completion handler with the result
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: completion)
        } else {
            // Cannot open the URL, call completion with false
            completion(false)
        }
    }
    
    /// Returns the topmost view controller in the application's window hierarchy
    /// Useful for presenting alerts or other view controllers from anywhere in the app
    static func topViewController() -> UIViewController? {
        // Get the key window
        guard let keyWindow = mainKeyWindow else { return nil }
        
        // Get root view controller
        guard var topController = keyWindow.rootViewController else { return nil }
        
        // Loop through presented view controllers to find the topmost one
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        // Handle navigation controllers
        if let navigationController = topController as? UINavigationController {
            if let visibleViewController = navigationController.visibleViewController {
                return visibleViewController
            }
            return navigationController
        }
        
        // Handle tab bar controllers
        if let tabBarController = topController as? UITabBarController {
            if let selectedViewController = tabBarController.selectedViewController {
                return selectedViewController
            }
            return tabBarController
        }
        
        return topController
    }
    
    /// Checks if the keyboard is currently displayed
    static var isKeyboardPresented: Bool {
        // Check if any window has a view that is first responder
        // This is a common way to determine if the keyboard is visible
        if #available(iOS 15.0, *) {
            return UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .filter { $0.isKeyWindow }
                .first?.firstResponder != nil
        } else {
            return UIApplication.shared.windows
                .filter { $0.isKeyWindow }
                .first?.firstResponder != nil
        }
    }
    
    /// Returns the main key window of the application
    static var mainKeyWindow: UIWindow? {
        // iOS 13+ uses window scenes
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow && $0.isHidden == false }
        } else {
            // For iOS 12 and earlier
            return UIApplication.shared.windows.first { $0.isKeyWindow && $0.isHidden == false }
        }
    }
}

// MARK: - UIWindow Extension for First Responder
extension UIWindow {
    /// Returns the current first responder if available
    var firstResponder: UIView? {
        guard let rootViewController = self.rootViewController else { return nil }
        return rootViewController.view.firstResponder()
    }
}

// MARK: - UIView Extension for First Responder
extension UIView {
    /// Recursively finds the first responder in the view hierarchy
    func firstResponder() -> UIView? {
        // If this view is first responder, return self
        if self.isFirstResponder {
            return self
        }
        
        // Otherwise, recursively search through subviews
        for subview in self.subviews {
            if let firstResponder = subview.firstResponder() {
                return firstResponder
            }
        }
        
        return nil
    }
}