//
//  HistoricalRateService.swift
//  ExchangeRates
//
//  Fetches historical exchange rate data for sparklines
//

import Foundation

/// Response structure from Frankfurter API for time series data
struct FrankfurterTimeSeriesResponse: Codable {
    let amount: Double
    let base: String
    let startDate: String
    let endDate: String
    let rates: [String: [String: Double]]
    
    enum CodingKeys: String, CodingKey {
        case amount
        case base
        case startDate = "start_date"
        case endDate = "end_date"
        case rates
    }
}

/// Historical rate data point
struct HistoricalRatePoint: Codable {
    let date: Date
    let rate: Double
}

/// Service for fetching historical exchange rate data
class HistoricalRateService {
    static let shared = HistoricalRateService()
    
    private let baseURL = "https://api.frankfurter.app"
    private let dateFormatter: DateFormatter
    
    // Cache for historical data to reduce API calls
    private var cache: [String: (data: [Double], expiry: Date)] = [:]
    private let cacheExpiry: TimeInterval = 60 * 60 // 1 hour
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
    }
    
    /// Fetch 7-day historical rates for a currency pair
    /// - Parameters:
    ///   - baseCurrency: The base currency code (e.g., "USD")
    ///   - targetCurrency: The target currency code (e.g., "ILS")
    /// - Returns: Array of rates for the past 7 days (oldest to newest)
    func fetch7DayHistory(baseCurrency: String, targetCurrency: String) async throws -> [Double] {
        let cacheKey = "\(baseCurrency)_\(targetCurrency)"
        
        // Check cache first
        if let cached = cache[cacheKey], cached.expiry > Date() {
            LogManager.shared.log("Using cached historical data for \(cacheKey)", level: .debug, source: "HistoricalRateService")
            return cached.data
        }
        
        // Calculate date range (7 days ago to today)
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        // Build URL
        guard let url = URL(string: "\(baseURL)/\(startDateString)..\(endDateString)?from=\(baseCurrency)&to=\(targetCurrency)") else {
            throw URLError(.badURL)
        }
        
        LogManager.shared.log("🟢 Frankfurter API: GET \(url.absoluteString)", level: .debug, source: "HistoricalRateService")
        
        // Fetch data
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            LogManager.shared.log("Frankfurter API error: \(httpResponse.statusCode)", level: .error, source: "HistoricalRateService")
            throw URLError(.badServerResponse)
        }
        
        // Parse response
        let decoder = JSONDecoder()
        let timeSeriesResponse = try decoder.decode(FrankfurterTimeSeriesResponse.self, from: data)
        
        // Extract rates sorted by date
        var rates: [HistoricalRatePoint] = []
        
        for (dateString, currencyRates) in timeSeriesResponse.rates {
            if let date = dateFormatter.date(from: dateString),
               let rate = currencyRates[targetCurrency] {
                rates.append(HistoricalRatePoint(date: date, rate: rate))
            }
        }
        
        // Sort by date (oldest first)
        rates.sort { $0.date < $1.date }
        
        // Extract just the rate values
        let rateValues = rates.map { $0.rate }
        
        // Cache the result
        cache[cacheKey] = (data: rateValues, expiry: Date().addingTimeInterval(cacheExpiry))
        
        LogManager.shared.log("Fetched \(rateValues.count) historical rates for \(cacheKey)", level: .success, source: "HistoricalRateService")
        
        return rateValues
    }
    
    /// Fetch historical rates for multiple currencies at once
    /// - Parameters:
    ///   - baseCurrency: The base currency code
    ///   - targetCurrencies: Array of target currency codes
    /// - Returns: Dictionary mapping currency code to sparkline data
    func fetch7DayHistoryBatch(baseCurrency: String, targetCurrencies: [String]) async throws -> [String: [Double]] {
        // Calculate date range
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        // Build URL with multiple target currencies
        let targetsString = targetCurrencies.joined(separator: ",")
        guard let url = URL(string: "\(baseURL)/\(startDateString)..\(endDateString)?from=\(baseCurrency)&to=\(targetsString)") else {
            throw URLError(.badURL)
        }
        
        LogManager.shared.log("🟢 Frankfurter API (batch): GET \(url.absoluteString)", level: .debug, source: "HistoricalRateService")
        
        // Fetch data
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            LogManager.shared.log("Frankfurter API batch error: \(httpResponse.statusCode)", level: .error, source: "HistoricalRateService")
            throw URLError(.badServerResponse)
        }
        
        // Parse response
        let decoder = JSONDecoder()
        let timeSeriesResponse = try decoder.decode(FrankfurterTimeSeriesResponse.self, from: data)
        
        // Build result dictionary
        var result: [String: [Double]] = [:]
        
        // Initialize arrays for each target currency
        for currency in targetCurrencies {
            result[currency] = []
        }
        
        // Sort dates and extract rates
        let sortedDates = timeSeriesResponse.rates.keys.sorted()
        
        for dateString in sortedDates {
            if let currencyRates = timeSeriesResponse.rates[dateString] {
                for currency in targetCurrencies {
                    if let rate = currencyRates[currency] {
                        result[currency]?.append(rate)
                    }
                }
            }
        }
        
        // Cache each currency pair
        for (currency, rates) in result {
            let cacheKey = "\(baseCurrency)_\(currency)"
            cache[cacheKey] = (data: rates, expiry: Date().addingTimeInterval(cacheExpiry))
        }
        
        LogManager.shared.log("Fetched historical rates for \(result.count) currencies", level: .success, source: "HistoricalRateService")
        
        return result
    }
    
    /// Clear the cache
    func clearCache() {
        cache.removeAll()
        LogManager.shared.log("Historical rate cache cleared", level: .info, source: "HistoricalRateService")
    }
    
    /// Get cached sparkline data if available
    func getCachedSparkline(baseCurrency: String, targetCurrency: String) -> [Double]? {
        let cacheKey = "\(baseCurrency)_\(targetCurrency)"
        if let cached = cache[cacheKey], cached.expiry > Date() {
            return cached.data
        }
        return nil
    }
}
