import SwiftUI

// Number of columns in the emotion grid
let GRID_COLUMNS = 4

// Spacing between grid items
let GRID_SPACING: CGFloat = 12.0

/// A SwiftUI component that provides a grid-based selector for choosing emotion types
/// during emotional check-ins. It displays emotion icons with labels in a visually
/// appealing grid layout, with visual feedback for the selected emotion.
struct EmotionSelector: View {
    // Binding to the selected emotion
    @Binding var selectedEmotion: EmotionType
    
    // Optional callback when an emotion is selected
    var onEmotionSelected: ((EmotionType) -> Void)?
    
    /// Initializes a new EmotionSelector with the specified binding and optional callback
    /// - Parameters:
    ///   - selectedEmotion: Binding to the selected emotion
    ///   - onEmotionSelected: Optional callback when an emotion is selected
    init(selectedEmotion: Binding<EmotionType>, onEmotionSelected: ((EmotionType) -> Void)? = nil) {
        self._selectedEmotion = selectedEmotion
        self.onEmotionSelected = onEmotionSelected
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title label
            Text("Emoción principal:")
                .font(.headline)
                .foregroundColor(ColorConstants.textPrimary)
                .accessibility(label: Text("Select primary emotion"))
            
            // Grid of emotion options
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: GRID_SPACING), count: GRID_COLUMNS), spacing: GRID_SPACING) {
                // Create a grid item for each emotion type
                ForEach(EmotionType.allCases, id: \.self) { emotion in
                    EmotionGridItem(
                        emotion: emotion,
                        isSelected: selectedEmotion == emotion,
                        onSelect: {
                            selectEmotion(emotion)
                        }
                    )
                    .accessibility(label: Text(emotion.displayName()))
                    .accessibility(hint: Text("Double tap to select this emotion"))
                    .accessibility(addTraits: selectedEmotion == emotion ? .isSelected : [])
                }
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(ColorConstants.surface)
        .cornerRadius(12)
    }
    
    /// Handles the selection of an emotion type
    /// - Parameter emotion: The selected emotion
    private func selectEmotion(_ emotion: EmotionType) {
        selectedEmotion = emotion
        Haptics.shared.play()
        onEmotionSelected?(emotion)
    }
}

/// A SwiftUI view that represents a single emotion option in the grid
struct EmotionGridItem: View {
    // The emotion this grid item represents
    let emotion: EmotionType
    
    // Whether this emotion is currently selected
    let isSelected: Bool
    
    // Callback when this emotion is selected
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // Emotion icon
                Image(emotionIconName())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundColor(isSelected ? emotion.color() : ColorConstants.textSecondary)
                
                // Emotion name
                Text(emotion.displayName())
                    .font(.caption)
                    .fontWeight(isSelected ? .medium : .regular)
                    .foregroundColor(isSelected ? emotion.color() : ColorConstants.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding(12)
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(emotion.color().opacity(isSelected ? 0.2 : 0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? emotion.color() : ColorConstants.border, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? emotion.color().opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// Determines the appropriate icon name for the emotion
    /// - Returns: The icon name to use for the emotion
    private func emotionIconName() -> String {
        return "emotion_\(emotion.rawValue.lowercased())"
    }
}