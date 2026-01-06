//
//  Cryptocurrency.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import Foundation

/// Sparkline data from CoinGecko API
struct SparklineIn7d: Codable {
    let price: [Double]
}

struct Cryptocurrency: Codable, Identifiable {
    let id: String                          // "bitcoin"
    let symbol: String                      // "btc"
    let name: String                        // "Bitcoin"
    let image: String                       // Logo URL
    let currentPrice: Double                // 87805.0
    let priceChangePercentage24h: Double?   // +2.1%
    let lastUpdated: String?
    let sparklineIn7d: SparklineIn7d?       // 7-day price sparkline
    let marketCapRank: Int?                 // Market cap rank
    let high24h: Double?                    // 24h high price
    let low24h: Double?                     // 24h low price
    
    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case image
        case currentPrice = "current_price"
        case priceChangePercentage24h = "price_change_percentage_24h"
        case lastUpdated = "last_updated"
        case sparklineIn7d = "sparkline_in_7d"
        case marketCapRank = "market_cap_rank"
        case high24h = "high_24h"
        case low24h = "low_24h"
    }
    
    /// Get sparkline prices array
    var sparklinePrices: [Double]? {
        sparklineIn7d?.price
    }
    
    // Formatted price with dollar sign
    var formattedPrice: String {
        if currentPrice >= 1.0 {
            return String(format: "$%.2f", currentPrice)
        } else {
            return String(format: "$%.4f", currentPrice)
        }
    }
    
    // Formatted percentage change with sign
    var formattedChange: String {
        guard let change = priceChangePercentage24h else { return String(localized: "not_available") }
        let sign = change >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, change)
    }
    
    // Check if change is positive
    var isPositiveChange: Bool {
        (priceChangePercentage24h ?? 0) >= 0
    }
    
    // Symbol in uppercase
    var displaySymbol: String {
        symbol.uppercased()
    }
    
    // Computed property for Date from ISO string
    var lastUpdatedDate: Date? {
        guard let dateString = lastUpdated else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString)
    }
    
    // Relative time string (e.g., "Updated 2m ago")
    var relativeTimeString: String {
        guard let date = lastUpdatedDate else { return "" }
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
    
    // Formatted high 24h price
    var formattedHigh24h: String {
        guard let high = high24h else { return String(localized: "not_available") }
        if high >= 1.0 {
            return String(format: "$%.2f", high)
        } else {
            return String(format: "$%.4f", high)
        }
    }
    
    // Formatted low 24h price
    var formattedLow24h: String {
        guard let low = low24h else { return String(localized: "not_available") }
        if low >= 1.0 {
            return String(format: "$%.2f", low)
        } else {
            return String(format: "$%.4f", low)
        }
    }
}

