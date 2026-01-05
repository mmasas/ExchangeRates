//
//  CoinGeckoCryptoService.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import Foundation

class CoinGeckoCryptoService: CryptoProvider {
    static let shared = CoinGeckoCryptoService()
    
    private let baseURL = "https://api.coingecko.com/api/v3"
    private let maxRetries = 2
    private let baseRetryDelay: TimeInterval = 2.0
    
    private init() {}
    
    /// Execute a request with retry logic for rate limiting (429 errors)
    private func executeWithRetry<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Check if it's a 429 rate limit error
                if let urlError = error as? URLError,
                   let retryAfter = urlError.userInfo["retryAfter"] as? Int {
                    // If this is not the last attempt, wait and retry
                    if attempt < maxRetries {
                        // Use Retry-After value directly, with a minimum delay
                        let delay = max(TimeInterval(retryAfter), baseRetryDelay * pow(2.0, Double(attempt)))
                        LogManager.shared.log("Rate limited (429), retrying after \(delay) seconds (attempt \(attempt + 1)/\(maxRetries + 1))", level: .warning, source: "CoinGeckoCryptoService")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                }
                
                // If not a retryable error or max retries reached, throw
                throw error
            }
        }
        
        // Should never reach here, but just in case
        throw lastError ?? URLError(.unknown)
    }
    
    /// Fetch cryptocurrency prices using the /coins/markets endpoint
    /// This returns price, 24h change, image URL, name, and symbol in a single request
    func fetchCryptoPrices(ids: [String]? = nil) async throws -> [Cryptocurrency] {
        let baseURL = self.baseURL
        return try await executeWithRetry {
            let cryptoIds = ids ?? MainCryptoHelper.mainCryptos
            let idsString = cryptoIds.joined(separator: ",")
            
            guard let url = URL(string: "\(baseURL)/coins/markets?vs_currency=usd&ids=\(idsString)&order=market_cap_desc&sparkline=true") else {
                throw URLError(.badURL)
            }
            
            // Log the full URL for debugging
            LogManager.shared.log("🟢 CoinGecko API: GET \(url.absoluteString)", level: .debug, source: "CoinGeckoCryptoService")
            
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
                if httpResponse.statusCode == 429 {
                    LogManager.shared.log("CoinGecko API rate limit (429) - too many requests", level: .warning, source: "CoinGeckoCryptoService")
                    // Check for Retry-After header
                    if let retryAfterString = httpResponse.value(forHTTPHeaderField: "Retry-After"),
                       let retryAfter = Int(retryAfterString) {
                        LogManager.shared.log("Retry-After header: \(retryAfter) seconds", level: .info, source: "CoinGeckoCryptoService")
                        throw URLError(.badServerResponse, userInfo: [
                            NSLocalizedDescriptionKey: "Rate limit exceeded. Please try again in \(retryAfter) seconds.",
                            "retryAfter": retryAfter
                        ])
                    } else {
                        throw URLError(.badServerResponse, userInfo: [
                            NSLocalizedDescriptionKey: "Rate limit exceeded. Please try again later."
                        ])
                    }
                }
                LogManager.shared.log("CoinGecko API error: \(httpResponse.statusCode)", level: .error, source: "CoinGeckoCryptoService")
                throw URLError(.badServerResponse)
            }
            
            let decoder = JSONDecoder()
            let cryptos = try decoder.decode([Cryptocurrency].self, from: data)
            
            LogManager.shared.log("Fetched \(cryptos.count) cryptocurrencies from CoinGecko", level: .success, source: "CoinGeckoCryptoService")
            
            return cryptos
        }
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
        let baseURL = self.baseURL
        return try await executeWithRetry {
            guard let url = URL(string: "\(baseURL)/coins/\(id)/market_chart?vs_currency=usd&days=\(days)") else {
                throw URLError(.badURL)
            }
            
            // Log the full URL for debugging
            LogManager.shared.log("🟢 CoinGecko API: GET \(url.absoluteString)", level: .debug, source: "CoinGeckoCryptoService")
            
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
                if httpResponse.statusCode == 429 {
                    LogManager.shared.log("CoinGecko market_chart API rate limit (429) - too many requests", level: .warning, source: "CoinGeckoCryptoService")
                    // Check for Retry-After header
                    if let retryAfterString = httpResponse.value(forHTTPHeaderField: "Retry-After"),
                       let retryAfter = Int(retryAfterString) {
                        LogManager.shared.log("Retry-After header: \(retryAfter) seconds", level: .info, source: "CoinGeckoCryptoService")
                        throw URLError(.badServerResponse, userInfo: [
                            NSLocalizedDescriptionKey: "Rate limit exceeded. Please try again in \(retryAfter) seconds.",
                            "retryAfter": retryAfter
                        ])
                    } else {
                        throw URLError(.badServerResponse, userInfo: [
                            NSLocalizedDescriptionKey: "Rate limit exceeded. Please try again later."
                        ])
                    }
                }
                LogManager.shared.log("CoinGecko market_chart API error: \(httpResponse.statusCode)", level: .error, source: "CoinGeckoCryptoService")
                throw URLError(.badServerResponse)
            }
            
            // Parse the response
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let pricesArray = json?["prices"] as? [[Double]] else {
                LogManager.shared.log("Failed to parse market_chart response", level: .error, source: "CoinGeckoCryptoService")
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
            
            LogManager.shared.log("Fetched \(chartData.count) chart data points for \(id) (\(days) days) from CoinGecko", level: .success, source: "CoinGeckoCryptoService")
            
            return chartData
        }
    }
}

