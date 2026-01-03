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
            // Language section
            Section {
                Picker(String(localized: "language"), selection: $viewModel.language) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text(String(localized: "language"))
            }
            
            // Home Currency section
            Section {
                Picker(String(localized: "home_currency"), selection: $viewModel.homeCurrency) {
                    ForEach(viewModel.allCurrenciesForHomePicker, id: \.self) { code in
                        Text("\(CurrencyFlagHelper.flag(for: code)) \(code) - \(CurrencyFlagHelper.countryName(for: code))")
                            .tag(code)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text(String(localized: "home_currency"))
            } footer: {
                Text(String(localized: "home_currency_footer"))
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
                    Picker(String(localized: "add_currency"), selection: $viewModel.selectedCurrency) {
                        Text(String(localized: "select_currency")).tag("")
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
                                Text(String(localized: "add"))
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
                Text(String(localized: "add_new_currency"))
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
                    Text(String(localized: "custom_currencies"))
                }
            }
            
            // Color scheme section
            Section {
                Picker(String(localized: "color_scheme"), selection: $viewModel.colorScheme) {
                    ForEach(ColorSchemeOption.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text(String(localized: "color_scheme"))
            }
            
            // Reset currency order section
            Section {
                Button {
                    viewModel.resetCurrencyOrder()
                } label: {
                    HStack {
                        Spacer()
                        Text(String(localized: "reset_currency_order"))
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(String(localized: "settings"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadData()
        }
        .alert(String(localized: "language_change_restart_required", defaultValue: "Language Changed"), isPresented: $viewModel.showLanguageChangeAlert) {
            Button(String(localized: "ok"), role: .cancel) {
                viewModel.showLanguageChangeAlert = false
            }
        } message: {
            Text(String(localized: "language_change_message", defaultValue: "Please close and reopen the app for the language change to take full effect."))
        }
    }
}

class SettingsViewModel: ObservableObject {
    @Published var customCurrencies: [String] = []
    @Published var availableCurrencies: [String] = []
    @Published var selectedCurrency: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
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
    @Published var language: AppLanguage {
        didSet {
            // Only show alert if language actually changed (not during initial load)
            if oldValue != language && !isInitialLoad {
                LanguageManager.shared.setLanguage(language)
                showLanguageChangeAlert = true
            } else if oldValue != language {
                LanguageManager.shared.setLanguage(language)
            }
        }
    }
    @Published var showLanguageChangeAlert: Bool = false
    private var isInitialLoad: Bool = true
    
    private let currencyManager = CustomCurrencyManager.shared
    private let colorSchemeManager = ColorSchemeManager.shared
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
        self.language = LanguageManager.shared.getLanguage()
    }
    
    func loadData() {
        customCurrencies = currencyManager.getCustomCurrencies()
        updateAvailableCurrencies()
        colorScheme = colorSchemeManager.getColorScheme()
        homeCurrency = homeCurrencyManager.getHomeCurrency()
        language = LanguageManager.shared.getLanguage()
        // Mark initial load as complete after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isInitialLoad = false
        }
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
                errorMessage = String(format: String(localized: "failed_to_load_exchange_rate", defaultValue: "Failed to load exchange rate: %@"), String(describing: error.localizedDescription))
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

