//
//  DataCacheManager.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 02/01/2026.
//

import Foundation

class DataCacheManager {
    static let shared = DataCacheManager()
    
    private let userDefaults = UserDefaults.standard
    
    // Keys for cached data
    private let cachedExchangeRatesKey = "cachedExchangeRates"
    private let cachedCustomExchangeRatesKey = "cachedCustomExchangeRates"
    private let cachedCryptocurrenciesKey = "cachedCryptocurrencies"
    private let lastExchangeRatesUpdateKey = "lastExchangeRatesUpdate"
    private let lastCryptocurrenciesUpdateKey = "lastCryptocurrenciesUpdate"
    
    private init() {}
    
    // MARK: - Exchange Rates
    
    func saveExchangeRates(_ rates: [ExchangeRate]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(rates)
            userDefaults.set(data, forKey: cachedExchangeRatesKey)
            userDefaults.set(Date(), forKey: lastExchangeRatesUpdateKey)
            LogManager.shared.log("Saved \(rates.count) exchange rates to cache", level: .success, source: "DataCacheManager")
        } catch {
            LogManager.shared.log("Failed to encode exchange rates: \(error)", level: .error, source: "DataCacheManager")
        }
    }
    
    func loadExchangeRates() -> [ExchangeRate] {
        guard let data = userDefaults.data(forKey: cachedExchangeRatesKey) else {
            LogManager.shared.log("No cached exchange rates found", level: .info, source: "DataCacheManager")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let rates = try decoder.decode([ExchangeRate].self, from: data)
            LogManager.shared.log("Loaded \(rates.count) exchange rates from cache", level: .success, source: "DataCacheManager")
            return rates
        } catch {
            LogManager.shared.log("Failed to decode exchange rates: \(error)", level: .error, source: "DataCacheManager")
            return []
        }
    }
    
    func saveCustomExchangeRates(_ rates: [ExchangeRate]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(rates)
            userDefaults.set(data, forKey: cachedCustomExchangeRatesKey)
            // Update the same timestamp as main rates since they're loaded together
            userDefaults.set(Date(), forKey: lastExchangeRatesUpdateKey)
            LogManager.shared.log("Saved \(rates.count) custom exchange rates to cache", level: .success, source: "DataCacheManager")
        } catch {
            LogManager.shared.log("Failed to encode custom exchange rates: \(error)", level: .error, source: "DataCacheManager")
        }
    }
    
    func loadCustomExchangeRates() -> [ExchangeRate] {
        guard let data = userDefaults.data(forKey: cachedCustomExchangeRatesKey) else {
            LogManager.shared.log("No cached custom exchange rates found", level: .info, source: "DataCacheManager")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let rates = try decoder.decode([ExchangeRate].self, from: data)
            LogManager.shared.log("Loaded \(rates.count) custom exchange rates from cache", level: .success, source: "DataCacheManager")
            return rates
        } catch {
            LogManager.shared.log("Failed to decode custom exchange rates: \(error)", level: .error, source: "DataCacheManager")
            return []
        }
    }
    
    func getLastExchangeRatesUpdateDate() -> Date? {
        return userDefaults.object(forKey: lastExchangeRatesUpdateKey) as? Date
    }
    
    // MARK: - Cryptocurrencies
    
    func saveCryptocurrencies(_ cryptos: [Cryptocurrency]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(cryptos)
            userDefaults.set(data, forKey: cachedCryptocurrenciesKey)
            userDefaults.set(Date(), forKey: lastCryptocurrenciesUpdateKey)
            LogManager.shared.log("Saved \(cryptos.count) cryptocurrencies to cache", level: .success, source: "DataCacheManager")
        } catch {
            LogManager.shared.log("Failed to encode cryptocurrencies: \(error)", level: .error, source: "DataCacheManager")
        }
    }
    
    func loadCryptocurrencies() -> [Cryptocurrency] {
        guard let data = userDefaults.data(forKey: cachedCryptocurrenciesKey) else {
            LogManager.shared.log("No cached cryptocurrencies found", level: .info, source: "DataCacheManager")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let cryptos = try decoder.decode([Cryptocurrency].self, from: data)
            LogManager.shared.log("Loaded \(cryptos.count) cryptocurrencies from cache", level: .success, source: "DataCacheManager")
            return cryptos
        } catch {
            LogManager.shared.log("Failed to decode cryptocurrencies: \(error)", level: .error, source: "DataCacheManager")
            return []
        }
    }
    
    func getLastCryptocurrenciesUpdateDate() -> Date? {
        return userDefaults.object(forKey: lastCryptocurrenciesUpdateKey) as? Date
    }
    
    // MARK: - Combined Last Update Date
    
    /// Get the most recent update date between exchange rates and cryptocurrencies
    func getLastUpdateDate() -> Date? {
        let exchangeRatesDate = getLastExchangeRatesUpdateDate()
        let cryptocurrenciesDate = getLastCryptocurrenciesUpdateDate()
        
        if let exchangeRatesDate = exchangeRatesDate, let cryptocurrenciesDate = cryptocurrenciesDate {
            return max(exchangeRatesDate, cryptocurrenciesDate)
        } else if let exchangeRatesDate = exchangeRatesDate {
            return exchangeRatesDate
        } else if let cryptocurrenciesDate = cryptocurrenciesDate {
            return cryptocurrenciesDate
        }
        return nil
    }
}






