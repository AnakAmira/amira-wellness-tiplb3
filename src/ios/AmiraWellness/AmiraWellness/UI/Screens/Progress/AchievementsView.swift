import SwiftUI // iOS SDK
import struct SwiftUI.View // iOS SDK
import class SwiftUI.StateObject // iOS SDK
import struct SwiftUI.Binding // iOS SDK
import struct SwiftUI.List // iOS SDK
import struct SwiftUI.LazyVGrid // iOS SDK
import struct SwiftUI.GridItem // iOS SDK
import struct SwiftUI.ScrollView // iOS SDK
import struct SwiftUI.HStack // iOS SDK
import struct SwiftUI.VStack // iOS SDK
import struct SwiftUI.Text // iOS SDK
import struct SwiftUI.Image // iOS SDK
import struct SwiftUI.Button // iOS SDK
import struct SwiftUI.Divider // iOS SDK
import struct SwiftUI.GeometryReader // iOS SDK
import struct SwiftUI.ZStack // iOS SDK
import struct SwiftUI.RoundedRectangle // iOS SDK
import struct SwiftUI.ProgressView // iOS SDK
import struct SwiftUI.AsyncImage // iOS SDK
import enum SwiftUI.ContentMode // iOS SDK
import struct SwiftUI.EdgeInsets // iOS SDK
import struct SwiftUI.Group // iOS SDK
import struct SwiftUI.Spacer // iOS SDK
import struct SwiftUI.Environment // iOS SDK
import enum SwiftUI.VerticalAlignment // iOS SDK
import enum SwiftUI.HorizontalAlignment // iOS SDK
import class Combine.AnyCancellable // Latest
import class Combine.PassthroughSubject // Latest

// Internal imports
import class AchievementsViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Progress/AchievementsViewModel.swift
import struct Achievement // src/ios/AmiraWellness/AmiraWellness/Models/Achievement.swift
import enum AchievementCategory // src/ios/AmiraWellness/AmiraWellness/Models/Achievement.swift
import struct AchievementCard // src/ios/AmiraWellness/AmiraWellness/UI/Components/Cards/AchievementCard.swift
import struct LoadingView // src/ios/AmiraWellness/AmiraWellness/UI/Components/Loading/LoadingView.swift
import struct EmptyStateView // src/ios/AmiraWellness/AmiraWellness/UI/Components/Feedback/EmptyStateView.swift
import struct ColorConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ColorConstants.swift

/// A SwiftUI view that displays user achievements and progress
struct AchievementsView: View {
    
    /// Provides data and business logic for the achievements view
    @StateObject var viewModel = AchievementsViewModel()
    
    /// Stores the selected achievement for detailed view
    @State private var selectedAchievement: Achievement? = nil
    
    /// Controls the presentation of the achievement detail sheet
    @State private var showingAchievementDetail = false
    
    /// Controls the refreshing state of the view
    @State private var isRefreshing = false
    
    /// Default initializer for AchievementsView
    init() {
        // Initialize the view with default values
    }
    
    /// Builds the main view hierarchy for the achievements screen
    var body: some View {
        NavigationView {
            ZStack {
                contentView() // Add the main content view with achievements
                
                if viewModel.isLoading { // Add a LoadingView when viewModel.isLoading is true
                    LoadingView(message: "Cargando logros...")
                }
            }
            .navigationTitle("Mis Logros") // Set up navigation title and bar appearance
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.refreshAchievements()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear { // Call viewModel.loadAchievements() when the view appears
                viewModel.loadAchievements()
            }
            .sheet(item: $selectedAchievement) { achievement in // Add a sheet for displaying achievement details
                if let achievement = selectedAchievement {
                    achievementDetailView(achievement: achievement)
                }
            }
        }
    }
    
    /// Creates the main content view with achievements list and filters
    private func contentView() -> some View {
        VStack {
            progressSummaryView() // Add a progress summary section at the top
            
            categoryFiltersView() // Add category filter buttons in a ScrollView
            
            Toggle("Mostrar solo logros obtenidos", isOn: $viewModel.showEarnedOnly) // Add a toggle for showing earned achievements only
                .padding()
            
            if viewModel.filteredAchievements.isEmpty { // Show an EmptyStateView when no achievements are available
                EmptyStateView(message: "No hay logros disponibles en esta categoría.")
            } else {
                achievementsListView() // Add the achievements list grouped by category
            }
        }
        .padding(.bottom) // Apply appropriate styling and spacing
    }
    
    /// Creates a view showing overall achievement progress
    private func progressSummaryView() -> some View {
        VStack(alignment: .leading) {
            Text("Progreso general") // Add a progress bar showing overall completion
                .font(.headline)
                .foregroundColor(ColorConstants.textPrimary)
                .padding(.horizontal)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(ColorConstants.divider)
                        .frame(height: 10)
                    
                    RoundedRectangle(cornerRadius: 5)
                        .fill(ColorConstants.primary)
                        .frame(width: geometry.size.width * CGFloat(viewModel.achievementProgress), height: 10)
                }
            }
            .frame(height: 10)
            .padding(.horizontal)
            
            HStack { // Add text showing earned/total achievements count
                Text("\(viewModel.getEarnedCount())/\(viewModel.getTotalCount()) Logros obtenidos")
                    .font(.subheadline)
                    .foregroundColor(ColorConstants.textSecondary)
                
                Spacer()
                
                Text(viewModel.getFormattedProgress()) // Add a formatted percentage text
                    .font(.subheadline)
                    .foregroundColor(ColorConstants.textSecondary)
            }
            .padding(.horizontal)
        }
        .padding(.top) // Apply appropriate styling and animations
    }
    
    /// Creates a horizontal scrolling view with category filter buttons
    private func categoryFiltersView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button("Todos") { // Add an 'All' button that clears the category filter
                    viewModel.selectCategory(category: nil)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(viewModel.selectedCategory == nil ? ColorConstants.primary : ColorConstants.surface)
                .foregroundColor(viewModel.selectedCategory == nil ? ColorConstants.textOnPrimary : ColorConstants.textPrimary)
                .cornerRadius(10)
                
                ForEach(AchievementCategory.allCases, id: \.self) { category in // Add buttons for each achievement category
                    Button(getCategoryName(category: category)) {
                        viewModel.selectCategory(category: category)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(viewModel.selectedCategory == category ? ColorConstants.primary : ColorConstants.surface) // Style the buttons based on selection state
                    .foregroundColor(viewModel.selectedCategory == category ? ColorConstants.textOnPrimary : ColorConstants.textPrimary)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal) // Apply appropriate spacing and padding
        }
    }
    
    /// Creates a list view of achievements grouped by category
    private func achievementsListView() -> some View {
        ScrollView {
            ForEach(AchievementCategory.allCases, id: \.self) { category in // For each category group, create a section
                if !viewModel.getAchievementsByCategory()[category]!.isEmpty {
                    VStack(alignment: .leading) {
                        Text(getCategoryName(category: category)) // Add a section header with the category name
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) { // Add a LazyVGrid with AchievementCard instances for each achievement
                            ForEach(viewModel.getAchievementsByCategory()[category]!) { achievement in
                                AchievementCard(achievement: achievement) {
                                    selectedAchievement = achievement // Make each card tappable to show achievement details
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    /// Creates a detailed view for a selected achievement
    private func achievementDetailView(achievement: Achievement) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack { // Add a header with achievement icon and name
                Image(systemName: getAchievementIcon(category: achievement.category))
                    .font(.title)
                    .foregroundColor(ColorConstants.secondary)
                
                Text(achievement.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(ColorConstants.textPrimary)
            }
            
            Text("Progreso: \(Int(achievement.getProgressPercentage() * 100))%") // Add a progress indicator
                .font(.headline)
                .foregroundColor(ColorConstants.textSecondary)
            
            Text(achievement.description) // Add the achievement description
                .font(.body)
                .foregroundColor(ColorConstants.textSecondary)
            
            Text("Criterios: \(achievement.getCriteriaDescription())") // Add criteria information if available
                .font(.caption)
                .foregroundColor(ColorConstants.textTertiary)
            
            if achievement.isEarned() { // Add earned date if the achievement is earned
                Text("Obtenido el: \(achievement.getFormattedEarnedDate())")
                    .font(.caption)
                    .foregroundColor(ColorConstants.success)
            }
            
            Spacer()
        }
        .padding()
    }
    
    /// Returns a localized display name for an achievement category
    private func getCategoryName(category: AchievementCategory) -> String {
        switch category { // Switch on the category parameter
        case .streak: // Return the appropriate localized string for each category
            return "Racha"
        case .journaling:
            return "Diario"
        case .emotionalAwareness:
            return "Conciencia Emocional"
        case .toolUsage:
            return "Uso de Herramientas"
        case .milestone:
            return "Hito"
        }
    }
    
    /// Returns an appropriate icon for an achievement category
    private func getAchievementIcon(category: AchievementCategory) -> String {
        switch category { // Switch on the category parameter
        case .streak: // Return the appropriate system icon name for each category
            return "flame.fill"
        case .journaling:
            return "pencil.and.outline"
        case .emotionalAwareness:
            return "face.smiling"
        case .toolUsage:
            return "wrench.and.screwdriver"
        case .milestone:
            return "flag.checkered"
        }
    }
}