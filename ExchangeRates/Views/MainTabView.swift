//
//  MainTabView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import SwiftUI

struct MainTabView: View {
    
    init() {
        // Configure tab bar with more transparent blur effect
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.3)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView {
            CurrencyView()
                .tabItem {
                    Image(systemName: "dollarsign.circle.fill")
                    Text(String(localized: "currencies_tab"))
                }
            
            CryptoView()
                .tabItem {
                    Image(systemName: "bitcoinsign.circle.fill")
                    Text(String(localized: "crypto_tab"))
                }
            
            NavigationStack {
                AlertsView()
            }
            .tabItem {
                Image(systemName: "bell.fill")
                Text(String(localized: "alerts_tab"))
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text(String(localized: "settings_tab"))
            }
        }
        .tint(.blue)
    }
}

#Preview {
    MainTabView()
}

