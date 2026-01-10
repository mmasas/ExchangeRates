//
//  CurrencyPickerSheet.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 09/01/2026.
//

import SwiftUI

struct CurrencyPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCurrency: String
    let availableCurrencies: [String]
    let title: String
    
    @State private var searchText = ""
    
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
                                    .foregroundColor(.primary)
                                
                                Text(CurrencyFlagHelper.countryName(for: currency))
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Checkmark for selected currency
                            if currency == selectedCurrency {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: String(localized: "search_currency", defaultValue: "Search currency..."))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
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
