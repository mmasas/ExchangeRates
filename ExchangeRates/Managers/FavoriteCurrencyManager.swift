//
//  FavoriteCurrencyManager.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 09/01/2026.
//

import Foundation

/// Manages favorite currencies with persistent storage
class FavoriteCurrencyManager {
    static let shared = FavoriteCurrencyManager()
    
    private let userDefaults = UserDefaults.standard
    private let favoriteCurrenciesKey = "favoriteCurrencies"
    
    /// Notification name for when favorites change
    static let favoritesDidChangeNotification = NSNotification.Name("FavoriteCurrenciesDidChange")
    
    private init() {}
    
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
            postFavoritesChangedNotification()
        }
    }
    
    /// Remove a currency from favorites
    func removeFavorite(_ currencyCode: String) {
        var favorites = getFavorites()
        favorites.removeAll { $0 == currencyCode }
        userDefaults.set(favorites, forKey: favoriteCurrenciesKey)
        postFavoritesChangedNotification()
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
}
