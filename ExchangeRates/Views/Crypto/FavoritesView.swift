//
//  FavoritesView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 07/01/2026.
//

import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = CryptoViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var websocketService = BinanceWebSocketService.shared
    @ObservedObject private var websocketManager = WebSocketManager.shared
    @Environment(\.layoutDirection) private var layoutDirection
    
    private let cacheManager = DataCacheManager.shared
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.favoriteCryptocurrencies.isEmpty {
                    // Empty state
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            ForEach(viewModel.favoriteCryptocurrencies, id: \.id) { crypto in
                                CryptoRow(
                                    cryptocurrency: crypto,
                                    sparklinePrices: crypto.sparklinePrices
                                )
                                .environmentObject(viewModel)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: layoutDirection == .rightToLeft ? .leading : .trailing) {
                                    Button(role: .destructive) {
                                        FavoriteCryptoManager.shared.removeFavorite(crypto.id)
                                    } label: {
                                        Label(
                                            String(localized: "remove_from_favorites"),
                                            systemImage: "star.slash.fill"
                                        )
                                    }
                                    .tint(.red)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        LogManager.shared.log("Pull to refresh favorites triggered", level: .info, source: "FavoritesView")
                        await viewModel.refreshCryptocurrencies()
                        LogManager.shared.log("Pull to refresh favorites completed", level: .success, source: "FavoritesView")
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
                            Spacer()
                            
                            Text(String(localized: "favorites_title"))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    FavoritesView()
}
