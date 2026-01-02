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
                    Text(String(localized: "currencies_tab", defaultValue: "Currencies"))
                }
            
            CryptoView()
                .tabItem {
                    Image(systemName: "bitcoinsign.circle.fill")
                    Text(String(localized: "crypto_tab", defaultValue: "Crypto"))
                }
        }
        .tint(.blue)
    }
}

#Preview {
    MainTabView()
}

