//
//  ExchangeRate.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 26/12/2025.
//

import Foundation

struct ExchangeRatesResponse: Codable {
    let exchangeRates: [ExchangeRate]
}

struct ExchangeRate: Codable, Identifiable {
    let key: String
    let currentExchangeRate: Double
    let currentChange: Double
    let unit: Int
    let lastUpdate: String
    
    var id: String { key }
    
    // Computed property for Date from ISO string
    var lastUpdateDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: lastUpdate)
    }
    
    // Formatted exchange rate
    var formattedRate: String {
        // Format with 3-4 decimal places depending on the value
        if currentExchangeRate >= 1.0 {
            return String(format: "%.3f", currentExchangeRate)
        } else {
            return String(format: "%.4f", currentExchangeRate)
        }
    }
    
    // Formatted percentage change with sign
    var formattedChange: String {
        let sign = currentChange >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, currentChange)
    }
    
    // Relative time string (e.g., "2m ago")
    var relativeTimeString: String {
        guard let date = lastUpdateDate else { return "" }
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        let minutes = Int(timeInterval / 60)
        let hours = Int(timeInterval / 3600)
        let days = Int(timeInterval / 86400)
        
        if minutes < 1 {
            return "Updated just now"
        } else if minutes < 60 {
            return "Updated \(minutes)m ago"
        } else if hours < 24 {
            return "Updated \(hours)h ago"
        } else {
            return "Updated \(days)d ago"
        }
    }
    
    // Check if change is positive
    var isPositiveChange: Bool {
        currentChange >= 0
    }
}

