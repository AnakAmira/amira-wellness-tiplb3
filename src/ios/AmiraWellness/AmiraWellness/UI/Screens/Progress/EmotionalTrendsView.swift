import SwiftUI // SwiftUI - iOS SDK
import Foundation // Foundation - iOS SDK

// Internal imports
import EmotionalTrendsViewModel // src/ios/AmiraWellness/AmiraWellness/UI/Screens/Progress/EmotionalTrendsViewModel.swift
import EmotionTrendChart // src/ios/AmiraWellness/AmiraWellness/UI/Components/Charts/EmotionTrendChart.swift
import EmotionalTrend // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalTrend.swift
import EmotionalInsight // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalTrend.swift
import TrendPeriodType // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalTrend.swift
import InsightType // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalTrend.swift
import EmotionType // src/ios/AmiraWellness/AmiraWellness/Models/EmotionalState.swift
import LoadingView // src/ios/AmiraWellness/AmiraWellness/UI/Components/Loading/LoadingView.swift
import EmptyStateView // src/ios/AmiraWellness/AmiraWellness/UI/Components/Feedback/EmptyStateView.swift
import ErrorView // src/ios/AmiraWellness/AmiraWellness/UI/Components/Feedback/ErrorView.swift
import ColorConstants // src/ios/AmiraWellness/AmiraWellness/Core/Constants/ColorConstants.swift
import View+Extensions // src/ios/AmiraWellness/AmiraWellness/Core/Extensions/View+Extensions.swift
import Date+Extensions // src/ios/AmiraWellness/AmiraWellness/Core/Extensions/Date+Extensions.swift
import Haptics // src/ios/AmiraWellness/AmiraWellness/Core/Utilities/Haptics.swift

/// A SwiftUI view that displays detailed emotional trend visualizations and insights
struct EmotionalTrendsView: View {
    
    // MARK: - Observed Object
    
    /// Observed object for managing emotional trends data
    @StateObject private var viewModel: EmotionalTrendsViewModel
    
    // MARK: - State Properties
    
    /// State variable to control the visibility of the date picker
    @State private var showDatePicker: Bool = false
    
    /// Temporary start date for date range selection
    @State private var tempStartDate: Date
    
    /// Temporary end date for date range selection
    @State private var tempEndDate: Date
    
    /// State variable to control the visibility of the trend detail view
    @State private var showTrendDetail: Bool = false
    
    /// State variable to control the visibility of the insight detail view
    @State private var showInsightDetail: Bool = false
    
    /// State variable to store the selected emotional insight for detailed viewing
    @State private var selectedInsight: EmotionalInsight? = nil
    
    // MARK: - Initializer
    
    /// Initializes the EmotionalTrendsView with an optional view model
    /// - Parameter viewModel: Optional view model for dependency injection
    init(viewModel: EmotionalTrendsViewModel? = nil) {
        // Initialize the viewModel property with the provided viewModel or create a new instance
        _viewModel = StateObject(wrappedValue: viewModel ?? EmotionalTrendsViewModel())
        // Initialize showDatePicker to false
        _showDatePicker = State(initialValue: false)
        // Initialize tempStartDate and tempEndDate from viewModel's date range
        _tempStartDate = State(initialValue: viewModel?.startDate ?? Date())
        _tempEndDate = State(initialValue: viewModel?.endDate ?? Date())
        // Initialize showTrendDetail to false
        _showTrendDetail = State(initialValue: false)
        // Initialize showInsightDetail to false
        _showInsightDetail = State(initialValue: false)
        // Initialize selectedInsight to nil
        _selectedInsight = State(initialValue: nil)
    }
    
    // MARK: - Body
    
    /// Builds the view hierarchy for the EmotionalTrendsView
    var body: some View {
        NavigationView {
            VStack {
                headerSection() // Add a header section with title and date range
                periodSelectionSection() // Add period selection buttons (daily, weekly, monthly)
                dateRangeSection() // Add date range selector with date picker toggle
                
                if showDatePicker {
                    datePicker() // Show date picker if showDatePicker is true
                }
                
                emotionFilterSection() // Add emotion type filter chips
                
                // Show appropriate content based on state (loading, error, empty, or trends)
                if viewModel.isLoading {
                    LoadingView(message: "Cargando tendencias...") // If loading, show LoadingView
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage) {
                        viewModel.loadTrends()
                    } // If error, show ErrorView with retry action
                } else if viewModel.trends.isEmpty {
                    EmptyStateView(message: "No hay datos disponibles para el período seleccionado.") // If no trends, show EmptyStateView
                } else {
                    trendsSection() // Otherwise, show trend charts and insights
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Tendencias Emocionales")
                        .font(.headline)
                        .foregroundColor(ColorConstants.textPrimary)
                }
            }
            .padding()
            .onAppear {
                viewModel.loadTrends() // Call viewModel.loadTrends() when view appears
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Creates the header section with title and date range
    private func headerSection() -> some View {
        VStack(alignment: .leading) {
            Text("Tendencias Emocionales")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorConstants.textPrimary)
            
            Text("Del \(viewModel.startDate.toShortString()) al \(viewModel.endDate.toShortString())")
                .font(.subheadline)
                .foregroundColor(ColorConstants.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// Creates the period selection buttons section
    private func periodSelectionSection() -> some View {
        VStack(alignment: .leading) {
            Text("Período")
                .font(.headline)
                .foregroundColor(ColorConstants.textPrimary)
            
            HStack {
                ForEach(TrendPeriodType.allCases, id: \.self) { periodType in
                    Button(action: {
                        viewModel.changePeriod(periodType: periodType)
                    }) {
                        Text(periodType.displayName())
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedPeriod == periodType ? ColorConstants.primaryLight : ColorConstants.surface)
                            .foregroundColor(viewModel.selectedPeriod == periodType ? ColorConstants.textOnPrimary : ColorConstants.textPrimary)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// Creates the date range selection section
    private func dateRangeSection() -> some View {
        HStack {
            Text("Rango de fechas:")
                .font(.subheadline)
                .foregroundColor(ColorConstants.textPrimary)
            
            Spacer()
            
            Button(action: {
                showDatePicker.toggle()
            }) {
                Text("\(viewModel.startDate.toMediumString()) - \(viewModel.endDate.toMediumString())")
                    .font(.subheadline)
                    .foregroundColor(ColorConstants.primary)
            }
        }
    }
    
    /// Creates the date picker section for custom date range selection
    private func datePicker() -> some View {
        VStack {
            DatePicker(
                "Fecha de inicio",
                selection: $tempStartDate,
                in: ...viewModel.endDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            
            DatePicker(
                "Fecha de fin",
                selection: $tempEndDate,
                in: tempStartDate...,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            
            HStack {
                Button("Cancelar") {
                    showDatePicker = false
                }
                
                Button("Aplicar") {
                    viewModel.updateDateRange(start: tempStartDate, end: tempEndDate)
                    showDatePicker = false
                }
            }
        }
        .padding()
        .background(ColorConstants.surface)
        .cornerRadius(12)
    }
    
    /// Creates the emotion type filter section with selectable chips
    private func emotionFilterSection() -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Filtrar por emoción")
                    .font(.headline)
                    .foregroundColor(ColorConstants.textPrimary)
                
                Spacer()
                
                Button("Limpiar") {
                    viewModel.clearEmotionTypeFilters()
                }
                .foregroundColor(ColorConstants.primary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: [GridItem(.adaptive(minimum: 40))]) {
                    ForEach(EmotionType.allCases, id: \.self) { emotionType in
                        emotionFilterChip(emotionType: emotionType, isSelected: viewModel.selectedEmotionTypes.contains(emotionType))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// Creates the main trends visualization section with charts
    private func trendsSection() -> some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.trends, id: \.emotionType) { trend in
                    NavigationLink(destination: trendDetailView(trend: trend)) {
                        VStack(alignment: .leading) {
                            EmotionTrendChart(trend: trend)
                            
                            Text(trend.trendDescription())
                                .font(.subheadline)
                                .foregroundColor(ColorConstants.textSecondary)
                        }
                        .cardStyle()
                    }
                }
            }
        }
    }
    
    /// Creates a detailed view for a selected emotional trend
    private func trendDetailView(trend: EmotionalTrend) -> some View {
        ScrollView {
            VStack(alignment: .leading) {
                EmotionTrendChart(trend: trend, showLabels: true, showGrid: true, showLegend: true, showTrendIndicator: true)
                
                Text("Promedio de intensidad: \(trend.formattedAverageIntensity())")
                    .font(.headline)
                    .foregroundColor(ColorConstants.textPrimary)
                
                Text("Punto máximo: \(trend.formattedPeakIntensity()) el \(trend.formattedPeakDate())")
                    .font(.subheadline)
                    .foregroundColor(ColorConstants.textSecondary)
                
                Text("Insights relacionados:")
                    .font(.headline)
                    .foregroundColor(ColorConstants.textPrimary)
                
                ForEach(viewModel.getInsightsForEmotion(emotionType: trend.emotionType), id: \.description) { insight in
                    Text("- \(insight.description)")
                        .font(.subheadline)
                        .foregroundColor(ColorConstants.textSecondary)
                }
            }
            .padding()
        }
    }
    
    /// Creates a detailed view for a selected emotional insight
    private func insightDetailView(insight: EmotionalInsight) -> some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Tipo de Insight: \(insight.type.displayName())")
                    .font(.headline)
                    .foregroundColor(ColorConstants.textPrimary)
                
                Text("Descripción: \(insight.description)")
                    .font(.subheadline)
                    .foregroundColor(ColorConstants.textSecondary)
                
                Text("Emociones relacionadas: \(insight.relatedEmotionsText())")
                    .font(.subheadline)
                    .foregroundColor(ColorConstants.textSecondary)
                
                Text("Confianza: \(insight.formattedConfidence())")
                    .font(.subheadline)
                    .foregroundColor(ColorConstants.textSecondary)
                
                Text("Acciones recomendadas:")
                    .font(.headline)
                    .foregroundColor(ColorConstants.textPrimary)
                
                ForEach(insight.recommendedActions, id: \.self) { action in
                    Text("- \(action)")
                        .font(.subheadline)
                        .foregroundColor(ColorConstants.textSecondary)
                }
            }
            .padding()
        }
    }
    
    /// Creates a selectable chip for emotion type filtering
    private func emotionFilterChip(emotionType: EmotionType, isSelected: Bool) -> some View {
        Button(action: {
            viewModel.toggleEmotionTypeFilter(emotionType: emotionType)
        }) {
            Text(emotionType.displayName())
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? emotionType.color() : ColorConstants.surface)
                .foregroundColor(isSelected ? ColorConstants.textOnPrimary : ColorConstants.textPrimary)
                .cornerRadius(8)
        }
    }
}