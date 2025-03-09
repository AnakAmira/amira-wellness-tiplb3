#if os(iOS)
import SwiftUI
import Combine

// Internal imports
import ProgressDashboardViewModel
import EmotionTrendChart
import StreakChart
import ActivityBarChart
import AchievementCard
import LoadingView
import ErrorView
import ColorConstants
import View_Extensions

/// A SwiftUI view that displays the progress dashboard screen in the Amira Wellness application,
/// showing emotional trends, streak information, achievements, and activity data to help users
/// track their emotional wellness journey.
struct ProgressDashboardView: View {
    
    /// The view model that provides data and business logic for the progress dashboard screen.
    @ObservedObject var viewModel: ProgressDashboardViewModel
    
    /// A state variable to control the refreshing of data.
    @State private var isRefreshing: Bool = false
    
    /// A state variable to track the selected period index for emotional trends.
    @State private var selectedPeriodIndex: Int = 0
    
    /// An optional closure to handle navigation to the detailed emotional trends view.
    var onNavigateToEmotionalTrends: (() -> Void)?
    
    /// An optional closure to handle navigation to the achievements view.
    var onNavigateToAchievements: (() -> Void)?
    
    /// Initializes the ProgressDashboardView with a view model and navigation handlers.
    /// - Parameters:
    ///   - viewModel: The view model to use for data access.
    ///   - onNavigateToEmotionalTrends: An optional closure to handle navigation to the emotional trends view.
    ///   - onNavigateToAchievements: An optional closure to handle navigation to the achievements view.
    init(
        viewModel: ProgressDashboardViewModel,
        onNavigateToEmotionalTrends: (() -> Void)? = nil,
        onNavigateToAchievements: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onNavigateToEmotionalTrends = onNavigateToEmotionalTrends
        self.onNavigateToAchievements = onNavigateToAchievements
        _isRefreshing = State(initialValue: false)
        _selectedPeriodIndex = State(initialValue: 0)
    }
    
    /// Builds the view hierarchy for the progress dashboard screen.
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack {
                        streakSection()
                        emotionalTrendsSection()
                        achievementsSection()
                        activitySummarySection()
                    }
                    .padding(.bottom)
                }
                .refreshable {
                    await handleRefresh()
                }
                .navigationTitle("Mi Progreso")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.loadData()
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                .onAppear {
                    viewModel.loadData()
                }
                
                if viewModel.isLoading {
                    LoadingView(isLoading: viewModel.isLoading)
                }
                
                if !viewModel.errorMessage.isEmpty {
                    ErrorView(message: viewModel.errorMessage) {
                        viewModel.loadData()
                    }
                }
            }
        }
    }
    
    /// Creates the section displaying streak information and progress.
    private func streakSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Racha actual")
            
            HStack {
                Text("Current Streak: \(viewModel.getFormattedStreak())")
                    .font(.headline)
                    .foregroundColor(ColorConstants.textPrimary)
                
                Spacer()
            }
            
            StreakChart(
                currentStreak: viewModel.currentStreak,
                nextMilestone: viewModel.nextMilestone,
                progress: viewModel.streakProgress
            )
            
            Text(viewModel.getFormattedNextMilestone())
                .font(.subheadline)
                .foregroundColor(ColorConstants.textSecondary)
        }
        .cardStyle()
    }
    
    /// Creates the section displaying emotional trend data and charts.
    private func emotionalTrendsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: "Tendencias emocionales", actionText: "Ver más") {
                    navigateToEmotionalTrends()
                }
                
                Picker("Periodo", selection: $selectedPeriodIndex) {
                    Text("Semanal").tag(0)
                    Text("Mensual").tag(1)
                }
                .onChange(of: selectedPeriodIndex) { _ in
                    periodTypeChanged()
                }
                .pickerStyle(.segmented)
            }
            
            if !viewModel.emotionalTrends.isEmpty {
                ForEach(viewModel.emotionalTrends.prefix(2), id: \.emotionType) { trend in
                    EmotionTrendChart(trend: trend)
                }
            } else {
                Text("No hay suficientes datos para mostrar tendencias emocionales.")
                    .foregroundColor(ColorConstants.textSecondary)
                    .italic()
            }
        }
        .cardStyle()
    }
    
    /// Creates the section displaying recent achievements and progress.
    private func achievementsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: "Logros", actionText: "Ver todos") {
                    navigateToAchievements()
                }
            }
            
            if !viewModel.earnedAchievements.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(viewModel.earnedAchievements.prefix(3), id: \.id) { achievement in
                            AchievementCard(achievement: achievement)
                        }
                    }
                }
            } else {
                Text("Aún no has desbloqueado ningún logro. ¡Explora la app para comenzar!")
                    .foregroundColor(ColorConstants.textSecondary)
                    .italic()
            }
        }
        .cardStyle()
    }
    
    /// Creates the section displaying weekly activity data in a bar chart.
    private func activitySummarySection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Actividad semanal")
            
            ActivityBarChart(activityData: Dictionary(uniqueKeysWithValues: viewModel.activitySummary.map { (key, value) in
                (key.toString(format: "E"), Double(value))
            }))
        }
        .cardStyle()
    }
    
    /// Creates a consistent header for dashboard sections.
    /// - Parameters:
    ///   - title: The title of the section.
    ///   - actionText: The text for the action button (optional).
    ///   - action: The action to perform when the button is tapped (optional).
    private func sectionHeader(title: String, actionText: String? = nil, action: (() -> Void)? = nil) -> some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(ColorConstants.textPrimary)
            
            Spacer()
            
            if let actionText = actionText, let action = action {
                Button(action: action) {
                    Text(actionText)
                        .font(.subheadline)
                        .foregroundColor(ColorConstants.primary)
                }
            }
        }
    }
    
    /// Handles the pull-to-refresh action.
    private func handleRefresh() async {
        isRefreshing = true
        viewModel.loadData()
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isRefreshing = false
    }
    
    /// Navigates to the detailed emotional trends view.
    private func navigateToEmotionalTrends() {
        onNavigateToEmotionalTrends?()
    }
    
    /// Navigates to the achievements view.
    private func navigateToAchievements() {
        onNavigateToAchievements?()
    }
    
    /// Handles changes to the selected period type.
    private func periodTypeChanged() {
        switch selectedPeriodIndex {
        case 0:
            viewModel.changePeriodType(newPeriodType: .weekly)
        case 1:
            viewModel.changePeriodType(newPeriodType: .monthly)
        default:
            viewModel.changePeriodType(newPeriodType: .weekly)
        }
    }
}
#endif