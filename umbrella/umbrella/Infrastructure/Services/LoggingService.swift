//
//  LoggingService.swift
//  umbrella
//
//  Created by Денис on 31.12.2025.
//

import Foundation
import OSLog

/// Centralized logging service for the umbrella app
/// Uses OSLog for efficient, structured logging with proper log levels
final class LoggingService {
    static let shared = LoggingService()

    private let logger: Logger

    private init() {
        self.logger = Logger(subsystem: "com.chinese-umbrella.app", category: "Umbrella")
    }

    // MARK: - Public Logging Methods

    /// Log debug information (only in development builds)
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let context = formatContext(file: file, function: function, line: line)
        logger.debug("\(context) \(message)")
        #endif
    }

    /// Log general information
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let context = formatContext(file: file, function: function, line: line)
        logger.info("\(context) \(message)")
    }

    /// Log warnings (potential issues)
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let context = formatContext(file: file, function: function, line: line)
        logger.log(level: .default, "\(context) \(message)")
    }

    /// Log errors (failures that need attention)
    func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let context = formatContext(file: file, function: function, line: line)
        var fullMessage = "\(context) \(message)"
        if let error = error {
            fullMessage += " Error: \(error.localizedDescription)"
        }
        logger.error("\(fullMessage)")
    }

    /// Log critical errors (app-threatening issues)
    func critical(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let context = formatContext(file: file, function: function, line: line)
        var fullMessage = "\(context) \(message)"
        if let error = error {
            fullMessage += " Error: \(error.localizedDescription)"
        }
        logger.critical("\(fullMessage)")
    }

    // MARK: - Private Helpers

    private func formatContext(file: String, function: String, line: Int) -> String {
        let filename = (file as NSString).lastPathComponent
        return "[\(filename):\(line) \(function)]"
    }
}

// MARK: - Convenience Extensions

extension LoggingService {
    /// Log authentication-related events
    func auth(_ message: String, level: OSLogType = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let context = formatContext(file: file, function: function, line: line)
        logger.log(level: level, "\(context) [AUTH] \(message)")
    }

    /// Log Core Data operations
    func coreData(_ message: String, level: OSLogType = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let context = formatContext(file: file, function: function, line: line)
        logger.log(level: level, "\(context) [COREDATA] \(message)")
    }

    /// Log OCR operations
    func ocr(_ message: String, level: OSLogType = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let context = formatContext(file: file, function: function, line: line)
        logger.log(level: level, "\(context) [OCR] \(message)")
    }

    /// Log reading session events
    func reading(_ message: String, level: OSLogType = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let context = formatContext(file: file, function: function, line: line)
        logger.log(level: level, "\(context) [READING] \(message)")
    }

    /// Log performance metrics
    func performance(_ message: String, duration: TimeInterval? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let context = formatContext(file: file, function: function, line: line)
        var fullMessage = "\(context) [PERFORMANCE] \(message)"
        if let duration = duration {
            fullMessage += " Duration: \(String(format: "%.2f", duration))ms"
        }
        logger.log(level: .info, "\(fullMessage)")
    }
}
