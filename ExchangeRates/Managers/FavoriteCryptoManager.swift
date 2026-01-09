//
//  FavoriteCryptoManager.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 07/01/2026.
//

import Foundation

/// Manages favorite cryptocurrencies with persistent storage
class FavoriteCryptoManager {
    static let shared = FavoriteCryptoManager()
    
    private let userDefaults = UserDefaults.standard
    private let favoriteCryptosKey = "favoriteCryptos"
    
    /// Notification name for when favorites change
    static let favoritesDidChangeNotification = NSNotification.Name("FavoriteCryptosDidChange")
    
    private init() {}
    
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
            postFavoritesChangedNotification()
        }
    }
    
    /// Remove a cryptocurrency from favorites
    func removeFavorite(_ coinGeckoId: String) {
        var favorites = getFavorites()
        favorites.removeAll { $0 == coinGeckoId }
        userDefaults.set(favorites, forKey: favoriteCryptosKey)
        postFavoritesChangedNotification()
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
}
