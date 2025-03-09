import SwiftUI
import CardModifier
import ColorConstants
import IconButton
import Tool
import ToolCategory

/// A SwiftUI view that displays tool information in a card format
struct ToolCard: View {
    // MARK: - Properties
    
    let tool: Tool
    let isCompact: Bool
    let showActions: Bool
    let onTap: (() -> Void)?
    let onStart: (() -> Void)?
    let onFavoriteToggle: ((Bool) -> Void)?
    
    // MARK: - Initialization
    
    init(
        tool: Tool,
        isCompact: Bool = false,
        showActions: Bool = true,
        onTap: (() -> Void)? = nil,
        onStart: (() -> Void)? = nil,
        onFavoriteToggle: ((Bool) -> Void)? = nil
    ) {
        self.tool = tool
        self.isCompact = isCompact
        self.showActions = showActions
        self.onTap = onTap
        self.onStart = onStart
        self.onFavoriteToggle = onFavoriteToggle
    }
    
    // MARK: - Body
    
    var body: some View {
        if let onTap = onTap {
            Button(action: onTap) {
                cardContent
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            cardContent
        }
    }
    
    // MARK: - Card Content
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            
            if !isCompact {
                descriptionView
            }
            
            metadataView
            
            if showActions {
                actionsView
            }
        }
        .cardStyle(
            backgroundColor: ColorConstants.surface,
            cornerRadius: 16,
            padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
            shadowRadius: 4,
            shadowX: 0,
            shadowY: 2,
            shadowOpacity: 0.1
        )
        .background(categoryColor)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tool.name), \(tool.category.displayName()), \(tool.formattedDuration())")
    }
    
    // MARK: - Helper Views
    
    /// Creates the header section of the tool card
    private var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: tool.category.iconName())
                .font(.system(size: 20))
                .foregroundColor(tool.category.color())
                .frame(width: 32, height: 32)
                .background(tool.category.color().opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tool.name)
                    .font(.headline)
                    .foregroundColor(ColorConstants.textPrimary)
                    .lineLimit(1)
                
                Text(tool.category.displayName())
                    .font(.subheadline)
                    .foregroundColor(ColorConstants.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
    }
    
    /// Creates a view showing the tool description
    private var descriptionView: some View {
        Text(tool.description)
            .font(.body)
            .foregroundColor(ColorConstants.textSecondary)
            .lineLimit(isCompact ? 2 : 3)
            .padding(.vertical, 4)
    }
    
    /// Creates a view showing the tool metadata (duration, difficulty)
    private var metadataView: some View {
        HStack(spacing: 16) {
            // Duration
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundColor(ColorConstants.textSecondary)
                
                Text(tool.formattedDuration())
                    .font(.caption)
                    .foregroundColor(ColorConstants.textSecondary)
            }
            
            // Difficulty
            HStack(spacing: 4) {
                Image(systemName: difficultyIcon)
                    .font(.system(size: 14))
                    .foregroundColor(ColorConstants.textSecondary)
                
                Text(tool.difficulty.displayName())
                    .font(.caption)
                    .foregroundColor(ColorConstants.textSecondary)
            }
            
            Spacer()
        }
    }
    
    /// Creates a view with action buttons for the tool
    private var actionsView: some View {
        HStack {
            Spacer()
            
            // Start button
            if let onStart = onStart {
                IconButton(
                    systemName: "play.fill",
                    label: "Comenzar \(tool.name)",
                    iconColor: .white,
                    backgroundColor: ColorConstants.primary,
                    size: 40,
                    iconSize: 16,
                    hasShadow: true,
                    action: onStart
                )
            }
            
            // Favorite button
            if let onFavoriteToggle = onFavoriteToggle {
                IconButton(
                    systemName: tool.isFavorite ? "heart.fill" : "heart",
                    label: tool.isFavorite ? "Quitar de favoritos" : "Añadir a favoritos",
                    iconColor: tool.isFavorite ? ColorConstants.primary : ColorConstants.textSecondary,
                    backgroundColor: ColorConstants.surface,
                    size: 40,
                    iconSize: 16,
                    hasShadow: false,
                    action: {
                        onFavoriteToggle(!tool.isFavorite)
                    }
                )
            }
        }
        .padding(.top, 8)
    }
    
    /// Calculates the appropriate background color for the card based on the tool category
    private var categoryColor: Color {
        tool.category.color().opacity(0.15)
    }
    
    /// Returns the appropriate icon for the tool's difficulty level
    private var difficultyIcon: String {
        switch tool.difficulty {
        case .beginner:
            return "1.circle"
        case .intermediate:
            return "2.circle"
        case .advanced:
            return "3.circle"
        }
    }
}