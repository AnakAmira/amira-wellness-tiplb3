import SwiftUI // iOS SDK
import Combine // iOS SDK

/// A custom slider component for selecting emotion intensity in the Amira Wellness app
struct IntensitySlider: View {
    // MARK: - Properties
    
    /// The currently selected intensity value (bidirectional binding)
    @Binding var value: Int
    
    /// The emotion type that influences the slider's color
    var emotionType: EmotionType
    
    /// Label for the low end of the slider
    var lowLabel: String
    
    /// Label for the high end of the slider
    var highLabel: String
    
    /// Whether to show the low/high labels
    var showLabels: Bool
    
    /// Whether to show the current value
    var showValue: Bool
    
    /// Optional override for the accent color
    var accentColor: Color?
    
    /// Tracks whether the user is currently dragging the slider
    @State private var isDragging: Bool = false
    
    /// Stores the current drag offset
    @State private var dragOffset: CGFloat = 0
    
    /// Tracks the last value for detecting changes
    @State private var lastValue: Int
    
    // Fixed constants
    private let minValue: Int = 1
    private let maxValue: Int = 10
    private let trackHeight: CGFloat = 8
    private let thumbSize: CGFloat = 28
    private let labelPadding: CGFloat = 8
    
    // MARK: - Initialization
    
    /// Initializes the IntensitySlider with the provided parameters
    /// - Parameters:
    ///   - value: Binding to the intensity value (1-10)
    ///   - emotionType: The emotion type that influences the slider's color
    ///   - lowLabel: Label for the low end of the slider
    ///   - highLabel: Label for the high end of the slider
    ///   - showLabels: Whether to show the low/high labels
    ///   - showValue: Whether to show the current value
    ///   - accentColor: Optional override for the accent color
    init(value: Binding<Int>, 
         emotionType: EmotionType = .joy,
         lowLabel: String = NSLocalizedString("Baja", comment: "Low intensity label"),
         highLabel: String = NSLocalizedString("Alta", comment: "High intensity label"),
         showLabels: Bool = true,
         showValue: Bool = true,
         accentColor: Color? = nil) {
        self._value = value
        self.emotionType = emotionType
        self.lowLabel = lowLabel
        self.highLabel = highLabel
        self.showLabels = showLabels
        self.showValue = showValue
        self.accentColor = accentColor
        self._lastValue = State(initialValue: value.wrappedValue)
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: labelPadding) {
                ZStack(alignment: .leading) {
                    // Track background
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .fill(ColorConstants.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: trackHeight / 2)
                                .stroke(ColorConstants.border, lineWidth: 1)
                        )
                        .frame(height: trackHeight)
                    
                    // Filled track - uses emotion-specific color
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .fill(getTrackColor())
                        .frame(width: max(0, calculateThumbPosition(width: geometry.size.width) - thumbSize / 2), height: trackHeight)
                    
                    // Thumb - circular handle with shadow for depth
                    Circle()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                        .overlay(
                            Circle()
                                .stroke(getTrackColor(), lineWidth: 2)
                        )
                        .frame(width: thumbSize, height: thumbSize)
                        .position(x: calculateThumbPosition(width: geometry.size.width), y: trackHeight / 2)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    if !isDragging {
                                        // Initial touch feedback
                                        HapticManager.shared.generateFeedback(.light)
                                        isDragging = true
                                    }
                                    
                                    let newX = max(thumbSize / 2, min(gesture.location.x, geometry.size.width - thumbSize / 2))
                                    dragOffset = newX
                                    let newValue = calculateValueFromPosition(position: newX, width: geometry.size.width)
                                    updateValueWithHaptic(newValue)
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    dragOffset = 0
                                    // End of drag feedback
                                    HapticManager.shared.generateFeedback(.selection)
                                }
                        )
                }
                .frame(height: trackHeight)
                .padding(.vertical, thumbSize / 2)
                
                if showLabels {
                    HStack {
                        Text(lowLabel)
                            .font(.caption)
                            .foregroundColor(ColorConstants.textSecondary)
                        
                        Spacer()
                        
                        if showValue {
                            Text("\(value)")
                                .font(.subheadline)
                                .foregroundColor(getTrackColor())
                                .fontWeight(.bold)
                                .frame(minWidth: 24)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(ColorConstants.background)
                                        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                                )
                                .scaleEffect(isDragging ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3), value: isDragging)
                        }
                        
                        Spacer()
                        
                        Text(highLabel)
                            .font(.caption)
                            .foregroundColor(ColorConstants.textSecondary)
                    }
                }
            }
        }
        .frame(height: showLabels ? thumbSize + trackHeight + (showValue ? 30 : 20) : thumbSize + trackHeight)
        .accessibilityValue("\(value) of \(maxValue)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                if value < maxValue {
                    updateValueWithHaptic(value + 1)
                }
            case .decrement:
                if value > minValue {
                    updateValueWithHaptic(value - 1)
                }
            default:
                break
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculates the horizontal position of the thumb based on the current value
    private func calculateThumbPosition(width: CGFloat) -> CGFloat {
        let availableWidth = width - thumbSize
        let normalizedValue = CGFloat(value - minValue) / CGFloat(maxValue - minValue)
        return (normalizedValue * availableWidth) + thumbSize / 2
    }
    
    /// Calculates the value based on the thumb position
    private func calculateValueFromPosition(position: CGFloat, width: CGFloat) -> Int {
        let availableWidth = width - thumbSize
        let normalizedPosition = (position - thumbSize / 2) / availableWidth
        let rawValue = normalizedPosition * CGFloat(maxValue - minValue) + CGFloat(minValue)
        return min(maxValue, max(minValue, Int(rawValue.rounded())))
    }
    
    /// Gets the color for the filled portion of the track based on the emotion type
    private func getTrackColor() -> Color {
        if let color = accentColor {
            return color
        }
        return EmotionColors.forEmotionType(emotionType: emotionType)
    }
    
    /// Updates the value and provides haptic feedback if the value changed
    private func updateValueWithHaptic(_ newValue: Int) {
        if newValue != value {
            value = newValue
            
            // Provide haptic feedback based on the direction of change
            if isDragging {
                HapticManager.shared.generateFeedback(.light)
            }
            
            lastValue = newValue
        }
    }
}