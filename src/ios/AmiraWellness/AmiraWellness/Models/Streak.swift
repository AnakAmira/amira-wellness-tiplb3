import Foundation // Latest

// Define streak milestones (in days)
let streakMilestones = [3, 7, 14, 30, 60, 90, 180, 365]

/// Model representing a user's streak of consistent app usage
struct Streak: Codable, Equatable {
    let id: UUID
    let userId: UUID
    var currentStreak: Int
    var longestStreak: Int
    var lastActivityDate: Date?
    var activityDates: [Date]
    var totalDaysActive: Int
    var hasGracePeriodUsed: Bool
    
    /// Initializes a Streak with the provided parameters
    init(id: UUID = UUID(), 
         userId: UUID, 
         currentStreak: Int = 0, 
         longestStreak: Int = 0, 
         lastActivityDate: Date? = nil, 
         activityDates: [Date] = [], 
         totalDaysActive: Int = 0, 
         hasGracePeriodUsed: Bool = false) {
        self.id = id
        self.userId = userId
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastActivityDate = lastActivityDate
        self.activityDates = activityDates
        self.totalDaysActive = totalDaysActive
        self.hasGracePeriodUsed = hasGracePeriodUsed
    }
    
    /// Updates the streak based on a new activity date
    /// - Parameter activityDate: The date of the new activity
    /// - Returns: True if the streak increased, false otherwise
    mutating func updateStreak(activityDate: Date) -> Bool {
        // Check if this activity date has already been recorded
        let calendar = Calendar.current
        let normalizedActivityDate = calendar.startOfDay(for: activityDate)
        
        // If the activity date is already recorded, no change to streak
        if activityDates.contains(where: { calendar.isDate($0, inSameDayAs: normalizedActivityDate) }) {
            return false
        }
        
        // If this is the first activity, initialize streak
        guard let lastDate = lastActivityDate else {
            currentStreak = 1
            lastActivityDate = normalizedActivityDate
            activityDates.append(normalizedActivityDate)
            totalDaysActive += 1
            updateLongestStreak()
            return true
        }
        
        // Normalize the last activity date to start of day
        let normalizedLastDate = calendar.startOfDay(for: lastDate)
        
        // Calculate days between last activity and current activity
        let components = calendar.dateComponents([.day], from: normalizedLastDate, to: normalizedActivityDate)
        guard let daysSinceLastActivity = components.day else {
            return false
        }
        
        var streakIncreased = false
        
        switch daysSinceLastActivity {
        case 0:
            // Same day activity, no change to streak
            return false
            
        case 1:
            // Next day activity, increase streak
            currentStreak += 1
            streakIncreased = true
            
        case 2:
            // Missed one day, can use grace period
            if !hasGracePeriodUsed {
                currentStreak += 1
                hasGracePeriodUsed = true
                streakIncreased = true
            } else {
                // Grace period already used, reset streak
                currentStreak = 1
                hasGracePeriodUsed = false
            }
            
        default:
            // Missed more than one day, reset streak
            currentStreak = 1
            hasGracePeriodUsed = false
        }
        
        // Update streak-related properties
        lastActivityDate = normalizedActivityDate
        activityDates.append(normalizedActivityDate)
        totalDaysActive += 1
        updateLongestStreak()
        
        return streakIncreased
    }
    
    /// Updates the longest streak if current streak is greater
    private mutating func updateLongestStreak() {
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
    }
    
    /// Calculates the next streak milestone to achieve
    /// - Returns: Days needed for next milestone or 0 if all milestones achieved
    func getNextMilestone() -> Int {
        for milestone in streakMilestones.sorted() {
            if milestone > currentStreak {
                return milestone
            }
        }
        return 0 // All milestones achieved
    }
    
    /// Calculates the progress percentage towards the next milestone
    /// - Returns: Progress percentage between 0.0 and 1.0
    func progressToNextMilestone() -> Double {
        let nextMilestone = getNextMilestone()
        if nextMilestone == 0 {
            return 1.0 // All milestones achieved
        }
        
        // Find the previous milestone or use 0 if this is the first milestone
        var previousMilestone = 0
        for milestone in streakMilestones.sorted() {
            if milestone > currentStreak {
                break
            }
            previousMilestone = milestone
        }
        
        // Calculate progress between previous and next milestone
        let progress = Double(currentStreak - previousMilestone) / Double(nextMilestone - previousMilestone)
        return max(0.0, min(1.0, progress)) // Ensure progress is between 0 and 1
    }
    
    /// Determines if the streak is still active (activity within the last day)
    /// - Returns: True if streak is active, false otherwise
    func isActive() -> Bool {
        guard let lastDate = lastActivityDate else {
            return false
        }
        
        let calendar = Calendar.current
        let normalizedLastDate = calendar.startOfDay(for: lastDate)
        let normalizedCurrentDate = calendar.startOfDay(for: Date())
        
        let components = calendar.dateComponents([.day], from: normalizedLastDate, to: normalizedCurrentDate)
        guard let daysSinceLastActivity = components.day else {
            return false
        }
        
        // Streak is active if last activity was today or yesterday
        return daysSinceLastActivity <= 1
    }
    
    /// Determines if the grace period can be used for the current streak
    /// - Returns: True if grace period can be used, false otherwise
    func canUseGracePeriod() -> Bool {
        return !hasGracePeriodUsed
    }
    
    /// Resets the grace period usage flag
    mutating func resetGracePeriod() {
        hasGracePeriodUsed = false
    }
    
    /// Returns the activity history for a specified period
    /// - Parameter days: Number of days to include in history
    /// - Returns: Array of activity dates within the specified period
    func getActivityHistory(days: Int) -> [Date] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            return []
        }
        
        return activityDates.filter { $0 >= startDate }
    }
}

/// Notification structure for when a streak milestone is reached
struct StreakMilestoneReached {
    static let notificationName = Notification.Name("AmiraWellness.StreakMilestoneReached")
    static let milestoneKey = "milestone"
    static let streakKey = "streak"
}