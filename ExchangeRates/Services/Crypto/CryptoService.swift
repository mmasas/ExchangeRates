//
//  CryptoService.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import Foundation

/// Facade service that delegates to the selected crypto provider
class CryptoService {
    static let shared = CryptoService()
    
    private let providerManager = CryptoProviderManager.shared
    private let coinGeckoService = CoinGeckoCryptoService.shared
    private let binanceService = BinanceCryptoService.shared
    
    private init() {}
    
    /// Get the current provider instance
    private var currentProvider: CryptoProvider {
        switch providerManager.getProvider() {
        case .coingecko:
            return coinGeckoService
        case .binance:
            return binanceService
        }
    }
    
    /// Fetch cryptocurrency prices using the selected provider
    func fetchCryptoPrices(ids: [String]? = nil) async throws -> [Cryptocurrency] {
        return try await currentProvider.fetchCryptoPrices(ids: ids)
    }
    
    /// Fetch a single cryptocurrency's data using the selected provider
    func fetchCrypto(id: String) async throws -> Cryptocurrency {
        return try await currentProvider.fetchCrypto(id: id)
    }
    
    /// Fetch market chart data - tries Binance first, falls back to CoinGecko if not available
    /// Note: Chart data tries Binance first (experimental), but falls back to CoinGecko if the crypto is not available on Binance
    func fetchMarketChart(id: String, days: Int) async throws -> [ChartDataPoint] {
        // Try Binance first
        if MainCryptoHelper.getSymbol(for: id) != nil {
            do {
                return try await binanceService.fetchMarketChart(id: id, days: days)
            } catch {
                // If Binance fails and it's not a "resource unavailable" error, fall back to CoinGecko
                if let urlError = error as? URLError, urlError.code != .resourceUnavailable {
                    LogManager.shared.log("Binance chart fetch failed for \(id), falling back to CoinGecko", level: .warning, source: "CryptoService")
                    return try await coinGeckoService.fetchMarketChart(id: id, days: days)
                }
                throw error
            }
        }
        
        // If not available on Binance, use CoinGecko
        LogManager.shared.log("\(id) not available on Binance, using CoinGecko for chart", level: .info, source: "CryptoService")
        return try await coinGeckoService.fetchMarketChart(id: id, days: days)
    }
}

