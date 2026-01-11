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
        }
    }
    
    /// Whether this theme uses system colors (adapts to iOS appearance)
    var usesSystemColors: Bool {
        switch self {
        case .light, .dark, .system:
            return true
        case .oceanic, .forest, .sunset, .midnight:
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
        case .oceanic, .forest, .sunset, .midnight:
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
        }
    }
    
    // MARK: - Text Colors
    
    var primaryTextColor: Color {
        switch self {
        case .light, .dark, .system:
            return Color(.label)
        case .oceanic, .forest, .sunset, .midnight:
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
        }
    }
    
    // MARK: - Helpers
    
    var isDark: Bool {
        switch self {
        case .light:
            return false
        case .dark, .system: // system will be handled dynamically
            return true
        case .oceanic, .forest, .sunset, .midnight:
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
