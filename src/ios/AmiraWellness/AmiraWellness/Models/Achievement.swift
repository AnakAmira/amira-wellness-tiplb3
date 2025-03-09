import Foundation // Latest

enum AchievementType: String, Codable, CaseIterable, Equatable {
    case firstStep
    case streak3Days
    case streak7Days
    case streak14Days
    case streak30Days
    case journals5
    case journals10
    case journals25
    case emotionalCheckins10
    case emotionalCheckins25
    case toolsExplorer
    case toolsMaster
}

enum AchievementCategory: String, Codable, CaseIterable, Equatable {
    case streak
    case journaling
    case emotionalAwareness
    case toolUsage
    case milestone
}

struct Achievement: Codable, Identifiable, Equatable {
    let id: UUID
    let type: AchievementType
    let category: AchievementCategory
    let name: String
    let description: String
    let iconUrl: String
    let points: Int
    let isHidden: Bool
    let earnedDate: Date?
    let progress: Double
    
    // Private properties for JSON storage
    private var criteriaJSON: String?
    private var metadataJSON: String?
    
    // Computed properties for dictionary interface
    var criteria: [String: Any]? {
        guard let jsonString = criteriaJSON,
              let data = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return dict
    }
    
    var metadata: [String: Any]? {
        guard let jsonString = metadataJSON,
              let data = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return dict
    }
    
    // Custom coding keys
    enum CodingKeys: String, CodingKey {
        case id, type, category, name, description, iconUrl, points, isHidden, earnedDate, progress, criteriaJSON, metadataJSON
    }
    
    // Initializer
    init(id: UUID, type: AchievementType, category: AchievementCategory, name: String, description: String, iconUrl: String, points: Int, isHidden: Bool, earnedDate: Date? = nil, progress: Double = 0.0, criteria: [String: Any]? = nil, metadata: [String: Any]? = nil) {
        self.id = id
        self.type = type
        self.category = category
        self.name = name
        self.description = description
        self.iconUrl = iconUrl
        self.points = points
        self.isHidden = isHidden
        self.earnedDate = earnedDate
        self.progress = progress
        
        // Convert dictionaries to JSON strings
        if let criteria = criteria, 
           let data = try? JSONSerialization.data(withJSONObject: criteria),
           let jsonString = String(data: data, encoding: .utf8) {
            self.criteriaJSON = jsonString
        } else {
            self.criteriaJSON = nil
        }
        
        if let metadata = metadata,
           let data = try? JSONSerialization.data(withJSONObject: metadata),
           let jsonString = String(data: data, encoding: .utf8) {
            self.metadataJSON = jsonString
        } else {
            self.metadataJSON = nil
        }
    }
    
    // Manual implementation of Codable
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(AchievementType.self, forKey: .type)
        category = try container.decode(AchievementCategory.self, forKey: .category)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        iconUrl = try container.decode(String.self, forKey: .iconUrl)
        points = try container.decode(Int.self, forKey: .points)
        isHidden = try container.decode(Bool.self, forKey: .isHidden)
        earnedDate = try container.decodeIfPresent(Date.self, forKey: .earnedDate)
        progress = try container.decode(Double.self, forKey: .progress)
        criteriaJSON = try container.decodeIfPresent(String.self, forKey: .criteriaJSON)
        metadataJSON = try container.decodeIfPresent(String.self, forKey: .metadataJSON)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(category, forKey: .category)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(iconUrl, forKey: .iconUrl)
        try container.encode(points, forKey: .points)
        try container.encode(isHidden, forKey: .isHidden)
        try container.encodeIfPresent(earnedDate, forKey: .earnedDate)
        try container.encode(progress, forKey: .progress)
        try container.encodeIfPresent(criteriaJSON, forKey: .criteriaJSON)
        try container.encodeIfPresent(metadataJSON, forKey: .metadataJSON)
    }
    
    // Functions
    func isEarned() -> Bool {
        return earnedDate != nil
    }
    
    func getProgressPercentage() -> Double {
        if isEarned() {
            return 1.0
        }
        return progress
    }
    
    func getFormattedEarnedDate() -> String {
        guard let date = earnedDate else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func getCriteriaDescription() -> String {
        guard let criteria = criteria else {
            return "Complete the required actions to earn this achievement."
        }
        
        if let count = criteria["count"] as? Int, let action = criteria["action"] as? String {
            return "Complete \(count) \(action) to earn this achievement."
        }
        
        return "Complete the required actions to earn this achievement."
    }
    
    func getNextAchievementType() -> AchievementType? {
        guard let metadata = metadata, let nextAchievement = metadata["nextAchievement"] as? String else {
            return nil
        }
        
        return AchievementType(rawValue: nextAchievement)
    }
}

struct AchievementResponse: Codable {
    let achievements: [Achievement]
    let totalEarned: Int
    let totalAvailable: Int
    
    init(achievements: [Achievement], totalEarned: Int, totalAvailable: Int) {
        self.achievements = achievements
        self.totalEarned = totalEarned
        self.totalAvailable = totalAvailable
    }
}