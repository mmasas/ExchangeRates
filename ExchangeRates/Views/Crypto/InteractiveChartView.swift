//
//  InteractiveChartView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 04/01/2026.
//

import SwiftUI

struct InteractiveChartView: View {
    let chartData: [ChartDataPoint]
    let timeRange: ChartTimeRange
    let isPositive: Bool
    let isLoading: Bool
    let isOffline: Bool
    let errorMessage: String?
    
    @State private var animationProgress: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    @State private var selectedPoint: ChartDataPoint?
    @State private var tapLocation: CGPoint = .zero
    
    private var chartColor: Color {
        isPositive ? .green : .red
    }
    
    private var visibleData: [ChartDataPoint] {
        chartData
    }
    
    private var xAxisLabels: [String] {
        guard !chartData.isEmpty else { return [] }
        
        let labelCount = 3 // Show 3 labels (start, middle, end)
        var labels: [String] = []
        
        for i in 0..<labelCount {
            let index = (chartData.count - 1) * i / (labelCount - 1)
            if index < chartData.count {
                labels.append(chartData[index].formattedDate(for: timeRange))
            }
        }
        
        return labels
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if isLoading {
                // Loading state
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text(String(localized: "loading_chart", defaultValue: "Loading chart..."))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
            } else if isOffline {
                // Offline state
                VStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                    Text(String(localized: "chart_offline_unavailable", defaultValue: "Chart is not available offline"))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
            } else if let errorMessage = errorMessage {
                // Error state
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
            } else if chartData.isEmpty {
                // No data state
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text(String(localized: "no_chart_data", defaultValue: "No chart data available"))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
            } else {
                // Chart with data
                GeometryReader { geometry in
                    ZStack {
                        // Gradient fill under the line
                        InteractiveChartPath(dataPoints: visibleData)
                            .fill(
                                LinearGradient(
                                    colors: [chartColor.opacity(0.3), chartColor.opacity(0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .opacity(animationProgress)
                        
                        // Main line
                        InteractiveChartLinePath(dataPoints: visibleData)
                            .trim(from: 0, to: animationProgress)
                            .stroke(
                                chartColor,
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                            )
                        
                        // Y-axis labels (min and max price)
                        if let minPrice = visibleData.map({ $0.price }).min(),
                           let maxPrice = visibleData.map({ $0.price }).max() {
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
                        
                        // Tooltip overlay
                        if let selectedPoint = selectedPoint {
                            VStack(spacing: 4) {
                                Text(selectedPoint.formattedPrice)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(selectedPoint.formattedDate(for: timeRange))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.primary.opacity(0.2), radius: 4, x: 0, y: 2)
                            )
                            .position(tooltipPosition(in: geometry.size))
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                handleTap(at: value.location, in: geometry.size)
                            }
                            .onEnded { _ in
                                // Keep tooltip visible after drag ends
                            }
                    )
                    .onTapGesture { location in
                        // Dismiss tooltip if tapping outside
                        if selectedPoint != nil {
                            withAnimation(.easeOut(duration: 0.15)) {
                                selectedPoint = nil
                            }
                        }
                    }
                }
                .frame(height: 220)
                
                // X-axis date labels
                HStack {
                    ForEach(Array(xAxisLabels.enumerated()), id: \.offset) { index, label in
                        Text(label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        if index < xAxisLabels.count - 1 {
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animationProgress = 1
            }
        }
        .onChange(of: chartData) { _, _ in
            // Reset animation when data changes
            animationProgress = 0
            selectedPoint = nil
            withAnimation(.easeOut(duration: 0.8)) {
                animationProgress = 1
            }
        }
    }
    
    private func handleTap(at location: CGPoint, in size: CGSize) {
        guard !visibleData.isEmpty else { return }
        
        let padding: CGFloat = 4
        let drawableWidth = size.width - (padding * 2)
        let stepX = drawableWidth / CGFloat(visibleData.count - 1)
        
        // Find closest data point
        let relativeX = location.x - padding
        let index = Int(round(relativeX / stepX))
        let clampedIndex = max(0, min(visibleData.count - 1, index))
        
        withAnimation(.easeOut(duration: 0.15)) {
            selectedPoint = visibleData[clampedIndex]
            tapLocation = location
        }
    }
    
    private func tooltipPosition(in size: CGSize) -> CGPoint {
        guard let selectedPoint = selectedPoint else { return .zero }
        guard let index = visibleData.firstIndex(where: { $0.id == selectedPoint.id }) else {
            return .zero
        }
        
        let padding: CGFloat = 4
        let drawableWidth = size.width - (padding * 2)
        let stepX = drawableWidth / CGFloat(visibleData.count - 1)
        
        let x = padding + CGFloat(index) * stepX
        
        // Position tooltip above the chart line
        let y = size.height * 0.2
        
        return CGPoint(x: x, y: y)
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

private struct InteractiveChartLinePath: Shape {
    let dataPoints: [ChartDataPoint]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard dataPoints.count >= 2 else { return path }
        
        let prices = dataPoints.map { $0.price }
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 0
        let priceRange = maxPrice - minPrice
        
        let padding: CGFloat = 4
        let drawableWidth = rect.width - (padding * 2)
        let drawableHeight = rect.height - (padding * 2)
        
        let stepX = drawableWidth / CGFloat(dataPoints.count - 1)
        
        for (index, dataPoint) in dataPoints.enumerated() {
            let x = padding + CGFloat(index) * stepX
            let normalizedY: CGFloat
            
            if priceRange == 0 {
                normalizedY = 0.5
            } else {
                normalizedY = CGFloat((dataPoint.price - minPrice) / priceRange)
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

private struct InteractiveChartPath: Shape {
    let dataPoints: [ChartDataPoint]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard dataPoints.count >= 2 else { return path }
        
        let prices = dataPoints.map { $0.price }
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 0
        let priceRange = maxPrice - minPrice
        
        let padding: CGFloat = 4
        let drawableWidth = rect.width - (padding * 2)
        let drawableHeight = rect.height - (padding * 2)
        
        let stepX = drawableWidth / CGFloat(dataPoints.count - 1)
        let bottomY = rect.height
        
        // Start at bottom left
        path.move(to: CGPoint(x: padding, y: bottomY))
        
        // Draw line through all price points
        for (index, dataPoint) in dataPoints.enumerated() {
            let x = padding + CGFloat(index) * stepX
            let normalizedY: CGFloat
            
            if priceRange == 0 {
                normalizedY = 0.5
            } else {
                normalizedY = CGFloat((dataPoint.price - minPrice) / priceRange)
            }
            
            let y = padding + drawableHeight * (1 - normalizedY)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Close the path by going to bottom right, then back to start
        let lastX = padding + CGFloat(dataPoints.count - 1) * stepX
        path.addLine(to: CGPoint(x: lastX, y: bottomY))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Previews

#Preview("Interactive Chart - With Data") {
    let sampleData = (0..<50).map { i in
        ChartDataPoint(
            timestamp: Date().addingTimeInterval(TimeInterval(-86400 * (50 - i))),
            price: 85000 + Double.random(in: -3000...3000)
        )
    }
    
    return InteractiveChartView(
        chartData: sampleData,
        timeRange: .sevenDays,
        isPositive: true,
        isLoading: false,
        isOffline: false,
        errorMessage: nil
    )
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Interactive Chart - Loading") {
    InteractiveChartView(
        chartData: [],
        timeRange: .sevenDays,
        isPositive: true,
        isLoading: true,
        isOffline: false,
        errorMessage: nil
    )
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Interactive Chart - Offline") {
    InteractiveChartView(
        chartData: [],
        timeRange: .sevenDays,
        isPositive: true,
        isLoading: false,
        isOffline: true,
        errorMessage: nil
    )
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Interactive Chart - Error") {
    InteractiveChartView(
        chartData: [],
        timeRange: .sevenDays,
        isPositive: true,
        isLoading: false,
        isOffline: false,
        errorMessage: "Failed to load chart data"
    )
    .padding()
    .background(Color(.systemBackground))
}




