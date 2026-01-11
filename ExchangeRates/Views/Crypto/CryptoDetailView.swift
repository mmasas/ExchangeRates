//
//  CryptoDetailView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 02/01/2026.
//

import SwiftUI

struct CryptoDetailView: View {
    let cryptocurrencyId: String
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var isWebSocketEnabled: Bool = false
    @State private var previousPrice: Double?
    @ObservedObject private var websocketManager = WebSocketManager.shared
    @EnvironmentObject var viewModel: CryptoViewModel
    
    private var theme: AppTheme { themeManager.currentTheme }
    private var primaryColor: Color { theme.usesSystemColors ? .primary : theme.primaryTextColor }
    private var secondaryColor: Color { theme.usesSystemColors ? .secondary : theme.secondaryTextColor }
    private var cardBackground: Color { theme.usesSystemColors ? Color(.systemBackground) : theme.cardBackgroundColor }
    private var backgroundColor: Color { theme.usesSystemColors ? Color(.systemGroupedBackground) : theme.backgroundColor }
    
    // Get current cryptocurrency from viewModel (updates when WebSocket updates price)
    private var cryptocurrency: Cryptocurrency? {
        viewModel.cryptocurrencies.first { $0.id == cryptocurrencyId }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    private func lastUpdatedDate(for crypto: Cryptocurrency) -> Date? {
        guard let dateString = crypto.lastUpdated else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return isoFormatter.date(from: dateString)
    }
    
    var body: some View {
        Group {
            if let crypto = cryptocurrency {
                ScrollView {
                    VStack(spacing: 24) {
                        // Logo and name section
                        VStack(spacing: 12) {
                            AsyncImage(url: URL(string: crypto.image)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 80, height: 80)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .shadow(color: Color.primary.opacity(0.15), radius: 8, x: 0, y: 4)
                        case .failure:
                            // Empty placeholder - just show a gray circle
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 80, height: 80)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    
                            VStack(spacing: 4) {
                                Text(crypto.name)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(primaryColor)
                                
                                Text(crypto.displaySymbol)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(secondaryColor)
                            }
                        }
                        .padding(.top, 24)
                        
                        // Price section
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                PriceChangeAnimationView(
                                    price: crypto.currentPrice,
                                    previousPrice: previousPrice
                                )
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(primaryColor)
                                
                                if isWebSocketEnabled {
                                    LiveIndicatorView()
                                }
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: crypto.isPositiveChange ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                                    .font(.system(size: 14))
                                Text(crypto.formattedChange)
                                    .font(.system(size: 18, weight: .semibold))
                                Text("(24h)")
                                    .font(.system(size: 14))
                                    .foregroundColor(secondaryColor)
                            }
                            .foregroundColor(crypto.isPositiveChange ? .green : .red)
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(cardBackground)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 16)
                        
                        // Chart section
                        VStack(alignment: .leading, spacing: 12) {
                            Text(viewModel.selectedTimeRange.chartTitle)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(secondaryColor)
                                .padding(.horizontal, 4)
                            
                            // Time range selector
                            TimeRangeSelectorView(
                                selectedRange: $viewModel.selectedTimeRange,
                                onRangeSelected: { range in
                                    viewModel.updateTimeRange(range, for: crypto.id)
                                }
                            )
                            
                            // Interactive chart
                            InteractiveChartView(
                                chartData: viewModel.chartData,
                                timeRange: viewModel.selectedTimeRange,
                                isPositive: crypto.isPositiveChange,
                                isLoading: viewModel.isLoadingChart,
                                isOffline: !networkMonitor.isConnected,
                                errorMessage: viewModel.chartErrorMessage
                            )
                        }
                        .padding(16)
                        .background(cardBackground)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 16)
                        
                        // Market data section under the chart
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(String(localized: "market_cap_rank", defaultValue: "Market Cap Rank"))
                                    .font(.system(size: 12))
                                    .foregroundColor(secondaryColor)
                                Text(crypto.marketCapRank.map { "#\($0)" } ?? String(localized: "not_available", defaultValue: "N/A"))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(primaryColor)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .center, spacing: 6) {
                                Text(String(localized: "24h_low", defaultValue: "24h Low"))
                                    .font(.system(size: 12))
                                    .foregroundColor(secondaryColor)
                                Text(crypto.formattedLow24h)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            
                            VStack(alignment: .trailing, spacing: 6) {
                                Text(String(localized: "24h_high", defaultValue: "24h High"))
                                    .font(.system(size: 12))
                                    .foregroundColor(secondaryColor)
                                Text(crypto.formattedHigh24h)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(16)
                        .background(cardBackground)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 16)
                        
                        // Last updated
                        if let date = lastUpdatedDate(for: crypto) {
                            HStack {
                                Image(systemName: "clock")
                                    .font(.system(size: 14))
                                Text(String(localized: "last_updated"))
                                Text(dateFormatter.string(from: date))
                            }
                            .font(.system(size: 14))
                            .foregroundColor(secondaryColor)
                            .padding(.top, 4)
                        }
                        
                        Spacer(minLength: 32)
                    }
                }
                .background(backgroundColor)
                .presentationDragIndicator(.visible)
                .onAppear {
                    // Check if this crypto uses WebSocket and if WebSocket is enabled
                    if let crypto = cryptocurrency {
                        isWebSocketEnabled = MainCryptoHelper.shouldUseWebSocket(crypto.id) && websocketManager.isWebSocketEnabled
                        previousPrice = crypto.currentPrice
                        
                        // Load chart data for default range when view appears
                        viewModel.loadChartData(cryptoId: crypto.id, range: viewModel.selectedTimeRange)
                    }
                }
                .onChange(of: cryptocurrency?.currentPrice) { oldValue, newValue in
                    if let oldValue = oldValue {
                        previousPrice = oldValue
                    }
                }
                .onChange(of: websocketManager.isWebSocketEnabled) { _, newValue in
                    // Update WebSocket enabled state when preference changes
                    if let crypto = cryptocurrency {
                        isWebSocketEnabled = MainCryptoHelper.shouldUseWebSocket(crypto.id) && newValue
                    }
                }
            } else {
                // Fallback if cryptocurrency not found
                Text("Cryptocurrency not found")
                    .foregroundColor(secondaryColor)
            }
        }
    }
}

#Preview {
    let viewModel = CryptoViewModel()
    viewModel.cryptocurrencies = [
        Cryptocurrency(
            id: "bitcoin",
            symbol: "btc",
            name: "Bitcoin",
            image: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png",
            currentPrice: 87805.0,
            priceChangePercentage24h: 2.1,
            lastUpdated: "2026-01-02T10:30:00.000Z",
            sparklineIn7d: SparklineIn7d(price: [
                85000, 85500, 86000, 85800, 86200, 86500, 86300,
                86800, 87000, 86700, 87200, 87500, 87300, 87800,
                88000, 87600, 87900, 88200, 87800, 88100, 87805
            ]),
            marketCapRank: 1,
            high24h: 89000.0,
            low24h: 85000.0
        )
    ]
    return CryptoDetailView(cryptocurrencyId: "bitcoin")
        .environmentObject(viewModel)
}

