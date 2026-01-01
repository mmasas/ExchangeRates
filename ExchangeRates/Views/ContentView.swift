//
//  ContentView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 26/12/2025.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = ExchangeRatesViewModel()
    @State private var tapCount = 0
    @State private var lastTapTime = Date()
    @State private var navigationPath = NavigationPath()
    @State private var activeAlertsCount: Int = 0
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Custom header with title and gear icon aligned
                HStack {
                    NavigationLink(value: "alerts") {
                        ZStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.primary)
                                .font(.system(size: 20))
                            
                            if activeAlertsCount > 0 {
                                Text("\(activeAlertsCount)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                                    .offset(x: 10, y: -10)
                            }
                        }
                    }
                    .frame(width: 44, height: 44)
                    
                    Spacer()
                    
                    Text(String(localized: "exchange_rates_title"))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .onTapGesture {
                            handleTitleTap()
                        }
                    
                    Spacer()
                    
                    NavigationLink(value: "settings") {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.primary)
                            .font(.system(size: 20))
                    }
                    .frame(width: 44, height: 44)
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
                .padding(.horizontal, 16)
                
                // Content
                if let errorMessage = viewModel.errorMessage, !viewModel.isLoading {
                    VStack {
                        Text(String(localized: "error"))
                            .font(.headline)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if viewModel.isLoading && viewModel.allExchangeRates.isEmpty {
                            // Show skeleton rows when loading and no data exists
                            ForEach(0..<8, id: \.self) { _ in
                                ExchangeRateRowSkeleton()
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                        } else {
                            // Show actual data (merged main API + custom currencies) with drag-and-drop
                            ForEach(viewModel.allExchangeRates) { rate in
                                ExchangeRateRow(exchangeRate: rate)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                            .onMove(perform: { source, destination in
                                // Haptic feedback when move completes
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                viewModel.updateCurrencyOrder(from: source, to: destination)
                            })
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        LogManager.shared.log("Pull to refresh triggered", level: .info, source: "ContentView")
                        await viewModel.refreshAllRates()
                        LogManager.shared.log("Pull to refresh completed", level: .success, source: "ContentView")
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "settings":
                    SettingsView(existingCurrencyCodes: viewModel.exchangeRates.map { $0.key })
                case "alerts":
                    AlertsView()
                case "debug":
                    DebugMenuView()
                default:
                    EmptyView()
                }
            }
            .onAppear {
                updateActiveAlertsCount()
            }
        }
    }
    
    private func updateActiveAlertsCount() {
        activeAlertsCount = CurrencyAlertManager.shared.getActiveAlerts().count
    }
    
    private func handleTitleTap() {
        let now = Date()
        let timeSinceLastTap = now.timeIntervalSince(lastTapTime)
        
        // Reset tap count if more than 1 second has passed
        if timeSinceLastTap > 1.0 {
            tapCount = 1
        } else {
            tapCount += 1
        }
        
        lastTapTime = now
        
        // Triple tap detected - navigate to debug menu
        if tapCount >= 3 {
            tapCount = 0
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Navigate to debug menu
            navigationPath.append("debug")
        }
    }
}

#Preview {
    ContentView()
}







