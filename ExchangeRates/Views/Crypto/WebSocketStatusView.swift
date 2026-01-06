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
                    .foregroundColor(.secondary)
            } else {
                Text(String(localized: "live_updates_disabled", defaultValue: "Live updates disabled"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
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


