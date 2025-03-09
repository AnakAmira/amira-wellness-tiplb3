import SwiftUI // SwiftUI - Latest - Framework for building the user interface
import Foundation // Foundation - Latest - Core iOS framework for fundamental data types

// Internal imports
import DIContainer // src/ios/AmiraWellness/AmiraWellness/Core/DI/DIContainer.swift - Access service instances for dependency injection
import OnboardingViewModel // ../Screens/Onboarding/OnboardingViewModel - Create OnboardingViewModel instances
import OnboardingView // ../Screens/Onboarding/OnboardingView - Create OnboardingView instances
import LoginViewModel // ../Screens/Authentication/LoginViewModel - Create LoginViewModel instances
import LoginView // ../Screens/Authentication/LoginView - Create LoginView instances
import RegisterViewModel // ../Screens/Authentication/RegisterViewModel - Create RegisterViewModel instances
import RegisterView // ../Screens/Authentication/RegisterView - Create RegisterView instances
import ForgotPasswordViewModel // ../Screens/Authentication/ForgotPasswordViewModel - Create ForgotPasswordViewModel instances
import ForgotPasswordView // ../Screens/Authentication/ForgotPasswordView - Create ForgotPasswordView instances
import HomeViewModel // ../Screens/Home/HomeViewModel - Create HomeViewModel instances
import HomeView // ../Screens/Home/HomeView - Create HomeView instances
import JournalListViewModel // ../Screens/Journal/JournalListViewModel - Create JournalListViewModel instances
import JournalListView // ../Screens/Journal/JournalListView - Create JournalListView instances
import JournalDetailViewModel // ../Screens/Journal/JournalDetailViewModel - Create JournalDetailViewModel instances
import JournalDetailView // ../Screens/Journal/JournalDetailView - Create JournalDetailView instances
import RecordJournalViewModel // ../Screens/Journal/RecordJournalViewModel - Create RecordJournalViewModel instances
import RecordJournalView // ../Screens/Journal/RecordJournalView - Create RecordJournalView instances
import EmotionalCheckinViewModel // ../Screens/EmotionalCheckin/EmotionalCheckinViewModel - Create EmotionalCheckinViewModel instances
import EmotionalCheckinView // ../Screens/EmotionalCheckin/EmotionalCheckinView - Create EmotionalCheckinView instances
import EmotionalCheckinResultViewModel // ../Screens/EmotionalCheckin/EmotionalCheckinResultViewModel - Create EmotionalCheckinResultViewModel instances
import EmotionalCheckinResultView // ../Screens/EmotionalCheckin/EmotionalCheckinResultView - Create EmotionalCheckinResultView instances
import ToolLibraryViewModel // ../Screens/ToolLibrary/ToolLibraryViewModel - Create ToolLibraryViewModel instances
import ToolLibraryView // ../Screens/ToolLibrary/ToolLibraryView - Create ToolLibraryView instances
import ToolCategoryViewModel // ../Screens/ToolLibrary/ToolCategoryViewModel - Create ToolCategoryViewModel instances
import ToolCategoryView // ../Screens/ToolLibrary/ToolCategoryView - Create ToolCategoryView instances
import ToolDetailViewModel // ../Screens/ToolLibrary/ToolDetailViewModel - Create ToolDetailViewModel instances
import ToolDetailView // ../Screens/ToolLibrary/ToolDetailView - Create ToolDetailView instances
import ToolInProgressViewModel // ../Screens/ToolLibrary/ToolInProgressViewModel - Create ToolInProgressViewModel instances
import ToolInProgressView // ../Screens/ToolLibrary/ToolInProgressView - Create ToolInProgressView instances
import ToolCompletionViewModel // ../Screens/ToolLibrary/ToolCompletionViewModel - Create ToolCompletionViewModel instances
import ToolCompletionView // ../Screens/ToolLibrary/ToolCompletionView - Create ToolCompletionView instances
import ProgressDashboardViewModel // ../Screens/Progress/ProgressDashboardViewModel - Create ProgressDashboardViewModel instances
import ProgressDashboardView // ../Screens/Progress/ProgressDashboardView - Create ProgressDashboardView instances
import ProfileViewModel // ../Screens/Profile/ProfileViewModel - Create ProfileViewModel instances
import ProfileView // ../Screens/Profile/ProfileView - Create ProfileView instances
import SettingsViewModel // ../Screens/Settings/SettingsViewModel - Create SettingsViewModel instances
import SettingsView // ../Screens/Settings/SettingsView - Create SettingsView instances
import MainTabView // ../Screens/Main/MainTabView - Create MainTabView instances
import EmotionalState // ../../Models/EmotionalState - Used as parameter type for emotional check-in related views

/// A factory class that creates view instances with proper dependencies
class ViewFactory {
    private let container: DIContainer

    /// Initializes the ViewFactory with a dependency container
    /// - Parameter container: The dependency container
    init(container: DIContainer = .shared) {
        self.container = container
    }

    /// Creates an OnboardingView with proper dependencies
    /// - Returns: A configured OnboardingView instance
    func makeOnboardingView(onboardingCompleted: @escaping () -> Void) -> OnboardingView {
        let viewModel = OnboardingViewModel(onboardingCompletedHandler: onboardingCompleted)
        return OnboardingView(viewModel: viewModel, onboardingCompleted: onboardingCompleted)
    }

    /// Creates a LoginView with proper dependencies
    /// - Returns: A configured LoginView instance
    func makeLoginView(onNavigateToRegister: @escaping () -> Void, onNavigateToForgotPassword: @escaping () -> Void, onNavigateToMainTabView: @escaping () -> Void) -> LoginView {
        let authService = container.getAuthService()
        let viewModel = LoginViewModel(authService: authService)
        return LoginView(viewModel: viewModel, onNavigateToRegister: onNavigateToRegister, onNavigateToForgotPassword: onNavigateToForgotPassword, onNavigateToMainTabView: onNavigateToMainTabView)
    }

    /// Creates a RegisterView with proper dependencies
    /// - Returns: A configured RegisterView instance
    func makeRegisterView(onNavigateToLogin: @escaping () -> Void, onRegistrationSuccess: @escaping () -> Void) -> RegisterView {
        let authService = container.getAuthService()
        let viewModel = RegisterViewModel(authService: authService)
        return RegisterView(viewModel: viewModel, onNavigateToLogin: onNavigateToLogin, onRegistrationSuccess: onRegistrationSuccess)
    }

    /// Creates a ForgotPasswordView with proper dependencies
    /// - Returns: A configured ForgotPasswordView instance
    func makeForgotPasswordView(onNavigateToLogin: @escaping () -> Void, onGoBack: @escaping () -> Void) -> ForgotPasswordView {
        let authService = container.getAuthService()
        let viewModel = ForgotPasswordViewModel()
        return ForgotPasswordView(viewModel: viewModel, onNavigateToLogin: onNavigateToLogin, onGoBack: onGoBack)
    }

    /// Creates a HomeView with proper dependencies
    /// - Returns: A configured HomeView instance
    func makeHomeView() -> HomeView {
        let journalService = container.getJournalService()
        let emotionService = container.getEmotionService()
        let toolService = container.getToolService()
        let progressService = container.getProgressService()
        let viewModel = HomeViewModel(journalService: journalService, emotionService: emotionService, toolService: toolService, progressService: progressService)
        return HomeView(viewModel: viewModel)
    }

    /// Creates a JournalListView with proper dependencies
    /// - Returns: A configured JournalListView instance
    func makeJournalListView(navigateToJournalDetailHandler: @escaping (UUID) -> Void, navigateToRecordJournalHandler: @escaping () -> Void) -> JournalListView {
        let journalService = container.getJournalService()
        let viewModel = JournalListViewModel(journalService: journalService, navigateToJournalDetailHandler: navigateToJournalDetailHandler, navigateToRecordJournalHandler: navigateToRecordJournalHandler)
        return JournalListView(viewModel: viewModel)
    }

    /// Creates a JournalDetailView with proper dependencies
    /// - Parameter journalId: The ID of the journal to display
    /// - Returns: A configured JournalDetailView instance
    func makeJournalDetailView(journalId: UUID) -> JournalDetailView {
        let journalService = container.getJournalService()
        let audioPlaybackService = container.getAudioPlaybackService()
        let viewModel = JournalDetailViewModel(journalId: journalId)
        return JournalDetailView(journalId: journalId)
    }

    /// Creates a RecordJournalView with proper dependencies
    /// - Returns: A configured RecordJournalView instance
    func makeRecordJournalView() -> RecordJournalView {
        let journalService = container.getJournalService()
        let audioRecordingService = container.getAudioRecordingService()
        let emotionService = container.getEmotionService()
        let viewModel = RecordJournalViewModel(journalService: journalService, recordingService: audioRecordingService, emotionService: emotionService)
        return RecordJournalView(viewModel: viewModel)
    }

    /// Creates an EmotionalCheckinView with proper dependencies
    /// - Returns: A configured EmotionalCheckinView instance
    func makeEmotionalCheckinView() -> EmotionalCheckinView {
        let emotionService = container.getEmotionService()
        let viewModel = EmotionalCheckinViewModel(emotionService: emotionService)
        return EmotionalCheckinView(viewModel: viewModel)
    }

    /// Creates an EmotionalCheckinResultView with proper dependencies
    /// - Parameter emotionalState: The emotional state to display
    /// - Returns: A configured EmotionalCheckinResultView instance
    func makeEmotionalCheckinResultView(emotionalState: EmotionalState) -> EmotionalCheckinResultView {
        let emotionService = container.getEmotionService()
        let toolService = container.getToolService()
        let viewModel = EmotionalCheckinResultViewModel(currentState: emotionalState, emotionService: emotionService, toolService: toolService)
        return EmotionalCheckinResultView(viewModel: viewModel)
    }

    /// Creates a ToolLibraryView with proper dependencies
    /// - Returns: A configured ToolLibraryView instance
    func makeToolLibraryView() -> ToolLibraryView {
        let toolService = container.getToolService()
        let viewModel = ToolLibraryViewModel(toolService: toolService, navigationDelegate: nil)
        return ToolLibraryView(viewModel: viewModel)
    }

    /// Creates a ToolCategoryView with proper dependencies
    /// - Parameter categoryId: The ID of the category to display
    /// - Returns: A configured ToolCategoryView instance
    func makeToolCategoryView(categoryId: String) -> ToolCategoryView {
        let toolService = container.getToolService()
        let viewModel = ToolCategoryViewModel(category: ToolCategory(rawValue: categoryId)!, toolService: toolService, navigationHandler: nil)
        return ToolCategoryView(viewModel: viewModel)
    }

    /// Creates a ToolDetailView with proper dependencies
    /// - Parameter toolId: The ID of the tool to display
    /// - Returns: A configured ToolDetailView instance
    func makeToolDetailView(toolId: String) -> ToolDetailView {
        let toolService = container.getToolService()
        let viewModel = ToolDetailViewModel(toolId: toolId)
        return ToolDetailView(toolId: toolId, viewModel: viewModel)
    }

    /// Creates a ToolInProgressView with proper dependencies
    /// - Parameter toolId: The ID of the tool to display
    /// - Returns: A configured ToolInProgressView instance
    func makeToolInProgressView(toolId: String) -> ToolInProgressView {
        let toolService = container.getToolService()
        let viewModel = ToolInProgressViewModel(tool: Tool(id: UUID(), name: "Sample Tool", description: "Sample Description", category: ToolCategory.breathing, contentType: ToolContentType.text, content: ToolContent(title: "Sample Content", instructions: "Sample Instructions"), isFavorite: false, usageCount: 0, targetEmotions: [], estimatedDuration: 5, difficulty: ToolDifficulty.beginner))
        return ToolInProgressView(viewModel: viewModel)
    }

    /// Creates a ToolCompletionView with proper dependencies
    /// - Parameter toolId: The ID of the tool to display
    /// - Returns: A configured ToolCompletionView instance
    func makeToolCompletionView(toolId: String) -> ToolCompletionView {
        let toolService = container.getToolService()
        let emotionService = container.getEmotionService()
        let progressService = container.getProgressService()
        let viewModel = ToolCompletionViewModel(completedTool: Tool(id: UUID(), name: "Sample Tool", description: "Sample Description", category: ToolCategory.breathing, contentType: ToolContentType.text, content: ToolContent(title: "Sample Content", instructions: "Sample Instructions"), isFavorite: false, usageCount: 0, targetEmotions: [], estimatedDuration: 5, difficulty: ToolDifficulty.beginner), usageDuration: 10)
        return ToolCompletionView(viewModel: viewModel)
    }

    /// Creates a ProgressDashboardView with proper dependencies
    /// - Returns: A configured ProgressDashboardView instance
    func makeProgressDashboardView() -> ProgressDashboardView {
        let progressService = container.getProgressService()
        let viewModel = ProgressDashboardViewModel(progressService: progressService)
        return ProgressDashboardView(viewModel: viewModel)
    }

    /// Creates a ProfileView with proper dependencies
    /// - Returns: A configured ProfileView instance
    func makeProfileView() -> ProfileView {
        let authService = container.getAuthService()
        let progressService = container.getProgressService()
        let viewModel = ProfileViewModel(authService: authService, journalService: container.getJournalService(), emotionService: container.getEmotionService(), progressService: progressService, apiClient: APIClient.shared)
        return ProfileView(viewModel: viewModel)
    }

    /// Creates a SettingsView with proper dependencies
    /// - Returns: A configured SettingsView instance
    func makeSettingsView() -> SettingsView {
        let authService = container.getAuthService()
        let notificationService = container.getNotificationService()
        let viewModel = SettingsViewModel(authService: authService, notificationManager: notificationService)
        return SettingsView(viewModel: viewModel)
    }
    
    /// Creates a MainTabView with proper dependencies
    /// - Parameter selectedTab: Binding to the selected tab
    /// - Returns: A configured MainTabView instance
    func makeMainTabView(selectedTab: Binding<Int>) -> MainTabView {
        let router = TabNavigationRouter(selectedTab: selectedTab.wrappedValue)
        return MainTabView(router: router)
    }
}