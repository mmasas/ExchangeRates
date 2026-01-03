//
//  CryptoRow.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import SwiftUI

struct CryptoRow: View {
    let cryptocurrency: Cryptocurrency
    let sparklinePrices: [Double]?
    let isLoadingSparkline: Bool
    
    @State private var isPressed = false
    @State private var showDetail = false
    
    init(cryptocurrency: Cryptocurrency, sparklinePrices: [Double]? = nil, isLoadingSparkline: Bool = false) {
        self.cryptocurrency = cryptocurrency
        self.sparklinePrices = sparklinePrices
        self.isLoadingSparkline = isLoadingSparkline
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // 1. Crypto logo (RIGHT in RTL)
            AsyncImage(url: URL(string: cryptocurrency.image)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 40, height: 40)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                case .failure:
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                        .frame(width: 40, height: 40)
                @unknown default:
                    EmptyView()
                }
            }
            
            // 2. Name and symbol (truncate if too long)
            VStack(alignment: .leading, spacing: 2) {
                Text(cryptocurrency.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(cryptocurrency.displaySymbol)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 60, maxWidth: 110, alignment: .leading)
            
            // 3. Sparkline chart (attached to name)
            SparklineView(prices: sparklinePrices, isLoading: isLoadingSparkline)
                .frame(width: 70, height: 30)
            
            Spacer(minLength: 8)
            
            // 4. Price and change (LEFT in RTL - end of row)
            VStack(alignment: .trailing, spacing: 2) {
                Text(cryptocurrency.formattedPrice)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                
                HStack(spacing: 2) {
                    Image(systemName: cryptocurrency.isPositiveChange ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.system(size: 8))
                    Text(cryptocurrency.formattedChange)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(cryptocurrency.isPositiveChange ? .green : .red)
            }
            .frame(minWidth: 80, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.3, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .sensoryFeedback(.impact(weight: .medium), trigger: isPressed)
        .onTapGesture {
            showDetail = true
        }
        .sheet(isPresented: $showDetail) {
            CryptoDetailView(cryptocurrency: cryptocurrency)
        }
    }
}

#Preview("With Sparkline") {
    CryptoRow(
        cryptocurrency: Cryptocurrency(
            id: "bitcoin",
            symbol: "btc",
            name: "Bitcoin",
            image: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png",
            currentPrice: 87805.0,
            priceChangePercentage24h: 2.1,
            lastUpdated: "2026-01-01T10:00:00.000Z",
            sparklineIn7d: SparklineIn7d(price: [85000, 86000, 84500, 87000, 88000, 87500, 87805])
        ),
        sparklinePrices: [85000, 86000, 84500, 87000, 88000, 87500, 87805]
    )
    .padding()
}

#Preview("Loading Sparkline") {
    CryptoRow(
        cryptocurrency: Cryptocurrency(
            id: "bitcoin",
            symbol: "btc",
            name: "Bitcoin",
            image: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png",
            currentPrice: 87805.0,
            priceChangePercentage24h: 2.1,
            lastUpdated: "2026-01-01T10:00:00.000Z",
            sparklineIn7d: nil
        ),
        isLoadingSparkline: true
    )
    .padding()
}

