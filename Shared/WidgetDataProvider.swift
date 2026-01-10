//
//  WidgetDataProvider.swift
//  ExchangeRates
//
//  Handles data sharing between main app and widget via App Group
//

import Foundation
import WidgetKit

/// Provides data access for the widget through App Group shared container
class WidgetDataProvider {
    static let shared = WidgetDataProvider()
    
    private let userDefaults: UserDefaults?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        userDefaults = UserDefaults(suiteName: appGroupIdentifier)
        if userDefaults == nil {
            print("⚠️ WidgetDataProvider: Failed to access App Group UserDefaults")
        }
    }
    
    // MARK: - Watchlist Items
    
    /// Load watchlist items from App Group
    func loadWatchlistItems() -> [WatchlistItem] {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: WidgetDataKeys.watchlistItems) else {
            return []
        }
        
        do {
            let items = try decoder.decode([WatchlistItem].self, from: data)
            return items
        } catch {
            print("⚠️ WidgetDataProvider: Failed to decode watchlist items: \(error)")
            return []
        }
    }
    
    /// Save watchlist items to App Group
    func saveWatchlistItems(_ items: [WatchlistItem]) {
        guard let userDefaults = userDefaults else { return }
        
        do {
            let data = try encoder.encode(items)
            userDefaults.set(data, forKey: WidgetDataKeys.watchlistItems)
            userDefaults.set(Date(), forKey: WidgetDataKeys.lastUpdateDate)
            userDefaults.synchronize()
        } catch {
            print("⚠️ WidgetDataProvider: Failed to encode watchlist items: \(error)")
        }
    }
    
    /// Get last update date
    func getLastUpdateDate() -> Date? {
        return userDefaults?.object(forKey: WidgetDataKeys.lastUpdateDate) as? Date
    }
    
    // MARK: - Favorites
    
    /// Get favorite currency codes
    func getFavoriteCurrencies() -> [String] {
        return userDefaults?.stringArray(forKey: WidgetDataKeys.favoriteCurrencies) ?? []
    }
    
    /// Save favorite currency codes
    func saveFavoriteCurrencies(_ currencies: [String]) {
        userDefaults?.set(currencies, forKey: WidgetDataKeys.favoriteCurrencies)
        userDefaults?.synchronize()
    }
    
    /// Get favorite crypto IDs
    func getFavoriteCryptos() -> [String] {
        return userDefaults?.stringArray(forKey: WidgetDataKeys.favoriteCryptos) ?? []
    }
    
    /// Save favorite crypto IDs
    func saveFavoriteCryptos(_ cryptos: [String]) {
        userDefaults?.set(cryptos, forKey: WidgetDataKeys.favoriteCryptos)
        userDefaults?.synchronize()
    }
    
    // MARK: - Widget Type Selection
    
    /// Get selected widget type
    func getSelectedWidgetType() -> WatchlistWidgetType {
        guard let userDefaults = userDefaults,
              let rawValue = userDefaults.string(forKey: WidgetDataKeys.selectedWidgetType),
              let type = WatchlistWidgetType(rawValue: rawValue) else {
            return .mixed
        }
        return type
    }
    
    /// Save selected widget type
    func saveSelectedWidgetType(_ type: WatchlistWidgetType) {
        userDefaults?.set(type.rawValue, forKey: WidgetDataKeys.selectedWidgetType)
        userDefaults?.synchronize()
    }
    
    // MARK: - Widget Reload
    
    /// Trigger widget reload
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Filtered Items
    
    /// Load watchlist items filtered by type
    func loadWatchlistItems(ofType type: WatchlistWidgetType) -> [WatchlistItem] {
        let allItems = loadWatchlistItems()
        
        switch type {
        case .crypto:
            return allItems.filter { $0.type == .crypto }
        case .currency:
            return allItems.filter { $0.type == .currency }
        case .mixed:
            return allItems
        }
    }
    
    /// Get items for widget display (limited by widget size)
    func getItemsForWidget(type: WatchlistWidgetType, maxItems: Int) -> [WatchlistItem] {
        let allItems = loadWatchlistItems()
        
        switch type {
        case .crypto:
            return Array(allItems.filter { $0.type == .crypto }.prefix(maxItems))
        case .currency:
            return Array(allItems.filter { $0.type == .currency }.prefix(maxItems))
        case .mixed:
            // Half currencies, half crypto (currencies first)
            let currencies = allItems.filter { $0.type == .currency }
            let cryptos = allItems.filter { $0.type == .crypto }
            
            let halfCount = maxItems / 2
            let currencyCount = min(currencies.count, halfCount)
            let cryptoCount = min(cryptos.count, maxItems - currencyCount)
            
            var result = Array(currencies.prefix(currencyCount))
            result.append(contentsOf: cryptos.prefix(cryptoCount))
            return result
        }
    }
}

// MARK: - Convenience Extensions

extension WidgetDataProvider {
    /// Check if there are any favorite items
    var hasFavorites: Bool {
        !getFavoriteCurrencies().isEmpty || !getFavoriteCryptos().isEmpty
    }
    
    /// Check if data is stale (older than 30 minutes)
    var isDataStale: Bool {
        guard let lastUpdate = getLastUpdateDate() else { return true }
        let staleThreshold: TimeInterval = 30 * 60 // 30 minutes
        return Date().timeIntervalSince(lastUpdate) > staleThreshold
    }
}
