//
//  SparklineView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 02/01/2026.
//

import SwiftUI

struct SparklineView: View {
    let prices: [Double]?
    let isLoading: Bool
    
    /// View dimensions
    private let width: CGFloat = 120
    private let height: CGFloat = 40
    private let lineWidth: CGFloat = 1.5
    
    /// Animation state
    @State private var animationProgress: CGFloat = 0
    
    init(prices: [Double]? = nil, isLoading: Bool = false) {
        self.prices = prices
        self.isLoading = isLoading
    }
    
    var body: some View {
        ZStack {
            if isLoading {
                // Skeleton placeholder
                SparklineSkeleton()
            } else if let prices = prices, prices.count >= 2 {
                // Actual sparkline
                SparklinePath(prices: prices, lineWidth: lineWidth)
                    .trim(from: 0, to: animationProgress)
                    .stroke(trendColor(for: prices), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.4)) {
                            animationProgress = 1
                        }
                    }
            } else {
                // Not enough data - show placeholder line
                PlaceholderLine()
            }
        }
        .frame(width: width, height: height)
    }
    
    /// Determine color based on price trend
    private func trendColor(for prices: [Double]) -> Color {
        guard let first = prices.first, let last = prices.last else {
            return .gray
        }
        
        if last > first {
            return .green
        } else if last < first {
            return .red
        } else {
            return .gray
        }
    }
}

// MARK: - Sparkline Path Shape

private struct SparklinePath: Shape {
    let prices: [Double]
    let lineWidth: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard prices.count >= 2 else { return path }
        
        // Calculate min/max for normalization
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 0
        
        // Avoid division by zero if all prices are the same
        let priceRange = maxPrice - minPrice
        let normalizedPrices: [CGFloat]
        
        if priceRange == 0 {
            // All same values - draw horizontal line at center
            normalizedPrices = prices.map { _ in CGFloat(0.5) }
        } else {
            normalizedPrices = prices.map { CGFloat(($0 - minPrice) / priceRange) }
        }
        
        // Add padding for line stroke
        let paddingY = lineWidth
        let drawableHeight = rect.height - (paddingY * 2)
        let stepX = rect.width / CGFloat(prices.count - 1)
        
        // Create path points
        for (index, normalizedPrice) in normalizedPrices.enumerated() {
            let x = CGFloat(index) * stepX
            // Invert Y because SwiftUI coordinates start from top
            let y = paddingY + drawableHeight * (1 - normalizedPrice)
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
}

// MARK: - Placeholder Line (when no data)

private struct PlaceholderLine: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let y = geometry.size.height / 2
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: geometry.size.width, y: y))
            }
            .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }
    }
}

// MARK: - Skeleton View

private struct SparklineSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            // Wavy skeleton shape
            Path { path in
                let midY = geometry.size.height / 2
                let amplitude: CGFloat = 8
                let width = geometry.size.width
                
                path.move(to: CGPoint(x: 0, y: midY))
                
                // Create a gentle wave pattern
                for x in stride(from: 0, through: width, by: 2) {
                    let progress = x / width
                    let y = midY + sin(progress * .pi * 2) * amplitude
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            .opacity(isAnimating ? 0.3 : 0.6)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Sparkline - Uptrend") {
    SparklineView(prices: [100, 102, 98, 105, 110, 108, 115])
        .padding()
        .background(Color(.systemBackground))
}

#Preview("Sparkline - Downtrend") {
    SparklineView(prices: [115, 110, 112, 105, 100, 102, 95])
        .padding()
        .background(Color(.systemBackground))
}

#Preview("Sparkline - Flat") {
    SparklineView(prices: [100, 100, 100, 100, 100])
        .padding()
        .background(Color(.systemBackground))
}

#Preview("Sparkline - Loading") {
    SparklineView(isLoading: true)
        .padding()
        .background(Color(.systemBackground))
}

#Preview("Sparkline - No Data") {
    SparklineView()
        .padding()
        .background(Color(.systemBackground))
}


