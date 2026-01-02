//
//  Cryptocurrency.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import Foundation

struct Cryptocurrency: Codable, Identifiable {
    let id: String                          // "bitcoin"
    let symbol: String                      // "btc"
    let name: String                        // "Bitcoin"
    let image: String                       // Logo URL
    let currentPrice: Double                // 87805.0
    let priceChangePercentage24h: Double?   // +2.1%
    let lastUpdated: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case image
        case currentPrice = "current_price"
        case priceChangePercentage24h = "price_change_percentage_24h"
        case lastUpdated = "last_updated"
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
        guard let change = priceChangePercentage24h else { return "N/A" }
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
}

