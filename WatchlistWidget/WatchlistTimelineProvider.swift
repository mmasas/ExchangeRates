//
//  WatchlistTimelineProvider.swift
//  WatchlistWidget
//
//  Timeline provider for the Watchlist widget
//

import WidgetKit
import SwiftUI

struct WatchlistTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = WatchlistEntry
    typealias Intent = WatchlistWidgetIntent
    
    private let dataProvider = WidgetDataProvider.shared
    
    // MARK: - Placeholder
    
    func placeholder(in context: Context) -> WatchlistEntry {
        WatchlistEntry.placeholder(widgetType: .mixed)
    }
    
    // MARK: - Snapshot
    
    func snapshot(for configuration: WatchlistWidgetIntent, in context: Context) async -> WatchlistEntry {
        // For preview/gallery, return placeholder
        if context.isPreview {
            return WatchlistEntry.placeholder(widgetType: configuration.widgetType)
        }
        
        // Return actual data for widget
        return await getEntry(for: configuration, context: context)
    }
    
    // MARK: - Timeline
    
    func timeline(for configuration: WatchlistWidgetIntent, in context: Context) async -> Timeline<WatchlistEntry> {
        let entry = await getEntry(for: configuration, context: context)
        
        // Refresh every 15 minutes
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }
    
    // MARK: - Helper Methods
    
    private func getEntry(for configuration: WatchlistWidgetIntent, context: Context) async -> WatchlistEntry {
        let widgetType = configuration.widgetType
        let maxItems = configuration.maxItems ?? maxItemsForFamily(context.family)
        
        // Clamp to valid range based on widget size
        let clampedMaxItems = min(maxItems, maxItemsForFamily(context.family))
        
        // Load items from App Group
        let items = dataProvider.getItemsForWidget(type: widgetType, maxItems: clampedMaxItems)
        
        // If no items, return empty entry
        if items.isEmpty {
            return WatchlistEntry.empty(widgetType: widgetType)
        }
        
        return WatchlistEntry(
            date: Date(),
            items: items,
            widgetType: widgetType
        )
    }
    
    private func maxItemsForFamily(_ family: WidgetFamily) -> Int {
        switch family {
        case .systemMedium:
            return 4
        case .systemLarge:
            return 10
        default:
            return 4
        }
    }
}
