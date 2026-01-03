//
//  LargeChartView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 02/01/2026.
//

import SwiftUI

struct LargeChartView: View {
    let prices: [Double]?
    let isPositive: Bool
    
    @State private var animationProgress: CGFloat = 0
    
    private var chartColor: Color {
        isPositive ? .green : .red
    }
    
    private var dateLabels: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        
        var labels: [String] = []
        let calendar = Calendar.current
        let today = Date()
        
        // Generate 7 day labels (from 6 days ago to today)
        for i in stride(from: 6, through: 0, by: -1) {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                labels.append(formatter.string(from: date))
            }
        }
        
        return labels
    }
    
    var body: some View {
        if let prices = prices, prices.count >= 2 {
            let minPrice = prices.min() ?? 0
            let maxPrice = prices.max() ?? 0
            
            VStack(spacing: 8) {
                // Chart with overlaid Y-axis labels
                GeometryReader { geometry in
                    ZStack {
                        // Gradient fill under the line
                        LargeChartPath(prices: prices)
                            .fill(
                                LinearGradient(
                                    colors: [chartColor.opacity(0.3), chartColor.opacity(0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .opacity(animationProgress)
                        
                        // Main line
                        LargeChartLinePath(prices: prices)
                            .trim(from: 0, to: animationProgress)
                            .stroke(
                                chartColor,
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                            )
                        
                        // Y-axis labels overlaid on chart (top-right and bottom-right)
                        VStack {
                            HStack {
                                Spacer()
                                Text(formatPrice(maxPrice))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemBackground).opacity(0.8))
                                    .cornerRadius(4)
                            }
                            
                            Spacer()
                            
                            HStack {
                                Spacer()
                                Text(formatPrice(minPrice))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemBackground).opacity(0.8))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(6)
                    }
                }
                
                // X-axis date labels below the chart
                HStack {
                    ForEach(Array(dateLabels.enumerated()), id: \.offset) { index, label in
                        if index == 0 || index == 3 || index == 6 {
                            Text(label)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            if index < 6 {
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .environment(\.layoutDirection, .leftToRight)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animationProgress = 1
                }
            }
        } else {
            // No data placeholder
            VStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary.opacity(0.5))
                
                Text(String(localized: "no_chart_data"))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func formatPrice(_ price: Double) -> String {
        if price >= 1000 {
            return String(format: "$%.0f", price)
        } else if price >= 1 {
            return String(format: "$%.2f", price)
        } else {
            return String(format: "$%.4f", price)
        }
    }
}

// MARK: - Chart Line Path (just the line)

private struct LargeChartLinePath: Shape {
    let prices: [Double]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard prices.count >= 2 else { return path }
        
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 0
        let priceRange = maxPrice - minPrice
        
        let padding: CGFloat = 4
        let drawableWidth = rect.width - (padding * 2)
        let drawableHeight = rect.height - (padding * 2)
        
        let stepX = drawableWidth / CGFloat(prices.count - 1)
        
        for (index, price) in prices.enumerated() {
            let x = padding + CGFloat(index) * stepX
            let normalizedY: CGFloat
            
            if priceRange == 0 {
                normalizedY = 0.5
            } else {
                normalizedY = CGFloat((price - minPrice) / priceRange)
            }
            
            let y = padding + drawableHeight * (1 - normalizedY)
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
}

// MARK: - Chart Fill Path (closed shape for gradient)

private struct LargeChartPath: Shape {
    let prices: [Double]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard prices.count >= 2 else { return path }
        
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 0
        let priceRange = maxPrice - minPrice
        
        let padding: CGFloat = 4
        let drawableWidth = rect.width - (padding * 2)
        let drawableHeight = rect.height - (padding * 2)
        
        let stepX = drawableWidth / CGFloat(prices.count - 1)
        let bottomY = rect.height
        
        // Start at bottom left
        path.move(to: CGPoint(x: padding, y: bottomY))
        
        // Draw line through all price points
        for (index, price) in prices.enumerated() {
            let x = padding + CGFloat(index) * stepX
            let normalizedY: CGFloat
            
            if priceRange == 0 {
                normalizedY = 0.5
            } else {
                normalizedY = CGFloat((price - minPrice) / priceRange)
            }
            
            let y = padding + drawableHeight * (1 - normalizedY)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Close the path by going to bottom right, then back to start
        let lastX = padding + CGFloat(prices.count - 1) * stepX
        path.addLine(to: CGPoint(x: lastX, y: bottomY))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Previews

#Preview("Large Chart - Uptrend") {
    LargeChartView(
        prices: [85000, 85500, 86000, 85800, 86200, 86500, 86300,
                 86800, 87000, 86700, 87200, 87500, 87300, 87800,
                 88000, 87600, 87900, 88200, 87800, 88100, 87805],
        isPositive: true
    )
    .frame(height: 220)
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Large Chart - Downtrend") {
    LargeChartView(
        prices: [88000, 87500, 87800, 87000, 86500, 86800, 86000,
                 85500, 85800, 85200, 84800, 85000, 84500, 84200,
                 84500, 84000, 84300, 83800, 84000, 83500, 83200],
        isPositive: false
    )
    .frame(height: 220)
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Large Chart - No Data") {
    LargeChartView(prices: nil, isPositive: true)
        .frame(height: 220)
        .padding()
        .background(Color(.systemBackground))
}

