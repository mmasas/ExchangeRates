//
//  SettingsView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import SwiftUI
import Combine

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    
    init(existingCurrencyCodes: [String] = []) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(existingCurrencyCodes: existingCurrencyCodes))
    }
    
    
    var body: some View {
        List {
            // Home Currency section
            Section {
                Picker("מטבע בית", selection: $viewModel.homeCurrency) {
                    ForEach(viewModel.allCurrenciesForHomePicker, id: \.self) { code in
                        Text("\(CurrencyFlagHelper.flag(for: code)) \(code) - \(CurrencyFlagHelper.countryName(for: code))")
                            .tag(code)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("מטבע בית")
            } footer: {
                Text("כל שערי המטבעות יוצגו ביחס למטבע הבית שנבחר")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Add currency section
            Section {
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                } else {
                    Picker("הוסף מטבע", selection: $viewModel.selectedCurrency) {
                        Text("בחר מטבע").tag("")
                        ForEach(viewModel.availableCurrencies, id: \.self) { code in
                            Text("\(CurrencyFlagHelper.flag(for: code)) \(code) - \(CurrencyFlagHelper.countryName(for: code))")
                                .tag(code)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if !viewModel.selectedCurrency.isEmpty {
                        Button {
                            viewModel.addSelectedCurrency()
                        } label: {
                            HStack {
                                Spacer()
                                Text("הוסף")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            } header: {
                Text("הוסף מטבע חדש")
            }
            
            // Current custom currencies section
            if !viewModel.customCurrencies.isEmpty {
                Section {
                    ForEach(viewModel.customCurrencies, id: \.self) { code in
                        HStack {
                            Text(CurrencyFlagHelper.flag(for: code))
                                .font(.system(size: 24))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(code)
                                    .font(.system(size: 16, weight: .medium))
                                Text(CurrencyFlagHelper.countryName(for: code))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .onDelete(perform: viewModel.removeCurrency)
                } header: {
                    Text("מטבעות מותאמים אישית")
                }
            }
            
            // Currency Alerts section
            Section {
                NavigationLink(value: "alerts") {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("התראות שערי מטבע")
                            .layoutPriority(1)
                        Spacer(minLength: 8)
                        if viewModel.activeAlertsCount > 0 {
                            Text("\(viewModel.activeAlertsCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
            } header: {
                Text("התראות")
            }
            
            // Color scheme section
            Section {
                Picker("ערכת נושא", selection: $viewModel.colorScheme) {
                    ForEach(ColorSchemeOption.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("ערכת נושא")
            }
            
            // Reset currency order section
            Section {
                Button {
                    viewModel.resetCurrencyOrder()
                } label: {
                    HStack {
                        Spacer()
                        Text("איפוס סדר מטבעות")
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("הגדרות")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadData()
        }
    }
}

class SettingsViewModel: ObservableObject {
    @Published var customCurrencies: [String] = []
    @Published var availableCurrencies: [String] = []
    @Published var selectedCurrency: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var activeAlertsCount: Int = 0
    @Published var homeCurrency: String {
        didSet {
            HomeCurrencyManager.shared.setHomeCurrency(homeCurrency)
        }
    }
    @Published var colorScheme: ColorSchemeOption {
        didSet {
            ColorSchemeManager.shared.setColorScheme(colorScheme)
            // Notify the app to update color scheme
            NotificationCenter.default.post(
                name: NSNotification.Name("ColorSchemeChanged"),
                object: nil
            )
        }
    }
    
    private let currencyManager = CustomCurrencyManager.shared
    private let colorSchemeManager = ColorSchemeManager.shared
    private let alertManager = CurrencyAlertManager.shared
    private let homeCurrencyManager = HomeCurrencyManager.shared
    private let orderManager = CurrencyOrderManager.shared
    private let existingCurrencyCodes: [String]
    
    // All currencies sorted for home currency picker (main currencies first)
    var allCurrenciesForHomePicker: [String] {
        MainCurrenciesHelper.getAllCurrenciesForPicker()
    }
    
    init(existingCurrencyCodes: [String] = []) {
        self.existingCurrencyCodes = existingCurrencyCodes
        self.colorScheme = ColorSchemeManager.shared.getColorScheme()
        self.homeCurrency = HomeCurrencyManager.shared.getHomeCurrency()
    }
    
    func loadData() {
        customCurrencies = currencyManager.getCustomCurrencies()
        updateAvailableCurrencies()
        colorScheme = colorSchemeManager.getColorScheme()
        homeCurrency = homeCurrencyManager.getHomeCurrency()
        updateActiveAlertsCount()
    }
    
    private func updateActiveAlertsCount() {
        activeAlertsCount = alertManager.getActiveAlerts().count
    }
    
    private func updateAvailableCurrencies() {
        // Exclude home currency, existing main currencies, and already-added custom currencies
        let homeCurrency = homeCurrencyManager.getHomeCurrency()
        let excluded = customCurrencies + existingCurrencyCodes + [homeCurrency]
        availableCurrencies = currencyManager.getAvailableCurrenciesForAdding(excluding: excluded)
    }
    
    func addSelectedCurrency() {
        guard !selectedCurrency.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            // Verify the currency can be fetched
            let homeCurrency = homeCurrencyManager.getHomeCurrency()
            do {
                _ = try await CustomCurrencyService.shared.fetchExchangeRate(for: selectedCurrency, target: homeCurrency)
                
                currencyManager.addCustomCurrency(selectedCurrency)
                customCurrencies = currencyManager.getCustomCurrencies()
                updateAvailableCurrencies()
                let addedCurrency = selectedCurrency
                selectedCurrency = ""
                
                // Notify ExchangeRatesViewModel to reload with currency code
                NotificationCenter.default.post(
                    name: NSNotification.Name("CustomCurrencyAdded"),
                    object: nil,
                    userInfo: ["currencyCode": addedCurrency]
                )
                
            } catch {
                errorMessage = "נכשל בטעינת שער המרה: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
    
    func removeCurrency(at offsets: IndexSet) {
        var removedCodes: [String] = []
        for index in offsets {
            let code = customCurrencies[index]
            removedCodes.append(code)
            currencyManager.removeCustomCurrency(code)
        }
        customCurrencies = currencyManager.getCustomCurrencies()
        updateAvailableCurrencies()
        
        // Notify ExchangeRatesViewModel to reload with currency codes
        for code in removedCodes {
            NotificationCenter.default.post(
                name: NSNotification.Name("CustomCurrencyRemoved"),
                object: nil,
                userInfo: ["currencyCode": code]
            )
        }
    }
    
    func resetCurrencyOrder() {
        // Reset the order using the manager which handles combining, sorting, and resetting
        orderManager.resetToDefaultOrderWithCurrentCurrencies(existingCurrencyCodes: existingCurrencyCodes)
        
        // Notify ExchangeRatesViewModel to refresh the view
        NotificationCenter.default.post(
            name: NSNotification.Name("CurrencyOrderReset"),
            object: nil
        )
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}

