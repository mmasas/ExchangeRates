//
//  WatchlistWidgetIntent.swift
//  WatchlistWidget
//
//  App Intent for widget configuration
//

import AppIntents
import WidgetKit

/// App Intent for configuring the Watchlist widget
struct WatchlistWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("widget_config_title", defaultValue: "Watchlist Configuration")
    static var description = IntentDescription(LocalizedStringResource("widget_config_description", defaultValue: "Configure which items to display in the watchlist widget."))
    
    @Parameter(title: LocalizedStringResource("widget_display_type", defaultValue: "Display Type"), default: .mixed)
    var displayType: WatchlistDisplayType
    
    @Parameter(title: LocalizedStringResource("widget_items_count", defaultValue: "Number of Items"), default: .auto)
    var itemsCount: WatchlistItemsCount
    
    /// Get the widget type from the display type parameter
    var widgetType: WatchlistWidgetType {
        switch displayType {
        case .crypto:
            return .crypto
        case .currency:
            return .currency
        case .mixed:
            return .mixed
        }
    }
    
    /// Get the max items count
    var maxItems: Int? {
        switch itemsCount {
        case .auto:
            return nil // Use default based on widget size
        case .two:
            return 2
        case .three:
            return 3
        case .four:
            return 4
        case .five:
            return 5
        case .six:
            return 6
        case .seven:
            return 7
        case .eight:
            return 8
        case .nine:
            return 9
        case .ten:
            return 10
        }
    }
}

/// Display type options for the widget
enum WatchlistDisplayType: String, AppEnum {
    case crypto = "crypto"
    case currency = "currency"
    case mixed = "mixed"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: LocalizedStringResource("widget_display_type", defaultValue: "Display Type"))
    }
    
    static var caseDisplayRepresentations: [WatchlistDisplayType: DisplayRepresentation] {
        [
            .crypto: DisplayRepresentation(
                title: LocalizedStringResource("widget_type_crypto", defaultValue: "Crypto Only"),
                subtitle: LocalizedStringResource("widget_type_crypto_subtitle", defaultValue: "Show only cryptocurrencies")
            ),
            .currency: DisplayRepresentation(
                title: LocalizedStringResource("widget_type_currency", defaultValue: "Currency Only"),
                subtitle: LocalizedStringResource("widget_type_currency_subtitle", defaultValue: "Show only currencies")
            ),
            .mixed: DisplayRepresentation(
                title: LocalizedStringResource("widget_type_mixed", defaultValue: "Mixed"),
                subtitle: LocalizedStringResource("widget_type_mixed_subtitle", defaultValue: "Show both crypto and currencies")
            )
        ]
    }
}

/// Number of items to display in the widget
enum WatchlistItemsCount: String, AppEnum {
    case auto = "auto"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case six = "6"
    case seven = "7"
    case eight = "8"
    case nine = "9"
    case ten = "10"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: LocalizedStringResource("widget_items_count", defaultValue: "Number of Items"))
    }
    
    static var caseDisplayRepresentations: [WatchlistItemsCount: DisplayRepresentation] {
        [
            .auto: DisplayRepresentation(
                title: LocalizedStringResource("widget_count_auto", defaultValue: "Auto")
            ),
            .two: DisplayRepresentation(title: "2"),
            .three: DisplayRepresentation(title: "3"),
            .four: DisplayRepresentation(title: "4"),
            .five: DisplayRepresentation(title: "5"),
            .six: DisplayRepresentation(title: "6"),
            .seven: DisplayRepresentation(title: "7"),
            .eight: DisplayRepresentation(title: "8"),
            .nine: DisplayRepresentation(title: "9"),
            .ten: DisplayRepresentation(title: "10")
        ]
    }
}
