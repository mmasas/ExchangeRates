//
//  LanguageManager.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import Foundation
import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable {
    case system = "system"
    case hebrew = "he"
    case english = "en"
    case spanish = "es"
    case french = "fr"
    
    var displayName: String {
        switch self {
        case .system:
            return String(localized: "language_system", defaultValue: "System")
        case .hebrew:
            // Return Hebrew name in Hebrew
            return "עברית"
        case .english:
            // Return English name in English
            return "English"
        case .spanish:
            // Return Spanish name in Spanish
            return "Español"
        case .french:
            // Return French name in French
            return "Français"
        }
    }
    
    var locale: Locale {
        switch self {
        case .system:
            return Locale.current
        case .hebrew:
            return Locale(identifier: "he_IL")
        case .english:
            return Locale(identifier: "en_US")
        case .spanish:
            return Locale(identifier: "es_ES")
        case .french:
            return Locale(identifier: "fr_FR")
        }
    }
    
    var languageCode: String {
        switch self {
        case .system:
            // Determine from device language
            let deviceLang = Locale.preferredLanguages.first ?? "en"
            if deviceLang.hasPrefix("he") {
                return "he"
            } else if deviceLang.hasPrefix("es") {
                return "es"
            } else if deviceLang.hasPrefix("fr") {
                return "fr"
            } else {
                return "en"
            }
        case .hebrew:
            return "he"
        case .english:
            return "en"
        case .spanish:
            return "es"
        case .french:
            return "fr"
        }
    }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            saveLanguage()
            updateBundle()
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let languageKey = "appLanguage"
    
    private init() {
        // Load saved language or default to system
        if let savedLanguage = userDefaults.string(forKey: languageKey),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = .system
        }
        updateBundle()
    }
    
    private func saveLanguage() {
        userDefaults.set(currentLanguage.rawValue, forKey: languageKey)
    }
    
    private func updateBundle() {
        // Note: Runtime language switching requires app restart for full effect
        // For immediate effect, we use environment locale in the app
        UserDefaults.standard.set([currentLanguage.languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Post notification for views to update
        NotificationCenter.default.post(
            name: NSNotification.Name("LanguageChanged"),
            object: nil
        )
    }
    
    /// Get the current locale for date/number formatting
    var currentLocale: Locale {
        return currentLanguage.locale
    }
    
    /// Get the current language code for bundle lookups
    var currentLanguageCode: String {
        return currentLanguage.languageCode
    }
    
    /// Set the language (called from Settings)
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }
    
    /// Get the current language
    func getLanguage() -> AppLanguage {
        return currentLanguage
    }
}
