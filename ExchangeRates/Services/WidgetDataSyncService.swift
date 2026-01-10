//
//  WidgetDataSyncService.swift
//  ExchangeRates
//
//  Syncs main app data to App Group for widget consumption
//

import Foundation
import WidgetKit

/// Service responsible for syncing app data to the widget via App Group
class WidgetDataSyncService {
    static let shared = WidgetDataSyncService()
    
    private let dataProvider = WidgetDataProvider.shared
    private let favoriteCurrencyManager = FavoriteCurrencyManager.shared
    private let favoriteCryptoManager = FavoriteCryptoManager.shared
    private let historicalRateService = HistoricalRateService.shared
    private let homeCurrencyManager = HomeCurrencyManager.shared
    
    private init() {}
    
    // MARK: - Sync Methods
    
    /// Sync favorite cryptocurrencies to widget
    /// - Parameter cryptocurrencies: Array of cryptocurrency data
    func syncCryptoData(_ cryptocurrencies: [Cryptocurrency]) {
        let favoriteCryptoIds = favoriteCryptoManager.getFavorites()
        
        // Filter to only favorites and convert to WatchlistItems
        let favoritesCryptos = cryptocurrencies.filter { favoriteCryptoIds.contains($0.id) }
        
        let cryptoItems: [WatchlistItem] = favoritesCryptos.map { crypto in
            WatchlistItem(
                id: crypto.id,
                name: crypto.name,
                symbol: crypto.symbol,
                currentValue: crypto.currentPrice,
                changePercent: crypto.priceChangePercentage24h ?? 0,
                sparklineData: crypto.sparklinePrices,
                imageURL: crypto.image,
                type: .crypto,
                lastUpdated: crypto.lastUpdatedDate ?? Date()
            )
        }
        
        // Merge with existing currency items
        var existingItems = dataProvider.loadWatchlistItems()
        existingItems.removeAll { $0.type == .crypto }
        existingItems.append(contentsOf: cryptoItems)
        
        // Sort: cryptos first, then currencies
        existingItems.sort { lhs, rhs in
            if lhs.type == rhs.type {
                return false // Keep original order within type
            }
            return lhs.type == .crypto
        }
        
        dataProvider.saveWatchlistItems(existingItems)
        
        LogManager.shared.log("Synced \(cryptoItems.count) crypto items to widget", level: .success, source: "WidgetDataSyncService")
    }
    
    /// Sync favorite currencies to widget
    /// - Parameter exchangeRates: Array of exchange rate data
    func syncCurrencyData(_ exchangeRates: [ExchangeRate]) async {
        let favoriteCurrencyIds = favoriteCurrencyManager.getFavorites()
        let homeCurrency = homeCurrencyManager.getHomeCurrency()
        
        // Filter to only favorites
        let favoriteCurrencies = exchangeRates.filter { favoriteCurrencyIds.contains($0.key) }
        
        // Fetch sparkline data for favorites
        var sparklineData: [String: [Double]] = [:]
        
        if !favoriteCurrencies.isEmpty {
            let currencyCodes = favoriteCurrencies.map { $0.key }
            do {
                sparklineData = try await historicalRateService.fetch7DayHistoryBatch(
                    baseCurrency: homeCurrency,
                    targetCurrencies: currencyCodes
                )
            } catch {
                LogManager.shared.log("Failed to fetch currency sparklines: \(error.localizedDescription)", level: .warning, source: "WidgetDataSyncService")
            }
        }
        
        // Convert to WatchlistItems
        let currencyItems: [WatchlistItem] = favoriteCurrencies.map { rate in
            WatchlistItem(
                id: rate.key,
                name: currencyName(for: rate.key),
                symbol: rate.key,
                currentValue: rate.currentExchangeRate,
                changePercent: rate.currentChange,
                sparklineData: sparklineData[rate.key],
                imageURL: nil,
                type: .currency,
                lastUpdated: rate.lastUpdateDate ?? Date()
            )
        }
        
        // Merge with existing crypto items
        var existingItems = dataProvider.loadWatchlistItems()
        existingItems.removeAll { $0.type == .currency }
        existingItems.append(contentsOf: currencyItems)
        
        // Sort: cryptos first, then currencies
        existingItems.sort { lhs, rhs in
            if lhs.type == rhs.type {
                return false // Keep original order within type
            }
            return lhs.type == .crypto
        }
        
        dataProvider.saveWatchlistItems(existingItems)
        
        LogManager.shared.log("Synced \(currencyItems.count) currency items to widget", level: .success, source: "WidgetDataSyncService")
    }
    
    /// Sync both crypto and currency data
    func syncAllData(cryptocurrencies: [Cryptocurrency], exchangeRates: [ExchangeRate]) async {
        // Sync crypto synchronously (no network call needed for sparklines)
        syncCryptoData(cryptocurrencies)
        
        // Sync currencies with sparkline fetching
        await syncCurrencyData(exchangeRates)
        
        // Reload widget timelines
        reloadWidgets()
    }
    
    /// Reload widget timelines
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        LogManager.shared.log("Widget timelines reloaded", level: .debug, source: "WidgetDataSyncService")
    }
    
    // MARK: - Helper Methods
    
    /// Get display name for currency code
    private func currencyName(for code: String) -> String {
        let currencyNames: [String: String] = [
            "USD": "US Dollar",
            "EUR": "Euro",
            "GBP": "British Pound",
            "JPY": "Japanese Yen",
            "CHF": "Swiss Franc",
            "CAD": "Canadian Dollar",
            "AUD": "Australian Dollar",
            "NZD": "New Zealand Dollar",
            "CNY": "Chinese Yuan",
            "HKD": "Hong Kong Dollar",
            "SGD": "Singapore Dollar",
            "SEK": "Swedish Krona",
            "NOK": "Norwegian Krone",
            "DKK": "Danish Krone",
            "INR": "Indian Rupee",
            "RUB": "Russian Ruble",
            "BRL": "Brazilian Real",
            "MXN": "Mexican Peso",
            "ZAR": "South African Rand",
            "TRY": "Turkish Lira",
            "PLN": "Polish Zloty",
            "ILS": "Israeli Shekel",
            "KRW": "South Korean Won",
            "THB": "Thai Baht"
        ]
        
        return currencyNames[code.uppercased()] ?? code
    }
}
