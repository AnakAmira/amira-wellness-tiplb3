//
//  ActivityBarChart.swift
//  AmiraWellness
//
//  Created for Amira Wellness application
//

import SwiftUI // iOS SDK
import Foundation // iOS SDK

/// A SwiftUI view that displays a bar chart visualization of user activity data by day of the week
struct ActivityBarChart: View {
    // MARK: - Properties
    
    /// Data dictionary mapping days to activity values
    private let activityData: [String: Double]
    
    /// The height of the chart
    private let height: CGFloat
    
    /// The width of each bar
    private let barWidth: CGFloat
    
    /// The spacing between bars
    private let spacing: CGFloat
    
    /// The corner radius for the top of each bar
    private let cornerRadius: CGFloat
    
    /// Whether to show day labels below the bars
    private let showLabels: Bool
    
    /// Whether to show value labels above the bars
    private let showValues: Bool
    
    /// The color of the bars (default color will be used if nil)
    private let barColor: Color
    
    /// The color for the current day's bar (default color will be used if nil)
    private let highlightColor: Color
    
    /// The background color of the chart
    private let backgroundColor: Color
    
    /// The duration of the animation when the chart appears
    private let animationDuration: Double
    
    /// State to track the animation progress
    @State private var isAnimating: Bool = false
    
    // MARK: - Initializer
    
    /// Initializes the ActivityBarChart with the provided parameters
    /// - Parameters:
    ///   - activityData: Dictionary mapping days to activity values
    ///   - height: The height of the chart
    ///   - barWidth: The width of each bar
    ///   - spacing: The spacing between bars
    ///   - cornerRadius: The corner radius of the bars
    ///   - showLabels: Whether to show day labels
    ///   - showValues: Whether to show value labels
    ///   - barColor: The color of the bars (optional)
    ///   - highlightColor: The color for the current day's bar (optional)
    ///   - backgroundColor: The background color of the chart (optional)
    ///   - animationDuration: The duration of the bar animation
    init(
        activityData: [String: Double],
        height: CGFloat = 200,
        barWidth: CGFloat = 30,
        spacing: CGFloat = 12,
        cornerRadius: CGFloat = 6,
        showLabels: Bool = true,
        showValues: Bool = true,
        barColor: Color? = nil,
        highlightColor: Color? = nil,
        backgroundColor: Color? = nil,
        animationDuration: Double = 0.6
    ) {
        self.activityData = activityData
        self.height = height
        self.barWidth = barWidth
        self.spacing = spacing
        self.cornerRadius = cornerRadius
        self.showLabels = showLabels
        self.showValues = showValues
        self.barColor = barColor ?? ColorConstants.primary
        self.highlightColor = highlightColor ?? ColorConstants.secondary
        self.backgroundColor = backgroundColor ?? ColorConstants.background
        self.animationDuration = animationDuration
    }
    
    // MARK: - Body
    
    /// Builds the view hierarchy for the ActivityBarChart
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            // Chart background and bars
            ZStack(alignment: .bottom) {
                // Background
                Rectangle()
                    .fill(backgroundColor)
                    .frame(height: height)
                
                // Bars
                HStack(alignment: .bottom, spacing: spacing) {
                    // Create a bar for each day in the data
                    ForEach(activityData.sorted(by: { $0.key < $1.key }), id: \.key) { day, value in
                        VStack(spacing: 4) {
                            // Value label if enabled
                            if showValues {
                                valueLabel(value)
                            }
                            
                            // The bar
                            Rectangle()
                                .fill(barColorFor(day))
                                .frame(width: barWidth, height: normalizedHeight(value))
                                .cornerRadius(cornerRadius, corners: [.topLeft, .topRight])
                            
                            // Day label if enabled
                            if showLabels {
                                dayLabel(day)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .cardStyle(backgroundColor: backgroundColor)
        .onAppear {
            // Animate bars when the view appears
            animateChart()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculates the normalized height for a bar based on its value
    /// - Parameter value: The value for the bar
    /// - Returns: The calculated height for the bar
    private func normalizedHeight(_ value: Double) -> CGFloat {
        // Find the maximum value in the data
        let maxValue = activityData.values.max() ?? 1
        
        // Handle case where max is zero to avoid division by zero
        if maxValue == 0 {
            return 10 // Minimum height for visibility
        }
        
        // Calculate the proportional height
        let proportion = value / maxValue
        let calculatedHeight = CGFloat(proportion) * height
        
        // Apply animation scaling
        return isAnimating ? calculatedHeight : 0
    }
    
    /// Creates a label for the day of week
    /// - Parameter day: The day string to display
    /// - Returns: The day label view
    private func dayLabel(_ day: String) -> some View {
        Text(day.prefix(1).uppercased()) // Use just the first letter
            .font(.caption2)
            .foregroundColor(isCurrentDay(day) ? highlightColor : ColorConstants.textSecondary)
            .frame(width: barWidth)
            .padding(.top, 4)
    }
    
    /// Creates a label for the activity value
    /// - Parameter value: The value to display
    /// - Returns: The value label view
    private func valueLabel(_ value: Double) -> some View {
        Text(value == floor(value) ? "\(Int(value))" : String(format: "%.1f", value))
            .font(.caption2)
            .foregroundColor(ColorConstants.textPrimary)
            .frame(width: barWidth)
            .padding(.bottom, 4)
    }
    
    /// Triggers the animation for the chart bars
    private func animateChart() {
        // Reset animation state
        isAnimating = false
        
        // Small delay before animation for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: animationDuration)) {
                isAnimating = true
            }
        }
    }
    
    /// Determines if the given day string represents the current day of the week
    /// - Parameter day: The day string to check
    /// - Returns: True if the day is the current day of the week
    private func isCurrentDay(_ day: String) -> Bool {
        let currentDay = Date().weekdayName()
        return day.lowercased() == currentDay.lowercased()
    }
    
    /// Determines the color for a bar based on whether it represents the current day
    /// - Parameter day: The day to check
    /// - Returns: The color to use for the bar
    private func barColorFor(_ day: String) -> Color {
        return isCurrentDay(day) ? highlightColor : barColor
    }
}

// MARK: - Preview
#if DEBUG
struct ActivityBarChart_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ActivityBarChart(
                activityData: [
                    "Mon": 5,
                    "Tue": 7,
                    "Wed": 3,
                    "Thu": 8,
                    "Fri": 4,
                    "Sat": 10,
                    "Sun": 6
                ],
                height: 200,
                barWidth: 30,
                spacing: 12,
                showLabels: true,
                showValues: true
            )
            .padding()
            
            ActivityBarChart(
                activityData: [
                    "Mon": 2,
                    "Tue": 5,
                    "Wed": 8,
                    "Thu": 3,
                    "Fri": 7,
                    "Sat": 4,
                    "Sun": 9
                ],
                height: 150,
                barWidth: 25,
                spacing: 10,
                barColor: Color.blue,
                highlightColor: Color.orange
            )
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif