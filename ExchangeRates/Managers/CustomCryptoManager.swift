//
//  CustomCryptoManager.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import Foundation

class CustomCryptoManager {
    static let shared = CustomCryptoManager()
    
    private let userDefaults = UserDefaults.standard
    private let customCryptosKey = "customCryptos"
    
    private init() {}
    
    func getCustomCryptos() -> [String] {
        return userDefaults.stringArray(forKey: customCryptosKey) ?? []
    }
    
    func addCustomCrypto(_ coinGeckoId: String) {
        var cryptos = getCustomCryptos()
        if !cryptos.contains(coinGeckoId) {
            cryptos.append(coinGeckoId)
            userDefaults.set(cryptos, forKey: customCryptosKey)
        }
    }
    
    func removeCustomCrypto(_ coinGeckoId: String) {
        var cryptos = getCustomCryptos()
        cryptos.removeAll { $0 == coinGeckoId }
        userDefaults.set(cryptos, forKey: customCryptosKey)
    }
    
    func isCustomCrypto(_ coinGeckoId: String) -> Bool {
        return getCustomCryptos().contains(coinGeckoId)
    }
}

