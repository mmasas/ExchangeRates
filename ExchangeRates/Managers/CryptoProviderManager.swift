//
//  CryptoProviderManager.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import Foundation

enum CryptoProviderType: String, CaseIterable {
    case coingecko = "coingecko"
    case binance = "binance"
    
    var displayName: String {
        switch self {
        case .coingecko:
            return "CoinGecko"
        case .binance:
            return "Binance"
        }
    }
}

class CryptoProviderManager {
    static let shared = CryptoProviderManager()
    
    private let userDefaults = UserDefaults.standard
    private let providerKey = "cryptoProvider"
    
    /// Notification name for when provider changes
    static let providerChangedNotification = NSNotification.Name("CryptoProviderChanged")
    
    private init() {}
    
    /// Get the current crypto provider (default: CoinGecko)
    func getProvider() -> CryptoProviderType {
        if let rawValue = userDefaults.string(forKey: providerKey),
           let provider = CryptoProviderType(rawValue: rawValue) {
            return provider
        }
        return .coingecko // Default
    }
    
    /// Set the crypto provider and post notification
    func setProvider(_ provider: CryptoProviderType) {
        let oldProvider = getProvider()
        userDefaults.set(provider.rawValue, forKey: providerKey)
        
        // Post notification if provider changed
        if oldProvider != provider {
            NotificationCenter.default.post(
                name: CryptoProviderManager.providerChangedNotification,
                object: nil,
                userInfo: ["provider": provider]
            )
            LogManager.shared.log("Crypto provider changed to: \(provider.displayName)", level: .info, source: "CryptoProviderManager")
        }
    }
}

