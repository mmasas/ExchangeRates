//
//  DebugMenuView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import SwiftUI

struct DebugMenuView: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
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

