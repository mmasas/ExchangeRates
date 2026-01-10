//
//  WatchlistWidget.swift
//  WatchlistWidget
//
//  Widget extension for displaying favorite currencies and cryptocurrencies
//

import WidgetKit
import SwiftUI

@main
struct WatchlistWidget: Widget {
    let kind: String = "WatchlistWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: WatchlistWidgetIntent.self,
            provider: WatchlistTimelineProvider()
        ) { entry in
            WatchlistWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(Text("widget_name", bundle: .main, comment: "Widget display name"))
        .description(Text("widget_description", bundle: .main, comment: "Widget description"))
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    WatchlistWidget()
} timeline: {
    WatchlistEntry.placeholder(widgetType: .mixed)
}

#Preview(as: .systemLarge) {
    WatchlistWidget()
} timeline: {
    WatchlistEntry.placeholder(widgetType: .mixed)
}
