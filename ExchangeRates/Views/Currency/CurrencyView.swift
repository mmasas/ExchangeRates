//
//  CurrencyView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 26/12/2025.
//

import SwiftUI
import UIKit

struct CurrencyView: View {
    @StateObject private var viewModel = ExchangeRatesViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var tapCount = 0
    @State private var lastTapTime = Date()
    @State private var navigationPath = NavigationPath()
    
    private let cacheManager = DataCacheManager.shared
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
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
                        LogManager.shared.log("Pull to refresh triggered", level: .info, source: "CurrencyView")
                        await viewModel.refreshAllRates()
                        LogManager.shared.log("Pull to refresh completed", level: .success, source: "CurrencyView")
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                // Custom header with blur effect
                VStack(spacing: 0) {
                    // Offline indicator banner (if offline)
                    if !networkMonitor.isConnected {
                        OfflineIndicatorView(lastUpdateDate: cacheManager.getLastUpdateDate())
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Header content
                    HStack {
                        // Empty spacer to balance the header (matching CryptoView structure)
                        Color.clear
                            .frame(width: 44, height: 44)
                        
                        Spacer()
                        
                        Text(String(localized: "exchange_rates_title"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .onTapGesture {
                                handleTitleTap()
                            }
                        
                        Spacer()
                        
                        // Empty spacer to balance the header
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
            .background(Color(.systemGroupedBackground))
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "debug":
                    DebugMenuView()
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
    CurrencyView()
}
