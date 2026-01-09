//
//  StandaloneConverterViewModel.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 09/01/2026.
//

import Foundation
import SwiftUI
import Combine

class StandaloneConverterViewModel: ObservableObject {
    @Published var sourceCurrency: String
    @Published var targetCurrency: String
    @Published var sourceAmount: String = ""
    @Published var targetAmount: String = ""
    
    private var exchangeRates: [ExchangeRate]
    private let homeCurrency: String
    
    // Track which field is being actively edited
    private var activeField: ActiveField = .none
    
    private enum ActiveField {
        case none, source, target
    }
    
    init(exchangeRates: [ExchangeRate]) {
        self.exchangeRates = exchangeRates
        self.homeCurrency = HomeCurrencyManager.shared.getHomeCurrency()
        
        // Default source to USD, target to home currency
        self.sourceCurrency = "USD"
        self.targetCurrency = homeCurrency
        
        // If home currency is USD, set target to EUR
        if homeCurrency == "USD" {
            self.targetCurrency = "EUR"
        }
    }
    
    /// Update exchange rates (called when rates refresh)
    func updateRates(_ rates: [ExchangeRate]) {
        self.exchangeRates = rates
        // Recalculate conversion with new rates
        if !sourceAmount.isEmpty {
            updateSourceAmount(sourceAmount)
        }
    }
    
    /// Get rate for a currency relative to home currency
    private func getRate(for currencyCode: String) -> Double? {
        // If currency is home currency, rate is 1
        if currencyCode == homeCurrency {
            return 1.0
        }
        
        // Find the exchange rate for this currency
        guard let rate = exchangeRates.first(where: { $0.key == currencyCode }) else {
            return nil
        }
        
        // Return rate per unit
        return rate.currentExchangeRate / Double(rate.unit)
    }
    
    /// Calculate cross rate between two currencies
    /// Returns how many target units you get for 1 source unit
    func getCrossRate() -> Double? {
        guard let sourceRate = getRate(for: sourceCurrency),
              let targetRate = getRate(for: targetCurrency) else {
            return nil
        }
        
        // Cross rate: source/target
        // If USD rate is 3.68 ILS and EUR rate is 3.92 ILS
        // Then 1 USD = 3.68/3.92 = 0.939 EUR
        return sourceRate / targetRate
    }
    
    /// Formatted cross rate string for display
    var formattedCrossRate: String {
        guard let rate = getCrossRate() else {
            return "-"
        }
        
        if rate >= 1.0 {
            return String(format: "%.4f", rate)
        } else {
            return String(format: "%.6f", rate)
        }
    }
    
    /// Swap source and target currencies
    func swapCurrencies() {
        let temp = sourceCurrency
        sourceCurrency = targetCurrency
        targetCurrency = temp
        
        // Also swap amounts
        let tempAmount = sourceAmount
        sourceAmount = targetAmount
        targetAmount = tempAmount
    }
    
    // Format amount for display
    private func formatAmount(_ amount: Double) -> String {
        if amount == 0 {
            return ""
        }
        
        // Use appropriate decimal places based on value
        if amount >= 1 {
            return String(format: "%.3f", amount)
        } else if amount >= 0.001 {
            return String(format: "%.4f", amount)
        } else {
            return String(format: "%.6f", amount)
        }
    }
    
    /// Update source amount and convert to target
    func updateSourceAmount(_ value: String) {
        // If we're updating from target conversion, ignore
        guard activeField != .target else { return }
        
        // Mark source field as active
        activeField = .source
        
        // Allow user to type freely
        sourceAmount = value
        
        // Only update the converted field if we have a valid number
        if let amount = Double(value), amount > 0 {
            if let crossRate = getCrossRate() {
                let converted = amount * crossRate
                targetAmount = formatAmount(converted)
            }
        } else {
            targetAmount = ""
        }
        
        // Reset active field after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if self?.activeField == .source {
                self?.activeField = .none
            }
        }
    }
    
    /// Update target amount and convert to source
    func updateTargetAmount(_ value: String) {
        // If we're updating from source conversion, ignore
        guard activeField != .source else { return }
        
        // Mark target field as active
        activeField = .target
        
        // Allow user to type freely
        targetAmount = value
        
        // Only update the converted field if we have a valid number
        if let amount = Double(value), amount > 0 {
            if let crossRate = getCrossRate(), crossRate > 0 {
                let converted = amount / crossRate
                sourceAmount = formatAmount(converted)
            }
        } else {
            sourceAmount = ""
        }
        
        // Reset active field after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if self?.activeField == .target {
                self?.activeField = .none
            }
        }
    }
    
    /// Get list of available currencies for picker
    func getAvailableCurrencies() -> [String] {
        // Get currencies from exchange rates
        var currencies = exchangeRates.map { $0.key }
        
        // Add home currency if not already present
        if !currencies.contains(homeCurrency) {
            currencies.append(homeCurrency)
        }
        
        // Sort with main currencies first
        return MainCurrenciesHelper.sortCurrencies(currencies)
    }
}
