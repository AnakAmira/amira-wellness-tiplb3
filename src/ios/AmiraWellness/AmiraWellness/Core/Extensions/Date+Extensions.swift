//
//  Date+Extensions.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//
//  Extension methods for the Date class to provide common date manipulation,
//  formatting, and comparison functionality throughout the application.
//

import Foundation // iOS SDK

/// Format styles for date formatting
enum DateFormatStyle {
    case short          // 1/1/2023
    case medium         // Jan 1, 2023
    case long           // January 1, 2023
    case fullWithTime   // January 1, 2023 at 12:00 PM
    case time           // 12:00 PM
    case iso8601        // 2023-01-01T12:00:00Z
    case journalDate    // Used for journal entries display
    case emotionTracking // Used for emotional check-ins display
}

extension Date {
    /// Converts the date to a string using the specified format
    /// - Parameter format: The date format string (e.g., "yyyy-MM-dd")
    /// - Returns: Formatted date string
    func toString(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale.current
        return formatter.string(from: self)
    }
    
    /// Converts the date to a string using a predefined format style
    /// - Parameter style: The date format style to use
    /// - Returns: Formatted date string
    func toFormattedString(style: DateFormatStyle) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        switch style {
        case .short:
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        case .medium:
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
        case .long:
            formatter.dateStyle = .long
            formatter.timeStyle = .none
        case .fullWithTime:
            formatter.dateStyle = .long
            formatter.timeStyle = .short
        case .time:
            formatter.dateStyle = .none
            formatter.timeStyle = .short
        case .iso8601:
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
        case .journalDate:
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
        case .emotionTracking:
            formatter.dateFormat = "MMM d, h:mm a"
        }
        
        return formatter.string(from: self)
    }
    
    /// Checks if the date is today
    /// - Returns: True if the date is today, false otherwise
    func isToday() -> Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// Checks if the date is yesterday
    /// - Returns: True if the date is yesterday, false otherwise
    func isYesterday() -> Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    /// Checks if the date is the same day as another date
    /// - Parameter date: The date to compare with
    /// - Returns: True if the dates are on the same day, false otherwise
    func isSameDay(as date: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: date)
    }
    
    /// Checks if the date is in the same week as another date
    /// - Parameter date: The date to compare with
    /// - Returns: True if the dates are in the same week, false otherwise
    func isSameWeek(as date: Date) -> Bool {
        let calendar = Calendar.current
        let selfComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        let dateComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        
        return selfComponents.yearForWeekOfYear == dateComponents.yearForWeekOfYear &&
               selfComponents.weekOfYear == dateComponents.weekOfYear
    }
    
    /// Checks if the date is in the same month as another date
    /// - Parameter date: The date to compare with
    /// - Returns: True if the dates are in the same month, false otherwise
    func isSameMonth(as date: Date) -> Bool {
        let calendar = Calendar.current
        let selfComponents = calendar.dateComponents([.year, .month], from: self)
        let dateComponents = calendar.dateComponents([.year, .month], from: date)
        
        return selfComponents.year == dateComponents.year &&
               selfComponents.month == dateComponents.month
    }
    
    /// Returns a new date set to the start of the day (00:00:00)
    /// - Returns: Date at the start of the day
    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// Returns a new date set to the end of the day (23:59:59)
    /// - Returns: Date at the end of the day
    func endOfDay() -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        
        return Calendar.current.date(byAdding: components, to: self.startOfDay())!
    }
    
    /// Returns a new date set to the start of the week
    /// - Returns: Date at the start of the week
    func startOfWeek() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components)!.startOfDay()
    }
    
    /// Returns a new date set to the end of the week
    /// - Returns: Date at the end of the week
    func endOfWeek() -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.weekOfYear = 1
        components.second = -1
        
        return calendar.date(byAdding: components, to: self.startOfWeek())!
    }
    
    /// Returns a new date set to the start of the month
    /// - Returns: Date at the start of the month
    func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!.startOfDay()
    }
    
    /// Returns a new date set to the end of the month
    /// - Returns: Date at the end of the month
    func endOfMonth() -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.month = 1
        components.second = -1
        
        return calendar.date(byAdding: components, to: self.startOfMonth())!
    }
    
    /// Returns a new date by adding the specified number of days
    /// - Parameter days: Number of days to add
    /// - Returns: Date with days added
    func addDays(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self)!
    }
    
    /// Returns a new date by adding the specified number of weeks
    /// - Parameter weeks: Number of weeks to add
    /// - Returns: Date with weeks added
    func addWeeks(_ weeks: Int) -> Date {
        return Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self)!
    }
    
    /// Returns a new date by adding the specified number of months
    /// - Parameter months: Number of months to add
    /// - Returns: Date with months added
    func addMonths(_ months: Int) -> Date {
        return Calendar.current.date(byAdding: .month, value: months, to: self)!
    }
    
    /// Calculates the number of days between this date and another date
    /// - Parameter date: The date to calculate days between
    /// - Returns: Number of days between the dates
    func daysBetween(date: Date) -> Int {
        let startDate = self.startOfDay()
        let endDate = date.startOfDay()
        let calendar = Calendar.current
        
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return abs(components.day ?? 0)
    }
    
    /// Calculates the number of weeks between this date and another date
    /// - Parameter date: The date to calculate weeks between
    /// - Returns: Number of weeks between the dates
    func weeksBetween(date: Date) -> Int {
        let startDate = self.startOfWeek()
        let endDate = date.startOfWeek()
        let calendar = Calendar.current
        
        let components = calendar.dateComponents([.weekOfYear], from: startDate, to: endDate)
        return abs(components.weekOfYear ?? 0)
    }
    
    /// Calculates the number of months between this date and another date
    /// - Parameter date: The date to calculate months between
    /// - Returns: Number of months between the dates
    func monthsBetween(date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: self, to: date)
        return abs(components.month ?? 0)
    }
    
    /// Returns a human-readable string describing the time elapsed since this date
    /// - Returns: Localized string describing the time elapsed (e.g., '2 days ago')
    func timeAgoString() -> String {
        let calendar = Calendar.current
        let now = Date()
        let unitFlags: NSCalendar.Unit = [.second, .minute, .hour, .day, .weekOfYear, .month, .year]
        let components = (calendar as NSCalendar).components(unitFlags, from: self, to: now, options: [])
        
        if let year = components.year, year >= 1 {
            return year == 1 ? NSLocalizedString("1 year ago", comment: "") :
                String(format: NSLocalizedString("%d years ago", comment: ""), year)
        }
        
        if let month = components.month, month >= 1 {
            return month == 1 ? NSLocalizedString("1 month ago", comment: "") :
                String(format: NSLocalizedString("%d months ago", comment: ""), month)
        }
        
        if let week = components.weekOfYear, week >= 1 {
            return week == 1 ? NSLocalizedString("1 week ago", comment: "") :
                String(format: NSLocalizedString("%d weeks ago", comment: ""), week)
        }
        
        if let day = components.day, day >= 1 {
            return day == 1 ? NSLocalizedString("Yesterday", comment: "") :
                String(format: NSLocalizedString("%d days ago", comment: ""), day)
        }
        
        if let hour = components.hour, hour >= 1 {
            return hour == 1 ? NSLocalizedString("1 hour ago", comment: "") :
                String(format: NSLocalizedString("%d hours ago", comment: ""), hour)
        }
        
        if let minute = components.minute, minute >= 1 {
            return minute == 1 ? NSLocalizedString("1 minute ago", comment: "") :
                String(format: NSLocalizedString("%d minutes ago", comment: ""), minute)
        }
        
        if let second = components.second, second >= 3 {
            return String(format: NSLocalizedString("%d seconds ago", comment: ""), second)
        }
        
        return NSLocalizedString("Just now", comment: "")
    }
    
    /// Returns a relative time string (today, yesterday, or formatted date)
    /// - Returns: Relative time string
    func relativeTimeString() -> String {
        if self.isToday() {
            return NSLocalizedString("Today", comment: "")
        } else if self.isYesterday() {
            return NSLocalizedString("Yesterday", comment: "")
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            formatter.locale = Locale.current
            return formatter.string(from: self)
        }
    }
    
    /// Returns the localized name of the weekday for this date
    /// - Returns: Localized weekday name
    func weekdayName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full weekday name
        formatter.locale = Locale.current
        return formatter.string(from: self)
    }
    
    /// Returns the localized name of the month for this date
    /// - Returns: Localized month name
    func monthName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM" // Full month name
        formatter.locale = Locale.current
        return formatter.string(from: self)
    }
    
    /// Checks if the date is in the same week as the current date
    /// - Returns: True if the date is in the current week, false otherwise
    func isInSameWeekAsDate() -> Bool {
        return self.isSameWeek(as: Date())
    }
    
    /// Checks if the date is in the same month as the current date
    /// - Returns: True if the date is in the current month, false otherwise
    func isInSameMonthAsDate() -> Bool {
        return self.isSameMonth(as: Date())
    }
    
    /// Checks if the date is in the past
    /// - Returns: True if the date is in the past, false otherwise
    func isInPast() -> Bool {
        return self < Date()
    }
    
    /// Checks if the date is in the future
    /// - Returns: True if the date is in the future, false otherwise
    func isInFuture() -> Bool {
        return self > Date()
    }
}