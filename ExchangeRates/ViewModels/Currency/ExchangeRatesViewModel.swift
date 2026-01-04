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
    @Published var isOffline: Bool = false
    @Published var lastUpdateDate: Date?
    
    private var currentTask: Task<Void, Never>?
    private var customTask: Task<Void, Never>?
    private let orderManager = CurrencyOrderManager.shared
    private let homeCurrencyManager = HomeCurrencyManager.shared
    private let networkMonitor = NetworkMonitor.shared
    private let cacheManager = DataCacheManager.shared
    
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
        // Load from cache first if available
        loadFromCache()
        
        // Update offline status on main actor
        Task { @MainActor [weak self] in
            self?.updateOfflineStatus()
        }
        
        // Listen for network status changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NetworkStatusChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.updateOfflineStatus()
            }
        }
        
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
            LogManager.shared.log("Home currency changed, resetting order and reloading all rates", level: .info, source: "ExchangeRatesViewModel")
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
            LogManager.shared.log("Currency order reset, refreshing view", level: .info, source: "ExchangeRatesViewModel")
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
        LogManager.shared.log("Starting load - isInitialLoad: \(isInitialLoad), current rates count: \(exchangeRates.count)", level: .info, source: "ExchangeRatesViewModel")
        
        isLoading = isInitialLoad
        errorMessage = nil
        updateOfflineStatus()
        
        // Check if offline - load from cache if so
        if !networkMonitor.isConnected {
            LogManager.shared.log("Offline mode: loading exchange rates from cache", level: .info, source: "ExchangeRatesViewModel")
            let cachedRates = cacheManager.loadExchangeRates()
            if !cachedRates.isEmpty {
                exchangeRates = cachedRates
                mainCurrenciesLoaded = true
                isLoading = false
                lastUpdateDate = cacheManager.getLastExchangeRatesUpdateDate()
                LogManager.shared.log("Loaded \(cachedRates.count) exchange rates from cache", level: .success, source: "ExchangeRatesViewModel")
                syncOrderIfReady()
                return
            } else {
                LogManager.shared.log("No cached exchange rates available", level: .warning, source: "ExchangeRatesViewModel")
                isLoading = false
                return
            }
        }
        
        // Get home currency and main currencies
        let homeCurrency = homeCurrencyManager.getHomeCurrency()
        let mainCurrencies = MainCurrenciesHelper.mainCurrencies
        
        LogManager.shared.log("Loading main currencies relative to home currency: \(homeCurrency)", level: .info, source: "ExchangeRatesViewModel")
        
        var ratesDict: [String: ExchangeRate] = [:]
        
        // Load all main currencies relative to home currency (maintaining order)
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
                LogManager.shared.log("Added home currency \(homeCurrency) with rate 1.0", level: .success, source: "ExchangeRatesViewModel")
            } else {
                do {
                    // Fetch rate relative to home currency
                    let rate = try await CustomCurrencyService.shared.fetchExchangeRate(for: code, target: homeCurrency)
                    ratesDict[code] = rate
                    LogManager.shared.log("Loaded rate for \(code) relative to \(homeCurrency): \(rate.currentExchangeRate)", level: .success, source: "ExchangeRatesViewModel")
                } catch {
                    LogManager.shared.log("Failed to load rate for \(code): \(error.localizedDescription)", level: .error, source: "ExchangeRatesViewModel")
                    // Continue loading other currencies even if one fails
                }
            }
        }
        
        // Build rates array in the exact order of mainCurrencies
        let rates = mainCurrencies.compactMap { ratesDict[$0] }
        exchangeRates = rates
        mainCurrenciesLoaded = true
        
        // Save to cache on successful fetch
        if !rates.isEmpty {
            cacheManager.saveExchangeRates(rates)
            lastUpdateDate = cacheManager.getLastExchangeRatesUpdateDate()
            LogManager.shared.log("Saved \(rates.count) exchange rates to cache", level: .success, source: "ExchangeRatesViewModel")
        }
        
        // Initialize or reset order to maintain main currencies order
        let currencyCodes = mainCurrencies
        let existingOrder = orderManager.getOrderedCurrencies()
        if existingOrder.isEmpty {
            // First time setup - initialize with main currencies in their defined order
            orderManager.initializeOrder(with: currencyCodes)
        }
        
        isLoading = false
        LogManager.shared.log("Load completed successfully, loaded \(rates.count) main currencies, mainCurrenciesLoaded=true", level: .success, source: "ExchangeRatesViewModel")
        
        // Sync order only after BOTH main and custom currencies are loaded
        syncOrderIfReady()
        
        // Check alerts after rates are loaded
        checkAlertsIfReady()
    }
    
    @MainActor
    func loadCustomExchangeRatesAsync() async {
        LogManager.shared.log("Loading custom exchange rates", level: .info, source: "ExchangeRatesViewModel")
        
        isLoadingCustom = true
        updateOfflineStatus()
        
        let customCurrencyCodes = CustomCurrencyManager.shared.getCustomCurrencies()
        
        guard !customCurrencyCodes.isEmpty else {
            customExchangeRates = []
            customCurrenciesLoaded = true
            isLoadingCustom = false
            LogManager.shared.log("No custom currencies to load, customCurrenciesLoaded=true", level: .success, source: "ExchangeRatesViewModel")
            // Sync order only after BOTH main and custom currencies are loaded
            syncOrderIfReady()
            return
        }
        
        // Check if offline - load from cache if so
        if !networkMonitor.isConnected {
            LogManager.shared.log("Offline mode: loading custom exchange rates from cache", level: .info, source: "ExchangeRatesViewModel")
            let cachedRates = cacheManager.loadCustomExchangeRates()
            customExchangeRates = cachedRates
            customCurrenciesLoaded = true
            isLoadingCustom = false
            lastUpdateDate = cacheManager.getLastExchangeRatesUpdateDate()
            LogManager.shared.log("Loaded \(cachedRates.count) custom exchange rates from cache", level: .success, source: "ExchangeRatesViewModel")
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
                LogManager.shared.log("Loaded custom rate for \(code) relative to \(homeCurrency)", level: .success, source: "ExchangeRatesViewModel")
            } catch {
                LogManager.shared.log("Failed to load rate for \(code): \(error.localizedDescription)", level: .error, source: "ExchangeRatesViewModel")
                // Continue loading other currencies even if one fails
            }
        }
        
        customExchangeRates = rates
        customCurrenciesLoaded = true
        isLoadingCustom = false
        
        // Save to cache on successful fetch
        if !rates.isEmpty {
            cacheManager.saveCustomExchangeRates(rates)
            lastUpdateDate = cacheManager.getLastExchangeRatesUpdateDate()
            LogManager.shared.log("Saved \(rates.count) custom exchange rates to cache", level: .success, source: "ExchangeRatesViewModel")
        }
        
        LogManager.shared.log("Loaded \(rates.count) custom exchange rates, customCurrenciesLoaded=true", level: .success, source: "ExchangeRatesViewModel")
        
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
            LogManager.shared.log("syncOrderIfReady: waiting for both loads to complete (main=\(mainCurrenciesLoaded), custom=\(customCurrenciesLoaded))", level: .info, source: "ExchangeRatesViewModel")
            return
        }
        
        let allCurrencyCodes = (exchangeRates + customExchangeRates).map { $0.key }
        // Only sync if we have currencies loaded, otherwise preserve existing order
        guard !allCurrencyCodes.isEmpty else {
            LogManager.shared.log("syncOrderIfReady: no currencies loaded, skipping sync", level: .warning, source: "ExchangeRatesViewModel")
            return
        }
        
        LogManager.shared.log("syncOrderIfReady: both loads complete, syncing order with \(allCurrencyCodes.count) currencies", level: .success, source: "ExchangeRatesViewModel")
        orderManager.syncOrder(with: allCurrencyCodes)
    }
    
    /// Load data from cache (used on app init)
    @MainActor
    private func loadFromCache() {
        let cachedMainRates = cacheManager.loadExchangeRates()
        let cachedCustomRates = cacheManager.loadCustomExchangeRates()
        
        if !cachedMainRates.isEmpty {
            exchangeRates = cachedMainRates
            mainCurrenciesLoaded = true
        }
        
        if !cachedCustomRates.isEmpty {
            customExchangeRates = cachedCustomRates
            customCurrenciesLoaded = true
        }
        
        if !cachedMainRates.isEmpty || !cachedCustomRates.isEmpty {
            lastUpdateDate = cacheManager.getLastUpdateDate()
            LogManager.shared.log("Loaded cached data: \(cachedMainRates.count) main, \(cachedCustomRates.count) custom", level: .info, source: "ExchangeRatesViewModel")
        }
    }
    
    /// Update offline status based on network monitor
    @MainActor
    private func updateOfflineStatus() {
        isOffline = !networkMonitor.isConnected
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
                    LogManager.shared.log("\(triggeredAlerts.count) alerts triggered on app launch", level: .info, source: "ExchangeRatesViewModel")
                    
                    // Check notification permission
                    let status = await NotificationService.shared.getAuthorizationStatus()
                    if status != .authorized {
                        LogManager.shared.log("Notifications not authorized, requesting permission...", level: .warning, source: "ExchangeRatesViewModel")
                        let granted = await NotificationService.shared.requestPermission()
                        if !granted {
                            LogManager.shared.log("Notification permission denied", level: .error, source: "ExchangeRatesViewModel")
                            return
                        }
                    }
                    
                    // Send notifications for triggered alerts
                    for alert in triggeredAlerts {
                        let currentRate = try await AlertCheckerService.shared.fetchRateForPair(
                            base: alert.baseCurrency,
                            target: alert.targetCurrency
                        )
                        
                        LogManager.shared.log("Sending notification for \(alert.currencyPair)", level: .info, source: "ExchangeRatesViewModel")
                        NotificationService.shared.scheduleNotification(
                            for: alert,
                            currentRate: currentRate.currentExchangeRate
                        )
                    }
                }
            } catch {
                LogManager.shared.log("Failed to check alerts: \(error.localizedDescription)", level: .warning, source: "ExchangeRatesViewModel")
            }
        }
    }
}

