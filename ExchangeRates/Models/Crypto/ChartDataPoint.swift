//
//  ChartDataPoint.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 04/01/2026.
//

import Foundation

struct ChartDataPoint: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let price: Double
    
    // Equatable conformance - compare by timestamp and price (not id)
    static func == (lhs: ChartDataPoint, rhs: ChartDataPoint) -> Bool {
        return lhs.timestamp == rhs.timestamp && lhs.price == rhs.price
    }
    
    /// Formatted price for tooltip display
    var formattedPrice: String {
        if price >= 1000 {
            return String(format: "$%.0f", price)
        } else if price >= 1 {
            return String(format: "$%.2f", price)
        } else {
            return String(format: "$%.4f", price)
        }
    }
    
    /// Formatted date for tooltip display
    func formattedDate(for range: ChartTimeRange) -> String {
        let formatter = DateFormatter()
        
        switch range {
        case .oneDay:
            // Show time for 1 day
            formatter.dateFormat = "HH:mm"
        case .sevenDays, .oneMonth:
            // Show short date for 7 days and 1 month
            formatter.dateFormat = "dd/MM"
        case .threeMonths, .sixMonths, .oneYear:
            // Show month and year for longer ranges
            formatter.dateFormat = "MMM yyyy"
        }
        
        return formatter.string(from: timestamp)
    }
}

