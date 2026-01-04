//
//  LoggingService.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation
import OSLog

/// Log levels that can be filtered and configured
enum LogLevel {
    case debug
    case info
    case `default`
    case error
    case fault

    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .default: return .default
        case .error: return .error
        case .fault: return .fault
        }
    }
}

/// Protocol defining logging interface for consistent logging across the app
protocol Logger {
    func debug(_ message: String, metadata: [String: Any]?)
    func info(_ message: String, metadata: [String: Any]?)
    func warning(_ message: String, metadata: [String: Any]?)
    func error(_ message: String, error: Error?, metadata: [String: Any]?)
}

// Extension to provide convenience methods with default nil metadata
extension Logger {
    func debug(_ message: String) {
        debug(message, metadata: nil)
    }

    func info(_ message: String) {
        info(message, metadata: nil)
    }

    func warning(_ message: String) {
        warning(message, metadata: nil)
    }

    func error(_ message: String, error: Error?) {
        self.error(message, error: error, metadata: nil)
    }

    func error(_ message: String) {
        self.error(message, error: nil, metadata: nil)
    }
}

/// Centralized logging service for the umbrella app
/// Uses OSLog for efficient, structured logging with proper log levels
final class LoggingService: Logger {
    static let shared = LoggingService()

    private let logger: os.Logger

    private init() {
        self.logger = os.Logger(subsystem: "com.chinese-umbrella.app", category: "Umbrella")
    }

    // MARK: - Public Logging Methods

    /// Log debug information (only in development builds)
    func debug(_ message: String, metadata: [String: Any]?) {
        debug(message, metadata: metadata, file: #file, function: #function, line: #line)
    }

    /// Log debug information with metadata (only in development builds)
    func debug(_ message: String, metadata: [String: Any]?, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let context = formatContext(file: file, function: function, line: line)
        let fullMessage = formatMessage(message, metadata: metadata)
        logger.debug("\(context) \(fullMessage)")
        #endif
    }

    /// Log general information
    func info(_ message: String, metadata: [String: Any]?) {
        info(message, metadata: metadata, file: #file, function: #function, line: #line)
    }

    /// Log general information with metadata
    func info(_ message: String, metadata: [String: Any]?, file: String = #file, function: String = #function, line: Int = #line) {
        let context = formatContext(file: file, function: function, line: line)
        let fullMessage = formatMessage(message, metadata: metadata)
        logger.info("\(context) \(fullMessage)")
    }

    /// Log warnings (potential issues)
    func warning(_ message: String, metadata: [String: Any]?) {
        warning(message, metadata: metadata, file: #file, function: #function, line: #line)
    }

    /// Log warnings with metadata (potential issues)
    func warning(_ message: String, metadata: [String: Any]?, file: String = #file, function: String = #function, line: Int = #line) {
        let context = formatContext(file: file, function: function, line: line)
        let fullMessage = formatMessage(message, metadata: metadata)
        logger.log(level: .default, "\(context) \(fullMessage)")
    }

    /// Log errors (failures that need attention)
    func error(_ message: String, error: Error?, metadata: [String: Any]?) {
        self.error(message, error: error, metadata: metadata, file: #file, function: #function, line: #line)
    }

    /// Log errors with metadata (failures that need attention)
    func error(_ message: String, error: Error?, metadata: [String: Any]?, file: String = #file, function: String = #function, line: Int = #line) {
        let context = formatContext(file: file, function: function, line: line)
        var fullMessage = "\(context) \(message)"
        if let error = error {
            fullMessage += " Error: \(error.localizedDescription)"
        }
        if let metadata = metadata {
            fullMessage += formatMetadata(metadata)
        }
        logger.error("\(fullMessage)")
    }

    /// Log critical errors (app-threatening issues)
    func critical(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        critical(message, error: error, metadata: nil, file: file, function: function, line: line)
    }

    /// Log critical errors with metadata (app-threatening issues)
    func critical(_ message: String, error: Error?, metadata: [String: Any]?, file: String = #file, function: String = #function, line: Int = #line) {
        let context = formatContext(file: file, function: function, line: line)
        var fullMessage = "\(context) \(message)"
        if let error = error {
            fullMessage += " Error: \(error.localizedDescription)"
        }
        if let metadata = metadata {
            fullMessage += formatMetadata(metadata)
        }
        logger.critical("\(fullMessage)")
    }

    // MARK: - Private Helpers

    private func formatContext(file: String, function: String, line: Int) -> String {
        let filename = (file as NSString).lastPathComponent
        return "[\(filename):\(line) \(function)]"
    }

    private func formatMessage(_ message: String, metadata: [String: Any]?) -> String {
        var fullMessage = message
        if let metadata = metadata {
            fullMessage += formatMetadata(metadata)
        }
        return fullMessage
    }

    private func formatMetadata(_ metadata: [String: Any]) -> String {
        let metadataString = metadata.map { key, value in
            "\(key)=\(String(describing: value))"
        }.joined(separator: " ")
        return " [\(metadataString)]"
    }

    private func logCategory(_ message: String, category: String, metadata: [String: Any]?, level: LogLevel, file: String, function: String, line: Int) {
        let context = formatContext(file: file, function: function, line: line)
        let fullMessage = formatMessage("[\(category)] \(message)", metadata: metadata)
        logger.log(level: level.osLogType, "\(context) \(fullMessage)")
    }
}

// MARK: - Convenience Extensions

extension LoggingService {
    /// Log authentication-related events
    func auth(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        auth(message, metadata: nil, level: level, file: file, function: function, line: line)
    }

    /// Log authentication-related events with metadata
    func auth(_ message: String, metadata: [String: Any]?, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        logCategory(message, category: "AUTH", metadata: metadata, level: level, file: file, function: function, line: line)
    }

    /// Log Core Data operations
    func coreData(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        coreData(message, metadata: nil, level: level, file: file, function: function, line: line)
    }

    /// Log Core Data operations with metadata
    func coreData(_ message: String, metadata: [String: Any]?, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        logCategory(message, category: "COREDATA", metadata: metadata, level: level, file: file, function: function, line: line)
    }

    /// Log OCR operations
    func ocr(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        ocr(message, metadata: nil, level: level, file: file, function: function, line: line)
    }

    /// Log OCR operations with metadata
    func ocr(_ message: String, metadata: [String: Any]?, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        logCategory(message, category: "OCR", metadata: metadata, level: level, file: file, function: function, line: line)
    }

    /// Log reading session events
    func reading(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        reading(message, metadata: nil, level: level, file: file, function: function, line: line)
    }

    /// Log reading session events with metadata
    func reading(_ message: String, metadata: [String: Any]?, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        logCategory(message, category: "READING", metadata: metadata, level: level, file: file, function: function, line: line)
    }

    /// Log performance metrics
    func performance(_ message: String, duration: TimeInterval? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        performance(message, metadata: nil, duration: duration, file: file, function: function, line: line)
    }

    /// Log performance metrics with metadata
    func performance(_ message: String, metadata: [String: Any]?, duration: TimeInterval? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let context = formatContext(file: file, function: function, line: line)
        var fullMessage = "[PERFORMANCE] \(message)"
        if let duration = duration {
            fullMessage += " Duration: \(String(format: "%.2f", duration))ms"
        }
        fullMessage = formatMessage(fullMessage, metadata: metadata)
        logger.log(level: .info, "\(context) \(fullMessage)")
    }
}
