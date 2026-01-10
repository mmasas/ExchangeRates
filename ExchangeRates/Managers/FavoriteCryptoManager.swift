//
//  FavoriteCryptoManager.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 07/01/2026.
//

import Foundation
import WidgetKit

/// Manages favorite cryptocurrencies with persistent storage using App Groups
class FavoriteCryptoManager {
    static let shared = FavoriteCryptoManager()
    
    /// Use App Group UserDefaults for sharing with widget
    private let userDefaults: UserDefaults
    private let favoriteCryptosKey = "favoriteCryptos"
    
    /// Notification name for when favorites change
    static let favoritesDidChangeNotification = NSNotification.Name("FavoriteCryptosDidChange")
    
    private init() {
        // Try to use App Group UserDefaults, fallback to standard if not available
        if let appGroupDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            userDefaults = appGroupDefaults
            // Migrate existing favorites from standard UserDefaults if needed
            migrateFromStandardDefaults()
        } else {
            userDefaults = UserDefaults.standard
            LogManager.shared.log("⚠️ FavoriteCryptoManager: App Group not available, using standard UserDefaults", level: .warning, source: "FavoriteCryptoManager")
        }
    }
    
    /// Migrate favorites from standard UserDefaults to App Group (one-time migration)
    private func migrateFromStandardDefaults() {
        let migrationKey = "favoriteCryptosMigrated"
        guard !userDefaults.bool(forKey: migrationKey) else { return }
        
        // Check if there are favorites in standard UserDefaults
        let standardDefaults = UserDefaults.standard
        if let existingFavorites = standardDefaults.stringArray(forKey: favoriteCryptosKey),
           !existingFavorites.isEmpty {
            // Copy to App Group
            userDefaults.set(existingFavorites, forKey: favoriteCryptosKey)
            LogManager.shared.log("Migrated \(existingFavorites.count) crypto favorites to App Group", level: .info, source: "FavoriteCryptoManager")
        }
        
        userDefaults.set(true, forKey: migrationKey)
        userDefaults.synchronize()
    }
    
    /// Get all favorite cryptocurrency IDs
    func getFavorites() -> [String] {
        return userDefaults.stringArray(forKey: favoriteCryptosKey) ?? []
    }
    
    /// Add a cryptocurrency to favorites
    func addFavorite(_ coinGeckoId: String) {
        var favorites = getFavorites()
        if !favorites.contains(coinGeckoId) {
            favorites.append(coinGeckoId)
            userDefaults.set(favorites, forKey: favoriteCryptosKey)
            userDefaults.synchronize()
            postFavoritesChangedNotification()
            reloadWidgets()
        }
    }
    
    /// Remove a cryptocurrency from favorites
    func removeFavorite(_ coinGeckoId: String) {
        var favorites = getFavorites()
        favorites.removeAll { $0 == coinGeckoId }
        userDefaults.set(favorites, forKey: favoriteCryptosKey)
        userDefaults.synchronize()
        postFavoritesChangedNotification()
        reloadWidgets()
    }
    
    /// Check if a cryptocurrency is favorited
    func isFavorite(_ coinGeckoId: String) -> Bool {
        return getFavorites().contains(coinGeckoId)
    }
    
    /// Toggle favorite status for a cryptocurrency
    func toggleFavorite(_ coinGeckoId: String) {
        if isFavorite(coinGeckoId) {
            removeFavorite(coinGeckoId)
        } else {
            addFavorite(coinGeckoId)
        }
    }
    
    /// Post notification that favorites have changed
    private func postFavoritesChangedNotification() {
        NotificationCenter.default.post(
            name: FavoriteCryptoManager.favoritesDidChangeNotification,
            object: nil
        )
    }
    
    /// Reload widget timelines when favorites change
    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        LogManager.shared.log("Widget timelines reloaded after crypto favorites change", level: .debug, source: "FavoriteCryptoManager")
    }
}
