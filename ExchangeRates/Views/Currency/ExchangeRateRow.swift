//
//  ExchangeRateRow.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 26/12/2025.
//

import SwiftUI

struct ExchangeRateRow: View {
    let exchangeRate: ExchangeRate
    @State private var showConverter = false
    @State private var isPressed = false
    
    private var homeCurrency: String {
        HomeCurrencyManager.shared.getHomeCurrency()
    }
    
    var body: some View {
        Button(action: {
            showConverter = true
        }) {
            HStack(spacing: 16) {
                // Flag
                CurrencyFlagHelper.flagImage(for: exchangeRate.key)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                
                // Currency code
                Text("\(exchangeRate.key) / \(homeCurrency)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Right side content
                VStack(alignment: .trailing, spacing: 4) {
                    // Exchange rate
                    Text(exchangeRate.formattedRate)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    // Percentage change with arrow
                    HStack(spacing: 4) {
                        Image(systemName: exchangeRate.isPositiveChange ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                            .font(.system(size: 10))
                        Text(exchangeRate.formattedChange)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(exchangeRate.isPositiveChange ? .green : .red)
                    
                    // Timestamp
                    Text(exchangeRate.relativeTimeString)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.3, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .sensoryFeedback(.impact(weight: .medium), trigger: isPressed)
        .sheet(isPresented: $showConverter) {
            NavigationStack {
                CurrencyConverterView(exchangeRate: exchangeRate)
            }
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    ExchangeRateRow(exchangeRate: ExchangeRate(
        key: "USD",
        currentExchangeRate: 3.682,
        currentChange: 0.32,
        unit: 1,
        lastUpdate: "2025-12-24T13:21:03.7337919Z"
    ))
    .padding()
}

