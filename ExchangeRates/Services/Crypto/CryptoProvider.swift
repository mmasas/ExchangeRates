//
//  CryptoProvider.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import Foundation

/// Protocol defining the interface for cryptocurrency data providers
protocol CryptoProvider {
    /// Fetch cryptocurrency prices for multiple IDs
    /// - Parameter ids: Array of cryptocurrency IDs (provider-specific)
    /// - Returns: Array of Cryptocurrency objects
    func fetchCryptoPrices(ids: [String]?) async throws -> [Cryptocurrency]
    
    /// Fetch a single cryptocurrency's data
    /// - Parameter id: The cryptocurrency ID (provider-specific)
    /// - Returns: Cryptocurrency object
    func fetchCrypto(id: String) async throws -> Cryptocurrency
    
    /// Fetch market chart data for a cryptocurrency over a specified time range
    /// - Parameters:
    ///   - id: The cryptocurrency ID (provider-specific)
    ///   - days: Number of days of data (1, 7, 30, 90, 180, 365)
    /// - Returns: Array of ChartDataPoint with timestamps and prices
    func fetchMarketChart(id: String, days: Int) async throws -> [ChartDataPoint]
}






