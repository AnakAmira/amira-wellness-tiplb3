import SwiftUI // Latest
import Combine // Latest

// Internal imports
import HomeView // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Home/HomeView.swift
import JournalListView // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Journal/JournalListView.swift
import ToolLibraryView // src/ios/AmiraWellness/AmiraWellness/UI/Screens/ToolLibrary/ToolLibraryView.swift
import ProgressDashboardView // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Progress/ProgressDashboardView.swift
import ProfileView // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Profile/ProfileView.swift
import HomeViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Home/HomeViewModel.swift
import JournalListViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Journal/JournalListViewModel.swift
import ToolLibraryViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/ToolLibrary/ToolLibraryViewModel.swift
import ProgressDashboardViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Progress/ProgressDashboardViewModel.swift
import ProfileViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Profile/ProfileViewModel.swift
import ColorConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ColorConstants.swift
import DIContainer // src/ios/AmiraWellness/AmiraWellness/Core/DI/DIContainer.swift

/// A SwiftUI view that implements the main tab navigation for the Amira Wellness application
struct MainTabView: View {
    /// Observed object for managing tab navigation state
    @ObservedObject var router: TabNavigationProtocol
    /// Private state for tracking the selected tab
    @State private var selectedTab: Int

    /// Initializes the MainTabView with a navigation router
    /// - Parameter router: The navigation router for tab selection
    init(router: TabNavigationProtocol) {
        self.router = router // Store the provided router
        _selectedTab = State(initialValue: router.selectedTab) // Initialize selectedTab to router.selectedTab
    }

    /// Builds the main tab view with all primary navigation tabs
    var body: some View {
        TabView(selection: $selectedTab) { // Create a TabView bound to selectedTab
            makeHomeView() // Add HomeView as the first tab with a house icon and "Inicio" label
            makeJournalListView() // Add JournalListView as the second tab with a journal icon and "Diarios" label
            makeToolLibraryView() // Add ToolLibraryView as the third tab with a toolbox icon and "Herramientas" label
            makeProgressDashboardView() // Add ProgressDashboardView as the fourth tab with a chart icon and "Progreso" label
            makeProfileView() // Add ProfileView as the fifth tab with a person icon and "Perfil" label
        }
        .onChange(of: selectedTab) { newTab in // Set up a binding between selectedTab and router.selectedTab
            router.selectedTab = newTab
        }
        .background(ColorConstants.background) // Apply the app's background color to the TabView
    }

    /// Creates the home view with appropriate dependencies
    /// - Returns: The configured home view
    private func makeHomeView() -> some View {
        let homeViewModel = DIContainer.shared.homeViewModel() // Create a HomeViewModel using DIContainer
        return HomeView(viewModel: homeViewModel) // Create a HomeView with the view model
            .environmentObject(router) // Inject the router as an environment object
            .tabItem { // Apply tab item styling with house icon and "Inicio" label
                Image(systemName: "house")
                Text("Inicio")
            }
            .tag(0)
    }

    /// Creates the journal list view with appropriate dependencies
    /// - Returns: The configured journal list view
    private func makeJournalListView() -> some View {
        let journalListViewModel = DIContainer.shared.journalListViewModel() // Create a JournalListViewModel using DIContainer
        return JournalListView(viewModel: journalListViewModel) // Create a JournalListView with the view model
            .environmentObject(router) // Inject the router as an environment object
            .tabItem { // Apply tab item styling with journal icon and "Diarios" label
                Image(systemName: "book")
                Text("Diarios")
            }
            .tag(1)
    }

    /// Creates the tool library view with appropriate dependencies
    /// - Returns: The configured tool library view
    private func makeToolLibraryView() -> some View {
        let toolLibraryViewModel = DIContainer.shared.toolLibraryViewModel() // Create a ToolLibraryViewModel using DIContainer
        return ToolLibraryView(viewModel: toolLibraryViewModel) // Create a ToolLibraryView with the view model
            .environmentObject(router) // Inject the router as an environment object
            .tabItem { // Apply tab item styling with toolbox icon and "Herramientas" label
                Image(systemName: "toolbox.horizontal")
                Text("Herramientas")
            }
            .tag(2)
    }

    /// Creates the progress dashboard view with appropriate dependencies
    /// - Returns: The configured progress dashboard view
    private func makeProgressDashboardView() -> some View {
        let progressDashboardViewModel = DIContainer.shared.progressDashboardViewModel() // Create a ProgressDashboardViewModel using DIContainer
        return ProgressDashboardView(viewModel: progressDashboardViewModel) // Create a ProgressDashboardView with the view model
            .environmentObject(router) // Inject the router as an environment object
            .tabItem { // Apply tab item styling with chart icon and "Progreso" label
                Image(systemName: "chart.bar")
                Text("Progreso")
            }
            .tag(3)
    }

    /// Creates the profile view with appropriate dependencies
    /// - Returns: The configured profile view
    private func makeProfileView() -> some View {
        let profileViewModel = DIContainer.shared.profileViewModel() // Create a ProfileViewModel using DIContainer
        return ProfileView(viewModel: profileViewModel) // Create a ProfileView with the view model and navigation delegate
            .environmentObject(router) // Inject the router as an environment object
            .tabItem { // Apply tab item styling with person icon and "Perfil" label
                Image(systemName: "person.crop.circle")
                Text("Perfil")
            }
            .tag(4)
    }
}