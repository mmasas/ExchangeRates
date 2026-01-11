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
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @State private var tapCount = 0
    @State private var lastTapTime = Date()
    @State private var navigationPath = NavigationPath()
    @State private var showConverter = false
    @Environment(\.layoutDirection) private var layoutDirection
    
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
                        } else if viewModel.filterMode == .favorites && viewModel.filteredExchangeRates.isEmpty {
                            // Show empty state when in favorites mode with no favorites
                            Section {
                                VStack(spacing: 20) {
                                    Image(systemName: "star.slash")
                                        .font(.system(size: 60))
                                        .foregroundColor(.secondary)
                                    
                                    Text(String(localized: "no_favorites_title"))
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(String(localized: "no_currency_favorites_message"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 60)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        } else {
                            // Show actual data (merged main API + custom currencies) with drag-and-drop
                            ForEach(viewModel.filteredExchangeRates) { rate in
                                ExchangeRateRow(exchangeRate: rate)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: layoutDirection == .rightToLeft ? .leading : .trailing) {
                                        Button {
                                            FavoriteCurrencyManager.shared.toggleFavorite(rate.key)
                                        } label: {
                                            Label(
                                                viewModel.favoriteCurrencyIds.contains(rate.key)
                                                    ? String(localized: "remove_from_favorites")
                                                    : String(localized: "add_to_favorites"),
                                                systemImage: "star.fill"
                                            )
                                        }
                                        .tint(viewModel.favoriteCurrencyIds.contains(rate.key) ? .orange : .yellow)
                                    }
                            }
                            .onMove(perform: viewModel.filterMode == .all ? { source, destination in
                                // Haptic feedback when move completes
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                viewModel.updateCurrencyOrder(from: source, to: destination)
                            } : nil)
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
                        // Converter button
                        Button {
                            showConverter = true
                        } label: {
                            Image(systemName: "arrow.left.arrow.right")
                                .foregroundColor(.primary)
                                .font(.system(size: 20))
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
                        
                        // Empty spacer to balance the header
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .padding(.horizontal, 16)
                    
                    // Filter toggle bar
                    VStack(spacing: 0) {
                        Divider()
                        
                        HStack {
                            Picker("", selection: $viewModel.filterMode) {
                                Text(String(localized: "All", defaultValue: "All"))
                                    .tag(CurrencyFilterMode.all)
                                Text(String(localized: "favorites_tab", defaultValue: "Favorites"))
                                    .tag(CurrencyFilterMode.favorites)
                            }
                            .pickerStyle(.segmented)
                            .padding(.vertical, 8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .animation(.default, value: networkMonitor.isConnected)
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
            .sheet(isPresented: $showConverter) {
                StandaloneConverterView(exchangeRates: viewModel.allExchangeRates)
                    .presentationDragIndicator(.visible)
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
