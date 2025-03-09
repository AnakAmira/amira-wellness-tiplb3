import SwiftUI // Latest
import Combine // Latest

// Internal imports
import HomeViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Home/HomeViewModel.swift
import JournalCard // src/ios/AmiraWellness/AmiraWellness/UI/Components/Cards/JournalCard.swift
import EmotionCard // src/ios/AmiraWellness/AmiraWellness/UI/Components/Cards/EmotionCard.swift
import ToolCard // src/ios/AmiraWellness/AmiraWellness/UI/Components/Cards/ToolCard.swift
import StreakChart // src/ios/AmiraWellness/AmiraWellness/UI/Components/Charts/StreakChart.swift
import PrimaryButton // src/ios/AmiraWellness/AmiraWellness/UI/Components/Buttons/PrimaryButton.swift
import ColorConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ColorConstants.swift

/// The main home screen view for the Amira Wellness application
struct HomeView: View {
    /// Provides data and business logic for the home screen
    @ObservedObject var viewModel: HomeViewModel
    /// Controls the refreshing state of the view
    @State private var isRefreshing: Bool = false
    /// Namespace for matched geometry effect
    @Namespace private var animation

    /// Initializes the HomeView with a view model
    /// - Parameter viewModel: The view model for the home screen
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }

    /// Builds the main view hierarchy for the home screen
    var body: some View {
        ZStack {
            // Show loading indicator when data is loading
            if viewModel.isLoading {
                ProgressView()
                    .centerInScreen()
            } else {
                // Main content in a ScrollView with pull-to-refresh
                ScrollView {
                    mainContentView()
                }
                .refreshable {
                    await handleRefresh()
                }
            }
        }
        .background(ColorConstants.background)
        .navigationTitle("Amira")
        .onAppear {
            viewModel.refreshData()
        }
    }

    /// Creates the main content view with all sections
    private func mainContentView() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            greetingSection()
            emotionalCheckinSection()
            recentActivitiesSection()
            recommendedToolsSection()
            streakSection()
        }
        .padding()
    }

    /// Creates the greeting section with user's name
    private func greetingSection() -> some View {
        VStack(alignment: .leading) {
            Text("Hola, \(viewModel.userName)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(ColorConstants.textPrimary)
                .accessibilityLabel("Hola, \(viewModel.userName)")
        }
        .padding(.bottom, 10)
    }

    /// Creates the emotional check-in prompt section
    private func emotionalCheckinSection() -> some View {
        VStack(alignment: .leading) {
            Text("¿Cómo te sientes hoy?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(ColorConstants.textPrimary)
                .accessibilityLabel("¿Cómo te sientes hoy?")

            PrimaryButton(title: "Hacer check-in emocional", action: {
                viewModel.navigateToEmotionalCheckin()
            })
            .padding(.top, 5)

            if let currentEmotionalState = viewModel.currentEmotionalState {
                EmotionCard(emotionalState: currentEmotionalState, showContext: false, showDate: true)
                    .padding(.top, 10)
            }
        }
    }

    /// Creates the section displaying recent journals and emotional check-ins
    private func recentActivitiesSection() -> some View {
        VStack(alignment: .leading) {
            sectionHeader(title: "Actividades recientes")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(viewModel.recentJournals) { journal in
                        JournalCard(journal: journal, showEmotionalShift: false, showActions: false) {
                            viewModel.navigateToJournalDetail(journalId: journal.id)
                        }
                        .frame(width: 280)
                    }

                    ForEach(viewModel.recentEmotionalCheckins) { checkin in
                        EmotionCard(emotionalState: checkin, showContext: true, showDate: true, showNotes: false)
                            .frame(width: 200)
                    }

                    if viewModel.recentJournals.isEmpty && viewModel.recentEmotionalCheckins.isEmpty {
                        emptyStateView(message: "No hay actividades recientes")
                    }
                }
            }
        }
    }

    /// Creates the section displaying recommended tools
    private func recommendedToolsSection() -> some View {
        VStack(alignment: .leading) {
            sectionHeader(title: "Herramientas recomendadas")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(viewModel.recommendedTools) { tool in
                        ToolCard(tool: tool, isCompact: true, showActions: false) {
                            viewModel.navigateToToolDetail(toolId: tool.id)
                        }
                        .frame(width: 200)
                    }

                    if viewModel.recommendedTools.isEmpty {
                        emptyStateView(message: "No hay herramientas recomendadas")
                    }
                }
            }
        }
    }

    /// Creates the section displaying streak information
    private func streakSection() -> some View {
        VStack(alignment: .leading) {
            Text("Tu racha actual: \(viewModel.currentStreak) días")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(ColorConstants.textPrimary)
                .accessibilityLabel("Tu racha actual: \(viewModel.currentStreak) días")

            StreakChart(currentStreak: viewModel.currentStreak, nextMilestone: viewModel.nextMilestone, progress: viewModel.streakProgress)
                .padding(.vertical, 5)

            Text("Próximo logro: \(viewModel.nextMilestone) días")
                .font(.subheadline)
                .foregroundColor(ColorConstants.textSecondary)
                .accessibilityLabel("Próximo logro: \(viewModel.nextMilestone) días")
        }
    }

    /// Creates a consistent section header with the given title
    /// - Parameter title: The title for the section
    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(ColorConstants.textPrimary)
            Spacer()
        }
        .padding(.bottom, 5)
    }

    /// Creates a view to display when a section has no content
    /// - Parameter message: The message to display
    private func emptyStateView(message: String) -> some View {
        VStack {
            Text(message)
                .font(.body)
                .foregroundColor(ColorConstants.textSecondary)
                .multilineTextAlignment(.center)
                .padding()
                .opacity(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    /// Handles the pull-to-refresh action
    private func handleRefresh() async {
        isRefreshing = true
        viewModel.refreshData()
        try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
        isRefreshing = false
    }
}