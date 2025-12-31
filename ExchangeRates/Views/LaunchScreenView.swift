//
//  LaunchScreenView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 26/12/2025.
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var titleOpacity: Double = 0
    @State private var titleScale: CGFloat = 0.8
    @State private var rotationAngle: Double = 0
    @State private var symbolOpacities: [Double] = [0, 0, 0, 0, 0]
    @State private var symbolScales: [CGFloat] = [0.3, 0.3, 0.3, 0.3, 0.3]
    
    let currencySymbols = ["₪", "$", "€", "£", "¥"]
    let symbolCount = 5
    
    var body: some View {
        ZStack {
            // Background - system adaptive
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // Currency symbols orbiting around center
            ForEach(0..<symbolCount, id: \.self) { index in
                let radius: CGFloat = index == 0 ? 160 : 130 // Shekel symbol needs more distance
                let angleOffset: Double = index == 0 ? -0.3 : 0 // Shekel symbol shifted upward
                let baseAngle = Double(index) * 2 * .pi / Double(symbolCount)
                let angle = rotationAngle + baseAngle + angleOffset
                let xOffset = cos(angle) * radius
                let yOffset = sin(angle) * radius
                Text(currencySymbols[index])
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.primary)
                    .opacity(symbolOpacities[index])
                    .scaleEffect(symbolScales[index])
                    .offset(x: xOffset, y: yOffset)
            }
            
            // App title - on top layer
            VStack(spacing: 16) {
                Text(String(localized: "exchange_rates_title"))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                    .opacity(titleOpacity)
                    .scaleEffect(titleScale)
            }
            .zIndex(1)
        }
        .onAppear {
            // Animate title
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                titleOpacity = 1
                titleScale = 1.0
            }
            
            // Animate currency symbols with staggered delays
            for index in 0..<symbolCount {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3 + Double(index) * 0.1)) {
                    symbolOpacities[index] = 0.7
                    symbolScales[index] = 1.0
                }
            }
            
            // Continuous orbiting animation
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotationAngle = 2 * .pi
            }
        }
    }
}

#Preview {
    LaunchScreenView()
        .preferredColorScheme(.light)
}

#Preview {
    LaunchScreenView()
        .preferredColorScheme(.dark)
}

