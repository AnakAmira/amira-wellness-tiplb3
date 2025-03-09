import Foundation // For basic data types and JSON handling

// MARK: - TrendDirection

@frozen
enum TrendDirection: String, Codable {
    case increasing
    case decreasing
    case stable
    case fluctuating
    
    func displayName() -> String {
        switch self {
        case .increasing:
            return NSLocalizedString("En aumento", comment: "Increasing trend direction")
        case .decreasing:
            return NSLocalizedString("En descenso", comment: "Decreasing trend direction")
        case .stable:
            return NSLocalizedString("Estable", comment: "Stable trend direction")
        case .fluctuating:
            return NSLocalizedString("Fluctuante", comment: "Fluctuating trend direction")
        }
    }
    
    func description() -> String {
        switch self {
        case .increasing:
            return NSLocalizedString("Esta emoción ha estado aumentando con el tiempo", comment: "Increasing trend description")
        case .decreasing:
            return NSLocalizedString("Esta emoción ha estado disminuyendo con el tiempo", comment: "Decreasing trend description")
        case .stable:
            return NSLocalizedString("Esta emoción ha permanecido constante", comment: "Stable trend description")
        case .fluctuating:
            return NSLocalizedString("Esta emoción ha estado fluctuando considerablemente", comment: "Fluctuating trend description")
        }
    }
    
    func icon() -> String {
        switch self {
        case .increasing:
            return "arrow.up.right"
        case .decreasing:
            return "arrow.down.right"
        case .stable:
            return "arrow.right"
        case .fluctuating:
            return "waveform.path"
        }
    }
}

// MARK: - TrendPeriodType

@frozen
enum TrendPeriodType: String, Codable {
    case daily
    case weekly
    case monthly
    
    func displayName() -> String {
        switch self {
        case .daily:
            return NSLocalizedString("Diario", comment: "Daily period type")
        case .weekly:
            return NSLocalizedString("Semanal", comment: "Weekly period type")
        case .monthly:
            return NSLocalizedString("Mensual", comment: "Monthly period type")
        }
    }
    
    func dateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        
        switch self {
        case .daily:
            formatter.dateStyle = .short
            formatter.timeStyle = .short
        case .weekly:
            formatter.dateFormat = "EEEE, d MMM"
        case .monthly:
            formatter.dateFormat = "d MMM, yyyy"
        }
        
        formatter.locale = Locale(identifier: "es")
        return formatter
    }
    
    func defaultRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let end = Date()
        
        switch self {
        case .daily:
            let start = calendar.date(byAdding: .day, value: -1, to: end)!
            return (start, end)
        case .weekly:
            let start = calendar.date(byAdding: .day, value: -7, to: end)!
            return (start, end)
        case .monthly:
            let start = calendar.date(byAdding: .month, value: -1, to: end)!
            return (start, end)
        }
    }
}

// MARK: - InsightType

@frozen
enum InsightType: String, Codable {
    case pattern
    case trigger
    case improvement
    case correlation
    case recommendation
    
    func displayName() -> String {
        switch self {
        case .pattern:
            return NSLocalizedString("Patrón", comment: "Pattern insight type")
        case .trigger:
            return NSLocalizedString("Desencadenante", comment: "Trigger insight type")
        case .improvement:
            return NSLocalizedString("Mejora", comment: "Improvement insight type")
        case .correlation:
            return NSLocalizedString("Correlación", comment: "Correlation insight type")
        case .recommendation:
            return NSLocalizedString("Recomendación", comment: "Recommendation insight type")
        }
    }
    
    func icon() -> String {
        switch self {
        case .pattern:
            return "waveform.path.ecg"
        case .trigger:
            return "bolt.fill"
        case .improvement:
            return "chart.line.uptrend.xyaxis"
        case .correlation:
            return "link"
        case .recommendation:
            return "lightbulb.fill"
        }
    }
}

// MARK: - TrendDataPoint

struct TrendDataPoint: Codable, Equatable {
    let date: Date
    let value: Int
    let context: String?
    
    init(date: Date, value: Int, context: String? = nil) {
        self.date = date
        self.value = value
        self.context = context
    }
    
    func formattedDate(formatter: DateFormatter? = nil) -> String {
        let dateFormatter = formatter ?? {
            let df = DateFormatter()
            df.dateStyle = .short
            df.timeStyle = .short
            df.locale = Locale(identifier: "es")
            return df
        }()
        
        return dateFormatter.string(from: date)
    }
    
    func formattedValue() -> String {
        return "\(value)/10"
    }
}

// MARK: - EmotionalInsight

struct EmotionalInsight: Codable, Equatable {
    let type: InsightType
    let description: String
    let relatedEmotions: [EmotionType]
    let confidence: Double // 0.0 - 1.0
    let recommendedActions: [String]
    
    init(type: InsightType, description: String, relatedEmotions: [EmotionType], confidence: Double, recommendedActions: [String]) {
        self.type = type
        self.description = description
        self.relatedEmotions = relatedEmotions
        self.confidence = min(max(confidence, 0.0), 1.0) // Ensure between 0 and 1
        self.recommendedActions = recommendedActions
    }
    
    func formattedConfidence() -> String {
        let percentage = Int(confidence * 100)
        return "\(percentage)%"
    }
    
    func relatedEmotionsText() -> String {
        let emotionNames = relatedEmotions.map { $0.displayName() }
        return emotionNames.joined(separator: ", ")
    }
}

// MARK: - EmotionalTrend

struct EmotionalTrend: Codable, Equatable {
    let emotionType: EmotionType
    let dataPoints: [TrendDataPoint]
    let overallTrend: TrendDirection
    let averageIntensity: Double
    let peakIntensity: Double
    let peakDate: Date
    let occurrenceCount: Int
    
    init(emotionType: EmotionType, dataPoints: [TrendDataPoint], overallTrend: TrendDirection, averageIntensity: Double, peakIntensity: Double, peakDate: Date, occurrenceCount: Int) {
        self.emotionType = emotionType
        self.dataPoints = dataPoints
        self.overallTrend = overallTrend
        self.averageIntensity = averageIntensity
        self.peakIntensity = peakIntensity
        self.peakDate = peakDate
        self.occurrenceCount = occurrenceCount
    }
    
    func trendDescription() -> String {
        let emotionName = emotionType.displayName()
        let trendName = overallTrend.displayName().lowercased()
        let avgIntensity = String(format: "%.1f", averageIntensity)
        
        return NSLocalizedString(
            "\(emotionName) ha estado \(trendName) con una intensidad promedio de \(avgIntensity)/10",
            comment: "Trend description format"
        )
    }
    
    func formattedAverageIntensity() -> String {
        let formattedValue = String(format: "%.1f", averageIntensity)
        return "\(formattedValue)/10"
    }
    
    func formattedPeakIntensity() -> String {
        let formattedValue = String(format: "%.1f", peakIntensity)
        return "\(formattedValue)/10"
    }
    
    func formattedPeakDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "es")
        return formatter.string(from: peakDate)
    }
    
    func dateRange() -> (start: Date, end: Date) {
        guard !dataPoints.isEmpty else {
            // Default to current date if no data points
            let current = Date()
            return (current, current)
        }
        
        let sortedDates = dataPoints.map { $0.date }.sorted()
        return (sortedDates.first!, sortedDates.last!)
    }
    
    func intensityRange() -> (min: Int, max: Int) {
        guard !dataPoints.isEmpty else {
            return (0, 0)
        }
        
        let values = dataPoints.map { $0.value }
        return (values.min()!, values.max()!)
    }
}

// MARK: - EmotionalTrendRequest

struct EmotionalTrendRequest: Codable, Equatable {
    let periodType: TrendPeriodType
    let startDate: Date
    let endDate: Date
    let emotionTypes: [EmotionType]?
    
    init(periodType: TrendPeriodType, startDate: Date, endDate: Date, emotionTypes: [EmotionType]? = nil) {
        self.periodType = periodType
        self.startDate = startDate
        self.endDate = endDate
        self.emotionTypes = emotionTypes
    }
    
    func isValid() -> Bool {
        // Ensure startDate is before endDate
        if startDate >= endDate {
            return false
        }
        
        // Ensure date range is not unreasonably large
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        if let days = components.day, days > 365 {
            return false
        }
        
        return true
    }
    
    func toParameters() -> [String: Any] {
        var parameters: [String: Any] = [:]
        
        parameters["periodType"] = periodType.rawValue
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        parameters["startDate"] = dateFormatter.string(from: startDate)
        parameters["endDate"] = dateFormatter.string(from: endDate)
        
        if let types = emotionTypes {
            parameters["emotionTypes"] = types.map { $0.rawValue }.joined(separator: ",")
        }
        
        return parameters
    }
}

// MARK: - EmotionalTrendResponse

struct EmotionalTrendResponse: Codable, Equatable {
    let trends: [EmotionalTrend]
    let insights: [EmotionalInsight]
    
    init(trends: [EmotionalTrend], insights: [EmotionalInsight]) {
        self.trends = trends
        self.insights = insights
    }
}