//
//  DebugMenuView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import SwiftUI

struct DebugMenuView: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var selectedProvider: CryptoProviderType
    
    init() {
        let provider = CryptoProviderManager.shared.getProvider()
        _selectedProvider = State(initialValue: provider)
    }
    
    var body: some View {
        List {
            Section("Crypto Provider") {
                Picker("Data Provider", selection: $selectedProvider) {
                    ForEach(CryptoProviderType.allCases, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedProvider) { oldValue, newValue in
                    CryptoProviderManager.shared.setProvider(newValue)
                }
                
                HStack {
                    Text("Current Provider:")
                    Spacer()
                    Text(selectedProvider.displayName)
                        .foregroundColor(.secondary)
                }
            }
            
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
        .onAppear {
            // Update selected provider when view appears
            selectedProvider = CryptoProviderManager.shared.getProvider()
        }
    }
}

#Preview {
    NavigationStack {
        DebugMenuView()
    }
}

