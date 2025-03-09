//
//  OnboardingViewModel.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // Latest
import Combine // Latest
import SwiftUI // Latest

/// Enum representing the different pages in the onboarding flow
enum OnboardingPage: Int, CaseIterable {
    case welcome
    case privacy
    case voiceJournaling
    case emotionalCheckins
    case toolLibrary
}

/// A view model that manages the state and business logic for the onboarding flow
@MainActor
class OnboardingViewModel: ObservableObject {
    /// The current page in the onboarding flow
    @Published var currentPage: OnboardingPage = .welcome
    
    /// Handler to be called when onboarding is completed
    private let onboardingCompletedHandler: () -> Void
    
    /// Set of cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Initializes the OnboardingViewModel with a completion handler
    /// - Parameter onboardingCompletedHandler: The closure to be called when onboarding is completed
    init(onboardingCompletedHandler: @escaping () -> Void) {
        self.onboardingCompletedHandler = onboardingCompletedHandler
        Logger.shared.debug("OnboardingViewModel initialized")
    }
    
    /// Advances to the next onboarding page or completes onboarding if on the last page
    func nextPage() {
        if isLastPage() {
            completeOnboarding()
        } else {
            let nextPageIndex = currentPage.rawValue + 1
            if let nextPage = OnboardingPage(rawValue: nextPageIndex) {
                currentPage = nextPage
                Logger.shared.logUserAction("Navigated to onboarding page: \(nextPage)")
            }
        }
    }
    
    /// Returns to the previous onboarding page if not on the first page
    func previousPage() {
        let previousPageIndex = currentPage.rawValue - 1
        if previousPageIndex >= 0, let previousPage = OnboardingPage(rawValue: previousPageIndex) {
            currentPage = previousPage
            Logger.shared.logUserAction("Navigated back to onboarding page: \(previousPage)")
        }
    }
    
    /// Skips the remaining onboarding pages and completes the onboarding process
    func skipOnboarding() {
        completeOnboarding()
        Logger.shared.logUserAction("Skipped onboarding flow")
    }
    
    /// Marks onboarding as completed and invokes the completion handler
    private func completeOnboarding() {
        UserDefaultsManager.shared.setBool(true, forKey: AppConstants.UserDefaults.hasCompletedOnboarding)
        onboardingCompletedHandler()
        Logger.shared.logUserAction("Completed onboarding flow")
    }
    
    /// Returns the localized title for the current onboarding page
    func getPageTitle() -> String {
        switch currentPage {
        case .welcome:
            return "Bienvenido a Amira Wellness"
        case .privacy:
            return "Tu privacidad es nuestra prioridad"
        case .voiceJournaling:
            return "Diario de voz"
        case .emotionalCheckins:
            return "Check-ins emocionales"
        case .toolLibrary:
            return "Biblioteca de herramientas"
        }
    }
    
    /// Returns the localized description for the current onboarding page
    func getPageDescription() -> String {
        switch currentPage {
        case .welcome:
            return "Un espacio seguro para expresar tus emociones y desarrollar hábitos de bienestar emocional a través de herramientas accesibles."
        case .privacy:
            return "Tus datos emocionales y grabaciones están protegidos con encriptación de extremo a extremo. Solo tú puedes acceder a tu información personal."
        case .voiceJournaling:
            return "Graba tus pensamientos y emociones con nuestra herramienta de diario de voz. Realiza check-ins emocionales antes y después para rastrear tus cambios emocionales."
        case .emotionalCheckins:
            return "Registra tu estado emocional de forma regular para identificar patrones y recibir recomendaciones personalizadas de herramientas para tu bienestar."
        case .toolLibrary:
            return "Explora nuestra colección de herramientas para la regulación emocional, organizadas por categorías y adaptadas a diferentes estados emocionales."
        }
    }
    
    /// Returns the image asset name for the current onboarding page
    func getPageImageName() -> String {
        switch currentPage {
        case .welcome:
            return "onboarding-welcome"
        case .privacy:
            return "onboarding-privacy"
        case .voiceJournaling:
            return "onboarding-journal"
        case .emotionalCheckins:
            return "onboarding-emotions"
        case .toolLibrary:
            return "onboarding-tools"
        }
    }
    
    /// Calculates the progress through the onboarding flow as a value between 0 and 1
    func getProgressValue() -> Float {
        return Float(currentPage.rawValue + 1) / Float(OnboardingPage.allCases.count)
    }
    
    /// Determines if the current page is the last page in the onboarding flow
    func isLastPage() -> Bool {
        return currentPage == OnboardingPage.allCases.last
    }
}