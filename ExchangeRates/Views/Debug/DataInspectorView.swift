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
    @State private var colorScheme: String = ""
    @State private var language: String = ""
    @State private var showingEditSheet = false
    @State private var editingItem: DataItem? = nil
    @State private var showingCopyConfirmation = false
    @State private var copiedItemName = ""
    
    var body: some View {
        List {
            // Currency Alerts Section
            Section {
                if alerts.isEmpty {
                    Text("No alerts")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(alerts) { alert in
                        DataItemRow(
                            title: alert.currencyPair,
                            value: formatAlert(alert),
                            onCopy: {
                                copyToClipboard(formatAlert(alert), itemName: "Alert")
                            },
                            onEdit: {
                                editingItem = .alert(alert)
                                showingEditSheet = true
                            }
                        )
                    }
                }
            } header: {
                HStack {
                    Text("Currency Alerts (\(alerts.count))")
                    Spacer()
                    if !alerts.isEmpty {
                        Button("Copy All") {
                            copyAlertsToClipboard()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
            
            // Home Currency Section
            Section("Home Currency") {
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
            }
            
            // Custom Currencies Section
            Section {
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
            } header: {
                HStack {
                    Text("Custom Currencies (\(customCurrencies.count))")
                    Spacer()
                    if !customCurrencies.isEmpty {
                        Button("Copy All") {
                            copyArrayToClipboard(customCurrencies, itemName: "Custom Currencies")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
            
            // Currency Order Section
            Section {
                if currencyOrder.isEmpty {
                    Text("No currency order")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(currencyOrder.enumerated()), id: \.offset) { index, currency in
                        DataItemRow(
                            title: "\(index + 1). \(currency)",
                            value: currency,
                            onCopy: {
                                copyToClipboard(currency, itemName: "Currency Order Item")
                            },
                            onEdit: nil
                        )
                    }
                }
            } header: {
                HStack {
                    Text("Currency Order (\(currencyOrder.count))")
                    Spacer()
                    if !currencyOrder.isEmpty {
                        Button("Copy All") {
                            copyArrayToClipboard(currencyOrder, itemName: "Currency Order")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
            
            // Color Scheme Section
            Section("App Settings") {
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
        
        // Load currency order
        currencyOrder = CurrencyOrderManager.shared.getOrderedCurrencies()
        
        // Load color scheme
        colorScheme = ColorSchemeManager.shared.getColorScheme().rawValue
        
        // Load language
        language = LanguageManager.shared.getLanguage().rawValue
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
            "currencyOrder": currencyOrder,
            "colorScheme": colorScheme,
            "language": language
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

