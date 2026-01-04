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
    
    private init() {}
    
    /// Get the device's currency based on locale
    private func getDeviceCurrency() -> String {
        // Try to get currency from device locale
        if let currencyCode = Locale.current.currency?.identifier {
            LogManager.shared.log("Device currency detected: \(currencyCode)", level: .info, source: "HomeCurrencyManager")
            return currencyCode
        }
        // Fallback to USD if device currency can't be determined
        LogManager.shared.log("Device currency not detected, using USD as fallback", level: .warning, source: "HomeCurrencyManager")
        return "USD"
    }
    
    /// Get the current home currency (default: device currency)
    func getHomeCurrency() -> String {
        return userDefaults.string(forKey: homeCurrencyKey) ?? getDeviceCurrency()
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
            LogManager.shared.log("Home currency changed from \(oldCurrency) to \(code)", level: .info, source: "HomeCurrencyManager")
        }
    }
}

