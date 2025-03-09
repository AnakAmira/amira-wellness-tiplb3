import SwiftUI

/// A SwiftUI view that displays journal entry information in a card format
struct JournalCard: View {
    // MARK: - Properties
    
    /// The journal entry to display
    let journal: Journal
    
    /// Whether to show the emotional shift section
    let showEmotionalShift: Bool
    
    /// Whether to show action buttons
    let showActions: Bool
    
    /// Callback for when the card is tapped
    let onTap: (() -> Void)?
    
    /// Callback for when the play button is tapped
    let onPlay: (() -> Void)?
    
    /// Callback for when the favorite button is toggled
    let onFavoriteToggle: ((Bool) -> Void)?
    
    /// Callback for when the export button is tapped
    let onExport: (() -> Void)?
    
    /// Callback for when the delete button is tapped
    let onDelete: (() -> Void)?
    
    // MARK: - Initialization
    
    /// Initializes a new JournalCard with the specified journal entry and callbacks
    init(
        journal: Journal,
        showEmotionalShift: Bool = true,
        showActions: Bool = true,
        onTap: (() -> Void)? = nil,
        onPlay: (() -> Void)? = nil,
        onFavoriteToggle: ((Bool) -> Void)? = nil,
        onExport: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.journal = journal
        self.showEmotionalShift = showEmotionalShift
        self.showActions = showActions
        self.onTap = onTap
        self.onPlay = onPlay
        self.onFavoriteToggle = onFavoriteToggle
        self.onExport = onExport
        self.onDelete = onDelete
    }
    
    // MARK: - Body
    
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
            backgroundColor: ColorConstants.surface,
            cornerRadius: 12
        )
        .background(emotionColor)
        .accessibilityLabel("Grabación de voz: \(journal.title)")
        .accessibilityHint("Toca dos veces para ver detalles")
    }
    
    // MARK: - Private Views
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            
            durationView
            
            if showEmotionalShift, journal.postEmotionalState != nil {
                emotionalShiftView
            }
            
            if showActions {
                actionsView
            }
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "mic.fill")
                .foregroundColor(ColorConstants.primary)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(journal.title)
                    .font(.headline)
                    .foregroundColor(ColorConstants.textPrimary)
                    .lineLimit(1)
                
                Text(journal.formattedDate())
                    .font(.subheadline)
                    .foregroundColor(ColorConstants.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if !journal.isUploaded {
                Image(systemName: "icloud.and.arrow.up")
                    .foregroundColor(ColorConstants.secondary)
                    .font(.system(size: 18))
                    .accessibilityLabel("Pendiente de subir")
            }
        }
    }
    
    private var durationView: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .foregroundColor(ColorConstants.textSecondary)
                .font(.system(size: 14))
            
            Text(journal.formattedDuration())
                .font(.subheadline)
                .foregroundColor(ColorConstants.textSecondary)
            
            Spacer()
        }
    }
    
    private var emotionalShiftView: some View {
        if let shift = journal.getEmotionalShift() {
            return VStack(alignment: .leading, spacing: 8) {
                Text("Cambio emocional:")
                    .font(.subheadline)
                    .foregroundColor(ColorConstants.textSecondary)
                
                HStack(spacing: 16) {
                    // Pre emotional state
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Antes:")
                            .font(.caption)
                            .foregroundColor(ColorConstants.textSecondary)
                        
                        Text(journal.preEmotionalState.summary())
                            .font(.subheadline)
                            .foregroundColor(EmotionColors.forEmotionType(emotionType: journal.preEmotionalState.emotionType))
                    }
                    
                    // Arrow indicator
                    Image(systemName: "arrow.right")
                        .foregroundColor(ColorConstants.textSecondary)
                    
                    // Post emotional state
                    if let postState = journal.postEmotionalState {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Después:")
                                .font(.caption)
                                .foregroundColor(ColorConstants.textSecondary)
                            
                            Text(postState.summary())
                                .font(.subheadline)
                                .foregroundColor(EmotionColors.forEmotionType(emotionType: postState.emotionType))
                        }
                    }
                    
                    Spacer()
                    
                    // Shift indicator icon
                    Image(systemName: shift.isPositive() ? "arrow.up.circle.fill" : 
                          shift.isNegative() ? "arrow.down.circle.fill" : 
                          "equal.circle.fill")
                        .foregroundColor(shift.isPositive() ? ColorConstants.success : 
                                        shift.isNegative() ? ColorConstants.warning : 
                                        ColorConstants.textSecondary)
                        .font(.system(size: 20))
                        .accessibilityLabel(shift.isPositive() ? "Cambio positivo" : 
                                           shift.isNegative() ? "Cambio negativo" : 
                                           "Sin cambio significativo")
                }
                .padding(8)
                .background(Color.white.opacity(0.5))
                .cornerRadius(8)
            }
            .padding(.vertical, 4)
        } else {
            return EmptyView()
        }
    }
    
    private var actionsView: some View {
        HStack(spacing: 12) {
            Spacer()
            
            if let onPlay = onPlay {
                IconButton(
                    systemName: "play.fill",
                    label: "Reproducir grabación",
                    iconColor: ColorConstants.primary,
                    backgroundColor: Color.white,
                    size: 36,
                    iconSize: 14,
                    action: onPlay
                )
            }
            
            if let onFavoriteToggle = onFavoriteToggle {
                IconButton(
                    systemName: journal.isFavorite ? "heart.fill" : "heart",
                    label: journal.isFavorite ? "Quitar de favoritos" : "Añadir a favoritos",
                    iconColor: journal.isFavorite ? ColorConstants.secondary : ColorConstants.textSecondary,
                    backgroundColor: Color.white,
                    size: 36,
                    iconSize: 14,
                    action: { onFavoriteToggle(!journal.isFavorite) }
                )
            }
            
            if let onExport = onExport {
                IconButton(
                    systemName: "square.and.arrow.up",
                    label: "Exportar grabación",
                    iconColor: ColorConstants.textSecondary,
                    backgroundColor: Color.white,
                    size: 36,
                    iconSize: 14,
                    action: onExport
                )
            }
            
            if let onDelete = onDelete {
                IconButton(
                    systemName: "trash",
                    label: "Eliminar grabación",
                    iconColor: ColorConstants.error,
                    backgroundColor: Color.white,
                    size: 36,
                    iconSize: 14,
                    action: onDelete
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// Returns a suitable background color based on the primary emotion
    private var emotionColor: Color {
        return EmotionColors.forEmotionType(emotionType: journal.preEmotionalState.emotionType).opacity(0.15)
    }
}