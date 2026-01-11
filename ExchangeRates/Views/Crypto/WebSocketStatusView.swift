//
//  WebSocketStatusView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import SwiftUI

struct WebSocketStatusView: View {
    let isConnected: Bool
    let enabledCryptosCount: Int
    let isWebSocketEnabled: Bool
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var theme: AppTheme { themeManager.currentTheme }
    private var secondaryColor: Color { theme.usesSystemColors ? .secondary : theme.secondaryTextColor }
    private var backgroundColor: Color { theme.usesSystemColors ? Color(.systemGray6) : theme.cardBackgroundColor }
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isWebSocketEnabled && isConnected ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            
            if isWebSocketEnabled {
                Text(isConnected ? 
                     String(localized: "live_updates_enabled", defaultValue: "Live") :
                     String(localized: "live_updates_connecting", defaultValue: "Connecting..."))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(secondaryColor)
            } else {
                Text(String(localized: "live_updates_disabled", defaultValue: "Live updates disabled"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(secondaryColor)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 20) {
        WebSocketStatusView(isConnected: true, enabledCryptosCount: 20, isWebSocketEnabled: true)
        WebSocketStatusView(isConnected: false, enabledCryptosCount: 20, isWebSocketEnabled: true)
        WebSocketStatusView(isConnected: false, enabledCryptosCount: 20, isWebSocketEnabled: false)
    }
    .padding()
}


