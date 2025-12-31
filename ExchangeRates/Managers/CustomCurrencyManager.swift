//
//  CustomCurrencyManager.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import Foundation

class CustomCurrencyManager {
    static let shared = CustomCurrencyManager()
    
    private let userDefaults = UserDefaults.standard
    private let customCurrenciesKey = "customCurrencies"
    
    private init() {}
    
    func getCustomCurrencies() -> [String] {
        return userDefaults.stringArray(forKey: customCurrenciesKey) ?? []
    }
    
    func addCustomCurrency(_ code: String) {
        var currencies = getCustomCurrencies()
        if !currencies.contains(code) {
            currencies.append(code)
            userDefaults.set(currencies, forKey: customCurrenciesKey)
        }
    }
    
    func removeCustomCurrency(_ code: String) {
        var currencies = getCustomCurrencies()
        currencies.removeAll { $0 == code }
        userDefaults.set(currencies, forKey: customCurrenciesKey)
    }
    
    func isCustomCurrency(_ code: String) -> Bool {
        return getCustomCurrencies().contains(code)
    }
    
    func getAvailableCurrencyCodes(excluding existingCodes: [String]) -> [String] {
        let allCodes = Locale.commonISOCurrencyCodes
        let existingSet = Set(existingCodes)
        let customSet = Set(getCustomCurrencies())
        
        return allCodes.filter { code in
            !existingSet.contains(code) && !customSet.contains(code)
        }.sorted()
    }
}

