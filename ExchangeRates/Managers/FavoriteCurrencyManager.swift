//
//  FavoriteCurrencyManager.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 09/01/2026.
//

import Foundation
import WidgetKit

/// Manages favorite currencies with persistent storage using App Groups
class FavoriteCurrencyManager {
    static let shared = FavoriteCurrencyManager()
    
    /// Use App Group UserDefaults for sharing with widget
    private let userDefaults: UserDefaults
    private let favoriteCurrenciesKey = "favoriteCurrencies"
    
    /// Notification name for when favorites change
    static let favoritesDidChangeNotification = NSNotification.Name("FavoriteCurrenciesDidChange")
    
    private init() {
        // Try to use App Group UserDefaults, fallback to standard if not available
        if let appGroupDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            userDefaults = appGroupDefaults
            // Migrate existing favorites from standard UserDefaults if needed
            migrateFromStandardDefaults()
        } else {
            userDefaults = UserDefaults.standard
            LogManager.shared.log("⚠️ FavoriteCurrencyManager: App Group not available, using standard UserDefaults", level: .warning, source: "FavoriteCurrencyManager")
        }
    }
    
    /// Migrate favorites from standard UserDefaults to App Group (one-time migration)
    private func migrateFromStandardDefaults() {
        let migrationKey = "favoriteCurrenciesMigrated"
        guard !userDefaults.bool(forKey: migrationKey) else { return }
        
        // Check if there are favorites in standard UserDefaults
        let standardDefaults = UserDefaults.standard
        if let existingFavorites = standardDefaults.stringArray(forKey: favoriteCurrenciesKey),
           !existingFavorites.isEmpty {
            // Copy to App Group
            userDefaults.set(existingFavorites, forKey: favoriteCurrenciesKey)
            LogManager.shared.log("Migrated \(existingFavorites.count) currency favorites to App Group", level: .info, source: "FavoriteCurrencyManager")
        }
        
        userDefaults.set(true, forKey: migrationKey)
        userDefaults.synchronize()
    }
    
    /// Get all favorite currency codes
    func getFavorites() -> [String] {
        return userDefaults.stringArray(forKey: favoriteCurrenciesKey) ?? []
    }
    
    /// Add a currency to favorites
    func addFavorite(_ currencyCode: String) {
        var favorites = getFavorites()
        if !favorites.contains(currencyCode) {
            favorites.append(currencyCode)
            userDefaults.set(favorites, forKey: favoriteCurrenciesKey)
            userDefaults.synchronize()
            postFavoritesChangedNotification()
            reloadWidgets()
        }
    }
    
    /// Remove a currency from favorites
    func removeFavorite(_ currencyCode: String) {
        var favorites = getFavorites()
        favorites.removeAll { $0 == currencyCode }
        userDefaults.set(favorites, forKey: favoriteCurrenciesKey)
        userDefaults.synchronize()
        postFavoritesChangedNotification()
        reloadWidgets()
    }
    
    /// Check if a currency is favorited
    func isFavorite(_ currencyCode: String) -> Bool {
        return getFavorites().contains(currencyCode)
    }
    
    /// Toggle favorite status for a currency
    func toggleFavorite(_ currencyCode: String) {
        if isFavorite(currencyCode) {
            removeFavorite(currencyCode)
        } else {
            addFavorite(currencyCode)
        }
    }
    
    /// Post notification that favorites have changed
    private func postFavoritesChangedNotification() {
        NotificationCenter.default.post(
            name: FavoriteCurrencyManager.favoritesDidChangeNotification,
            object: nil
        )
    }
    
    /// Reload widget timelines when favorites change
    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        LogManager.shared.log("Widget timelines reloaded after currency favorites change", level: .debug, source: "FavoriteCurrencyManager")
    }
}
