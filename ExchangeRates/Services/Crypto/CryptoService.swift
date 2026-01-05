//
//  CryptoService.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import Foundation

class CryptoService {
    static let shared = CryptoService()
    
    private let baseURL = "https://api.coingecko.com/api/v3"
    
    private init() {}
    
    /// Fetch cryptocurrency prices using the /coins/markets endpoint
    /// This returns price, 24h change, image URL, name, and symbol in a single request
    func fetchCryptoPrices(ids: [String]? = nil) async throws -> [Cryptocurrency] {
        let cryptoIds = ids ?? MainCryptoHelper.mainCryptos
        let idsString = cryptoIds.joined(separator: ",")
        
        guard let url = URL(string: "\(baseURL)/coins/markets?vs_currency=usd&ids=\(idsString)&order=market_cap_desc&sparkline=true") else {
            throw URLError(.badURL)
        }
        
        // Use Task.detached to ensure request completes even if parent task is cancelled
        let requestUrl = url
        let (data, response) = try await Task.detached(priority: .userInitiated) {
            var request = URLRequest(url: requestUrl)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 30
            return try await URLSession.shared.data(for: request)
        }.value
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            LogManager.shared.log("CoinGecko API error: \(httpResponse.statusCode)", level: .error, source: "CryptoService")
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let cryptos = try decoder.decode([Cryptocurrency].self, from: data)
        
        LogManager.shared.log("Fetched \(cryptos.count) cryptocurrencies", level: .success, source: "CryptoService")
        
        return cryptos
    }
    
    /// Fetch a single cryptocurrency's data
    func fetchCrypto(id: String) async throws -> Cryptocurrency {
        let cryptos = try await fetchCryptoPrices(ids: [id])
        guard let crypto = cryptos.first else {
            throw URLError(.resourceUnavailable)
        }
        return crypto
    }
    
    /// Fetch market chart data for a cryptocurrency over a specified time range
    /// - Parameters:
    ///   - id: The cryptocurrency ID (e.g., "bitcoin")
    ///   - days: Number of days of data (1, 7, 30, 90, 180, 365)
    /// - Returns: Array of ChartDataPoint with timestamps and prices
    func fetchMarketChart(id: String, days: Int) async throws -> [ChartDataPoint] {
        guard let url = URL(string: "\(baseURL)/coins/\(id)/market_chart?vs_currency=usd&days=\(days)") else {
            throw URLError(.badURL)
        }
        
        // Use Task.detached to ensure request completes even if parent task is cancelled
        let requestUrl = url
        let (data, response) = try await Task.detached(priority: .userInitiated) {
            var request = URLRequest(url: requestUrl)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 30
            return try await URLSession.shared.data(for: request)
        }.value
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            LogManager.shared.log("CoinGecko market_chart API error: \(httpResponse.statusCode)", level: .error, source: "CryptoService")
            throw URLError(.badServerResponse)
        }
        
        // Parse the response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let pricesArray = json?["prices"] as? [[Double]] else {
            LogManager.shared.log("Failed to parse market_chart response", level: .error, source: "CryptoService")
            throw URLError(.cannotParseResponse)
        }
        
        // Convert to ChartDataPoint array
        let chartData = pricesArray.compactMap { priceData -> ChartDataPoint? in
            guard priceData.count == 2 else { return nil }
            let timestampMs = priceData[0]
            let price = priceData[1]
            let date = Date(timeIntervalSince1970: timestampMs / 1000.0)
            return ChartDataPoint(timestamp: date, price: price)
        }
        
        LogManager.shared.log("Fetched \(chartData.count) chart data points for \(id) (\(days) days)", level: .success, source: "CryptoService")
        
        return chartData
    }
}

