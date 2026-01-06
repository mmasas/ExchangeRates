//
//  ChartTimeRange.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 04/01/2026.
//

import Foundation

enum ChartTimeRange: String, CaseIterable {
    case oneDay = "1D"
    case sevenDays = "7D"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    
    /// Number of days for API request
    var days: Int {
        switch self {
        case .oneDay: return 1
        case .sevenDays: return 7
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .oneYear: return 365
        }
    }
    
    /// Display label for UI
    var displayLabel: String {
        return self.rawValue
    }
    
    /// Localized chart title
    var chartTitle: String {
        switch self {
        case .oneDay:
            return String(localized: "1_day_chart", defaultValue: "1 Day Chart")
        case .sevenDays:
            return String(localized: "7_day_chart", defaultValue: "7 Day Chart")
        case .oneMonth:
            return String(localized: "1_month_chart", defaultValue: "1 Month Chart")
        case .threeMonths:
            return String(localized: "3_month_chart", defaultValue: "3 Month Chart")
        case .sixMonths:
            return String(localized: "6_month_chart", defaultValue: "6 Month Chart")
        case .oneYear:
            return String(localized: "1_year_chart", defaultValue: "1 Year Chart")
        }
    }
    
    /// Default time range
    static var defaultRange: ChartTimeRange {
        return .sevenDays
    }
}



