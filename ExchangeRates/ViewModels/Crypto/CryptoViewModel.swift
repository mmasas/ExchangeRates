//
//  CryptoViewModel.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import Foundation
import SwiftUI
import Combine

enum CryptoFilterMode: Int, CaseIterable {
    case all = 0
    case liveOnly = 1
    case favorites = 2
}

class CryptoViewModel: ObservableObject {
    @Published var cryptocurrencies: [Cryptocurrency] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingNextPage: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var filterMode: CryptoFilterMode = .all
    @Published var isOffline: Bool = false
    @Published var lastUpdateDate: Date?
    @Published var favoriteCryptoIds: Set<String> = []
    
    // Chart-specific state
    @Published var chartData: [ChartDataPoint] = []
    @Published var selectedTimeRange: ChartTimeRange = .defaultRange
    @Published var isLoadingChart: Bool = false
    @Published var chartErrorMessage: String?
    
    /// Current page number (1-indexed)
    private(set) var currentPage = 1
    
    /// Whether there are more pages to load
    var hasMorePages: Bool {
        let totalPages = MainCryptoHelper.totalPages
        return currentPage < totalPages
    }
    
    /// Filtered cryptocurrencies based on search text and filter mode
    var filteredCryptocurrencies: [Cryptocurrency] {
        var filtered = cryptocurrencies
        
        // Apply filter mode
        switch filterMode {
        case .all:
            // Show all cryptocurrencies
            break
        case .liveOnly:
            filtered = filtered.filter { crypto in
                MainCryptoHelper.shouldUseWebSocket(crypto.id) || customCryptoManager.isCustomCrypto(crypto.id)
            }
        case .favorites:
            filtered = filtered.filter { crypto in
                favoriteCryptoIds.contains(crypto.id)
            }
        }
        
        // Apply search filter if search text is not empty
        if !searchText.isEmpty {
            filtered = filtered.filter { crypto in
                crypto.name.localizedCaseInsensitiveContains(searchText) ||
                crypto.symbol.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    /// Favorite cryptocurrencies
    var favoriteCryptocurrencies: [Cryptocurrency] {
        return cryptocurrencies.filter { favoriteCryptoIds.contains($0.id) }
    }
    
    private var currentTask: Task<Void, Never>?
    private var prefetchTask: Task<Void, Never>?
    private var chartTask: Task<Void, Never>?
    private let networkMonitor = NetworkMonitor.shared
    private let cacheManager = DataCacheManager.shared
    private let webSocketService = BinanceWebSocketService.shared
    private let websocketManager = WebSocketManager.shared
    private let customCryptoManager = CustomCryptoManager.shared
    private let favoriteCryptoManager = FavoriteCryptoManager.shared
    
    // Cache for chart data: [cryptoId: [timeRange: chartData]]
    private var chartDataCache: [String: [ChartTimeRange: [ChartDataPoint]]] = [:]
    
    // Track previous prices for animation
    private var previousPrices: [String: Double] = [:]
    
    // Combine cancellables
    private var websocketCancellable: AnyCancellable?
    private var websocketPreferenceCancellable: AnyCancellable?
    private var favoritesCancellable: AnyCancellable?
    
    init() {
        // Load favorites
        favoriteCryptoIds = Set(favoriteCryptoManager.getFavorites())
        
        // Load from cache first if available (on main actor)
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.loadFromCache()
            self.updateOfflineStatus()
        }
        
        // Subscribe to WebSocket price updates
        websocketCancellable = webSocketService.$priceUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updates in
                self?.updatePricesFromWebSocket(updates)
            }
        
        // Subscribe to WebSocket preference changes
        websocketPreferenceCancellable = NotificationCenter.default.publisher(
            for: WebSocketManager.websocketPreferenceChangedNotification
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.handleWebSocketPreferenceChange()
        }
        
        // Subscribe to favorites changes
        favoritesCancellable = NotificationCenter.default.publisher(
            for: FavoriteCryptoManager.favoritesDidChangeNotification
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.handleFavoritesChanged()
        }
        
        // Subscribe to custom crypto changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCustomCryptoAdded),
            name: NSNotification.Name("CustomCryptoAdded"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCustomCryptoRemoved),
            name: NSNotification.Name("CustomCryptoRemoved"),
            object: nil
        )
        
        // Load fresh data (will use cache if offline)
        loadCryptocurrencies()
    }
    
    deinit {
        websocketCancellable?.cancel()
        websocketPreferenceCancellable?.cancel()
        favoritesCancellable?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadCryptocurrencies() {
        currentTask?.cancel()
        currentTask = Task {
            await loadCryptocurrenciesAsync()
        }
    }
    
    @MainActor
    func loadCryptocurrenciesAsync() async {
        let isInitialLoad = cryptocurrencies.isEmpty
        LogManager.shared.log("Starting crypto load - isInitialLoad: \(isInitialLoad), current count: \(cryptocurrencies.count)", level: .info, source: "CryptoViewModel")
        
        isLoading = isInitialLoad
        errorMessage = nil
        currentPage = 1
        updateOfflineStatus()
        
        // Check if offline - load from cache if so
        if !networkMonitor.isConnected {
            LogManager.shared.log("Offline mode: loading cryptocurrencies from cache", level: .info, source: "CryptoViewModel")
            
            // If we already have data from loadFromCache, keep it
            if !cryptocurrencies.isEmpty {
                LogManager.shared.log("Already have cached data: \(cryptocurrencies.count) items, skipping reload", level: .info, source: "CryptoViewModel")
                isLoading = false
                return
            }
            
            // Otherwise try to load from cache
            let cachedCryptos = cacheManager.loadCryptocurrencies()
            if !cachedCryptos.isEmpty {
                cryptocurrencies = cachedCryptos
                isLoading = false
                lastUpdateDate = cacheManager.getLastCryptocurrenciesUpdateDate()
                LogManager.shared.log("Loaded \(cachedCryptos.count) cryptocurrencies from cache", level: .success, source: "CryptoViewModel")
                return
            } else {
                LogManager.shared.log("No cached cryptocurrencies available", level: .warning, source: "CryptoViewModel")
                isLoading = false
                return
            }
        }
        
        do {
            // Get cryptos for page 1 from mainCryptos
            let page1Ids = Array(MainCryptoHelper.mainCryptos.prefix(MainCryptoHelper.pageSize))
            
            let cryptos = try await CryptoService.shared.fetchCryptoPrices(ids: page1Ids)
            cryptocurrencies = cryptos
            isLoading = false
            
            // Save to cache on successful fetch
            if !cryptos.isEmpty {
                cacheManager.saveCryptocurrencies(cryptos)
                lastUpdateDate = cacheManager.getLastCryptocurrenciesUpdateDate()
                LogManager.shared.log("Saved \(cryptos.count) cryptocurrencies to cache", level: .success, source: "CryptoViewModel")
            }
            
            // Load custom cryptos and add them to the list
            await loadCustomCryptos()
            
            // Connect WebSocket for selected cryptos if enabled
            if websocketManager.isWebSocketEnabled {
                connectWebSocketForLiveTracking()
            }
            
            LogManager.shared.log("Loaded \(cryptocurrencies.count) cryptocurrencies (page 1 + custom) with sparklines", level: .success, source: "CryptoViewModel")
        } catch {
            // Don't show error if task was cancelled
            if let urlError = error as? URLError, urlError.code == .cancelled {
                LogManager.shared.log("Request was cancelled", level: .warning, source: "CryptoViewModel")
                isLoading = false
                return
            }
            
            LogManager.shared.log("Error: \(error.localizedDescription)", level: .error, source: "CryptoViewModel")
            errorMessage = "Failed to load cryptocurrencies: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    /// Prefetch the next page of cryptocurrencies
    @MainActor
    func prefetchNextPage() {
        // Guard against duplicate calls or if no more pages
        guard !isLoadingNextPage && hasMorePages else {
            return
        }
        
        let nextPage = currentPage + 1
        LogManager.shared.log("Prefetching crypto page \(nextPage)", level: .info, source: "CryptoViewModel")
        
        isLoadingNextPage = true
        
        prefetchTask?.cancel()
        prefetchTask = Task {
            await loadNextPageAsync()
        }
    }
    
    @MainActor
    private func loadNextPageAsync() async {
        let nextPage = currentPage + 1
        
        do {
            // Get cryptos for next page from mainCryptos
            let startIndex = (nextPage - 1) * MainCryptoHelper.pageSize
            let endIndex = min(startIndex + MainCryptoHelper.pageSize, MainCryptoHelper.mainCryptos.count)
            guard startIndex < MainCryptoHelper.mainCryptos.count else {
                isLoadingNextPage = false
                return
            }
            
            let pageIds = Array(MainCryptoHelper.mainCryptos[startIndex..<endIndex])
            guard !pageIds.isEmpty else {
                isLoadingNextPage = false
                return
            }
            
            let newCryptos = try await CryptoService.shared.fetchCryptoPrices(ids: pageIds)
            
            // Append new cryptos to existing list (maintaining order)
            cryptocurrencies.append(contentsOf: newCryptos)
            currentPage = nextPage
            isLoadingNextPage = false
            
            LogManager.shared.log("Loaded \(newCryptos.count) more cryptocurrencies (page \(nextPage)), total: \(cryptocurrencies.count)", level: .success, source: "CryptoViewModel")
        } catch {
            if let urlError = error as? URLError, urlError.code == .cancelled {
                LogManager.shared.log("Prefetch request was cancelled", level: .warning, source: "CryptoViewModel")
                isLoadingNextPage = false
                return
            }
            
            LogManager.shared.log("Error prefetching page \(nextPage): \(error.localizedDescription)", level: .error, source: "CryptoViewModel")
            isLoadingNextPage = false
            // Don't set errorMessage for prefetch failures - page 1 data is still valid
        }
    }
    
    @MainActor
    func refreshCryptocurrencies() async {
        LogManager.shared.log("Refreshing cryptocurrencies", level: .info, source: "CryptoViewModel")
        // Reset to page 1 on refresh
        currentPage = 1
        await loadCryptocurrenciesAsync()
    }
    
    /// Load data from cache (used on app init)
    @MainActor
    private func loadFromCache() {
        let cachedCryptos = cacheManager.loadCryptocurrencies()
        if !cachedCryptos.isEmpty {
            cryptocurrencies = cachedCryptos
            lastUpdateDate = cacheManager.getLastCryptocurrenciesUpdateDate()
            LogManager.shared.log("Loaded \(cachedCryptos.count) cryptocurrencies from cache", level: .info, source: "CryptoViewModel")
        }
    }
    
    /// Update offline status based on network monitor
    @MainActor
    private func updateOfflineStatus() {
        isOffline = !networkMonitor.isConnected
    }
    
    // MARK: - Chart Data Management
    
    /// Load chart data for a specific cryptocurrency and time range
    @MainActor
    func loadChartData(cryptoId: String, range: ChartTimeRange) {
        // Cancel any existing chart task
        chartTask?.cancel()
        
        // Check cache first
        if let cachedData = chartDataCache[cryptoId]?[range], !cachedData.isEmpty {
            LogManager.shared.log("Using cached chart data for \(cryptoId) (\(range.displayLabel))", level: .info, source: "CryptoViewModel")
            chartData = cachedData
            chartErrorMessage = nil
            return
        }
        
        // Check if offline
        if !networkMonitor.isConnected {
            LogManager.shared.log("Offline: Cannot load chart data", level: .warning, source: "CryptoViewModel")
            chartErrorMessage = String(localized: "chart_offline_unavailable", defaultValue: "Chart is not available offline")
            isLoadingChart = false
            return
        }
        
        // Start loading
        isLoadingChart = true
        chartErrorMessage = nil
        
        chartTask = Task {
            await loadChartDataAsync(cryptoId: cryptoId, range: range)
        }
    }
    
    @MainActor
    private func loadChartDataAsync(cryptoId: String, range: ChartTimeRange) async {
        do {
            LogManager.shared.log("Fetching chart data for \(cryptoId) (\(range.displayLabel), \(range.days) days)", level: .info, source: "CryptoViewModel")
            
            let data = try await CryptoService.shared.fetchMarketChart(id: cryptoId, days: range.days)
            
            // Cache the data
            if chartDataCache[cryptoId] == nil {
                chartDataCache[cryptoId] = [:]
            }
            chartDataCache[cryptoId]?[range] = data
            
            // Update UI
            chartData = data
            isLoadingChart = false
            chartErrorMessage = nil
            
            LogManager.shared.log("Loaded \(data.count) chart data points for \(cryptoId)", level: .success, source: "CryptoViewModel")
        } catch {
            // Don't show error if task was cancelled
            if let urlError = error as? URLError, urlError.code == .cancelled {
                LogManager.shared.log("Chart request was cancelled", level: .warning, source: "CryptoViewModel")
                isLoadingChart = false
                return
            }
            
            LogManager.shared.log("Error loading chart data: \(error.localizedDescription)", level: .error, source: "CryptoViewModel")
            chartErrorMessage = String(localized: "failed_to_load_chart", defaultValue: "Failed to load chart data")
            isLoadingChart = false
            chartData = []
        }
    }
    
    /// Update the selected time range and reload chart data if needed
    @MainActor
    func updateTimeRange(_ range: ChartTimeRange, for cryptoId: String) {
        selectedTimeRange = range
        loadChartData(cryptoId: cryptoId, range: range)
    }
    
    // MARK: - WebSocket Price Updates
    
    /// Update prices from WebSocket updates
    @MainActor
    private func updatePricesFromWebSocket(_ updates: [String: Double]) {
        for (symbol, price) in updates {
            // Find the crypto by Binance symbol and update its price
            if let index = cryptocurrencies.firstIndex(where: { crypto in
                guard let binanceSymbol = MainCryptoHelper.getSymbol(for: crypto.id) else {
                    return false
                }
                return binanceSymbol == symbol
            }) {
                let currentCrypto = cryptocurrencies[index]
                
                // Store previous price for animation
                previousPrices[currentCrypto.id] = currentCrypto.currentPrice
                
                // Create updated crypto with new price
                let updatedCrypto = Cryptocurrency(
                    id: currentCrypto.id,
                    symbol: currentCrypto.symbol,
                    name: currentCrypto.name,
                    image: currentCrypto.image,
                    currentPrice: price,
                    priceChangePercentage24h: currentCrypto.priceChangePercentage24h,
                    lastUpdated: currentCrypto.lastUpdated,
                    sparklineIn7d: currentCrypto.sparklineIn7d,
                    marketCapRank: currentCrypto.marketCapRank,
                    high24h: currentCrypto.high24h,
                    low24h: currentCrypto.low24h
                )
                
                cryptocurrencies[index] = updatedCrypto
            }
        }
    }
    
    /// Handle WebSocket preference changes
    @MainActor
    private func handleWebSocketPreferenceChange() {
        if websocketManager.isWebSocketEnabled {
            // Connect WebSocket if enabled
            connectWebSocketForLiveTracking()
        } else {
            // Disconnect WebSocket if disabled
            webSocketService.disconnect(clearSubscriptions: true)
        }
    }
    
    /// Connect WebSocket for live tracking (includes both websocketEnabledCryptos and custom cryptos)
    @MainActor
    private func connectWebSocketForLiveTracking() {
        var symbols: [String] = []
        
        // Add symbols for websocket-enabled cryptos
        symbols.append(contentsOf: MainCryptoHelper.getWebSocketSymbols())
        
        // Add symbols for custom cryptos
        let customCryptos = customCryptoManager.getCustomCryptos()
        for cryptoId in customCryptos {
            if let symbol = MainCryptoHelper.getSymbol(for: cryptoId) {
                symbols.append(symbol)
            }
        }
        
        // Remove duplicates
        symbols = Array(Set(symbols))
        
        if !symbols.isEmpty {
            webSocketService.connect(symbols: symbols)
            LogManager.shared.log("Connected WebSocket for \(symbols.count) symbols (including \(customCryptos.count) custom cryptos)", level: .info, source: "CryptoViewModel")
        }
    }
    
    /// Load custom cryptos and add them to the cryptocurrencies list
    @MainActor
    private func loadCustomCryptos() async {
        let customCryptoIds = customCryptoManager.getCustomCryptos()
        guard !customCryptoIds.isEmpty else { return }
        
        // Filter out custom cryptos that are already in the list
        let existingIds = Set(cryptocurrencies.map { $0.id.lowercased() })
        let newCustomIds = customCryptoIds.filter { !existingIds.contains($0.lowercased()) }
        
        guard !newCustomIds.isEmpty else { return }
        
        do {
            // Use BinanceCryptoService for custom cryptos (not CoinGecko)
            let binanceService = BinanceCryptoService.shared
            let customCryptos = try await binanceService.fetchCryptoPrices(ids: newCustomIds)
            // Append custom cryptos to the end of the list
            cryptocurrencies.append(contentsOf: customCryptos)
            LogManager.shared.log("Loaded \(customCryptos.count) custom cryptocurrencies from Binance", level: .success, source: "CryptoViewModel")
        } catch {
            LogManager.shared.log("Error loading custom cryptos from Binance: \(error.localizedDescription)", level: .error, source: "CryptoViewModel")
        }
    }
    
    /// Handle custom crypto added notification
    @objc private func handleCustomCryptoAdded(_ notification: Notification) {
        guard let cryptoId = notification.userInfo?["cryptoId"] as? String else { return }
        
        Task { @MainActor in
            // Check if already in list
            if cryptocurrencies.contains(where: { $0.id.lowercased() == cryptoId.lowercased() }) {
                return
            }
            
            // Load the new custom crypto from Binance (not CoinGecko)
            do {
                let binanceService = BinanceCryptoService.shared
                let cryptos = try await binanceService.fetchCryptoPrices(ids: [cryptoId])
                if let newCrypto = cryptos.first {
                    cryptocurrencies.append(newCrypto)
                    LogManager.shared.log("Added custom crypto from Binance: \(cryptoId)", level: .success, source: "CryptoViewModel")
                    
                    // Update WebSocket connection to include new crypto
                    if websocketManager.isWebSocketEnabled {
                        connectWebSocketForLiveTracking()
                    }
                }
            } catch {
                LogManager.shared.log("Error loading added custom crypto \(cryptoId) from Binance: \(error.localizedDescription)", level: .error, source: "CryptoViewModel")
            }
        }
    }
    
    /// Handle custom crypto removed notification
    @objc private func handleCustomCryptoRemoved(_ notification: Notification) {
        guard let cryptoId = notification.userInfo?["cryptoId"] as? String else { return }
        
        Task { @MainActor in
            // Remove from list
            cryptocurrencies.removeAll { $0.id.lowercased() == cryptoId.lowercased() }
            LogManager.shared.log("Removed custom crypto: \(cryptoId)", level: .info, source: "CryptoViewModel")
            
            // Update WebSocket connection
            if websocketManager.isWebSocketEnabled {
                connectWebSocketForLiveTracking()
            }
        }
    }
    
    /// Get previous price for a crypto (for animation)
    func getPreviousPrice(for cryptoId: String) -> Double? {
        return previousPrices[cryptoId]
    }
    
    // MARK: - Favorites Management
    
    /// Handle favorites changed notification
    @MainActor
    private func handleFavoritesChanged() {
        favoriteCryptoIds = Set(favoriteCryptoManager.getFavorites())
        LogManager.shared.log("Favorites updated: \(favoriteCryptoIds.count) favorites", level: .info, source: "CryptoViewModel")
    }
}
