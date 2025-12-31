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
    @State private var isCheckingAlerts = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom header with title and gear icon aligned
                HStack {
                    // Invisible spacer to balance the gear icon on the right
                    Color.clear
                        .frame(width: 44, height: 44)
                    
                    Spacer()
                    
                    Text("שערי מטבעות")
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
                        Text("Error")
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
                        print("🔄 [ContentView] Pull to refresh triggered")
                        await viewModel.refreshAllRates()
                        print("✅ [ContentView] Pull to refresh completed")
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
                default:
                    EmptyView()
                }
            }
        }
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
        
        // Triple tap detected
        if tapCount >= 3 {
            tapCount = 0
            performSecretAlertCheck()
        }
    }
    
    private func performSecretAlertCheck() {
        guard !isCheckingAlerts else { return }
        
        isCheckingAlerts = true
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        Task {
            do {
                let triggeredAlerts = try await AlertCheckerService.shared.checkAlerts()
                
                await MainActor.run {
                    isCheckingAlerts = false
                    
                    // Haptic feedback for result
                    let resultGenerator = UINotificationFeedbackGenerator()
                    if triggeredAlerts.isEmpty {
                        resultGenerator.notificationOccurred(.success)
                    } else {
                        resultGenerator.notificationOccurred(.warning)
                    }
                    
                    print("🔔 [ContentView] Secret check completed. Triggered \(triggeredAlerts.count) alerts")
                }
            } catch {
                await MainActor.run {
                    isCheckingAlerts = false
                    print("❌ [ContentView] Secret check failed: \(error)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
