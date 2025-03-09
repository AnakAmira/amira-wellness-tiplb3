//
//  StreakChart.swift
//  AmiraWellness
//
//  Created for Amira Wellness application
//

import SwiftUI // iOS SDK
import Foundation // iOS SDK

/// A SwiftUI view that displays a visual representation of a user's streak and progress towards the next milestone
struct StreakChart: View {
    // MARK: - Properties
    
    /// The current streak count
    private let currentStreak: Int
    
    /// The next milestone to achieve
    private let nextMilestone: Int
    
    /// The progress towards the next milestone (0.0 - 1.0)
    private let progress: Double
    
    /// The height of the progress bar
    private let height: CGFloat
    
    /// Whether to show labels for the streak values
    private let showLabels: Bool
    
    /// The color for active/completed portions of the chart
    private let activeColor: Color
    
    /// The color for inactive/incomplete portions of the chart
    private let inactiveColor: Color
    
    /// The background color of the chart
    private let backgroundColor: Color
    
    /// The duration of the progress animation in seconds
    private let animationDuration: Double
    
    /// Track whether the chart is currently animating
    @State private var isAnimating: Bool = false
    
    // MARK: - Initializer
    
    /// Initializes the StreakChart with the provided parameters
    /// - Parameters:
    ///   - currentStreak: The user's current streak count
    ///   - nextMilestone: The next milestone to achieve
    ///   - progress: The progress towards the next milestone (0.0 - 1.0)
    ///   - height: The height of the progress bar
    ///   - showLabels: Whether to show labels for the streak values
    ///   - activeColor: The color for active/completed portions of the chart
    ///   - inactiveColor: The color for inactive/incomplete portions of the chart
    ///   - backgroundColor: The background color of the chart
    ///   - animationDuration: The duration of the progress animation in seconds
    init(
        currentStreak: Int,
        nextMilestone: Int,
        progress: Double,
        height: CGFloat = 20,
        showLabels: Bool = true,
        activeColor: Color? = nil,
        inactiveColor: Color? = nil,
        backgroundColor: Color? = nil,
        animationDuration: Double = 1.0
    ) {
        self.currentStreak = currentStreak
        self.nextMilestone = nextMilestone
        self.progress = min(max(progress, 0.0), 1.0) // Clamp between 0.0 and 1.0
        self.height = height
        self.showLabels = showLabels
        self.activeColor = activeColor ?? ColorConstants.primary
        self.inactiveColor = inactiveColor ?? ColorConstants.secondary.opacity(0.3)
        self.backgroundColor = backgroundColor ?? ColorConstants.surface
        self.animationDuration = animationDuration
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 8) {
            // Use GeometryReader to get proper container width
            GeometryReader { geometry in
                progressBar(width: geometry.size.width)
            }
            .frame(height: height)
            
            if showLabels {
                streakLabels()
            }
        }
        .cardStyle(backgroundColor: backgroundColor, padding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .onAppear {
            animateChart()
        }
    }
    
    // MARK: - Helper Views
    
    /// Creates the main progress bar showing streak progress towards milestone
    /// - Parameter width: The total width of the container
    /// - Returns: The progress bar view
    private func progressBar(width: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            // Background track
            RoundedRectangle(cornerRadius: height / 2)
                .fill(inactiveColor)
                .frame(height: height)
            
            // Progress bar
            RoundedRectangle(cornerRadius: height / 2)
                .fill(activeColor)
                .frame(width: isAnimating ? width * CGFloat(progress) : 0, height: height)
                .animation(.easeOut(duration: animationDuration), value: isAnimating)
            
            // Milestone markers
            milestoneMarkers(width: width)
        }
        .frame(height: height)
    }
    
    /// Creates markers for streak milestones on the progress bar
    /// - Parameter width: The total width of the container
    /// - Returns: The milestone markers view
    private func milestoneMarkers(width: CGFloat) -> some View {
        ZStack {
            // Get common milestone values (e.g., 3, 7, 14, 30 days)
            let milestones = [3, 7, 14, 30, 60, 90]
            
            // Filter to only show milestones up to the next milestone
            let visibleMilestones = milestones.filter { $0 <= nextMilestone }
            
            // Create markers for each milestone
            ForEach(visibleMilestones, id: \.self) { milestone in
                // Calculate the position for this milestone
                let position = getMilestonePosition(milestone)
                
                // Create a circle marker
                Circle()
                    .fill(position <= progress && isAnimating ? activeColor : inactiveColor)
                    .frame(width: height * 0.8, height: height * 0.8)
                    .position(x: width * CGFloat(position), y: height / 2)
            }
        }
    }
    
    /// Creates labels showing the current streak and next milestone
    /// - Returns: The streak labels view
    private func streakLabels() -> some View {
        HStack {
            // Current streak label
            Text(formatStreakCount(currentStreak))
                .font(.subheadline)
                .foregroundColor(ColorConstants.textPrimary)
            
            Spacer()
            
            // Next milestone label
            Text(nextMilestone > 0 ? "Próximo logro: \(formatStreakCount(nextMilestone))" : "¡Todos los logros conseguidos!")
                .font(.subheadline)
                .foregroundColor(ColorConstants.textSecondary)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Triggers the animation for the progress bar
    private func animateChart() {
        // Reset the animation state
        isAnimating = false
        
        // Animate with a slight delay for better user experience
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimating = true
        }
    }
    
    /// Calculates the relative position of a milestone on the progress bar
    /// - Parameter milestone: The milestone to calculate position for
    /// - Returns: The relative position (0.0-1.0)
    private func getMilestonePosition(_ milestone: Int) -> CGFloat {
        if nextMilestone <= 0 { return 1.0 }
        return min(max(CGFloat(milestone) / CGFloat(nextMilestone), 0.0), 1.0)
    }
    
    /// Formats a streak count with appropriate day/days suffix
    /// - Parameter count: The streak count to format
    /// - Returns: Formatted streak string
    private func formatStreakCount(_ count: Int) -> String {
        if count == 1 {
            return "\(count) día"
        } else {
            return "\(count) días"
        }
    }
}

// MARK: - Preview

struct StreakChart_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Preview with current streak of 5, next milestone 7, and progress 0.71
            StreakChart(currentStreak: 5, nextMilestone: 7, progress: 0.71)
                .padding()
            
            // Preview with complete progress
            StreakChart(currentStreak: 14, nextMilestone: 14, progress: 1.0)
                .padding()
            
            // Preview with no progress
            StreakChart(currentStreak: 0, nextMilestone: 3, progress: 0.0)
                .padding()
            
            // Preview with custom colors
            StreakChart(
                currentStreak: 10, 
                nextMilestone: 30, 
                progress: 0.33,
                activeColor: Color.green,
                inactiveColor: Color.gray.opacity(0.3),
                backgroundColor: Color.white
            )
            .padding()
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.light)
    }
}