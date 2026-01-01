//
//  LogManager.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import Foundation
import Combine

struct LogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let level: LogLevel
    let source: String
    let message: String
    
    init(id: UUID = UUID(), timestamp: Date = Date(), level: LogLevel, source: String, message: String) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.source = source
        self.message = message
    }
}

enum LogLevel: String, Codable, CaseIterable {
    case debug
    case info
    case warning
    case error
    case success
}

class LogManager: ObservableObject {
    static let shared = LogManager()
    
    @Published private(set) var logs: [LogEntry] = []
    
    private let maxLogs = 1000
    private let queue = DispatchQueue(label: "com.exchangerates.logger", qos: .utility)
    
    private init() {}
    
    func log(_ message: String, level: LogLevel = .info, source: String = "") {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let entry = LogEntry(
                level: level,
                source: source,
                message: message
            )
            
            DispatchQueue.main.async {
                self.logs.insert(entry, at: 0)
                
                // Keep only the last maxLogs entries
                if self.logs.count > self.maxLogs {
                    self.logs = Array(self.logs.prefix(self.maxLogs))
                }
            }
        }
    }
    
    func clearLogs() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
    
    func getLogs(level: LogLevel? = nil) -> [LogEntry] {
        if let level = level {
            return logs.filter { $0.level == level }
        }
        return logs
    }
}

