//
//  WaveformAnimation.swift
//  AmiraWellness
//
//  Created for the Amira Wellness application
//

import SwiftUI // iOS SDK
import Combine // iOS SDK

/// A SwiftUI view that displays an animated audio waveform visualization based on real-time audio levels
struct WaveformAnimation: View {
    // MARK: - Properties
    
    private let barCount: Int
    private let spacing: CGFloat
    private let minBarHeight: CGFloat
    private let maxBarHeight: CGFloat
    private let primaryColor: Color
    private let secondaryColor: Color
    
    @State private var barHeights: [CGFloat]
    @State private var size: CGSize = .zero
    @State private var currentLevel: Float = 0
    @State private var recordingState: RecordingState = .idle
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes a new WaveformAnimation with customizable parameters
    /// - Parameters:
    ///   - barCount: Number of bars in the waveform (default: 30)
    ///   - spacing: Spacing between bars (default: 4)
    ///   - minBarHeight: Minimum height of each bar (default: 3)
    ///   - maxBarHeight: Maximum height of each bar (default: 50)
    ///   - primaryColor: Primary color for the waveform (default: ColorConstants.primary)
    ///   - secondaryColor: Secondary color for the waveform (default: ColorConstants.secondary)
    init(
        barCount: Int = 30,
        spacing: CGFloat = 4,
        minBarHeight: CGFloat = 3,
        maxBarHeight: CGFloat = 50,
        primaryColor: Color? = nil,
        secondaryColor: Color? = nil
    ) {
        self.barCount = barCount
        self.spacing = spacing
        self.minBarHeight = minBarHeight
        self.maxBarHeight = maxBarHeight
        self.primaryColor = primaryColor ?? ColorConstants.primary
        self.secondaryColor = secondaryColor ?? ColorConstants.secondary
        self._barHeights = State(initialValue: Array(repeating: minBarHeight, count: barCount))
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            HStack(spacing: spacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    WaveformBar(
                        height: barHeights[index],
                        color: colorForIndex(index)
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: barHeights[index])
                }
            }
        }
        .readSize(onChange: $size)
        .onAppear {
            setupSubscriptions()
        }
        .onDisappear {
            cancelSubscriptions()
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up Combine subscriptions to audio level and recording state publishers
    private func setupSubscriptions() {
        AudioRecordingService.shared.audioLevelPublisher
            .sink { [weak self] level in
                self?.currentLevel = level
                self?.updateBarHeights()
            }
            .store(in: &cancellables)
        
        AudioRecordingService.shared.recordingStatePublisher
            .sink { [weak self] state in
                self?.recordingState = state
                
                // If state changes and we're not recording or paused, reset the visualization
                if state != .recording && state != .paused {
                    self?.resetBarHeights()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Cancels all active Combine subscriptions
    private func cancelSubscriptions() {
        cancellables.removeAll()
    }
    
    /// Updates the bar heights based on current audio level
    private func updateBarHeights() {
        guard recordingState == .recording else { return }
        
        // Shift existing heights to the right
        for i in (1..<barCount).reversed() {
            barHeights[i] = barHeights[i-1]
        }
        
        // Calculate new height for the first bar based on audio level
        let levelHeight = CGFloat(currentLevel) * maxBarHeight
        let randomness = CGFloat.random(in: -2...2) // Add slight randomness for natural appearance
        let newHeight = max(minBarHeight, min(maxBarHeight, levelHeight + randomness))
        barHeights[0] = newHeight
    }
    
    /// Resets all bar heights to minimum value
    private func resetBarHeights() {
        barHeights = Array(repeating: minBarHeight, count: barCount)
    }
    
    /// Calculates color for a bar based on its index for gradient effect
    /// - Parameter index: The index of the bar
    /// - Returns: The color for the specified bar index
    private func colorForIndex(_ index: Int) -> Color {
        let position = CGFloat(index) / CGFloat(barCount)
        return position < 0.5 ? primaryColor : secondaryColor
    }
}

/// A helper view representing a single bar in the waveform visualization
private struct WaveformBar: View {
    let height: CGFloat
    let color: Color
    let width: CGFloat
    let cornerRadius: CGFloat
    
    /// Initializes a new WaveformBar with specified parameters
    /// - Parameters:
    ///   - height: The height of the bar
    ///   - color: The color of the bar
    ///   - width: The width of the bar (default: 3)
    ///   - cornerRadius: The corner radius of the bar (default: 1.5)
    init(
        height: CGFloat,
        color: Color,
        width: CGFloat = 3,
        cornerRadius: CGFloat = 1.5
    ) {
        self.height = height
        self.color = color
        self.width = width
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Rectangle()
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .foregroundColor(color)
    }
}