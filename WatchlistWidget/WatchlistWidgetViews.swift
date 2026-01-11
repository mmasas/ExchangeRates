//
//  WatchlistWidgetViews.swift
//  WatchlistWidget
//
//  Views for the Watchlist widget (Medium and Large sizes)
//

import SwiftUI
import WidgetKit

// MARK: - Array Extension

extension Array {
    /// Split array into chunks of specified size
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Main Entry View

struct WatchlistWidgetEntryView: View {
    var entry: WatchlistEntry
    
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemMedium:
            MediumWidgetView(entry: entry, layout: entry.layout)
        case .systemLarge:
            LargeWidgetView(entry: entry, layout: entry.layout)
        default:
            MediumWidgetView(entry: entry, layout: entry.layout)
        }
    }
}

// MARK: - Medium Widget View (2x2)

struct MediumWidgetView: View {
    let entry: WatchlistEntry
    let layout: WatchlistLayout
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            WidgetHeaderView(widgetType: entry.widgetType)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            // Content
            if entry.items.isEmpty {
                EmptyStateView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                if layout == .twoColumns {
                    // 2-column layout using VStack of HStacks
                    let items = Array(entry.items.prefix(4)) // Show up to 4 items in 2x2 grid
                    let rows = items.chunked(into: 2) // Split into pairs for rows
                    VStack(spacing: 4) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, rowItems in
                            HStack(spacing: 8) {
                                ForEach(rowItems) { item in
                                    WatchlistRowView(item: item, isCompact: true)
                                }
                                
                                // Fill remaining space if odd number of items in last row
                                if rowItems.count == 1 {
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 12)
                } else {
                    // Single column layout
                    VStack(spacing: 4) {
                        ForEach(entry.items.prefix(3)) { item in
                            WatchlistRowView(item: item, isCompact: true)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Large Widget View (2x4)

struct LargeWidgetView: View {
    let entry: WatchlistEntry
    let layout: WatchlistLayout
    
    /// Use compact mode when showing more than 6 items (only for single column)
    private var isCompactMode: Bool {
        layout == .singleColumn && entry.items.count > 6
    }
    
    /// Maximum items to display
    private var maxDisplayItems: Int {
        layout == .twoColumns ? 10 : 10 // Can show more items in 2-column layout
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            WidgetHeaderView(widgetType: entry.widgetType)
                .padding(.horizontal, 16)
                .padding(.top, isCompactMode ? 8 : 12)
                .padding(.bottom, isCompactMode ? 4 : 8)
            
            // Divider
            Divider()
                .padding(.horizontal, 12)
            
            // Content
            if entry.items.isEmpty {
                EmptyStateView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                if layout == .twoColumns {
                    // 2-column layout using VStack of HStacks for better row control
                    let items = Array(entry.items.prefix(maxDisplayItems))
                    let rows = items.chunked(into: 2) // Split into pairs for rows
                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, rowItems in
                            HStack(spacing: 8) {
                                ForEach(rowItems) { item in
                                    WatchlistRowView(item: item, isCompact: true)
                                }
                                
                                // Fill remaining space if odd number of items in last row
                                if rowItems.count == 1 {
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 8)
                            
                            // Add divider between rows (not after last row)
                            if rowIndex < rows.count - 1 {
                                Divider()
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    // Single column layout
                    VStack(spacing: isCompactMode ? 0 : 2) {
                        ForEach(Array(entry.items.prefix(maxDisplayItems).enumerated()), id: \.element.id) { index, item in
                            WatchlistRowView(item: item, isCompact: isCompactMode)
                            
                            if index < min(entry.items.count, maxDisplayItems) - 1 {
                                Divider()
                                    .padding(.horizontal, 8)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, isCompactMode ? 4 : 8)
                }
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Widget Header

struct WidgetHeaderView: View {
    let widgetType: WatchlistWidgetType
    
    var body: some View {
        HStack {
            Image(systemName: "star.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.yellow)
            
            Text("widget_title", bundle: .main)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Type badge
            Text(widgetType.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(4)
        }
    }
}

// MARK: - Watchlist Row

struct WatchlistRowView: View {
    let item: WatchlistItem
    let isCompact: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            // Icon
            ItemIconView(item: item, size: isCompact ? 24 : 28)
            
            // Name and symbol
            VStack(alignment: .leading, spacing: 1) {
                Text(item.displaySymbol)
                    .font(.system(size: isCompact ? 13 : 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if !isCompact {
                    Text(item.name)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(minWidth: 40, alignment: .leading)
            
            // Sparkline (only for crypto items)
            if item.type == .crypto {
                WidgetSparklineView(prices: item.sparklineData, isPositive: item.isPositiveChange)
                    .frame(width: isCompact ? 40 : 50, height: isCompact ? 16 : 20)
            }
            
            Spacer(minLength: 4)
            
            // Price and change
            VStack(alignment: .trailing, spacing: 1) {
                Text(item.formattedValue)
                    .font(.system(size: isCompact ? 12 : 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 2) {
                    Image(systemName: item.isPositiveChange ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.system(size: 6))
                    Text(item.formattedChange)
                        .font(.system(size: isCompact ? 9 : 10, weight: .medium))
                }
                .foregroundColor(item.isPositiveChange ? .green : .red)
            }
        }
        .padding(.vertical, isCompact ? 6 : 8)
    }
}

// MARK: - Item Icon

struct ItemIconView: View {
    let item: WatchlistItem
    let size: CGFloat
    
    var body: some View {
        Group {
            if item.type == .currency {
                // Currency flag
                CurrencyFlagView(currencyCode: item.symbol, size: size)
            } else {
                // Crypto icon - use colored placeholder (AsyncImage doesn't work well in widgets)
                CryptoIconView(symbol: item.symbol, id: item.id, size: size)
            }
        }
    }
}

// MARK: - Crypto Icon View

struct CryptoIconView: View {
    let symbol: String
    let id: String
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(cryptoColor.gradient)
            
            Text(String(symbol.prefix(1)).uppercased())
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
    
    /// Get a consistent color for each crypto based on its ID
    private var cryptoColor: Color {
        let cryptoColors: [String: Color] = [
            "bitcoin": .orange,
            "ethereum": Color(red: 0.4, green: 0.4, blue: 0.9),
            "tether": Color(red: 0.2, green: 0.7, blue: 0.5),
            "binancecoin": .yellow,
            "ripple": Color(red: 0.0, green: 0.5, blue: 0.8),
            "cardano": Color(red: 0.0, green: 0.4, blue: 0.8),
            "solana": Color(red: 0.6, green: 0.3, blue: 0.9),
            "dogecoin": Color(red: 0.8, green: 0.6, blue: 0.2),
            "polkadot": Color(red: 0.9, green: 0.2, blue: 0.5),
            "litecoin": Color(red: 0.5, green: 0.5, blue: 0.5)
        ]
        
        if let color = cryptoColors[id.lowercased()] {
            return color
        }
        
        // Generate consistent color from ID hash
        let hash = abs(id.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }
}

// MARK: - Currency Flag View

struct CurrencyFlagView: View {
    let currencyCode: String
    let size: CGFloat
    
    var body: some View {
        // Map currency code to flag emoji
        let flag = flagEmoji(for: currencyCode)
        
        ZStack {
            Circle()
                .fill(Color.secondary.opacity(0.1))
            
            Text(flag)
                .font(.system(size: size * 0.6))
        }
        .frame(width: size, height: size)
    }
    
    private func flagEmoji(for code: String) -> String {
        // Map currency codes to country codes for flag emojis
        let currencyToCountry: [String: String] = [
            "USD": "US", "EUR": "EU", "GBP": "GB", "JPY": "JP",
            "CHF": "CH", "CAD": "CA", "AUD": "AU", "NZD": "NZ",
            "CNY": "CN", "HKD": "HK", "SGD": "SG", "SEK": "SE",
            "NOK": "NO", "DKK": "DK", "INR": "IN", "RUB": "RU",
            "BRL": "BR", "MXN": "MX", "ZAR": "ZA", "TRY": "TR",
            "PLN": "PL", "ILS": "IL", "KRW": "KR", "THB": "TH"
        ]
        
        guard let countryCode = currencyToCountry[code.uppercased()] else {
            return "💱"
        }
        
        // Convert country code to flag emoji
        let base: UInt32 = 127397
        var emoji = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            if let flagScalar = UnicodeScalar(base + scalar.value) {
                emoji.append(Character(flagScalar))
            }
        }
        
        return emoji.isEmpty ? "💱" : emoji
    }
}

// MARK: - Crypto Placeholder Icon

struct CryptoPlaceholderIcon: View {
    let symbol: String
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.2))
            
            Text(String(symbol.prefix(1)).uppercased())
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(.orange)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.slash")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            
            Text("widget_no_favorites", bundle: .main)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("widget_add_favorites", bundle: .main)
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.7))
        }
    }
}

// MARK: - Previews

#Preview("Medium - Mixed", as: .systemMedium) {
    WatchlistWidget()
} timeline: {
    WatchlistEntry.placeholder(widgetType: .mixed)
}

#Preview("Large - Mixed", as: .systemLarge) {
    WatchlistWidget()
} timeline: {
    WatchlistEntry.placeholder(widgetType: .mixed)
}

#Preview("Medium - Empty", as: .systemMedium) {
    WatchlistWidget()
} timeline: {
    WatchlistEntry.empty(widgetType: .mixed)
}

#Preview("Large - Crypto Only", as: .systemLarge) {
    WatchlistWidget()
} timeline: {
    WatchlistEntry.placeholder(widgetType: .crypto)
}
