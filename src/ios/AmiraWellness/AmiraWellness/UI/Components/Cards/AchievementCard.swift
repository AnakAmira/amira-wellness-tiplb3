//
//  AchievementCard.swift
//  AmiraWellness
//
//  Created for Amira Wellness application
//

import SwiftUI // iOS SDK
import struct ../../../Models/Achievement.Achievement
import enum ../../../Models/Achievement.AchievementCategory
import struct ../../../Core/Constants/ColorConstants.ColorConstants
import struct ../../../Core/Modifiers/CardModifier.CardModifier

/// A SwiftUI view that displays achievement information in a card format
struct AchievementCard: View {
    // MARK: - Properties
    
    /// The achievement to display
    let achievement: Achievement
    
    /// Whether to show detailed information about the achievement
    let showDetails: Bool
    
    /// Whether the achievement is locked/unavailable
    let isLocked: Bool
    
    /// Optional action to execute when the card is tapped
    let onTap: (() -> Void)?
    
    // MARK: - Initializers
    
    /// Initializes a new AchievementCard with the specified achievement
    /// - Parameters:
    ///   - achievement: The achievement to display
    ///   - showDetails: Whether to show the achievement description (default: true)
    ///   - isLocked: Whether the achievement is locked (default: false)
    ///   - onTap: Optional closure to execute when the card is tapped (default: nil)
    init(
        achievement: Achievement,
        showDetails: Bool = true,
        isLocked: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.achievement = achievement
        self.showDetails = showDetails
        self.isLocked = isLocked
        self.onTap = onTap
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
    
    // MARK: - Private Views
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            
            Divider()
                .background(ColorConstants.divider)
                .padding(.vertical, 4)
            
            progressView
            
            if showDetails {
                detailsView
            }
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 16, trailing: 16))
        .cardStyle(
            backgroundColor: ColorConstants.surface,
            cornerRadius: 12,
            padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
            shadowRadius: 3,
            shadowY: 1,
            shadowOpacity: 0.08
        )
        .overlay(
            isLocked ? lockedOverlayView : nil
        )
    }
    
    private var headerView: some View {
        HStack(spacing: 12) {
            // Achievement icon
            if !achievement.iconUrl.isEmpty {
                AsyncImage(url: URL(string: achievement.iconUrl)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if phase.error != nil {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(ColorConstants.secondary)
                    } else {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(ColorConstants.secondary)
                            .opacity(0.3)
                    }
                }
                .frame(width: 36, height: 36)
            } else {
                Image(systemName: "trophy.fill")
                    .foregroundColor(ColorConstants.secondary)
                    .frame(width: 36, height: 36)
            }
            
            // Achievement name
            Text(achievement.name)
                .font(.headline)
                .foregroundColor(ColorConstants.textPrimary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
    
    private var progressView: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .foregroundColor(ColorConstants.divider)
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    // Progress fill
                    Rectangle()
                        .foregroundColor(achievement.isEarned() ? ColorConstants.success : ColorConstants.primary)
                        .frame(width: geometry.size.width * CGFloat(achievement.getProgressPercentage()), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            // Progress text
            HStack {
                if achievement.isEarned() {
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(ColorConstants.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(ColorConstants.success.opacity(0.1))
                        .cornerRadius(4)
                } else {
                    Text("\(Int(achievement.getProgressPercentage() * 100))% complete")
                        .font(.caption)
                        .foregroundColor(ColorConstants.textSecondary)
                }
                
                Spacer()
            }
        }
    }
    
    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Description
            Text(achievement.description)
                .font(.body)
                .foregroundColor(ColorConstants.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
            
            // Earned date if applicable
            if achievement.isEarned(), !achievement.getFormattedEarnedDate().isEmpty {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(ColorConstants.textTertiary)
                    
                    Text("Earned on \(achievement.getFormattedEarnedDate())")
                        .font(.caption)
                        .foregroundColor(ColorConstants.textTertiary)
                }
                .padding(.top, 4)
            }
        }
    }
    
    private var lockedOverlayView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
            
            Image(systemName: "lock.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Accessibility
    
    private var accessibilityLabel: Text {
        if achievement.isEarned() {
            return Text("Completed achievement: \(achievement.name)")
        } else if isLocked {
            return Text("Locked achievement: \(achievement.name)")
        } else {
            return Text("In progress achievement: \(achievement.name), \(Int(achievement.getProgressPercentage() * 100))% complete")
        }
    }
    
    private var accessibilityHint: Text {
        if let _ = onTap {
            return Text("Double tap to view achievement details")
        } else {
            return Text("")
        }
    }
}

#if DEBUG
struct AchievementCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Complete achievement
            AchievementCard(
                achievement: Achievement(
                    id: UUID(),
                    type: .streak3Days,
                    category: .streak,
                    name: "3-Day Streak",
                    description: "Use the app for 3 consecutive days",
                    iconUrl: "",
                    points: 10,
                    isHidden: false,
                    earnedDate: Date(),
                    progress: 1.0
                )
            )
            
            // In-progress achievement
            AchievementCard(
                achievement: Achievement(
                    id: UUID(),
                    type: .streak7Days,
                    category: .streak,
                    name: "7-Day Streak",
                    description: "Use the app for 7 consecutive days",
                    iconUrl: "",
                    points: 20,
                    isHidden: false,
                    earnedDate: nil,
                    progress: 0.43
                )
            )
            
            // Locked achievement
            AchievementCard(
                achievement: Achievement(
                    id: UUID(),
                    type: .streak30Days,
                    category: .streak,
                    name: "30-Day Streak",
                    description: "Use the app for 30 consecutive days",
                    iconUrl: "",
                    points: 50,
                    isHidden: false
                ),
                isLocked: true
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif