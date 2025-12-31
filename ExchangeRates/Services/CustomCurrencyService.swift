//
//  CustomCurrencyService.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import Foundation

struct HexarateResponse: Codable {
    let statusCode: Int
    let data: HexarateData
    
    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case data
    }
}

struct HexarateData: Codable {
    let base: String
    let target: String
    let mid: Double
    let unit: Int
    let timestamp: String
}

class CustomCurrencyService {
    static let shared = CustomCurrencyService()
    
    private init() {}
    
    func fetchExchangeRate(for currencyCode: String, target: String) async throws -> ExchangeRate {
        guard let url = URL(string: "https://hexarate.paikama.co/api/rates/\(currencyCode)/\(target)/latest") else {
            throw URLError(.badURL)
        }
        
        // Use Task.detached to ensure request completes even if parent task is cancelled
        // This prevents SwiftUI's refreshable from cancelling the network request
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
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let hexarateResponse = try decoder.decode(HexarateResponse.self, from: data)
        
        // Convert hexarate response to ExchangeRate format
        // hexarate returns: base -> target with mid rate
        // Example: base=THB, target=USD, mid=0.031 means 1 THB = 0.031 USD
        // Our ExchangeRate stores "target per currency unit", so we use mid directly
        // Note: The API endpoint is {CURRENCY}/{TARGET}, so mid is already "target per currency unit"
        let exchangeRate = ExchangeRate(
            key: currencyCode,
            currentExchangeRate: hexarateResponse.data.mid,
            currentChange: 0.0, // No change tracking for custom currencies
            unit: hexarateResponse.data.unit,
            lastUpdate: hexarateResponse.data.timestamp
        )
        
        return exchangeRate
    }
}
