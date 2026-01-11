//
//  MainTabView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import SwiftUI
import UIKit

struct MainTabView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var badgeCount: Int = 0
    @State private var selectedTab: Int = 0
    @State private var tabViewId = UUID()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CurrencyView()
                .tabItem {
                    Image(systemName: "dollarsign.circle.fill")
                    Text(String(localized: "currencies_tab"))
                }
                .tag(0)
            
            CryptoView()
                .tabItem {
                    Image(systemName: "bitcoinsign.circle.fill")
                    Text(String(localized: "crypto_tab"))
                }
                .tag(1)
            
            NavigationStack {
                AlertsView()
            }
            .tabItem {
                Image(systemName: "bell.fill")
                Text(String(localized: "alerts_tab"))
            }
            .tag(2)
            .modifier(BadgeModifier(count: badgeCount))
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text(String(localized: "settings_tab"))
            }
            .tag(3)
        }
        .id(tabViewId)
        .tint(themeManager.currentTheme.usesSystemColors ? .blue : themeManager.currentTheme.accentColor)
        .onAppear {
            updateBadgeCount()
            updateTabBarAppearance()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AlertsUpdated"))) { _ in
            updateBadgeCount()
        }
        .onChange(of: themeManager.currentTheme) { _, _ in
            updateTabBarAppearance()
            // Force TabView to rebuild with new appearance
            tabViewId = UUID()
        }
    }
    
    private func updateTabBarAppearance() {
        let theme = themeManager.currentTheme
        let appearance = UITabBarAppearance()
        
        if theme.usesSystemColors {
            appearance.configureWithTransparentBackground()
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.3)
        } else {
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(theme.secondaryBackgroundColor)
        }
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func updateBadgeCount() {
        let alertManager = CurrencyAlertManager.shared
        let allAlerts = alertManager.getAllAlerts()
        let triggeredCount = allAlerts.filter { $0.status == .triggered }.count
        badgeCount = triggeredCount
        NotificationService.shared.setBadge(count: triggeredCount)
    }
}

struct BadgeModifier: ViewModifier {
    let count: Int
    
    func body(content: Content) -> some View {
        if count > 0 {
            content.badge(count)
        } else {
            content
        }
    }
}

#Preview {
    MainTabView()
}

