//
//  CurrencyPickerSheet.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 09/01/2026.
//

import SwiftUI

struct CurrencyPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @Binding var selectedCurrency: String
    let availableCurrencies: [String]
    let title: String
    
    @State private var searchText = ""
    
    private var theme: AppTheme { themeManager.currentTheme }
    private var primaryColor: Color { theme.usesSystemColors ? .primary : theme.primaryTextColor }
    private var secondaryColor: Color { theme.usesSystemColors ? .secondary : theme.secondaryTextColor }
    private var backgroundColor: Color { theme.usesSystemColors ? Color(.systemBackground) : theme.backgroundColor }
    private var rowBackground: Color { theme.usesSystemColors ? Color(.systemBackground) : theme.cardBackgroundColor }
    
    private var filteredCurrencies: [String] {
        if searchText.isEmpty {
            return availableCurrencies
        }
        
        let lowercasedSearch = searchText.lowercased()
        return availableCurrencies.filter { currency in
            // Search by currency code
            if currency.lowercased().contains(lowercasedSearch) {
                return true
            }
            // Search by country name
            if CurrencyFlagHelper.countryName(for: currency).lowercased().contains(lowercasedSearch) {
                return true
            }
            return false
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCurrencies, id: \.self) { currency in
                    Button {
                        selectedCurrency = currency
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            // Flag
                            CurrencyFlagHelper.circularFlag(for: currency, size: 32)
                            
                            // Currency info
                            VStack(alignment: .leading, spacing: 2) {
                                Text(currency)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(primaryColor)
                                
                                Text(CurrencyFlagHelper.countryName(for: currency))
                                    .font(.system(size: 13))
                                    .foregroundColor(secondaryColor)
                            }
                            
                            Spacer()
                            
                            // Checkmark for selected currency
                            if currency == selectedCurrency {
                                Image(systemName: "checkmark")
                                    .foregroundColor(theme.accentColor)
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(rowBackground)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(theme.usesSystemColors ? .automatic : .hidden)
            .background(backgroundColor)
            .searchable(text: $searchText, prompt: String(localized: "search_currency", defaultValue: "Search currency..."))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CurrencyPickerSheet(
        selectedCurrency: .constant("USD"),
        availableCurrencies: ["USD", "EUR", "GBP", "ILS", "JPY", "CNY"],
        title: "Select Currency"
    )
}
