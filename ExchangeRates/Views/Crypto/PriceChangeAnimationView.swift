//
//  PriceChangeAnimationView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import SwiftUI

struct PriceChangeAnimationView: View {
    let price: Double
    let previousPrice: Double?
    
    @State private var flashColor: Color = .clear
    @State private var scale: CGFloat = 1.0
    
    private func formatPrice(_ price: Double) -> String {
        if price >= 1.0 {
            return String(format: "$%.2f", price)
        } else {
            return String(format: "$%.4f", price)
        }
    }
    
    var body: some View {
        Text(formatPrice(price))
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.primary)
            .background(
                Rectangle()
                    .fill(flashColor)
                    .opacity(0.2)
            )
            .scaleEffect(scale)
            .onChange(of: price) { oldValue, newValue in
                // Compare oldValue with newValue directly, or use previousPrice if available
                let previous = previousPrice ?? oldValue
                if abs(newValue - previous) > 0.01 {
                    triggerAnimation(with: newValue, previous: previous)
                }
            }
    }
    
    private func triggerAnimation(with newPrice: Double, previous: Double) {
        let isIncrease = newPrice > previous
        flashColor = isIncrease ? .green : .red
        
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 1.05
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeIn(duration: 0.3)) {
                scale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                flashColor = .clear
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PriceChangeAnimationView(price: 50000.0, previousPrice: 49000.0)
        PriceChangeAnimationView(price: 0.05, previousPrice: 0.06)
    }
    .padding()
}


