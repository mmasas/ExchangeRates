//
//  WidgetSparklineView.swift
//  WatchlistWidget
//
//  Lightweight sparkline chart for widget display
//

import SwiftUI
import WidgetKit

/// A lightweight sparkline view optimized for widget display
struct WidgetSparklineView: View {
    let prices: [Double]?
    let isPositive: Bool
    
    /// View dimensions
    private let lineWidth: CGFloat = 1.2
    
    init(prices: [Double]?, isPositive: Bool = true) {
        self.prices = prices
        self.isPositive = isPositive
    }
    
    var body: some View {
        GeometryReader { geometry in
            if let prices = prices, prices.count >= 2 {
                SparklinePath(prices: prices, lineWidth: lineWidth)
                    .stroke(
                        trendColor,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                    )
            } else {
                // Placeholder line when no data
                Path { path in
                    let y = geometry.size.height / 2
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)
            }
        }
    }
    
    private var trendColor: Color {
        guard let prices = prices, prices.count >= 2,
              let first = prices.first, let last = prices.last else {
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

// MARK: - Preview

#Preview("Sparkline - Uptrend") {
    WidgetSparklineView(prices: [100, 102, 98, 105, 110, 108, 115], isPositive: true)
        .frame(width: 50, height: 20)
        .padding()
}

#Preview("Sparkline - Downtrend") {
    WidgetSparklineView(prices: [115, 110, 112, 105, 100, 102, 95], isPositive: false)
        .frame(width: 50, height: 20)
        .padding()
}

#Preview("Sparkline - No Data") {
    WidgetSparklineView(prices: nil, isPositive: true)
        .frame(width: 50, height: 20)
        .padding()
}
