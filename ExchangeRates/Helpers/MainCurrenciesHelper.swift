//
//  MainCurrenciesHelper.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 30/12/2025.
//

import Foundation

class MainCurrenciesHelper {
    /// The 14 main currencies that should appear first in all pickers
    static let mainCurrencies: [String] = [
        "USD", // דולר אמריקאי 🇺🇸
        "EUR", // אירו 🇪🇺
        "JPY", // ין יפני 🇯🇵
        "GBP", // לירה שטרלינג 🇬🇧
        "CNY", // יואן סיני 🇨🇳
        "AUD", // דולר אוסטרלי 🇦🇺
        "CAD", // דולר קנדי 🇨🇦
        "CHF", // פרנק שווייצרי 🇨🇭
        "KRW", // וון דרום־קוריאני 🇰🇷
        "ILS", // שקל חדש 🇮🇱
        "CZK", // קורונה צ'כית 🇨🇿
        "PLN", // זלוטי פולני 🇵🇱
        "THB", // באט תאילנדי 🇹🇭
        "AED"  // דירהם איחוד האמירויות 🇦🇪
    ]
    
    /// Check if a currency is a main currency
    static func isMainCurrency(_ code: String) -> Bool {
        return mainCurrencies.contains(code)
    }
    
    /// Sort currencies with main currencies first, then others alphabetically
    static func sortCurrencies(_ currencies: [String]) -> [String] {
        let mainSet = Set(mainCurrencies)
        let currencySet = Set(currencies)
        
        // Separate into main and others
        let main = mainCurrencies.filter { currencySet.contains($0) }
        let others = currencies.filter { !mainSet.contains($0) }.sorted()
        
        return main + others
    }
    
    /// Get all currencies sorted (main first, then all others from Locale)
    static func getAllCurrenciesSorted() -> [String] {
        let allLocaleCurrencies = Locale.commonISOCurrencyCodes
        let allCurrencies = Array(Set(mainCurrencies + allLocaleCurrencies))
        return sortCurrencies(allCurrencies)
    }
    
    /// Get all currencies for picker (main + locale currencies) sorted
    /// Used for currency selection in pickers like home currency picker
    static func getAllCurrenciesForPicker() -> [String] {
        let allLocaleCurrencies = Locale.commonISOCurrencyCodes
        let allCurrencies = Array(Set(mainCurrencies + allLocaleCurrencies))
        return sortCurrencies(allCurrencies)
    }
    
    /// Get all currencies including custom currencies with proper ordering
    /// Returns: main currencies first (in order), then custom currencies (sorted), then others (sorted)
    static func getAllCurrenciesIncludingCustom(customCurrencies: [String]) -> [String] {
        let allLocaleCurrencies = Locale.commonISOCurrencyCodes
        
        // Combine all and remove duplicates
        let allCurrenciesSet = Set(mainCurrencies + customCurrencies + allLocaleCurrencies)
        
        // Separate into main, custom, and others
        let mainSet = Set(mainCurrencies)
        let customSet = Set(customCurrencies)
        let othersSet = allCurrenciesSet.subtracting(mainSet).subtracting(customSet)
        
        // Return: main currencies first (in order), then custom, then others (sorted)
        return mainCurrencies.filter { allCurrenciesSet.contains($0) } +
               customCurrencies.sorted() +
               Array(othersSet).sorted()
    }
}

