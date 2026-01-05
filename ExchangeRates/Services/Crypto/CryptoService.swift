//
//  CryptoService.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import Foundation

/// Service for fetching cryptocurrency data
/// Main list uses CoinGecko, charts use Binance
class CryptoService {
    static let shared = CryptoService()
    
    private let coinGeckoService = CoinGeckoCryptoService.shared
    private let binanceService = BinanceCryptoService.shared
    
    private init() {}
    
    /// Fetch cryptocurrency prices using CoinGecko
    func fetchCryptoPrices(ids: [String]? = nil) async throws -> [Cryptocurrency] {
        return try await coinGeckoService.fetchCryptoPrices(ids: ids)
    }
    
    /// Fetch a single cryptocurrency's data using CoinGecko
    func fetchCrypto(id: String) async throws -> Cryptocurrency {
        return try await coinGeckoService.fetchCrypto(id: id)
    }
    
    /// Fetch market chart data using Binance
    func fetchMarketChart(id: String, days: Int) async throws -> [ChartDataPoint] {
        return try await binanceService.fetchMarketChart(id: id, days: days)
    }
}

