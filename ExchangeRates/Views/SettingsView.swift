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
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
    
    var body: some View {
        List {
            // MARK: - General Settings
            Section {
                Picker(String(localized: "language"), selection: $viewModel.language) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.menu)
                
                Picker(String(localized: "color_scheme"), selection: $viewModel.colorScheme) {
                    ForEach(ColorSchemeOption.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Label(String(localized: "general_settings", defaultValue: "General"), systemImage: "gearshape.fill")
            }
            
            // MARK: - Currency Management
            Section {
                Picker(String(localized: "home_currency"), selection: $viewModel.homeCurrency) {
                    ForEach(viewModel.allCurrenciesForHomePicker, id: \.self) { code in
                        Text("\(CurrencyFlagHelper.flag(for: code)) \(code) - \(CurrencyFlagHelper.countryName(for: code))")
                            .tag(code)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Label(String(localized: "currency_management", defaultValue: "Currency Management"), systemImage: "banknote.fill")
            } footer: {
                Text(String(localized: "home_currency_footer"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
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
            
            if !viewModel.customCurrencies.isEmpty {
                Section {
                    ForEach(viewModel.customCurrencies, id: \.self) { code in
                        HStack {
                            CurrencyFlagHelper.circularFlag(for: code, size: 28)
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
            
            // MARK: - Cryptocurrency Management
            Section {
                if viewModel.isLoadingCrypto {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                } else {
                    Picker(String(localized: "add_crypto", defaultValue: "Add Cryptocurrency"), selection: $viewModel.selectedCrypto) {
                        Text(String(localized: "select_crypto", defaultValue: "Select cryptocurrency")).tag("")
                        ForEach(viewModel.availableCryptos, id: \.self) { cryptoId in
                            Text(viewModel.getCryptoDisplayName(for: cryptoId))
                                .tag(cryptoId)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if !viewModel.selectedCrypto.isEmpty {
                        Button {
                            viewModel.addSelectedCrypto()
                        } label: {
                            HStack {
                                Spacer()
                                Text(String(localized: "add"))
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                        }
                        .disabled(viewModel.isLoadingCrypto)
                    }
                }
                
                if let error = viewModel.cryptoErrorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            } header: {
                Label(String(localized: "cryptocurrency_management", defaultValue: "Cryptocurrency Management"), systemImage: "bitcoinsign.circle.fill")
            } footer: {
                Text(String(localized: "custom_crypto_footer", defaultValue: "Add cryptocurrencies for live tracking. These will be included in your crypto list with real-time price updates."))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !viewModel.customCryptos.isEmpty {
                Section {
                    ForEach(viewModel.customCryptos, id: \.self) { cryptoId in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(viewModel.getCryptoDisplayName(for: cryptoId))
                                    .font(.system(size: 16, weight: .medium))
                                Text(cryptoId)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .onDelete(perform: viewModel.removeCrypto)
                } header: {
                    Text(String(localized: "custom_cryptos", defaultValue: "Custom Cryptocurrencies"))
                }
            }
            
            // MARK: - App Version
            Section {
                HStack {
                    Text(String(localized: "version", defaultValue: "Version"))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
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
    @Published var customCryptos: [String] = []
    @Published var availableCryptos: [String] = []
    @Published var selectedCrypto: String = ""
    @Published var isLoadingCrypto: Bool = false
    @Published var cryptoErrorMessage: String?
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
    private let cryptoManager = CustomCryptoManager.shared
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
        customCryptos = cryptoManager.getCustomCryptos()
        updateAvailableCryptos()
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
    
    private func updateAvailableCryptos() {
        // Get available cryptos from binancePairsDict, excluding mainCryptos and already-added custom cryptos
        availableCryptos = MainCryptoHelper.getAvailableCryptosForAdding(excluding: customCryptos)
    }
    
    func getCryptoDisplayName(for cryptoId: String) -> String {
        // Format the CoinGecko ID as a readable name
        // Replace hyphens with spaces and capitalize each word
        return cryptoId
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
    
    func addSelectedCrypto() {
        guard !selectedCrypto.isEmpty else { return }
        
        isLoadingCrypto = true
        cryptoErrorMessage = nil
        
        Task { @MainActor in
            // Verify the crypto exists in Binance by checking if we can get a symbol
            guard MainCryptoHelper.getSymbol(for: selectedCrypto) != nil else {
                cryptoErrorMessage = String(localized: "crypto_not_found_in_binance", defaultValue: "Cryptocurrency not found in Binance")
                isLoadingCrypto = false
                return
            }
            
            // Verify the crypto can be fetched from Binance (try to get price data)
            do {
                // Use BinanceCryptoService to verify the crypto exists and can be fetched
                let binanceService = BinanceCryptoService.shared
                let cryptos = try await binanceService.fetchCryptoPrices(ids: [selectedCrypto])
                
                if cryptos.isEmpty {
                    throw NSError(domain: "SettingsViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cryptocurrency not found in Binance"])
                }
                
                cryptoManager.addCustomCrypto(selectedCrypto)
                customCryptos = cryptoManager.getCustomCryptos()
                updateAvailableCryptos()
                let addedCrypto = selectedCrypto
                selectedCrypto = ""
                
                // Notify CryptoViewModel to reload with custom crypto
                NotificationCenter.default.post(
                    name: NSNotification.Name("CustomCryptoAdded"),
                    object: nil,
                    userInfo: ["cryptoId": addedCrypto]
                )
                
            } catch {
                cryptoErrorMessage = String(format: String(localized: "failed_to_load_crypto", defaultValue: "Failed to load cryptocurrency: %@"), String(describing: error.localizedDescription))
            }
            
            isLoadingCrypto = false
        }
    }
    
    func removeCrypto(at offsets: IndexSet) {
        var removedIds: [String] = []
        for index in offsets {
            let cryptoId = customCryptos[index]
            removedIds.append(cryptoId)
            cryptoManager.removeCustomCrypto(cryptoId)
        }
        customCryptos = cryptoManager.getCustomCryptos()
        updateAvailableCryptos()
        
        // Notify CryptoViewModel to reload with removed crypto IDs
        for cryptoId in removedIds {
            NotificationCenter.default.post(
                name: NSNotification.Name("CustomCryptoRemoved"),
                object: nil,
                userInfo: ["cryptoId": cryptoId]
            )
        }
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

