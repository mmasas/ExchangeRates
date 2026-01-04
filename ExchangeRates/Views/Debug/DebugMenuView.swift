//
//  DebugMenuView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import SwiftUI

struct DebugMenuView: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var simulateOffline = false
    
    var body: some View {
        List {
            Section("Network Testing") {
                Toggle("Simulate Offline Mode", isOn: $simulateOffline)
                    .onChange(of: simulateOffline) { _, newValue in
                        // Force network monitor to reflect simulated state
                        // Note: This is a debug-only feature
                        if newValue {
                            // We can't directly set isConnected, but we can use a workaround
                            // by posting a notification that simulates offline
                            NotificationCenter.default.post(name: NSNotification.Name("SimulateOffline"), object: nil)
                        } else {
                            NotificationCenter.default.post(name: NSNotification.Name("SimulateOnline"), object: nil)
                        }
                    }
                
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

