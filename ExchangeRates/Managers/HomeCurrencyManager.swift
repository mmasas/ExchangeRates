//
//  HomeCurrencyManager.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 30/12/2025.
//

import Foundation

class HomeCurrencyManager {
    static let shared = HomeCurrencyManager()
    
    private let userDefaults = UserDefaults.standard
    private let homeCurrencyKey = "homeCurrency"
    private let defaultHomeCurrency = "USD"
    
    private init() {}
    
    /// Get the current home currency (default: USD)
    func getHomeCurrency() -> String {
        return userDefaults.string(forKey: homeCurrencyKey) ?? defaultHomeCurrency
    }
    
    /// Set the home currency and notify listeners
    func setHomeCurrency(_ code: String) {
        let oldCurrency = getHomeCurrency()
        userDefaults.set(code, forKey: homeCurrencyKey)
        
        // Post notification if currency changed
        if oldCurrency != code {
            NotificationCenter.default.post(
                name: NSNotification.Name("HomeCurrencyChanged"),
                object: nil,
                userInfo: ["oldCurrency": oldCurrency, "newCurrency": code]
            )
            print("🔄 [HomeCurrencyManager] Home currency changed from \(oldCurrency) to \(code)")
        }
    }
}

