//
//  DebugMenuView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import SwiftUI

struct DebugMenuView: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var websocketManager = WebSocketManager.shared
    @StateObject private var websocketService = BinanceWebSocketService.shared
    
    var body: some View {
        List {
            Section("Network Testing") {
                Toggle("Simulate Offline Mode", isOn: $networkMonitor.simulateOffline)
                
                HStack {
                    Text("Current Status:")
                    Spacer()
                    Text(networkMonitor.isConnected ? "Online" : "Offline")
                        .foregroundColor(networkMonitor.isConnected ? .green : .orange)
                }
            }
            
            Section("WebSocket Settings") {
                Toggle("Enable WebSocket Updates", isOn: $websocketManager.isWebSocketEnabled)
                
                HStack {
                    Text("Connection Status:")
                    Spacer()
                    Text(websocketService.isConnected ? "Connected" : "Disconnected")
                        .foregroundColor(websocketService.isConnected ? .green : .gray)
                }
                
                HStack {
                    Text("Enabled Cryptos:")
                    Spacer()
                    Text("\(MainCryptoHelper.websocketEnabledCryptos.count)")
                        .foregroundColor(.secondary)
                }
                
                Text("Real-time price updates for selected cryptocurrencies via WebSocket connection to Binance.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Debug Tools") {
                NavigationLink(destination: LogsView()) {
                    Label("View Logs", systemImage: "doc.text")
                }
                
                NavigationLink(destination: DataInspectorView()) {
                    Label("View Stored Data", systemImage: "tray.full")
                }
            }
        }
        .navigationTitle("Debug Menu")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        DebugMenuView()
    }
}

