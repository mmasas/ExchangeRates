//
//  ExchangeRatesViewModel.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 26/12/2025.
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

class ExchangeRatesViewModel: ObservableObject {
    @Published var exchangeRates: [ExchangeRate] = []
    @Published var customExchangeRates: [ExchangeRate] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingCustom: Bool = false
    @Published var errorMessage: String?
    
    private var currentTask: Task<Void, Never>?
    private var customTask: Task<Void, Never>?
    private let orderManager = CurrencyOrderManager.shared
    private let homeCurrencyManager = HomeCurrencyManager.shared
    
    // Track if initial loads have completed (to avoid syncing with partial data)
    private var mainCurrenciesLoaded = false
    private var customCurrenciesLoaded = false
    
    // Combined list of all exchange rates (main API + custom) sorted by user-defined order
    var allExchangeRates: [ExchangeRate] {
        let allRates = exchangeRates + customExchangeRates
        let currencyCodes = allRates.map { $0.key }
        let sortedCodes = orderManager.sortCurrencies(currencyCodes)
        
        // Create a map for quick lookup
        let rateMap = Dictionary(uniqueKeysWithValues: allRates.map { ($0.key, $0) })
        
        // Return rates in the sorted order
        return sortedCodes.compactMap { rateMap[$0] }
    }
    
    init() {
        loadExchangeRates()
        loadCustomExchangeRates()
        
        // Listen for custom currency changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CustomCurrencyAdded"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            if let currencyCode = notification.userInfo?["currencyCode"] as? String {
                self.orderManager.addCurrency(currencyCode)
            }
            self.loadCustomExchangeRates()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CustomCurrencyRemoved"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            if let currencyCode = notification.userInfo?["currencyCode"] as? String {
                self.orderManager.removeCurrency(currencyCode)
            }
            self.loadCustomExchangeRates()
        }
        
        // Listen for home currency changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("HomeCurrencyChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            print("🔄 [ExchangeRatesViewModel] Home currency changed, resetting order and reloading all rates")
            // Reset order to main currencies order when home currency changes
            self.orderManager.resetToDefaultOrder(with: MainCurrenciesHelper.mainCurrencies)
            self.loadExchangeRates()
            self.loadCustomExchangeRates()
        }
        
        // Listen for currency order reset
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CurrencyOrderReset"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            print("🔄 [ExchangeRatesViewModel] Currency order reset, refreshing view")
            // Force view update by triggering a published property change
            self.objectWillChange.send()
        }
    }
    
    func loadExchangeRates() {
        currentTask?.cancel()
        currentTask = Task {
            await loadExchangeRatesAsync()
        }
    }
    
    func loadCustomExchangeRates() {
        customTask?.cancel()
        customTask = Task {
            await loadCustomExchangeRatesAsync()
        }
    }
    
    @MainActor
    func loadExchangeRatesAsync() async {
        let isInitialLoad = exchangeRates.isEmpty
        print("🔄 [ExchangeRatesViewModel] Starting load - isInitialLoad: \(isInitialLoad), current rates count: \(exchangeRates.count)")
        
        isLoading = isInitialLoad
        errorMessage = nil
        
        // Get home currency and main currencies
        let homeCurrency = homeCurrencyManager.getHomeCurrency()
        let mainCurrencies = MainCurrenciesHelper.mainCurrencies
        
        print("🌐 [ExchangeRatesViewModel] Loading main currencies relative to home currency: \(homeCurrency)")
        
        var ratesDict: [String: ExchangeRate] = [:]
        
        // Load all main currencies relative to home currency (maintaining order)
        do {
            for code in mainCurrencies {
                if code == homeCurrency {
                    // Home currency with rate 1.0
                    let homeCurrencyRate = ExchangeRate(
                        key: homeCurrency,
                        currentExchangeRate: 1.0,
                        currentChange: 0.0,
                        unit: 1,
                        lastUpdate: ISO8601DateFormatter().string(from: Date())
                    )
                    ratesDict[code] = homeCurrencyRate
                    print("✅ [ExchangeRatesViewModel] Added home currency \(homeCurrency) with rate 1.0")
                } else {
                    do {
                        // Fetch rate relative to home currency
                        let rate = try await CustomCurrencyService.shared.fetchExchangeRate(for: code, target: homeCurrency)
                        ratesDict[code] = rate
                        print("✅ [ExchangeRatesViewModel] Loaded rate for \(code) relative to \(homeCurrency): \(rate.currentExchangeRate)")
                    } catch {
                        print("❌ [ExchangeRatesViewModel] Failed to load rate for \(code): \(error.localizedDescription)")
                        // Continue loading other currencies even if one fails
                    }
                }
            }
            
            // Build rates array in the exact order of mainCurrencies
            let rates = mainCurrencies.compactMap { ratesDict[$0] }
            exchangeRates = rates
            mainCurrenciesLoaded = true
            
            // Initialize or reset order to maintain main currencies order
            let currencyCodes = mainCurrencies
            let existingOrder = orderManager.getOrderedCurrencies()
            if existingOrder.isEmpty {
                // First time setup - initialize with main currencies in their defined order
                orderManager.initializeOrder(with: currencyCodes)
            }
            
            isLoading = false
            print("✅ [ExchangeRatesViewModel] Load completed successfully, loaded \(rates.count) main currencies, mainCurrenciesLoaded=true")
            
            // Sync order only after BOTH main and custom currencies are loaded
            syncOrderIfReady()
            
            // Check alerts after rates are loaded
            checkAlertsIfReady()
        } catch {
            // Don't show error if task was cancelled (user-initiated)
            if let urlError = error as? URLError, urlError.code == .cancelled {
                print("⚠️ [ExchangeRatesViewModel] Request was cancelled (this is normal for pull-to-refresh)")
                isLoading = false
                return
            }
            
            print("❌ [ExchangeRatesViewModel] Error: \(error.localizedDescription)")
            print("❌ [ExchangeRatesViewModel] Error details: \(error)")
            errorMessage = "Failed to load exchange rates: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    @MainActor
    func loadCustomExchangeRatesAsync() async {
        print("🔄 [ExchangeRatesViewModel] Loading custom exchange rates")
        
        isLoadingCustom = true
        
        let customCurrencyCodes = CustomCurrencyManager.shared.getCustomCurrencies()
        
        guard !customCurrencyCodes.isEmpty else {
            customExchangeRates = []
            customCurrenciesLoaded = true
            isLoadingCustom = false
            print("✅ [ExchangeRatesViewModel] No custom currencies to load, customCurrenciesLoaded=true")
            // Sync order only after BOTH main and custom currencies are loaded
            syncOrderIfReady()
            return
        }
        
        var rates: [ExchangeRate] = []
        let homeCurrency = homeCurrencyManager.getHomeCurrency()
        
        for code in customCurrencyCodes {
            // Skip if it's the home currency (already in main list)
            if code == homeCurrency {
                continue
            }
            
            do {
                // Fetch rate relative to home currency
                let rate = try await CustomCurrencyService.shared.fetchExchangeRate(for: code, target: homeCurrency)
                rates.append(rate)
                print("✅ [ExchangeRatesViewModel] Loaded custom rate for \(code) relative to \(homeCurrency)")
            } catch {
                print("❌ [ExchangeRatesViewModel] Failed to load rate for \(code): \(error.localizedDescription)")
                // Continue loading other currencies even if one fails
            }
        }
        
        customExchangeRates = rates
        customCurrenciesLoaded = true
        isLoadingCustom = false
        print("✅ [ExchangeRatesViewModel] Loaded \(rates.count) custom exchange rates, customCurrenciesLoaded=true")
        
        // Sync order only after BOTH main and custom currencies are loaded
        syncOrderIfReady()
        
        // Check alerts after rates are loaded
        checkAlertsIfReady()
    }
    
    @MainActor
    func refreshAllRates() async {
        // Reset load flags for refresh
        mainCurrenciesLoaded = false
        customCurrenciesLoaded = false
        
        // Run both refresh operations in parallel
        // Don't cancel existing tasks - let them finish naturally
        // The new data will simply replace the old data when it arrives
        async let mainRatesTask: Void = loadExchangeRatesAsync()
        async let customRatesTask: Void = loadCustomExchangeRatesAsync()
        
        // Wait for both to complete
        await mainRatesTask
        await customRatesTask
        
        // syncOrderIfReady() is already called by each load function when both are ready
    }
    
    /// Update the currency order after user drag-and-drop
    @MainActor
    func updateCurrencyOrder(from source: IndexSet, to destination: Int) {
        let currentRates = allExchangeRates
        let currencyCodes = currentRates.map { $0.key }
        orderManager.moveCurrency(from: source, to: destination, currentOrder: currencyCodes)
        
        // Force view update by triggering a published property change
        objectWillChange.send()
    }
    
    /// Sync the order with currently available currencies
    /// Only syncs if BOTH main and custom currencies have finished loading
    /// This prevents corrupting the saved order with partial data
    private func syncOrderIfReady() {
        // Only sync when both main and custom currencies are loaded
        guard mainCurrenciesLoaded && customCurrenciesLoaded else {
            print("⏳ [ExchangeRatesViewModel] syncOrderIfReady: waiting for both loads to complete (main=\(mainCurrenciesLoaded), custom=\(customCurrenciesLoaded))")
            return
        }
        
        let allCurrencyCodes = (exchangeRates + customExchangeRates).map { $0.key }
        // Only sync if we have currencies loaded, otherwise preserve existing order
        guard !allCurrencyCodes.isEmpty else {
            print("⚠️ [ExchangeRatesViewModel] syncOrderIfReady: no currencies loaded, skipping sync")
            return
        }
        
        print("✅ [ExchangeRatesViewModel] syncOrderIfReady: both loads complete, syncing order with \(allCurrencyCodes.count) currencies")
        orderManager.syncOrder(with: allCurrencyCodes)
    }
    
    /// Check alerts after both main and custom currencies are loaded
    private func checkAlertsIfReady() {
        guard mainCurrenciesLoaded && customCurrenciesLoaded else {
            return
        }
        
        Task {
            do {
                let triggeredAlerts = try await AlertCheckerService.shared.checkAlerts()
                
                if !triggeredAlerts.isEmpty {
                    print("🔔 [ExchangeRatesViewModel] \(triggeredAlerts.count) alerts triggered on app launch")
                    
                    // Check notification permission
                    let status = await NotificationService.shared.getAuthorizationStatus()
                    if status != .authorized {
                        print("⚠️ [ExchangeRatesViewModel] Notifications not authorized, requesting permission...")
                        let granted = await NotificationService.shared.requestPermission()
                        if !granted {
                            print("❌ [ExchangeRatesViewModel] Notification permission denied")
                            return
                        }
                    }
                    
                    // Send notifications for triggered alerts
                    for alert in triggeredAlerts {
                        let currentRate = try await AlertCheckerService.shared.fetchRateForPair(
                            base: alert.baseCurrency,
                            target: alert.targetCurrency
                        )
                        
                        print("📱 [ExchangeRatesViewModel] Sending notification for \(alert.currencyPair)")
                        NotificationService.shared.scheduleNotification(
                            for: alert,
                            currentRate: currentRate.currentExchangeRate
                        )
                    }
                }
            } catch {
                print("⚠️ [ExchangeRatesViewModel] Failed to check alerts: \(error.localizedDescription)")
            }
        }
    }
}

