//
//  ColorSchemeManager.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import Foundation
import SwiftUI

enum ColorSchemeOption: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system:
            return String(localized: "system", defaultValue: "System")
        case .light:
            return String(localized: "light", defaultValue: "Light")
        case .dark:
            return String(localized: "dark", defaultValue: "Dark")
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

class ColorSchemeManager {
    static let shared = ColorSchemeManager()
    
    private let userDefaults = UserDefaults.standard
    private let colorSchemeKey = "colorScheme"
    
    private init() {}
    
    func getColorScheme() -> ColorSchemeOption {
        if let rawValue = userDefaults.string(forKey: colorSchemeKey),
           let option = ColorSchemeOption(rawValue: rawValue) {
            return option
        }
        return .system // Default to system
    }
    
    func setColorScheme(_ option: ColorSchemeOption) {
        userDefaults.set(option.rawValue, forKey: colorSchemeKey)
    }
}


