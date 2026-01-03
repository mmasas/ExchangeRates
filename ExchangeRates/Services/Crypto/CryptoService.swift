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
}

