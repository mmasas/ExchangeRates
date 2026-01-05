//
//  BinanceCryptoService.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import Foundation

class BinanceCryptoService: CryptoProvider {
    static let shared = BinanceCryptoService()
    
    private let baseURL = "https://api.binance.com/api/v3"
    
    private init() {}
    
    /// Fetch cryptocurrency prices using Binance ticker/price endpoint
    /// Fetches cryptos from binancePairsDict, maintaining original order
    /// - Parameter ids: CoinGecko IDs (for pagination) - will be converted to Binance symbols
    func fetchCryptoPrices(ids: [String]? = nil) async throws -> [Cryptocurrency] {
        // If ids provided, convert CoinGecko IDs to Binance symbols (for pagination)
        // Otherwise, get all Binance symbols from binancePairsDict in original order
        let binanceSymbols: [String]
        if let providedIds = ids, !providedIds.isEmpty {
            // Convert CoinGecko IDs to Binance symbols, maintaining the order of providedIds
            // This ensures the order matches mainCryptos order
            // Create a reverse map for efficient lookup: coinGeckoId (lowercase) -> binanceSymbol
            var idToSymbolMap: [String: String] = [:]
            for (symbol, coinGeckoId) in MainCryptoHelper.binancePairsDict {
                let lowercasedId = coinGeckoId.lowercased()
                // Only add if not already present (to handle duplicates)
                if idToSymbolMap[lowercasedId] == nil {
                    idToSymbolMap[lowercasedId] = symbol
                }
            }
            
            // Convert IDs to symbols in the same order as providedIds (mainCryptos order)
            binanceSymbols = providedIds.compactMap { idToSymbolMap[$0.lowercased()] }
        } else {
            // Get all Binance symbols in original order (as they appear in binancePairsDict)
            binanceSymbols = Array(MainCryptoHelper.binancePairsDict.keys)
        }
        
        guard !binanceSymbols.isEmpty else {
            LogManager.shared.log("No Binance symbols to fetch", level: .warning, source: "BinanceCryptoService")
            return []
        }
        
        LogManager.shared.log("Fetching \(binanceSymbols.count) Binance symbols (first 5: \(Array(binanceSymbols.prefix(5)).joined(separator: ", ")))", level: .info, source: "BinanceCryptoService")
        
        // Fetch prices
        let prices = try await fetchPrices(symbols: binanceSymbols)
        LogManager.shared.log("Fetched \(prices.count) prices from Binance", level: .info, source: "BinanceCryptoService")
        
        // Fetch 24h ticker data for price changes
        let tickers = try await fetch24hTickers(symbols: binanceSymbols)
        LogManager.shared.log("Fetched \(tickers.count) tickers from Binance", level: .info, source: "BinanceCryptoService")
        
        // Fetch sparklines (7 days of 1h klines) - fetch synchronously for now to ensure data is available
        var sparklines: [String: [Double]] = [:]
        for symbol in binanceSymbols {
            if let sparkline = try? await fetchSparkline(symbol: symbol) {
                sparklines[symbol] = sparkline
            }
        }
        LogManager.shared.log("Fetched \(sparklines.count) sparklines from Binance", level: .info, source: "BinanceCryptoService")
        
        // Get CoinGecko IDs for fetching image URLs
        let coinGeckoIds = binanceSymbols.compactMap { MainCryptoHelper.getCoinGeckoId(for: $0) }
        LogManager.shared.log("Fetching image URLs for \(coinGeckoIds.count) cryptos from CoinGecko", level: .info, source: "BinanceCryptoService")
        
        // Fetch image URLs from CoinGecko API (only for available cryptos)
        // This is necessary because CoinGecko uses internal IDs for image URLs, not the API IDs
        let coinGeckoService = CoinGeckoCryptoService.shared
        let coinGeckoCryptos = try? await coinGeckoService.fetchCryptoPrices(ids: coinGeckoIds)
        
        // Create a map of coinGeckoId -> image URL
        var imageURLMap: [String: String] = [:]
        if let coinGeckoCryptos = coinGeckoCryptos {
            for coinGeckoCrypto in coinGeckoCryptos {
                imageURLMap[coinGeckoCrypto.id] = coinGeckoCrypto.image
            }
            LogManager.shared.log("Fetched \(imageURLMap.count) image URLs from CoinGecko", level: .info, source: "BinanceCryptoService")
        } else {
            LogManager.shared.log("Failed to fetch image URLs from CoinGecko", level: .warning, source: "BinanceCryptoService")
        }
        
        // Convert Binance data to Cryptocurrency array, maintaining order of binanceSymbols
        var cryptocurrencies: [Cryptocurrency] = []
        
        for symbol in binanceSymbols {
            guard let priceData = prices.first(where: { $0.symbol == symbol }),
                  let coinGeckoId = MainCryptoHelper.getCoinGeckoId(for: symbol) else {
                continue
            }
            
            let price = Double(priceData.price) ?? 0.0
            let ticker = tickers.first(where: { $0.symbol == symbol })
            let priceChange24h = ticker?.priceChangePercent.flatMap { Double($0) }
            let sparklinePrices = sparklines[symbol]
            
            // Extract base symbol (e.g., "BTC" from "BTCUSDT")
            let baseSymbol = String(symbol.dropLast(4)).lowercased()
            
            // Get name from binancePairsDict
            let name = MainCryptoHelper.getName(for: symbol)?.capitalized ?? coinGeckoId.capitalized
            
            // Get image URL from CoinGecko API response (correct URL with internal ID)
            let imageURL = imageURLMap[coinGeckoId] ?? ""
            
            // Create Cryptocurrency object
            let crypto = Cryptocurrency(
                id: coinGeckoId,
                symbol: baseSymbol,
                name: name,
                image: imageURL,
                currentPrice: price,
                priceChangePercentage24h: priceChange24h,
                lastUpdated: ticker?.closeTime.map { String($0) },
                sparklineIn7d: sparklinePrices.map { SparklineIn7d(price: $0) }
            )
            
            cryptocurrencies.append(crypto)
        }
        
        LogManager.shared.log("Fetched \(cryptocurrencies.count) cryptocurrencies from Binance (first 5 IDs: \(Array(cryptocurrencies.prefix(5).map { $0.id }).joined(separator: ", ")))", level: .success, source: "BinanceCryptoService")
        
        return cryptocurrencies
    }
    
    /// Fetch a single cryptocurrency's data
    func fetchCrypto(id: String) async throws -> Cryptocurrency {
        guard let binanceSymbol = MainCryptoHelper.getSymbol(for: id) else {
            throw URLError(.resourceUnavailable)
        }
        
        // Fetch price
        let priceData = try await fetchPrice(symbol: binanceSymbol)
        let price = Double(priceData.price) ?? 0.0
        
        // Fetch 24h ticker
        let ticker = try await fetch24hTicker(symbol: binanceSymbol)
        let priceChange24h = ticker.priceChangePercent.flatMap { Double($0) }
        
        // Fetch sparkline
        let sparklinePrices = try? await fetchSparkline(symbol: binanceSymbol)
        
        // Extract base symbol
        let baseSymbol = String(binanceSymbol.dropLast(4)).lowercased()
        
        // Get name
        let name = MainCryptoHelper.getName(for: binanceSymbol)?.capitalized ?? id.capitalized
        
        // Get correct image URL from CoinGecko
        let coinGeckoService = CoinGeckoCryptoService.shared
        let coinGeckoCrypto = try? await coinGeckoService.fetchCrypto(id: id)
        let imageURL = coinGeckoCrypto?.image ?? ""
        
        return Cryptocurrency(
            id: id,
            symbol: baseSymbol,
            name: name,
            image: imageURL,
            currentPrice: price,
            priceChangePercentage24h: priceChange24h,
            lastUpdated: ticker.closeTime.map { String($0) },
            sparklineIn7d: sparklinePrices.map { SparklineIn7d(price: $0) }
        )
    }
    
    /// Fetch market chart data using Binance klines endpoint
    func fetchMarketChart(id: String, days: Int) async throws -> [ChartDataPoint] {
        guard let binanceSymbol = MainCryptoHelper.getSymbol(for: id) else {
            throw URLError(.resourceUnavailable)
        }
        
        // Map days to Binance interval and limit
        let (interval, limit) = getIntervalAndLimit(for: days)
        
        guard let url = URL(string: "\(baseURL)/klines?symbol=\(binanceSymbol)&interval=\(interval)&limit=\(limit)") else {
            throw URLError(.badURL)
        }
        
        // Log the full URL for debugging
        LogManager.shared.log("🔵 Binance API: GET \(url.absoluteString)", level: .debug, source: "BinanceCryptoService")
        
        let (data, response) = try await Task.detached(priority: .userInitiated) {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 30
            return try await URLSession.shared.data(for: request)
        }.value
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            LogManager.shared.log("Binance klines API error: \(httpResponse.statusCode)", level: .error, source: "BinanceCryptoService")
            throw URLError(.badServerResponse)
        }
        
        // Parse klines response: [[timestamp, open, high, low, close, volume, ...], ...]
        guard let klinesArray = try JSONSerialization.jsonObject(with: data) as? [[Any]] else {
            LogManager.shared.log("Failed to parse klines response", level: .error, source: "BinanceCryptoService")
            throw URLError(.cannotParseResponse)
        }
        
        // Convert to ChartDataPoint array (using close price at index 4)
        let chartData = klinesArray.compactMap { kline -> ChartDataPoint? in
            guard kline.count >= 5,
                  let timestampMs = kline[0] as? Double,
                  let closePriceString = kline[4] as? String,
                  let closePrice = Double(closePriceString) else {
                return nil
            }
            
            let date = Date(timeIntervalSince1970: timestampMs / 1000.0)
            return ChartDataPoint(timestamp: date, price: closePrice)
        }
        
        LogManager.shared.log("Fetched \(chartData.count) chart data points for \(id) (\(days) days) from Binance", level: .success, source: "BinanceCryptoService")
        
        return chartData
    }
    
    // MARK: - Private Helper Methods
    
    /// Fetch prices for multiple symbols
    private func fetchPrices(symbols: [String]) async throws -> [BinancePriceResponse] {
        // Binance API supports up to 100 symbols in one request
        // Format: symbols=["BTCUSDT","ETHUSDT"] as JSON array string
        let symbolsJSON = symbols.map { "\"\($0)\"" }.joined(separator: ",")
        let symbolsParam = "[\(symbolsJSON)]"
        
        // Use URLComponents to properly encode the query parameter
        guard var urlComponents = URLComponents(string: "\(baseURL)/ticker/price") else {
            throw URLError(.badURL)
        }
        urlComponents.queryItems = [
            URLQueryItem(name: "symbols", value: symbolsParam)
        ]
        
        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }
        
        // Log the full URL for debugging
        LogManager.shared.log("🔵 Binance API: GET \(url.absoluteString)", level: .debug, source: "BinanceCryptoService")
        
        let (data, response) = try await Task.detached(priority: .userInitiated) {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 30
            return try await URLSession.shared.data(for: request)
        }.value
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([BinancePriceResponse].self, from: data)
    }
    
    /// Fetch price for a single symbol
    private func fetchPrice(symbol: String) async throws -> BinancePriceResponse {
        guard let url = URL(string: "\(baseURL)/ticker/price?symbol=\(symbol)") else {
            throw URLError(.badURL)
        }
        
        // Log the full URL for debugging
        LogManager.shared.log("🔵 Binance API: GET \(url.absoluteString)", level: .debug, source: "BinanceCryptoService")
        
        let (data, response) = try await Task.detached(priority: .userInitiated) {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 30
            return try await URLSession.shared.data(for: request)
        }.value
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(BinancePriceResponse.self, from: data)
    }
    
    /// Fetch 24h ticker data for multiple symbols
    private func fetch24hTickers(symbols: [String]) async throws -> [Binance24hTickerResponse] {
        // Process in batches to avoid URL length issues
        var allTickers: [Binance24hTickerResponse] = []
        
        for symbol in symbols {
            if let ticker = try? await fetch24hTicker(symbol: symbol) {
                allTickers.append(ticker)
            }
        }
        
        return allTickers
    }
    
    /// Fetch 24h ticker data for a single symbol
    private func fetch24hTicker(symbol: String) async throws -> Binance24hTickerResponse {
        guard let url = URL(string: "\(baseURL)/ticker/24hr?symbol=\(symbol)") else {
            throw URLError(.badURL)
        }
        
        // Log the full URL for debugging
        LogManager.shared.log("🔵 Binance API: GET \(url.absoluteString)", level: .debug, source: "BinanceCryptoService")
        
        let (data, response) = try await Task.detached(priority: .userInitiated) {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 30
            return try await URLSession.shared.data(for: request)
        }.value
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(Binance24hTickerResponse.self, from: data)
    }
    
    /// Fetch sparkline data (7 days of 1h klines)
    private func fetchSparkline(symbol: String) async throws -> [Double] {
        guard let url = URL(string: "\(baseURL)/klines?symbol=\(symbol)&interval=1h&limit=168") else {
            throw URLError(.badURL)
        }
        
        // Log the full URL for debugging
        LogManager.shared.log("🔵 Binance API: GET \(url.absoluteString)", level: .debug, source: "BinanceCryptoService")
        
        let (data, response) = try await Task.detached(priority: .userInitiated) {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 30
            return try await URLSession.shared.data(for: request)
        }.value
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        guard let klinesArray = try JSONSerialization.jsonObject(with: data) as? [[Any]] else {
            throw URLError(.cannotParseResponse)
        }
        
        // Extract close prices (index 4)
        return klinesArray.compactMap { kline in
            guard kline.count >= 5,
                  let closePriceString = kline[4] as? String else {
                return nil
            }
            return Double(closePriceString)
        }
    }
    
    /// Map days to Binance interval and limit
    private func getIntervalAndLimit(for days: Int) -> (interval: String, limit: Int) {
        switch days {
        case 1:
            return ("1h", 24) // 1 day = 24 hours
        case 7:
            return ("1d", 7) // 7 days
        case 30:
            return ("1d", 30) // 1 month
        case 90:
            return ("1d", 90) // 3 months
        case 180:
            return ("1d", 180) // 6 months
        case 365:
            return ("1d", 365) // 1 year (Binance max is 1000)
        default:
            return ("1d", min(days, 1000))
        }
    }
}

// MARK: - Binance API Response Models

private struct BinancePriceResponse: Codable {
    let symbol: String
    let price: String
}

private struct Binance24hTickerResponse: Codable {
    let symbol: String
    let priceChangePercent: String?
    let closeTime: Int64?
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case priceChangePercent
        case closeTime
    }
}

