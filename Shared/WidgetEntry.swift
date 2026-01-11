//
//  WidgetEntry.swift
//  ExchangeRates
//
//  Shared models for Widget Extension
//

import Foundation
import WidgetKit

// MARK: - App Group Identifier

let appGroupIdentifier = "group.ExchangeRates.ExchangeRates"

// MARK: - Widget Type

enum WatchlistWidgetType: String, Codable, CaseIterable {
    case crypto = "crypto"
    case currency = "currency"
    case mixed = "mixed"
    
    var displayName: String {
        switch self {
        case .crypto:
            return String(localized: "widget_type_crypto", defaultValue: "Crypto")
        case .currency:
            return String(localized: "widget_type_currency", defaultValue: "Currency")
        case .mixed:
            return String(localized: "widget_type_mixed", defaultValue: "Mixed")
        }
    }
}

// MARK: - Widget Layout

enum WatchlistLayout: String, Codable {
    case singleColumn = "singleColumn"
    case twoColumns = "twoColumns"
}

// MARK: - Item Type

enum WatchlistItemType: String, Codable {
    case crypto
    case currency
}

// MARK: - Watchlist Item

struct WatchlistItem: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let symbol: String
    let currentValue: Double
    let changePercent: Double
    let sparklineData: [Double]?
    let imageURL: String?
    let type: WatchlistItemType
    let lastUpdated: Date
    
    /// Formatted value string
    var formattedValue: String {
        switch type {
        case .crypto:
            if currentValue >= 1.0 {
                return String(format: "$%.2f", currentValue)
            } else {
                return String(format: "$%.4f", currentValue)
            }
        case .currency:
            return String(format: "%.3f", currentValue)
        }
    }
    
    /// Formatted change percentage with sign
    var formattedChange: String {
        let sign = changePercent >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, changePercent)
    }
    
    /// Check if change is positive
    var isPositiveChange: Bool {
        changePercent >= 0
    }
    
    /// Display symbol (uppercase)
    var displaySymbol: String {
        symbol.uppercased()
    }
    
    static func == (lhs: WatchlistItem, rhs: WatchlistItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Widget Timeline Entry

struct WatchlistEntry: TimelineEntry {
    let date: Date
    let items: [WatchlistItem]
    let widgetType: WatchlistWidgetType
    let layout: WatchlistLayout
    let isPlaceholder: Bool
    
    init(date: Date, items: [WatchlistItem], widgetType: WatchlistWidgetType, layout: WatchlistLayout = .singleColumn, isPlaceholder: Bool = false) {
        self.date = date
        self.items = items
        self.widgetType = widgetType
        self.layout = layout
        self.isPlaceholder = isPlaceholder
    }
    
    /// Create a placeholder entry for preview
    static func placeholder(widgetType: WatchlistWidgetType = .mixed) -> WatchlistEntry {
        let placeholderItems: [WatchlistItem] = [
            WatchlistItem(
                id: "bitcoin",
                name: "Bitcoin",
                symbol: "BTC",
                currentValue: 97500.0,
                changePercent: 2.1,
                sparklineData: [95000, 96000, 95500, 97000, 98000, 97500, 97500],
                imageURL: nil,
                type: .crypto,
                lastUpdated: Date()
            ),
            WatchlistItem(
                id: "ethereum",
                name: "Ethereum",
                symbol: "ETH",
                currentValue: 3850.0,
                changePercent: -0.8,
                sparklineData: [3900, 3850, 3880, 3820, 3800, 3850, 3850],
                imageURL: nil,
                type: .crypto,
                lastUpdated: Date()
            ),
            WatchlistItem(
                id: "USD",
                name: "US Dollar",
                symbol: "USD",
                currentValue: 3.65,
                changePercent: 0.3,
                sparklineData: [3.62, 3.63, 3.64, 3.63, 3.65, 3.64, 3.65],
                imageURL: nil,
                type: .currency,
                lastUpdated: Date()
            ),
            WatchlistItem(
                id: "EUR",
                name: "Euro",
                symbol: "EUR",
                currentValue: 3.92,
                changePercent: -0.1,
                sparklineData: [3.93, 3.92, 3.91, 3.92, 3.93, 3.92, 3.92],
                imageURL: nil,
                type: .currency,
                lastUpdated: Date()
            ),
            WatchlistItem(
                id: "GBP",
                name: "British Pound",
                symbol: "GBP",
                currentValue: 4.58,
                changePercent: 0.2,
                sparklineData: [4.55, 4.56, 4.57, 4.56, 4.58, 4.57, 4.58],
                imageURL: nil,
                type: .currency,
                lastUpdated: Date()
            ),
            WatchlistItem(
                id: "JPY",
                name: "Japanese Yen",
                symbol: "JPY",
                currentValue: 0.024,
                changePercent: -0.4,
                sparklineData: [0.0242, 0.0241, 0.024, 0.0241, 0.024, 0.0239, 0.024],
                imageURL: nil,
                type: .currency,
                lastUpdated: Date()
            )
        ]
        
        return WatchlistEntry(
            date: Date(),
            items: placeholderItems,
            widgetType: widgetType,
            layout: .singleColumn,
            isPlaceholder: true
        )
    }
    
    /// Create an empty entry
    static func empty(widgetType: WatchlistWidgetType = .mixed) -> WatchlistEntry {
        WatchlistEntry(
            date: Date(),
            items: [],
            widgetType: widgetType,
            layout: .singleColumn,
            isPlaceholder: false
        )
    }
}

// MARK: - Widget Data Keys

struct WidgetDataKeys {
    static let watchlistItems = "watchlistItems"
    static let lastUpdateDate = "widgetLastUpdateDate"
    static let selectedWidgetType = "selectedWidgetType"
    static let favoriteCurrencies = "favoriteCurrencies"
    static let favoriteCryptos = "favoriteCryptos"
}
