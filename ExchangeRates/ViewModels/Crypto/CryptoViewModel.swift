//
//  CryptoViewModel.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import Foundation
import SwiftUI
import Combine

class CryptoViewModel: ObservableObject {
    @Published var cryptocurrencies: [Cryptocurrency] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingNextPage: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var isOffline: Bool = false
    @Published var lastUpdateDate: Date?
    
    /// Current page number (1-indexed)
    private(set) var currentPage = 1
    
    /// Whether there are more pages to load
    var hasMorePages: Bool {
        currentPage < MainCryptoHelper.totalPages
    }
    
    /// Filtered cryptocurrencies based on search text
    var filteredCryptocurrencies: [Cryptocurrency] {
        guard !searchText.isEmpty else { return cryptocurrencies }
        return cryptocurrencies.filter { crypto in
            crypto.name.localizedCaseInsensitiveContains(searchText) ||
            crypto.symbol.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var currentTask: Task<Void, Never>?
    private var prefetchTask: Task<Void, Never>?
    private let networkMonitor = NetworkMonitor.shared
    private let cacheManager = DataCacheManager.shared
    
    init() {
        // Load from cache first if available (on main actor)
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.loadFromCache()
            self.updateOfflineStatus()
        }
        
        // Load fresh data (will use cache if offline)
        loadCryptocurrencies()
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
            let page1Ids = MainCryptoHelper.getCryptos(forPage: 1)
            let cryptos = try await CryptoService.shared.fetchCryptoPrices(ids: page1Ids)
            cryptocurrencies = cryptos
            isLoading = false
            
            // Save to cache on successful fetch
            if !cryptos.isEmpty {
                cacheManager.saveCryptocurrencies(cryptos)
                lastUpdateDate = cacheManager.getLastCryptocurrenciesUpdateDate()
                LogManager.shared.log("Saved \(cryptos.count) cryptocurrencies to cache", level: .success, source: "CryptoViewModel")
            }
            
            LogManager.shared.log("Loaded \(cryptos.count) cryptocurrencies (page 1) with sparklines", level: .success, source: "CryptoViewModel")
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
            let pageIds = MainCryptoHelper.getCryptos(forPage: nextPage)
            let newCryptos = try await CryptoService.shared.fetchCryptoPrices(ids: pageIds)
            
            // Append new cryptos to existing list
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
}
