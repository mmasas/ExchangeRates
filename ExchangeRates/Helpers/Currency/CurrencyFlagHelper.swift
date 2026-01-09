//
//  CurrencyFlagHelper.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 26/12/2025.
//

import Foundation
import SwiftUI
import UIKit

struct CurrencyFlagHelper {
    // Special mappings for currencies that don't follow the standard pattern
    private static let specialCurrencyFlags: [String: String] = [
        "EUR": "🇪🇺",
        "XAF": "🇨🇲", // Central African CFA franc
        "XOF": "🇸🇳", // West African CFA franc
        "XPF": "🇵🇫", // CFP franc
    ]
    
    // Special mappings for currency codes to flag image asset names
    private static let specialCurrencyFlagAssets: [String: String] = [
        "EUR": "eu", // European Union flag
        "GBP": "uk", // Great Britain Pound -> UK flag
        "XAF": "cm", // Central African CFA franc -> Cameroon
        "XOF": "sn", // West African CFA franc -> Senegal
        "XPF": "pf", // CFP franc -> French Polynesia
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
    
    // Get flag image asset name for a currency code
    static func flagImageName(for currencyCode: String) -> String {
        // Check special mappings first
        if let specialAsset = specialCurrencyFlagAssets[currencyCode] {
            return specialAsset
        }
        
        // Convert currency code to country code (lowercase for asset names)
        let countryCode = String(currencyCode.prefix(2)).lowercased()
        return countryCode
    }
    
    // Get SwiftUI Image for a currency code
    // Returns the image asset if available, otherwise returns a placeholder
    static func flagImage(for currencyCode: String) -> Image {
        let imageName = flagImageName(for: currencyCode)
        // Check if image exists in bundle
        if UIImage(named: imageName) != nil {
            return Image(imageName)
        } else {
            // Fallback: return a system image placeholder
            // In practice, SwiftUI Image will handle missing images gracefully (shows nothing)
            // But we provide a fallback to avoid empty space
            return Image(systemName: "flag.fill")
        }
    }
    
    // Get a View that displays flag image with emoji fallback
    // Use this when you want to ensure something is always displayed
    @ViewBuilder
    static func flagImageWithFallback(for currencyCode: String, size: CGFloat = 24) -> some View {
        let imageName = flagImageName(for: currencyCode)
        if UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            // Fallback to emoji flag
            Text(flag(for: currencyCode))
                .font(.system(size: size))
        }
    }
    
    // Get country name from currency code
    static func countryName(for currencyCode: String) -> String {
        // Check special mappings first
        let specialCountryNames: [String: String] = [
            "EUR": String(localized: "europe", defaultValue: "Europe"),
            "XAF": String(localized: "central_africa", defaultValue: "Central Africa"),
            "XOF": String(localized: "west_africa", defaultValue: "West Africa"),
            "XPF": String(localized: "french_polynesia", defaultValue: "French Polynesia")
        ]
        
        if let specialName = specialCountryNames[currencyCode] {
            return specialName
        }
        
        // Convert currency code to country code
        let countryCode = String(currencyCode.prefix(2))
        
        // Get country name from locale using LanguageManager
        let locale = LanguageManager.shared.currentLocale
        if let countryName = locale.localizedString(forRegionCode: countryCode) {
            return countryName
        }
        
        // Fallback to currency code if country name not found
        return currencyCode
    }
    
    /// Get formatted currency symbol for a given currency code
    /// Returns the currency symbol (e.g., $, €, ₪) or the currency code as fallback
    static func currencySymbol(for currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        if let currencySymbol = formatter.currencySymbol {
            return currencySymbol
        }
        // Fallback to currency code if symbol not found
        return currencyCode
    }
    
    /// Get the localized currency name for a currency code
    /// Returns the currency name (e.g., "US Dollar", "Euro", "Israeli New Shekel")
    static func currencyName(for currencyCode: String) -> String {
        let locale = LanguageManager.shared.currentLocale
        if let name = locale.localizedString(forCurrencyCode: currencyCode) {
            return name
        }
        // Fallback to currency code if name not found
        return currencyCode
    }
}

