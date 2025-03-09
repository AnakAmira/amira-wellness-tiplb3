import SwiftUI

/// A reusable SwiftUI component that displays emotional state information in a card format,
/// following the app's minimalist, nature-inspired design language.
struct EmotionCard: View {
    let emotionalState: EmotionalState
    let showContext: Bool
    let showDate: Bool
    let showNotes: Bool
    let onTap: (() -> Void)?
    
    /// Initializes a new EmotionCard with the specified emotional state
    /// - Parameters:
    ///   - emotionalState: The emotional state to display
    ///   - showContext: Whether to show the context of the emotional check-in
    ///   - showDate: Whether to show the date of the check-in
    ///   - showNotes: Whether to show notes associated with the emotional state
    ///   - onTap: Optional callback for when the card is tapped
    init(
        emotionalState: EmotionalState,
        showContext: Bool = true,
        showDate: Bool = false,
        showNotes: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.emotionalState = emotionalState
        self.showContext = showContext
        self.showDate = showDate
        self.showNotes = showNotes
        self.onTap = onTap
    }
    
    var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: onTap) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
        .cardStyle(
            backgroundColor: emotionColor,
            shadowRadius: 2,
            shadowY: 1,
            shadowOpacity: 0.1
        )
        .accessibilityLabel(Text("Emotion: \(emotionalState.emotionType.displayName()), Intensity: \(emotionalState.formattedIntensity())"))
        .accessibilityHint(Text("Contains details about your emotional state"))
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            emotionHeaderView()
            
            if showContext {
                contextView()
            }
            
            if showDate {
                dateView()
            }
            
            if showNotes, let notes = emotionalState.notes, !notes.isEmpty {
                notesView()
            }
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    }
    
    /// Creates the header section of the emotion card with emotion type and intensity
    private func emotionHeaderView() -> some View {
        HStack {
            Text(emotionalState.emotionType.displayName())
                .font(.headline)
                .foregroundColor(ColorConstants.textPrimary)
            
            Spacer()
            
            Text(emotionalState.formattedIntensity())
                .font(.subheadline)
                .foregroundColor(ColorConstants.textSecondary)
        }
    }
    
    /// Creates a view showing the context of the emotional check-in
    private func contextView() -> some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(ColorConstants.textSecondary)
            
            Text(emotionalState.context.displayName())
                .font(.caption)
                .foregroundColor(ColorConstants.textSecondary)
        }
    }
    
    /// Creates a view showing the date of the emotional check-in
    private func dateView() -> some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(ColorConstants.textSecondary)
            
            Text(emotionalState.formattedDate())
                .font(.caption)
                .foregroundColor(ColorConstants.textSecondary)
        }
    }
    
    /// Creates a view showing any notes associated with the emotional state
    private func notesView() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notas:")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(ColorConstants.textSecondary)
            
            Text(emotionalState.notes ?? "")
                .font(.caption)
                .foregroundColor(ColorConstants.textSecondary)
                .padding(8)
                .background(ColorConstants.surface.opacity(0.5))
                .cornerRadius(6)
        }
    }
    
    /// Calculates the appropriate background color for the card based on the emotion type
    private var emotionColor: Color {
        EmotionColors.forEmotionType(emotionType: emotionalState.emotionType).opacity(0.15)
    }
}