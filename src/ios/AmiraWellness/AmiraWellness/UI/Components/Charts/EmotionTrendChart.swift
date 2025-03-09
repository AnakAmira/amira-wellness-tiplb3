import SwiftUI
import Foundation
import ColorConstants
import EmotionColors

/// A SwiftUI component that visualizes emotional trend data over time, displaying patterns in a user's emotional states with interactive line charts
struct EmotionTrendChart: View {
    // MARK: - Properties
    
    private let trend: EmotionalTrend
    private let height: CGFloat
    private let showLabels: Bool
    private let showGrid: Bool
    private let showLegend: Bool
    private let showTrendIndicator: Bool
    private let lineWidth: CGFloat
    private let pointRadius: CGFloat
    private let gridColor: Color
    private let backgroundColor: Color
    private let animationDuration: Double
    
    @State private var isAnimating: Bool = false
    @State private var selectedPointIndex: Int? = nil
    @State private var chartSize: CGSize = .zero
    
    // MARK: - Initialization
    
    /// Initializes the EmotionTrendChart with the provided parameters
    /// - Parameters:
    ///   - trend: The emotional trend data to visualize
    ///   - height: The height of the chart
    ///   - showLabels: Whether to show axis labels
    ///   - showGrid: Whether to show grid lines
    ///   - showLegend: Whether to show the legend
    ///   - showTrendIndicator: Whether to show trend direction indicator
    ///   - lineWidth: The width of the trend line
    ///   - pointRadius: The radius of data points
    ///   - gridColor: The color of grid lines
    ///   - backgroundColor: The background color of the chart
    ///   - animationDuration: The duration of the drawing animation
    init(
        trend: EmotionalTrend,
        height: CGFloat = 220,
        showLabels: Bool = true,
        showGrid: Bool = true,
        showLegend: Bool = true,
        showTrendIndicator: Bool = true,
        lineWidth: CGFloat = 2,
        pointRadius: CGFloat = 5,
        gridColor: Color? = nil,
        backgroundColor: Color? = nil,
        animationDuration: Double = 1.0
    ) {
        self.trend = trend
        self.height = height
        self.showLabels = showLabels
        self.showGrid = showGrid
        self.showLegend = showLegend
        self.showTrendIndicator = showTrendIndicator
        self.lineWidth = lineWidth
        self.pointRadius = pointRadius
        self.gridColor = gridColor ?? ColorConstants.divider
        self.backgroundColor = backgroundColor ?? ColorConstants.surface
        self.animationDuration = animationDuration
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background
                backgroundColor
                    .cornerRadius(12)
                
                // Grid
                if showGrid {
                    drawGrid()
                }
                
                // Axes
                drawAxes()
                
                // Trend line with data points
                drawTrendLine()
                
                // Legend
                if showLegend {
                    drawLegend()
                }
                
                // Trend indicator
                if showTrendIndicator {
                    drawTrendIndicator()
                }
            }
            .frame(height: height)
            .readSize(onChange: $chartSize)
            
            // X-axis labels
            if showLabels {
                drawXAxisLabels()
            }
        }
        .cardStyle(backgroundColor: backgroundColor)
        .contentShape(Rectangle()) // For tap gesture
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleTap(location: value.location)
                }
        )
        .onAppear {
            animateChart()
        }
    }
    
    // MARK: - Drawing Methods
    
    /// Draws the background grid lines for the chart
    private func drawGrid() -> some View {
        let horizontalLinesCount = 5
        let verticalLinesCount = 6
        
        return ZStack {
            // Horizontal grid lines
            ForEach(0..<horizontalLinesCount, id: \.self) { index in
                let yPosition = CGFloat(index) / CGFloat(horizontalLinesCount - 1)
                
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height * (1 - yPosition)))
                    path.addLine(to: CGPoint(x: chartSize.width, y: height * (1 - yPosition)))
                }
                .stroke(gridColor, lineWidth: 0.5)
                .opacity(0.5)
            }
            
            // Vertical grid lines
            ForEach(0..<verticalLinesCount, id: \.self) { index in
                let xPosition = CGFloat(index) / CGFloat(verticalLinesCount - 1)
                
                Path { path in
                    path.move(to: CGPoint(x: chartSize.width * xPosition, y: 0))
                    path.addLine(to: CGPoint(x: chartSize.width * xPosition, y: height))
                }
                .stroke(gridColor, lineWidth: 0.5)
                .opacity(0.5)
            }
        }
        .opacity(isAnimating ? 1 : 0)
        .animation(.easeIn(duration: animationDuration * 0.5), value: isAnimating)
    }
    
    /// Draws the x and y axes for the chart
    private func drawAxes() -> some View {
        ZStack {
            // X-axis (bottom)
            Path { path in
                path.move(to: CGPoint(x: 0, y: height))
                path.addLine(to: CGPoint(x: chartSize.width, y: height))
            }
            .stroke(ColorConstants.divider, lineWidth: 1)
            
            // Y-axis (left)
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: height))
            }
            .stroke(ColorConstants.divider, lineWidth: 1)
        }
        .opacity(isAnimating ? 1 : 0)
        .animation(.easeIn(duration: animationDuration * 0.5), value: isAnimating)
    }
    
    /// Draws the main trend line with data points
    private func drawTrendLine() -> some View {
        ZStack {
            // Draw the line connecting all points
            Path { path in
                guard !trend.dataPoints.isEmpty else { return }
                
                var isFirstPoint = true
                for point in trend.dataPoints {
                    let position = normalizedPosition(point: point)
                    let screenPosition = pointToScreenPosition(normalizedPosition: position)
                    
                    if isFirstPoint {
                        path.move(to: screenPosition)
                        isFirstPoint = false
                    } else {
                        path.addLine(to: screenPosition)
                    }
                }
            }
            .trim(from: 0, to: isAnimating ? 1 : 0)
            .stroke(trend.emotionType.color(), lineWidth: lineWidth)
            .animation(
                .easeInOut(duration: animationDuration)
                    .delay(animationDuration * 0.2),
                value: isAnimating
            )
            
            // Draw the data points
            ForEach(0..<trend.dataPoints.count, id: \.self) { index in
                let point = trend.dataPoints[index]
                let position = normalizedPosition(point: point)
                let screenPosition = pointToScreenPosition(normalizedPosition: position)
                
                Circle()
                    .fill(trend.emotionType.color())
                    .frame(width: pointRadius * 2, height: pointRadius * 2)
                    .position(screenPosition)
                    .scaleEffect(isAnimating ? (selectedPointIndex == index ? 1.5 : 1.0) : 0.0)
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.6)
                            .delay(animationDuration * 0.7 + Double(index) * 0.05),
                        value: isAnimating
                    )
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.6),
                        value: selectedPointIndex
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: pointRadius * 2, height: pointRadius * 2)
                            .opacity(selectedPointIndex == index ? 1 : 0)
                    )
            }
            
            // Draw tooltip for selected point
            if let selectedIndex = selectedPointIndex, selectedIndex < trend.dataPoints.count {
                drawTooltip()
            }
        }
    }
    
    /// Draws an indicator showing the overall trend direction
    private func drawTrendIndicator() -> some View {
        HStack(spacing: 4) {
            Image(systemName: trend.overallTrend.icon())
                .font(.caption)
                .foregroundColor(trend.emotionType.color())
            
            Text(trend.overallTrend.displayName())
                .font(.caption)
                .foregroundColor(ColorConstants.textSecondary)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
                .opacity(0.8)
        )
        .position(x: chartSize.width - 60, y: 20)
        .opacity(isAnimating ? 1 : 0)
        .animation(
            .easeInOut(duration: animationDuration)
                .delay(animationDuration),
            value: isAnimating
        )
    }
    
    /// Draws the labels for the x-axis (dates)
    private func drawXAxisLabels() -> some View {
        HStack(spacing: 0) {
            if trend.dataPoints.count > 1 {
                // Calculate how many labels to show based on width
                let labelCount = min(5, trend.dataPoints.count)
                let step = max(1, trend.dataPoints.count / labelCount)
                
                ForEach(0..<trend.dataPoints.count, id: \.self) { index in
                    if index % step == 0 || index == trend.dataPoints.count - 1 {
                        let point = trend.dataPoints[index]
                        let position = normalizedPosition(point: point)
                        
                        Text(point.formattedDate())
                            .font(.caption2)
                            .foregroundColor(ColorConstants.textSecondary)
                            .frame(width: chartSize.width / CGFloat(labelCount))
                            .position(x: chartSize.width * position.x, y: 10)
                    }
                }
            } else if let point = trend.dataPoints.first {
                // Only one point, center it
                Text(point.formattedDate())
                    .font(.caption2)
                    .foregroundColor(ColorConstants.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 20)
        .opacity(isAnimating ? 1 : 0)
        .animation(
            .easeInOut(duration: animationDuration)
                .delay(animationDuration * 0.8),
            value: isAnimating
        )
    }
    
    /// Draws the labels for the y-axis (intensity values)
    private func drawYAxisLabels() -> some View {
        let (minIntensity, maxIntensity) = trend.intensityRange()
        let labelCount = 5
        
        return ZStack {
            ForEach(0..<labelCount, id: \.self) { index in
                let intensity = minIntensity + (maxIntensity - minIntensity) * index / (labelCount - 1)
                let yPosition = 1.0 - CGFloat(index) / CGFloat(labelCount - 1)
                
                Text("\(intensity)")
                    .font(.caption2)
                    .foregroundColor(ColorConstants.textSecondary)
                    .position(x: -20, y: height * yPosition)
            }
        }
        .opacity(isAnimating ? 1 : 0)
        .animation(
            .easeInOut(duration: animationDuration)
                .delay(animationDuration * 0.8),
            value: isAnimating
        )
    }
    
    /// Draws a legend for the chart
    private func drawLegend() -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(trend.emotionType.color())
                .frame(width: 12, height: 4)
            
            Text(trend.emotionType.displayName())
                .font(.caption)
                .foregroundColor(ColorConstants.textSecondary)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor)
                .opacity(0.8)
        )
        .position(x: 70, y: 20)
        .opacity(isAnimating ? 1 : 0)
        .animation(
            .easeInOut(duration: animationDuration)
                .delay(animationDuration),
            value: isAnimating
        )
    }
    
    /// Draws a tooltip for the selected data point
    private func drawTooltip() -> some View {
        guard let selectedIndex = selectedPointIndex, selectedIndex < trend.dataPoints.count else {
            return EmptyView()
        }
        
        let point = trend.dataPoints[selectedIndex]
        let position = normalizedPosition(point: point)
        let screenPosition = pointToScreenPosition(normalizedPosition: position)
        
        return VStack(alignment: .leading, spacing: 4) {
            Text(point.formattedDate())
                .font(.caption)
                .foregroundColor(ColorConstants.textPrimary)
                .bold()
            
            Text("Intensidad: \(point.formattedValue())")
                .font(.caption)
                .foregroundColor(ColorConstants.textSecondary)
            
            if let context = point.context {
                Text(context)
                    .font(.caption)
                    .foregroundColor(ColorConstants.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .position(
            x: min(max(screenPosition.x, 80), chartSize.width - 80),
            y: screenPosition.y - 50
        )
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: selectedPointIndex)
    }
    
    // MARK: - Helper Methods
    
    /// Calculates the normalized position for a data point within the chart
    private func normalizedPosition(point: TrendDataPoint) -> CGPoint {
        let (startDate, endDate) = trend.dateRange()
        let (minIntensity, maxIntensity) = trend.intensityRange()
        
        // Ensure we don't divide by zero
        let dateRange = endDate.timeIntervalSince(startDate)
        let intensityRange = CGFloat(maxIntensity - minIntensity)
        
        let datePosition = dateRange > 0 ? 
            point.date.timeIntervalSince(startDate) / dateRange : 0.5
        
        // Normalize y value (intensity) - invert it so higher values are at the top
        let intensityPosition = intensityRange > 0 ? 
            1.0 - CGFloat(point.value - minIntensity) / intensityRange : 0.5
        
        return CGPoint(x: CGFloat(datePosition), y: intensityPosition)
    }
    
    /// Converts a normalized position to screen coordinates
    private func pointToScreenPosition(normalizedPosition: CGPoint) -> CGPoint {
        // Account for padding and other adjustments
        let xOffset: CGFloat = 10
        let yOffset: CGFloat = 10
        let chartWidth = chartSize.width - (xOffset * 2)
        let chartHeight = height - (yOffset * 2)
        
        return CGPoint(
            x: normalizedPosition.x * chartWidth + xOffset,
            y: normalizedPosition.y * chartHeight + yOffset
        )
    }
    
    /// Triggers the animation for the chart elements
    private func animateChart() {
        isAnimating = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                isAnimating = true
            }
        }
    }
    
    /// Handles tap gestures on the chart to select data points
    private func handleTap(location: CGPoint) {
        guard !trend.dataPoints.isEmpty else { return }
        
        var closestIndex: Int? = nil
        var closestDistance: CGFloat = .infinity
        
        // Find the closest point to the tap location
        for (index, point) in trend.dataPoints.enumerated() {
            let position = normalizedPosition(point: point)
            let screenPosition = pointToScreenPosition(normalizedPosition: position)
            
            let distance = hypot(location.x - screenPosition.x, location.y - screenPosition.y)
            
            // If the tap is close enough to a point, select it
            if distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }
        
        // Only select if tap is close enough (within 30 points)
        if closestDistance < 30, let index = closestIndex {
            if selectedPointIndex == index {
                // If tapping the same point, deselect it
                selectedPointIndex = nil
            } else {
                // Otherwise, select the closest point
                selectedPointIndex = index
                
                // Add haptic feedback for selection
                HapticManager.shared.generateFeedback(.selection)
            }
        } else {
            // Tapping empty space clears selection
            selectedPointIndex = nil
        }
    }
}