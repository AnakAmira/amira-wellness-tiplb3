//
//  Logger.swift
//  AmiraWellness
//
//  Created for Amira Wellness
//

import Foundation // Latest
import os.log // Latest

/// Defines log severity levels for filtering log messages
enum LogLevel: Int {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case none = 4
}

/// Categorizes log messages for better organization and filtering
enum LogCategory: String {
    case general = "General"
    case network = "Network"
    case database = "Database"
    case audio = "Audio"
    case encryption = "Encryption"
    case authentication = "Authentication"
    case userInterface = "UI"
    case sync = "Sync"
}

/// A singleton class that provides structured logging functionality with privacy considerations
class Logger {
    /// Shared instance of Logger (singleton)
    static let shared = Logger()
    
    // MARK: - Private Properties
    
    private var logLevel: LogLevel
    private let dateFormatter: DateFormatter
    private let isDebugBuild: Bool
    private let osLog: OSLog
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern
    private init() {
        // Set default log level based on build configuration
        #if DEBUG
        self.logLevel = .debug
        #else
        self.logLevel = .info
        #endif
        
        // Configure date formatter for log timestamps
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.dateFormatter.timeZone = TimeZone.current
        
        // Determine if we're running in a debug build
        #if DEBUG
        self.isDebugBuild = true
        #else
        self.isDebugBuild = false
        #endif
        
        // Check if debug logging is enabled in feature flags
        if AppConstants.FeatureFlags.defaultFeatureStates[AppConstants.FeatureFlags.debugLogging] == true {
            self.logLevel = .debug
        }
        
        // Initialize os_log with app subsystem
        self.osLog = OSLog(subsystem: AppConstants.App.bundleIdentifier, category: "AmiraWellness")
    }
    
    // MARK: - Public Methods
    
    /// Sets the minimum log level for logging
    /// - Parameter level: The minimum log level to display
    func setLogLevel(_ level: LogLevel) {
        self.logLevel = level
    }
    
    /// Logs a debug message if the current log level allows it
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The category of the log message
    ///   - file: The file from which the log is called (default: #file)
    ///   - line: The line number from which the log is called (default: #line)
    ///   - function: The function from which the log is called (default: #function)
    func debug(_ message: String, category: LogCategory = .general, file: String = #file, line: Int = #line, function: String = #function) {
        guard shouldLog(.debug) else { return }
        
        let formattedMessage = formatMessage(message, category: category, file: file, line: line, function: function)
        
        os_log("%{public}@", log: osLog, type: .debug, formattedMessage)
        
        if isDebugBuild {
            print("📝 DEBUG: \(formattedMessage)")
        }
    }
    
    /// Logs an informational message if the current log level allows it
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The category of the log message
    ///   - file: The file from which the log is called (default: #file)
    ///   - line: The line number from which the log is called (default: #line)
    ///   - function: The function from which the log is called (default: #function)
    func info(_ message: String, category: LogCategory = .general, file: String = #file, line: Int = #line, function: String = #function) {
        guard shouldLog(.info) else { return }
        
        let formattedMessage = formatMessage(message, category: category, file: file, line: line, function: function)
        
        os_log("%{public}@", log: osLog, type: .info, formattedMessage)
        
        if isDebugBuild {
            print("ℹ️ INFO: \(formattedMessage)")
        }
    }
    
    /// Logs a warning message if the current log level allows it
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The category of the log message
    ///   - file: The file from which the log is called (default: #file)
    ///   - line: The line number from which the log is called (default: #line)
    ///   - function: The function from which the log is called (default: #function)
    func warning(_ message: String, category: LogCategory = .general, file: String = #file, line: Int = #line, function: String = #function) {
        guard shouldLog(.warning) else { return }
        
        let formattedMessage = formatMessage(message, category: category, file: file, line: line, function: function)
        
        os_log("%{public}@", log: osLog, type: .fault, formattedMessage)
        
        if isDebugBuild {
            print("⚠️ WARNING: \(formattedMessage)")
        }
    }
    
    /// Logs an error message if the current log level allows it
    /// - Parameters:
    ///   - message: The message to log
    ///   - error: Optional error object with additional information
    ///   - category: The category of the log message
    ///   - file: The file from which the log is called (default: #file)
    ///   - line: The line number from which the log is called (default: #line)
    ///   - function: The function from which the log is called (default: #function)
    func error(_ message: String, error: Error? = nil, category: LogCategory = .general, file: String = #file, line: Int = #line, function: String = #function) {
        guard shouldLog(.error) else { return }
        
        var fullMessage = message
        if let error = error {
            fullMessage += " - Error: \(error.localizedDescription)"
        }
        
        let formattedMessage = formatMessage(fullMessage, category: category, file: file, line: line, function: function)
        
        os_log("%{public}@", log: osLog, type: .error, formattedMessage)
        
        if isDebugBuild {
            print("❌ ERROR: \(formattedMessage)")
        }
    }
    
    /// Logs encryption-related events with special privacy considerations
    /// - Parameters:
    ///   - message: The message to log
    ///   - level: The log level for this message
    ///   - file: The file from which the log is called (default: #file)
    ///   - line: The line number from which the log is called (default: #line)
    ///   - function: The function from which the log is called (default: #function)
    func logEncryption(_ message: String, level: LogLevel = .info, file: String = #file, line: Int = #line, function: String = #function) {
        guard shouldLog(level) else { return }
        
        // Ensure no sensitive data like keys or IVs are included in logs
        let sanitizedMessage = sanitizeMessage(message)
        let formattedMessage = formatMessage(sanitizedMessage, category: .encryption, file: file, line: line, function: function)
        
        let logType: OSLogType
        var consolePrefix = ""
        
        switch level {
        case .debug:
            logType = .debug
            consolePrefix = "📝 DEBUG"
        case .info:
            logType = .info
            consolePrefix = "ℹ️ INFO"
        case .warning:
            logType = .fault
            consolePrefix = "⚠️ WARNING"
        case .error:
            logType = .error
            consolePrefix = "❌ ERROR"
        case .none:
            return
        }
        
        os_log("%{public}@", log: osLog, type: logType, formattedMessage)
        
        if isDebugBuild {
            print("\(consolePrefix): \(formattedMessage)")
        }
    }
    
    /// Logs network-related events with privacy considerations
    /// - Parameters:
    ///   - message: The message to log
    ///   - level: The log level for this message
    ///   - file: The file from which the log is called (default: #file)
    ///   - line: The line number from which the log is called (default: #line)
    ///   - function: The function from which the log is called (default: #function)
    func logNetwork(_ message: String, level: LogLevel = .debug, file: String = #file, line: Int = #line, function: String = #function) {
        guard shouldLog(level) else { return }
        
        // Redact sensitive information like auth tokens and personal data
        let sanitizedMessage = sanitizeMessage(message)
        let formattedMessage = formatMessage(sanitizedMessage, category: .network, file: file, line: line, function: function)
        
        let logType: OSLogType
        var consolePrefix = ""
        
        switch level {
        case .debug:
            logType = .debug
            consolePrefix = "📝 DEBUG"
        case .info:
            logType = .info
            consolePrefix = "ℹ️ INFO"
        case .warning:
            logType = .fault
            consolePrefix = "⚠️ WARNING"
        case .error:
            logType = .error
            consolePrefix = "❌ ERROR"
        case .none:
            return
        }
        
        os_log("%{public}@", log: osLog, type: logType, formattedMessage)
        
        if isDebugBuild {
            print("\(consolePrefix): \(formattedMessage)")
        }
    }
    
    /// Logs user actions without including personal data
    /// - Parameters:
    ///   - action: The user action to log
    ///   - file: The file from which the log is called (default: #file)
    ///   - line: The line number from which the log is called (default: #line)
    ///   - function: The function from which the log is called (default: #function)
    func logUserAction(_ action: String, file: String = #file, line: Int = #line, function: String = #function) {
        guard shouldLog(.info) else { return }
        
        // Ensure no personal data is included
        let sanitizedAction = sanitizeMessage(action)
        let formattedMessage = formatMessage("User action: \(sanitizedAction)", category: .userInterface, file: file, line: line, function: function)
        
        os_log("%{public}@", log: osLog, type: .info, formattedMessage)
        
        if isDebugBuild {
            print("👤 USER: \(formattedMessage)")
        }
    }
    
    // MARK: - Private Methods
    
    /// Formats a log message with consistent structure
    /// - Parameters:
    ///   - message: The message to format
    ///   - category: The category of the log message
    ///   - file: The file from which the log is called
    ///   - line: The line number from which the log is called
    ///   - function: The function from which the log is called
    /// - Returns: A formatted log message
    private func formatMessage(_ message: String, category: LogCategory, file: String, line: Int, function: String) -> String {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        
        return "[\(timestamp)] [\(category.rawValue)] [\(fileName):\(line) \(function)] \(message)"
    }
    
    /// Removes or masks sensitive information from log messages
    /// - Parameter message: The original message
    /// - Returns: A sanitized message with sensitive data removed or masked
    private func sanitizeMessage(_ message: String) -> String {
        var sanitized = message
        
        // Mask email addresses
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        sanitized = sanitized.replacingOccurrences(of: emailRegex, with: "***@***.***", options: .regularExpression)
        
        // Mask authorization headers and tokens
        let authRegex = "Bearer\\s+[A-Za-z0-9-._~+/]+[=]*"
        sanitized = sanitized.replacingOccurrences(of: authRegex, with: "Bearer ***", options: .regularExpression)
        
        // Mask JSON token fields
        let tokenRegex = "\"(token|access_token|refresh_token|id_token)\":\\s*\"[^\"]*\""
        sanitized = sanitized.replacingOccurrences(of: tokenRegex, with: "\"$1\": \"***\"", options: .regularExpression)
        
        // Mask encryption keys and initialization vectors
        let keyRegex = "key(:|=)\\s*[A-Za-z0-9+/=]+"
        sanitized = sanitized.replacingOccurrences(of: keyRegex, with: "key$1 ***", options: .regularExpression)
        
        let ivRegex = "iv(:|=)\\s*[A-Za-z0-9+/=]+"
        sanitized = sanitized.replacingOccurrences(of: ivRegex, with: "iv$1 ***", options: .regularExpression)
        
        return sanitized
    }
    
    /// Determines if a message should be logged based on level
    /// - Parameter messageLevel: The level of the message to check
    /// - Returns: True if the message should be logged, false otherwise
    private func shouldLog(_ messageLevel: LogLevel) -> Bool {
        return messageLevel.rawValue >= logLevel.rawValue
    }
}