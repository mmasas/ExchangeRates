//
//  CryptoRow.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import SwiftUI

struct CryptoRow: View {
    let cryptocurrency: Cryptocurrency
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Crypto logo from CoinGecko
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
            
            // Name and symbol
            VStack(alignment: .leading, spacing: 2) {
                Text(cryptocurrency.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                Text(cryptocurrency.displaySymbol)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Right side content
            VStack(alignment: .trailing, spacing: 4) {
                // Price
                Text(cryptocurrency.formattedPrice)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                // Percentage change with arrow
                HStack(spacing: 4) {
                    Image(systemName: cryptocurrency.isPositiveChange ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.system(size: 10))
                    Text(cryptocurrency.formattedChange)
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(cryptocurrency.isPositiveChange ? .green : .red)
            }
        }
        .padding(.horizontal, 16)
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
    }
}

#Preview {
    CryptoRow(cryptocurrency: Cryptocurrency(
        id: "bitcoin",
        symbol: "btc",
        name: "Bitcoin",
        image: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png",
        currentPrice: 87805.0,
        priceChangePercentage24h: 2.1,
        lastUpdated: "2026-01-01T10:00:00.000Z"
    ))
    .padding()
}

