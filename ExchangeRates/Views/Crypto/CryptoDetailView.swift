//
//  CryptoDetailView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 02/01/2026.
//

import SwiftUI

struct CryptoDetailView: View {
    let cryptocurrency: Cryptocurrency
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @EnvironmentObject var viewModel: CryptoViewModel
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    private var lastUpdatedDate: Date? {
        guard let dateString = cryptocurrency.lastUpdated else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return isoFormatter.date(from: dateString)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Logo and name section
                VStack(spacing: 12) {
                    AsyncImage(url: URL(string: cryptocurrency.image)) { phase in
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
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                                .frame(width: 80, height: 80)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    
                    VStack(spacing: 4) {
                        Text(cryptocurrency.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(cryptocurrency.displaySymbol)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 24)
                
                // Price section
                VStack(spacing: 8) {
                    Text(cryptocurrency.formattedPrice)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: cryptocurrency.isPositiveChange ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                            .font(.system(size: 14))
                        Text(cryptocurrency.formattedChange)
                            .font(.system(size: 18, weight: .semibold))
                        Text("(24h)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(cryptocurrency.isPositiveChange ? .green : .red)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.primary.opacity(0.08), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 16)
                
                // Chart section
                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.selectedTimeRange.chartTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                    
                    // Time range selector
                    TimeRangeSelectorView(
                        selectedRange: $viewModel.selectedTimeRange,
                        onRangeSelected: { range in
                            viewModel.updateTimeRange(range, for: cryptocurrency.id)
                        }
                    )
                    
                    // Interactive chart
                    InteractiveChartView(
                        chartData: viewModel.chartData,
                        timeRange: viewModel.selectedTimeRange,
                        isPositive: cryptocurrency.isPositiveChange,
                        isLoading: viewModel.isLoadingChart,
                        isOffline: !networkMonitor.isConnected,
                        errorMessage: viewModel.chartErrorMessage
                    )
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.primary.opacity(0.08), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 16)
                
                // Last updated
                if let date = lastUpdatedDate {
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                        Text(String(localized: "last_updated"))
                        Text(dateFormatter.string(from: date))
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                }
                
                Spacer(minLength: 32)
            }
        }
        .background(Color(.systemGroupedBackground))
        .presentationDragIndicator(.visible)
        .onAppear {
            // Load chart data for default range when view appears
            viewModel.loadChartData(cryptoId: cryptocurrency.id, range: viewModel.selectedTimeRange)
        }
    }
}

#Preview {
    CryptoDetailView(
        cryptocurrency: Cryptocurrency(
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
            ])
        )
    )
    .environmentObject(CryptoViewModel())
}

