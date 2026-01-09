//
//  CryptoView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import SwiftUI

struct CryptoView: View {
    @StateObject private var viewModel = CryptoViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var websocketService = BinanceWebSocketService.shared
    @ObservedObject private var websocketManager = WebSocketManager.shared
    @State private var isSearchActive = false
    @FocusState private var isSearchFocused: Bool
    @Environment(\.layoutDirection) private var layoutDirection
    
    private let cacheManager = DataCacheManager.shared
    
    /// The row index at which to trigger prefetching of the next page
    private let prefetchThreshold = 35
    
    var body: some View {
        NavigationStack {
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
                        if viewModel.isLoading && viewModel.cryptocurrencies.isEmpty {
                            // Show skeleton rows when loading and no data exists
                            Section {
                                ForEach(0..<10, id: \.self) { _ in
                                    CryptoRowSkeleton()
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                }
                            }
                        } else if viewModel.filterMode == .favorites && viewModel.filteredCryptocurrencies.isEmpty {
                            // Show empty state when in favorites mode with no favorites
                            Section {
                                VStack(spacing: 20) {
                                    Image(systemName: "star.slash")
                                        .font(.system(size: 60))
                                        .foregroundColor(.secondary)
                                    
                                    Text(String(localized: "no_favorites_title"))
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(String(localized: "no_favorites_message"))
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
                            // Show actual cryptocurrency data
                            Section {
                                ForEach(Array(viewModel.filteredCryptocurrencies.enumerated()), id: \.element.id) { index, crypto in
                                    CryptoRow(
                                        cryptocurrency: crypto,
                                        sparklinePrices: crypto.sparklinePrices
                                    )
                                    .environmentObject(viewModel)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: layoutDirection == .rightToLeft ? .leading : .trailing) {
                                        Button {
                                            FavoriteCryptoManager.shared.toggleFavorite(crypto.id)
                                        } label: {
                                            Label(
                                                viewModel.favoriteCryptoIds.contains(crypto.id) 
                                                    ? String(localized: "remove_from_favorites")
                                                    : String(localized: "add_to_favorites"),
                                                systemImage: "star.fill"
                                            )
                                        }
                                        .tint(viewModel.favoriteCryptoIds.contains(crypto.id) ? .orange : .yellow)
                                    }
                                    .onAppear {
                                        // Trigger prefetch when reaching the threshold row (only when not searching)
                                        if viewModel.searchText.isEmpty && index == prefetchThreshold && viewModel.hasMorePages {
                                            viewModel.prefetchNextPage()
                                        }
                                    }
                                }
                                
                                // Show loading indicator at bottom when loading next page
                                if viewModel.isLoadingNextPage {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .padding(.vertical, 16)
                                        Spacer()
                                    }
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        LogManager.shared.log("Pull to refresh triggered", level: .info, source: "CryptoView")
                        await viewModel.refreshCryptocurrencies()
                        LogManager.shared.log("Pull to refresh completed", level: .success, source: "CryptoView")
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
                    VStack(spacing: 8) {
                        HStack {
                            // Search button (leading side)
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    isSearchActive.toggle()
                                    if isSearchActive {
                                        isSearchFocused = true
                                    } else {
                                        viewModel.searchText = ""
                                        isSearchFocused = false
                                    }
                                }
                            } label: {
                                Image(systemName: isSearchActive ? "xmark" : "magnifyingglass")
                                    .foregroundColor(.primary)
                                    .font(.system(size: 20))
                            }
                            .frame(width: 44, height: 44)
                            
                            Spacer()
                            
                            Text(String(localized: "crypto_title"))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // WebSocket status indicator (only shown when Live only filter is active)
                            if !isSearchActive && viewModel.filterMode == .liveOnly {
                                WebSocketStatusView(
                                    isConnected: websocketService.isConnected,
                                    enabledCryptosCount: MainCryptoHelper.websocketEnabledCryptos.count,
                                    isWebSocketEnabled: websocketManager.isWebSocketEnabled
                                )
                            } else {
                                // Empty spacer to balance the header when indicator is not shown
                                Color.clear
                                    .frame(width: 44, height: 44)
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, isSearchActive ? 8 : 12)
                    .padding(.horizontal, 16)
                    
                    // Search bar (only visible when active)
                    if isSearchActive {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            
                            TextField(String(localized: "search_crypto"), text: $viewModel.searchText)
                                .textFieldStyle(.plain)
                                .focused($isSearchFocused)
                            
                            if !viewModel.searchText.isEmpty {
                                Button {
                                    viewModel.searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Filter toggle bar (fixed below header, only when search is not active)
                    if !isSearchActive {
                        VStack(spacing: 0) {
                            Divider()
                            
                            HStack {
                                Picker("", selection: $viewModel.filterMode) {
                                    Text(String(localized: "All", defaultValue: "All"))
                                        .tag(CryptoFilterMode.all)
                                    Text(String(localized: "live_only", defaultValue: "Live only"))
                                        .tag(CryptoFilterMode.liveOnly)
                                    Text(String(localized: "favorites_tab", defaultValue: "Favorites"))
                                        .tag(CryptoFilterMode.favorites)
                                }
                                .pickerStyle(.segmented)
                                .padding(.vertical, 8)
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .animation(.easeInOut(duration: 0.25), value: isSearchActive)
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    CryptoView()
}
