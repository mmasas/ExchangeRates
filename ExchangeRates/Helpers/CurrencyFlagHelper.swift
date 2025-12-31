//
//  CurrencyFlagHelper.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 26/12/2025.
//

import Foundation

struct CurrencyFlagHelper {
    // Special mappings for currencies that don't follow the standard pattern
    private static let specialCurrencyFlags: [String: String] = [
        "EUR": "🇪🇺",
        "XAF": "🇨🇲", // Central African CFA franc
        "XOF": "🇸🇳", // West African CFA franc
        "XPF": "🇵🇫", // CFP franc
    ]
    
    // Map currency codes to flag emojis
    static func flag(for currencyCode: String) -> String {
        // Check special mappings first
        if let specialFlag = specialCurrencyFlags[currencyCode] {
            return specialFlag
        }
        
        // Convert currency code to country code
        // Most currency codes use the first 2 letters as country code
        // For example: USD -> US, GBP -> GB, ILS -> IL
        let countryCode = String(currencyCode.prefix(2))
        
        // Generate flag emoji from country code
        return flagEmoji(for: countryCode)
    }
    
    // Generate flag emoji from ISO 3166-1 alpha-2 country code
    private static func flagEmoji(for countryCode: String) -> String {
        guard countryCode.count == 2 else {
            return "🏳️"
        }
        
        let base: UInt32 = 127397 // Regional Indicator Symbol base
        var flag = ""
        
        for scalar in countryCode.uppercased().unicodeScalars {
            guard let value = UnicodeScalar(base + scalar.value) else {
                return "🏳️"
            }
            flag.append(String(Character(value)))
        }
        
        return flag.isEmpty ? "🏳️" : flag
    }
    
    // Get country name from currency code
    static func countryName(for currencyCode: String) -> String {
        // Check special mappings first
        let specialCountryNames: [String: String] = [
            "EUR": "אירופה",
            "XAF": "מרכז אפריקה",
            "XOF": "מערב אפריקה",
            "XPF": "פולינזיה הצרפתית"
        ]
        
        if let specialName = specialCountryNames[currencyCode] {
            return specialName
        }
        
        // Convert currency code to country code
        let countryCode = String(currencyCode.prefix(2))
        
        // Get country name from locale
        let locale = Locale(identifier: "he_IL")
        if let countryName = locale.localizedString(forRegionCode: countryCode) {
            return countryName
        }
        
        // Fallback to currency code if country name not found
        return currencyCode
    }
    
    /// Get formatted currency symbol for a given currency code
    /// Returns the currency symbol (e.g., $, €, ₪) or the currency code as fallback
    static func currencySymbol(for currencyCode: String) -> String {
        let locale = Locale(identifier: "en_US")
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        if let currencySymbol = formatter.currencySymbol {
            return currencySymbol
        }
        // Fallback to currency code if symbol not found
        return currencyCode
    }
}

