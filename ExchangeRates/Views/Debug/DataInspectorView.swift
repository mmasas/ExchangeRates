//
//  DataInspectorView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import SwiftUI
import UIKit

struct DataInspectorView: View {
    @State private var alerts: [CurrencyAlert] = []
    @State private var homeCurrency: String = ""
    @State private var customCurrencies: [String] = []
    @State private var currencyOrder: [String] = []
    @State private var customCryptos: [String] = []
    @State private var colorScheme: String = ""
    @State private var language: String = ""
    @State private var cryptoProvider: String = ""
    @State private var websocketEnabled: Bool = false
    @State private var cachedExchangeRatesCount: Int = 0
    @State private var cachedCustomExchangeRatesCount: Int = 0
    @State private var cachedCryptocurrenciesCount: Int = 0
    @State private var lastExchangeRatesUpdate: Date? = nil
    @State private var lastCryptocurrenciesUpdate: Date? = nil
    @State private var showingEditSheet = false
    @State private var editingItem: DataItem? = nil
    @State private var showingCopyConfirmation = false
    @State private var copiedItemName = ""
    
    var body: some View {
        List {
            // Alerts Section
            Section(header: HStack {
                Text("Currency Alerts")
                Spacer()
                Text("\(alerts.count)")
                    .foregroundColor(.secondary)
                if !alerts.isEmpty {
                    Button("Copy All") {
                        copyAlertsToClipboard()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }) {
                if alerts.isEmpty {
                    Text("No alerts")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(alerts) { alert in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(alert.currencyPair)
                                    .font(.headline)
                                Spacer()
                                HStack(spacing: 12) {
                                    Button(action: {
                                        copyToClipboard(formatAlert(alert), itemName: "Alert")
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button(action: {
                                        editingItem = .alert(alert)
                                        showingEditSheet = true
                                    }) {
                                        Image(systemName: "pencil")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            HStack {
                                Label(alert.status.rawValue.capitalized, systemImage: alert.isActive ? "bell.fill" : "bell.slash.fill")
                                    .font(.caption)
                                    .foregroundColor(alert.isActive ? .green : .orange)
                                
                                Spacer()
                                
                                Text(formatAlertSummary(alert))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            // User Preferences Section
            Section(header: Text("User Preferences")) {
                DataItemRow(
                    title: "Home Currency",
                    value: homeCurrency.isEmpty ? "Not set" : homeCurrency,
                    onCopy: {
                        copyToClipboard(homeCurrency, itemName: "Home Currency")
                    },
                    onEdit: {
                        editingItem = .homeCurrency(homeCurrency)
                        showingEditSheet = true
                    }
                )
                
                DataItemRow(
                    title: "Color Scheme",
                    value: colorScheme.isEmpty ? "Not set" : colorScheme,
                    onCopy: {
                        copyToClipboard(colorScheme, itemName: "Color Scheme")
                    },
                    onEdit: {
                        editingItem = .colorScheme(colorScheme)
                        showingEditSheet = true
                    }
                )
                
                DataItemRow(
                    title: "Language",
                    value: language.isEmpty ? "Not set" : language,
                    onCopy: {
                        copyToClipboard(language, itemName: "Language")
                    },
                    onEdit: {
                        editingItem = .language(language)
                        showingEditSheet = true
                    }
                )
                
                DataItemRow(
                    title: "Crypto Provider",
                    value: cryptoProvider.isEmpty ? "Not set" : cryptoProvider,
                    onCopy: {
                        copyToClipboard(cryptoProvider, itemName: "Crypto Provider")
                    },
                    onEdit: {
                        editingItem = .cryptoProvider(cryptoProvider)
                        showingEditSheet = true
                    }
                )
                
                HStack {
                    Text("WebSocket Enabled")
                    Spacer()
                    Text(websocketEnabled ? "Yes" : "No")
                        .foregroundColor(websocketEnabled ? .green : .secondary)
                }
            }
            
            // Custom Data Section
            Section(header: HStack {
                Text("Custom Currencies")
                Spacer()
                Text("\(customCurrencies.count)")
                    .foregroundColor(.secondary)
                if !customCurrencies.isEmpty {
                    Button("Copy All") {
                        copyArrayToClipboard(customCurrencies, itemName: "Custom Currencies")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }) {
                if customCurrencies.isEmpty {
                    Text("No custom currencies")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(customCurrencies, id: \.self) { currency in
                        DataItemRow(
                            title: currency,
                            value: currency,
                            onCopy: {
                                copyToClipboard(currency, itemName: "Currency")
                            },
                            onEdit: nil
                        )
                    }
                }
            }
            
            Section(header: HStack {
                Text("Custom Cryptocurrencies")
                Spacer()
                Text("\(customCryptos.count)")
                    .foregroundColor(.secondary)
                if !customCryptos.isEmpty {
                    Button("Copy All") {
                        copyArrayToClipboard(customCryptos, itemName: "Custom Cryptos")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }) {
                if customCryptos.isEmpty {
                    Text("No custom cryptocurrencies")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(customCryptos, id: \.self) { crypto in
                        DataItemRow(
                            title: crypto,
                            value: crypto,
                            onCopy: {
                                copyToClipboard(crypto, itemName: "Crypto")
                            },
                            onEdit: nil
                        )
                    }
                }
            }
            
            // Currency Order Section
            Section(header: HStack {
                Text("Currency Order")
                Spacer()
                Text("\(currencyOrder.count)")
                    .foregroundColor(.secondary)
                if !currencyOrder.isEmpty {
                    Button("Copy All") {
                        copyArrayToClipboard(currencyOrder, itemName: "Currency Order")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }) {
                if currencyOrder.isEmpty {
                    Text("No currency order")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(currencyOrder.enumerated()), id: \.offset) { index, currency in
                        HStack {
                            Text("\(index + 1).")
                                .foregroundColor(.secondary)
                                .frame(width: 30)
                            Text(currency)
                                .font(.body)
                            Spacer()
                            Button(action: {
                                copyToClipboard(currency, itemName: "Currency Order Item")
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            
            // Cache Information Section
            Section(header: Text("Cache Information")) {
                HStack {
                    Text("Exchange Rates")
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(cachedExchangeRatesCount) items")
                            .foregroundColor(.secondary)
                        if let date = lastExchangeRatesUpdate {
                            Text(formatDate(date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                HStack {
                    Text("Custom Exchange Rates")
                    Spacer()
                    Text("\(cachedCustomExchangeRatesCount) items")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Cryptocurrencies")
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(cachedCryptocurrenciesCount) items")
                            .foregroundColor(.secondary)
                        if let date = lastCryptocurrenciesUpdate {
                            Text(formatDate(date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Stored Data")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        copyAllDataToClipboard()
                    }) {
                        Label("Copy All Data", systemImage: "doc.on.doc")
                    }
                    
                    Button(action: {
                        loadData()
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            loadData()
        }
        .sheet(isPresented: $showingEditSheet) {
            if let item = editingItem {
                DataItemEditView(item: item) { updatedItem in
                    saveItem(updatedItem)
                    loadData()
                }
                .presentationDragIndicator(.visible)
            }
        }
        .alert("Copied!", isPresented: $showingCopyConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(copiedItemName) copied to clipboard")
        }
    }
    
    private func loadData() {
        // Load alerts
        alerts = CurrencyAlertManager.shared.getAllAlerts()
        
        // Load home currency
        homeCurrency = HomeCurrencyManager.shared.getHomeCurrency()
        
        // Load custom currencies
        customCurrencies = CustomCurrencyManager.shared.getCustomCurrencies()
        
        // Load custom cryptos
        customCryptos = CustomCryptoManager.shared.getCustomCryptos()
        
        // Load currency order
        currencyOrder = CurrencyOrderManager.shared.getOrderedCurrencies()
        
        // Load color scheme
        colorScheme = ColorSchemeManager.shared.getColorScheme().rawValue
        
        // Load language
        language = LanguageManager.shared.getLanguage().rawValue
        
        // Load crypto provider
        cryptoProvider = CryptoProviderManager.shared.getProvider().displayName
        
        // Load WebSocket enabled state
        websocketEnabled = WebSocketManager.shared.isWebSocketEnabled
        
        // Load cache information
        let cachedRates = DataCacheManager.shared.loadExchangeRates()
        cachedExchangeRatesCount = cachedRates.count
        
        let cachedCustomRates = DataCacheManager.shared.loadCustomExchangeRates()
        cachedCustomExchangeRatesCount = cachedCustomRates.count
        
        let cachedCryptos = DataCacheManager.shared.loadCryptocurrencies()
        cachedCryptocurrenciesCount = cachedCryptos.count
        
        lastExchangeRatesUpdate = DataCacheManager.shared.getLastExchangeRatesUpdateDate()
        lastCryptocurrenciesUpdate = DataCacheManager.shared.getLastCryptocurrenciesUpdateDate()
    }
    
    private func formatAlert(_ alert: CurrencyAlert) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(alert),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        return "Failed to encode alert"
    }
    
    private func formatAlertSummary(_ alert: CurrencyAlert) -> String {
        let conditionText: String
        switch alert.condition {
        case .above(let threshold):
            conditionText = "Above \(formatDecimal(threshold))"
        case .below(let threshold):
            conditionText = "Below \(formatDecimal(threshold))"
        }
        return conditionText
    }
    
    private func formatDecimal(_ value: Double) -> String {
        return String(format: "%.4f", value)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func copyToClipboard(_ text: String, itemName: String) {
        UIPasteboard.general.string = text
        copiedItemName = itemName
        showingCopyConfirmation = true
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func copyArrayToClipboard(_ array: [String], itemName: String) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        if let data = try? encoder.encode(array),
           let jsonString = String(data: data, encoding: .utf8) {
            copyToClipboard(jsonString, itemName: itemName)
        } else {
            // Fallback to comma-separated
            copyToClipboard(array.joined(separator: ", "), itemName: itemName)
        }
    }
    
    private func copyAlertsToClipboard() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(alerts),
           let jsonString = String(data: data, encoding: .utf8) {
            copyToClipboard(jsonString, itemName: "All Alerts")
        }
    }
    
    private func copyAllDataToClipboard() {
        // Encode alerts properly using JSONEncoder
        let alertEncoder = JSONEncoder()
        alertEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        alertEncoder.dateEncodingStrategy = .iso8601
        
        var alertsJSON: Any = []
        if let alertsData = try? alertEncoder.encode(alerts),
           let alertsDict = try? JSONSerialization.jsonObject(with: alertsData) {
            alertsJSON = alertsDict
        }
        
        let allData: [String: Any] = [
            "currencyAlerts": alertsJSON,
            "homeCurrency": homeCurrency,
            "customCurrencies": customCurrencies,
            "customCryptos": customCryptos,
            "currencyOrder": currencyOrder,
            "colorScheme": colorScheme,
            "language": language,
            "cryptoProvider": cryptoProvider,
            "websocketEnabled": websocketEnabled,
            "cacheInfo": [
                "exchangeRatesCount": cachedExchangeRatesCount,
                "customExchangeRatesCount": cachedCustomExchangeRatesCount,
                "cryptocurrenciesCount": cachedCryptocurrenciesCount,
                "lastExchangeRatesUpdate": lastExchangeRatesUpdate?.timeIntervalSince1970 ?? 0,
                "lastCryptocurrenciesUpdate": lastCryptocurrenciesUpdate?.timeIntervalSince1970 ?? 0
            ]
        ]
        
        // Convert to JSON
        if let jsonData = try? JSONSerialization.data(withJSONObject: allData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            copyToClipboard(jsonString, itemName: "All Data")
        }
    }
    
    private func saveItem(_ item: DataItem) {
        switch item {
        case .homeCurrency(let value):
            HomeCurrencyManager.shared.setHomeCurrency(value)
            
        case .colorScheme(let value):
            if let option = ColorSchemeOption(rawValue: value) {
                ColorSchemeManager.shared.setColorScheme(option)
            }
            
        case .language(let value):
            if let lang = AppLanguage(rawValue: value) {
                LanguageManager.shared.setLanguage(lang)
            }
            
        case .cryptoProvider(let value):
            if let provider = CryptoProviderType.allCases.first(where: { $0.displayName == value }) {
                CryptoProviderManager.shared.setProvider(provider)
            }
            
        case .alert(let alert):
            CurrencyAlertManager.shared.updateAlert(alert)
            
        case .customCurrencies(let currencies):
            // Remove all and re-add
            let current = CustomCurrencyManager.shared.getCustomCurrencies()
            for currency in current {
                CustomCurrencyManager.shared.removeCustomCurrency(currency)
            }
            for currency in currencies {
                CustomCurrencyManager.shared.addCustomCurrency(currency)
            }
            
        case .currencyOrder(let order):
            CurrencyOrderManager.shared.saveOrder(order)
        }
    }
}

struct DataItemRow: View {
    let title: String
    let value: String
    let onCopy: () -> Void
    let onEdit: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                HStack(spacing: 12) {
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    
                    if let onEdit = onEdit {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                Text(value)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 4)
    }
}

enum DataItem {
    case homeCurrency(String)
    case colorScheme(String)
    case language(String)
    case cryptoProvider(String)
    case alert(CurrencyAlert)
    case customCurrencies([String])
    case currencyOrder([String])
    
    var title: String {
        switch self {
        case .homeCurrency:
            return "Home Currency"
        case .colorScheme:
            return "Color Scheme"
        case .language:
            return "Language"
        case .cryptoProvider:
            return "Crypto Provider"
        case .alert:
            return "Alert"
        case .customCurrencies:
            return "Custom Currencies"
        case .currencyOrder:
            return "Currency Order"
        }
    }
}

#Preview {
    NavigationStack {
        DataInspectorView()
    }
}

