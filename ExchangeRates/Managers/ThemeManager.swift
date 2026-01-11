//
//  ThemeManager.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 11/01/2026.
//

import Foundation
import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case system
    case oceanic
    case forest
    case sunset
    case midnight
    case aurora
    case desert
    case meadow
    case roseGold
    case lavender
    case mint
    case amber
    case coral
    case navy
    case sepia
    case coffee
    case matrix
    case ember
    case arctic
    case sakura
    case cyber
    case hacker
    case neon
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .light:
            return String(localized: "theme_light", defaultValue: "Light")
        case .dark:
            return String(localized: "theme_dark", defaultValue: "Dark")
        case .system:
            return String(localized: "theme_system", defaultValue: "System")
        case .oceanic:
            return String(localized: "theme_oceanic", defaultValue: "Oceanic")
        case .forest:
            return String(localized: "theme_forest", defaultValue: "Forest")
        case .sunset:
            return String(localized: "theme_sunset", defaultValue: "Sunset")
        case .midnight:
            return String(localized: "theme_midnight", defaultValue: "Midnight")
        case .aurora:
            return String(localized: "theme_aurora", defaultValue: "Aurora")
        case .desert:
            return String(localized: "theme_desert", defaultValue: "Desert")
        case .meadow:
            return String(localized: "theme_meadow", defaultValue: "Meadow")
        case .roseGold:
            return String(localized: "theme_roseGold", defaultValue: "Rose Gold")
        case .lavender:
            return String(localized: "theme_lavender", defaultValue: "Lavender")
        case .mint:
            return String(localized: "theme_mint", defaultValue: "Mint")
        case .amber:
            return String(localized: "theme_amber", defaultValue: "Amber")
        case .coral:
            return String(localized: "theme_coral", defaultValue: "Coral")
        case .navy:
            return String(localized: "theme_navy", defaultValue: "Navy")
        case .sepia:
            return String(localized: "theme_sepia", defaultValue: "Sepia")
        case .coffee:
            return String(localized: "theme_coffee", defaultValue: "Coffee")
        case .matrix:
            return String(localized: "theme_matrix", defaultValue: "Matrix")
        case .ember:
            return String(localized: "theme_ember", defaultValue: "Ember")
        case .arctic:
            return String(localized: "theme_arctic", defaultValue: "Arctic")
        case .sakura:
            return String(localized: "theme_sakura", defaultValue: "Sakura")
        case .cyber:
            return String(localized: "theme_cyber", defaultValue: "Cyber")
        case .hacker:
            return String(localized: "theme_hacker", defaultValue: "Hacker")
        case .neon:
            return String(localized: "theme_neon", defaultValue: "Neon")
        }
    }
    
    /// Whether this theme uses system colors (adapts to iOS appearance)
    var usesSystemColors: Bool {
        switch self {
        case .light, .dark, .system:
            return true
        case .oceanic, .forest, .sunset, .midnight, .aurora, .desert, .meadow, .roseGold, .lavender, .mint, .amber, .coral, .navy, .sepia, .coffee, .matrix, .ember, .arctic, .sakura, .cyber, .hacker, .neon:
            return false
        }
    }
    
    /// The color scheme to force, or nil to follow system
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil // Follow system
        case .oceanic, .forest, .sunset, .midnight, .aurora, .desert, .meadow, .roseGold, .lavender, .mint, .amber, .coral, .navy, .sepia, .coffee, .matrix, .ember, .arctic, .sakura, .cyber, .hacker, .neon:
            return .dark // Premium themes are all dark
        }
    }
    
    // MARK: - Background Colors
    
    var backgroundColor: Color {
        switch self {
        case .light, .dark, .system:
            return Color(.systemBackground)
        case .oceanic:
            return Color(red: 0.102, green: 0.149, blue: 0.204) // #1a2634
        case .forest:
            return Color(red: 0.102, green: 0.180, blue: 0.102) // #1a2e1a
        case .sunset:
            return Color(red: 0.176, green: 0.122, blue: 0.176) // #2d1f2d
        case .midnight:
            return Color(red: 0.039, green: 0.039, blue: 0.039) // #0a0a0a
        case .aurora:
            return Color(red: 0.102, green: 0.075, blue: 0.149) // #1a1326
        case .desert:
            return Color(red: 0.165, green: 0.122, blue: 0.078) // #2a1f14
        case .meadow:
            return Color(red: 0.078, green: 0.180, blue: 0.149) // #142e26
        case .roseGold:
            return Color(red: 0.169, green: 0.102, blue: 0.122) // #2b1a1f
        case .lavender:
            return Color(red: 0.149, green: 0.102, blue: 0.165) // #261a2a
        case .mint:
            return Color(red: 0.102, green: 0.180, blue: 0.165) // #1a2e2a
        case .amber:
            return Color(red: 0.165, green: 0.122, blue: 0.039) // #2a1f0a
        case .coral:
            return Color(red: 0.176, green: 0.122, blue: 0.102) // #2d1f1a
        case .navy:
            return Color(red: 0.039, green: 0.071, blue: 0.125) // #0a1220
        case .sepia:
            return Color(red: 0.122, green: 0.102, blue: 0.063) // #1f1a10
        case .coffee:
            return Color(red: 0.102, green: 0.082, blue: 0.063) // #1a1510
        case .matrix:
            return Color(red: 0.0, green: 0.0, blue: 0.0) // #000000
        case .ember:
            return Color(red: 0.102, green: 0.039, blue: 0.039) // #1a0a0a
        case .arctic:
            return Color(red: 0.039, green: 0.086, blue: 0.125) // #0a1620
        case .sakura:
            return Color(red: 0.176, green: 0.102, blue: 0.125) // #2d1a20
        case .cyber:
            return Color(red: 0.039, green: 0.039, blue: 0.102) // #0a0a1a
        case .hacker:
            return Color(red: 0.039, green: 0.059, blue: 0.039) // #0a0f0a
        case .neon:
            return Color(red: 0.020, green: 0.020, blue: 0.020) // #050505
        }
    }
    
    var secondaryBackgroundColor: Color {
        switch self {
        case .light, .dark, .system:
            return Color(.secondarySystemBackground)
        case .oceanic:
            return Color(red: 0.08, green: 0.12, blue: 0.16) // darker for header
        case .forest:
            return Color(red: 0.08, green: 0.14, blue: 0.08)
        case .sunset:
            return Color(red: 0.14, green: 0.10, blue: 0.14)
        case .midnight:
            return Color(red: 0.05, green: 0.05, blue: 0.05)
        case .aurora:
            return Color(red: 0.06, green: 0.04, blue: 0.10)
        case .desert:
            return Color(red: 0.12, green: 0.09, blue: 0.06)
        case .meadow:
            return Color(red: 0.06, green: 0.14, blue: 0.12)
        case .roseGold:
            return Color(red: 0.12, green: 0.08, blue: 0.10)
        case .lavender:
            return Color(red: 0.10, green: 0.06, blue: 0.12)
        case .mint:
            return Color(red: 0.06, green: 0.14, blue: 0.12)
        case .amber:
            return Color(red: 0.12, green: 0.09, blue: 0.03)
        case .coral:
            return Color(red: 0.14, green: 0.10, blue: 0.08)
        case .navy:
            return Color(red: 0.03, green: 0.05, blue: 0.09)
        case .sepia:
            return Color(red: 0.09, green: 0.08, blue: 0.05)
        case .coffee:
            return Color(red: 0.08, green: 0.06, blue: 0.05)
        case .matrix:
            return Color(red: 0.0, green: 0.0, blue: 0.0)
        case .ember:
            return Color(red: 0.08, green: 0.03, blue: 0.03)
        case .arctic:
            return Color(red: 0.03, green: 0.06, blue: 0.09)
        case .sakura:
            return Color(red: 0.14, green: 0.08, blue: 0.10)
        case .cyber:
            return Color(red: 0.03, green: 0.03, blue: 0.08)
        case .hacker:
            return Color(red: 0.03, green: 0.04, blue: 0.03)
        case .neon:
            return Color(red: 0.015, green: 0.015, blue: 0.015)
        }
    }
    
    var cardBackgroundColor: Color {
        switch self {
        case .light, .dark, .system:
            return Color(.secondarySystemBackground)
        case .oceanic:
            return Color(red: 0.18, green: 0.24, blue: 0.32) // lighter cards for contrast
        case .forest:
            return Color(red: 0.16, green: 0.28, blue: 0.16)
        case .sunset:
            return Color(red: 0.28, green: 0.20, blue: 0.28)
        case .midnight:
            return Color(red: 0.15, green: 0.15, blue: 0.15)
        case .aurora:
            return Color(red: 0.18, green: 0.14, blue: 0.24)
        case .desert:
            return Color(red: 0.24, green: 0.18, blue: 0.12)
        case .meadow:
            return Color(red: 0.14, green: 0.28, blue: 0.24)
        case .roseGold:
            return Color(red: 0.28, green: 0.18, blue: 0.20)
        case .lavender:
            return Color(red: 0.24, green: 0.18, blue: 0.26)
        case .mint:
            return Color(red: 0.18, green: 0.28, blue: 0.24)
        case .amber:
            return Color(red: 0.24, green: 0.18, blue: 0.08)
        case .coral:
            return Color(red: 0.28, green: 0.20, blue: 0.18)
        case .navy:
            return Color(red: 0.08, green: 0.14, blue: 0.24)
        case .sepia:
            return Color(red: 0.20, green: 0.18, blue: 0.14)
        case .coffee:
            return Color(red: 0.18, green: 0.14, blue: 0.12)
        case .matrix:
            return Color(red: 0.05, green: 0.05, blue: 0.05)
        case .ember:
            return Color(red: 0.18, green: 0.08, blue: 0.08)
        case .arctic:
            return Color(red: 0.08, green: 0.16, blue: 0.24)
        case .sakura:
            return Color(red: 0.28, green: 0.18, blue: 0.22)
        case .cyber:
            return Color(red: 0.08, green: 0.08, blue: 0.18)
        case .hacker:
            return Color(red: 0.08, green: 0.12, blue: 0.08)
        case .neon:
            return Color(red: 0.08, green: 0.08, blue: 0.08)
        }
    }
    
    // MARK: - Accent Colors
    
    var accentColor: Color {
        switch self {
        case .light, .dark, .system:
            return .blue
        case .oceanic:
            return Color(red: 0.459, green: 0.569, blue: 0.706) // blue-gray
        case .forest:
            return Color(red: 0.290, green: 0.871, blue: 0.502) // #4ade80
        case .sunset:
            return Color(red: 1.0, green: 0.420, blue: 0.208) // #ff6b35
        case .midnight:
            return Color(red: 0.133, green: 0.827, blue: 0.933) // #22d3ee cyan
        case .aurora:
            return Color(red: 0.478, green: 0.918, blue: 0.757) // #7aea9f teal-green
        case .desert:
            return Color(red: 1.0, green: 0.647, blue: 0.0) // #ffa500 orange
        case .meadow:
            return Color(red: 0.522, green: 0.929, blue: 0.647) // #85eda5 mint-green
        case .roseGold:
            return Color(red: 0.929, green: 0.510, blue: 0.588) // #ed8296 rose
        case .lavender:
            return Color(red: 0.698, green: 0.518, blue: 0.878) // #b284e0 lavender
        case .mint:
            return Color(red: 0.416, green: 0.953, blue: 0.757) // #6af3c1 mint-teal
        case .amber:
            return Color(red: 1.0, green: 0.753, blue: 0.0) // #ffc000 amber
        case .coral:
            return Color(red: 1.0, green: 0.498, blue: 0.314) // #ff7f50 coral
        case .navy:
            return Color(red: 1.0, green: 0.843, blue: 0.0) // #ffd700 gold
        case .sepia:
            return Color(red: 0.855, green: 0.647, blue: 0.125) // #daa520 goldenrod
        case .coffee:
            return Color(red: 0.871, green: 0.722, blue: 0.529) // #deb887 burlywood
        case .matrix:
            return Color(red: 0.0, green: 1.0, blue: 0.0) // #00ff00 matrix green
        case .ember:
            return Color(red: 1.0, green: 0.271, blue: 0.0) // #ff4500 red-orange
        case .arctic:
            return Color(red: 0.529, green: 0.808, blue: 0.922) // #87ceeb sky blue
        case .sakura:
            return Color(red: 1.0, green: 0.753, blue: 0.796) // #ffc0cb pink
        case .cyber:
            return Color(red: 0.0, green: 0.980, blue: 1.0) // #00faff cyan-magenta mix
        case .hacker:
            return Color(red: 0.0, green: 1.0, blue: 0.502) // #00ff80 terminal green
        case .neon:
            return Color(red: 1.0, green: 0.0, blue: 1.0) // #ff00ff magenta
        }
    }
    
    // MARK: - Text Colors
    
    var primaryTextColor: Color {
        switch self {
        case .light, .dark, .system:
            return Color(.label)
        case .oceanic, .forest, .sunset, .midnight, .aurora, .desert, .meadow, .roseGold, .lavender, .mint, .amber, .coral, .navy, .sepia, .coffee, .matrix, .ember, .arctic, .sakura, .cyber, .hacker, .neon:
            return .white
        }
    }
    
    var secondaryTextColor: Color {
        switch self {
        case .light, .dark, .system:
            return Color(.secondaryLabel)
        case .oceanic:
            return Color(red: 0.7, green: 0.78, blue: 0.88) // brighter blue-gray
        case .forest:
            return Color(red: 0.7, green: 0.88, blue: 0.7) // brighter green
        case .sunset:
            return Color(red: 0.9, green: 0.8, blue: 0.9) // brighter purple/pink
        case .midnight:
            return Color(red: 0.7, green: 0.7, blue: 0.7) // brighter gray
        case .aurora:
            return Color(red: 0.8, green: 0.85, blue: 0.9) // brighter purple-teal
        case .desert:
            return Color(red: 0.9, green: 0.8, blue: 0.7) // brighter sand
        case .meadow:
            return Color(red: 0.7, green: 0.9, blue: 0.85) // brighter mint
        case .roseGold:
            return Color(red: 0.95, green: 0.85, blue: 0.88) // brighter rose
        case .lavender:
            return Color(red: 0.9, green: 0.85, blue: 0.95) // brighter lavender
        case .mint:
            return Color(red: 0.8, green: 0.95, blue: 0.9) // brighter mint-teal
        case .amber:
            return Color(red: 1.0, green: 0.9, blue: 0.7) // brighter amber
        case .coral:
            return Color(red: 1.0, green: 0.85, blue: 0.8) // brighter coral
        case .navy:
            return Color(red: 0.9, green: 0.9, blue: 0.95) // brighter navy-blue
        case .sepia:
            return Color(red: 0.9, green: 0.85, blue: 0.75) // brighter sepia
        case .coffee:
            return Color(red: 0.9, green: 0.8, blue: 0.7) // brighter coffee
        case .matrix:
            return Color(red: 0.0, green: 0.8, blue: 0.0) // matrix green
        case .ember:
            return Color(red: 1.0, green: 0.7, blue: 0.6) // brighter ember
        case .arctic:
            return Color(red: 0.8, green: 0.9, blue: 1.0) // brighter arctic blue
        case .sakura:
            return Color(red: 1.0, green: 0.9, blue: 0.92) // brighter sakura pink
        case .cyber:
            return Color(red: 0.7, green: 0.8, blue: 1.0) // brighter cyber blue
        case .hacker:
            return Color(red: 0.6, green: 0.9, blue: 0.7) // brighter hacker green
        case .neon:
            return Color(red: 0.95, green: 0.8, blue: 0.95) // brighter neon magenta
        }
    }
    
    // MARK: - Theme Preview Colors (for theme picker UI)
    
    var previewBackgroundColor: Color {
        switch self {
        case .light:
            return .white
        case .dark:
            return Color(red: 0.11, green: 0.11, blue: 0.12) // iOS dark mode background
        case .system:
            return Color(red: 0.5, green: 0.5, blue: 0.5) // Gray to represent "auto"
        case .oceanic:
            return Color(red: 0.102, green: 0.149, blue: 0.204)
        case .forest:
            return Color(red: 0.102, green: 0.180, blue: 0.102)
        case .sunset:
            return Color(red: 0.176, green: 0.122, blue: 0.176)
        case .midnight:
            return Color(red: 0.039, green: 0.039, blue: 0.039)
        case .aurora:
            return Color(red: 0.102, green: 0.075, blue: 0.149)
        case .desert:
            return Color(red: 0.165, green: 0.122, blue: 0.078)
        case .meadow:
            return Color(red: 0.078, green: 0.180, blue: 0.149)
        case .roseGold:
            return Color(red: 0.169, green: 0.102, blue: 0.122)
        case .lavender:
            return Color(red: 0.149, green: 0.102, blue: 0.165)
        case .mint:
            return Color(red: 0.102, green: 0.180, blue: 0.165)
        case .amber:
            return Color(red: 0.165, green: 0.122, blue: 0.039)
        case .coral:
            return Color(red: 0.176, green: 0.122, blue: 0.102)
        case .navy:
            return Color(red: 0.039, green: 0.071, blue: 0.125)
        case .sepia:
            return Color(red: 0.122, green: 0.102, blue: 0.063)
        case .coffee:
            return Color(red: 0.102, green: 0.082, blue: 0.063)
        case .matrix:
            return Color(red: 0.0, green: 0.0, blue: 0.0)
        case .ember:
            return Color(red: 0.102, green: 0.039, blue: 0.039)
        case .arctic:
            return Color(red: 0.039, green: 0.086, blue: 0.125)
        case .sakura:
            return Color(red: 0.176, green: 0.102, blue: 0.125)
        case .cyber:
            return Color(red: 0.039, green: 0.039, blue: 0.102)
        case .hacker:
            return Color(red: 0.039, green: 0.059, blue: 0.039)
        case .neon:
            return Color(red: 0.020, green: 0.020, blue: 0.020)
        }
    }
    
    var previewLineColor: Color {
        switch self {
        case .light:
            return Color(red: 0.6, green: 0.6, blue: 0.65)
        case .dark:
            return Color(red: 0.5, green: 0.5, blue: 0.55)
        case .system:
            return Color(red: 0.7, green: 0.7, blue: 0.7)
        case .oceanic:
            return Color(red: 0.5, green: 0.55, blue: 0.65)
        case .forest:
            return Color(red: 0.5, green: 0.6, blue: 0.5)
        case .sunset:
            return Color(red: 0.6, green: 0.55, blue: 0.6)
        case .midnight:
            return Color(red: 0.45, green: 0.45, blue: 0.45)
        case .aurora:
            return Color(red: 0.55, green: 0.5, blue: 0.6)
        case .desert:
            return Color(red: 0.6, green: 0.55, blue: 0.5)
        case .meadow:
            return Color(red: 0.5, green: 0.65, blue: 0.6)
        case .roseGold:
            return Color(red: 0.65, green: 0.55, blue: 0.6)
        case .lavender:
            return Color(red: 0.6, green: 0.55, blue: 0.65)
        case .mint:
            return Color(red: 0.55, green: 0.65, blue: 0.6)
        case .amber:
            return Color(red: 0.65, green: 0.6, blue: 0.5)
        case .coral:
            return Color(red: 0.65, green: 0.55, blue: 0.5)
        case .navy:
            return Color(red: 0.5, green: 0.55, blue: 0.65)
        case .sepia:
            return Color(red: 0.6, green: 0.55, blue: 0.5)
        case .coffee:
            return Color(red: 0.55, green: 0.5, blue: 0.45)
        case .matrix:
            return Color(red: 0.0, green: 0.4, blue: 0.0)
        case .ember:
            return Color(red: 0.6, green: 0.4, blue: 0.4)
        case .arctic:
            return Color(red: 0.5, green: 0.6, blue: 0.7)
        case .sakura:
            return Color(red: 0.65, green: 0.55, blue: 0.6)
        case .cyber:
            return Color(red: 0.5, green: 0.55, blue: 0.7)
        case .hacker:
            return Color(red: 0.4, green: 0.6, blue: 0.45)
        case .neon:
            return Color(red: 0.6, green: 0.5, blue: 0.6)
        }
    }
    
    // MARK: - Helpers
    
    var isDark: Bool {
        switch self {
        case .light:
            return false
        case .dark, .system: // system will be handled dynamically
            return true
        case .oceanic, .forest, .sunset, .midnight, .aurora, .desert, .meadow, .roseGold, .lavender, .mint, .amber, .coral, .navy, .sepia, .coffee, .matrix, .ember, .arctic, .sakura, .cyber, .hacker, .neon:
            return true
        }
    }
}

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    private let userDefaults = UserDefaults.standard
    private let themeKey = "appTheme"
    private let oldColorSchemeKey = "colorScheme" // For migration
    
    @Published var currentTheme: AppTheme
    @Published var isChangingTheme: Bool = false
    
    private init() {
        // Try to load saved theme
        if let rawValue = userDefaults.string(forKey: themeKey),
           let theme = AppTheme(rawValue: rawValue) {
            self.currentTheme = theme
        } else if let rawValue = userDefaults.string(forKey: themeKey), rawValue == "standard" {
            // Migrate from old "standard" theme - check old color scheme setting
            let oldScheme = userDefaults.string(forKey: oldColorSchemeKey) ?? "system"
            switch oldScheme {
            case "light":
                self.currentTheme = .light
            case "dark":
                self.currentTheme = .dark
            default:
                self.currentTheme = .system
            }
            // Save the migrated theme
            userDefaults.set(self.currentTheme.rawValue, forKey: themeKey)
        } else {
            // Check if there's an old color scheme setting to migrate
            if let oldScheme = userDefaults.string(forKey: oldColorSchemeKey) {
                switch oldScheme {
                case "light":
                    self.currentTheme = .light
                case "dark":
                    self.currentTheme = .dark
                default:
                    self.currentTheme = .system
                }
                // Save the migrated theme
                userDefaults.set(self.currentTheme.rawValue, forKey: themeKey)
            } else {
                // Default to system
                self.currentTheme = .system
            }
        }
    }
    
    func setTheme(_ theme: AppTheme) {
        // Prevent multiple rapid theme changes
        guard !isChangingTheme else { return }
        
        isChangingTheme = true
        
        // Perform the theme change
        currentTheme = theme
        userDefaults.set(theme.rawValue, forKey: themeKey)
        NotificationCenter.default.post(
            name: NSNotification.Name("ThemeChanged"),
            object: nil
        )
        
        // Allow time for SwiftUI to re-render all views
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
            isChangingTheme = false
        }
    }
    
    func getTheme() -> AppTheme {
        return currentTheme
    }
}
