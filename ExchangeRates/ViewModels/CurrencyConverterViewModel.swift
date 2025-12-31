//
//  CurrencyConverterViewModel.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 26/12/2025.
//

import Foundation
import SwiftUI
import Combine

class CurrencyConverterViewModel: ObservableObject {
    let exchangeRate: ExchangeRate
    
    @Published var homeAmount: String = ""
    @Published var foreignAmount: String = ""
    
    private var isUpdatingFromHome = false
    private var isUpdatingFromForeign = false
    
    private let homeCurrency: String
    
    init(exchangeRate: ExchangeRate) {
        self.exchangeRate = exchangeRate
        self.homeCurrency = HomeCurrencyManager.shared.getHomeCurrency()
    }
    
    var homeCurrencyCode: String {
        return homeCurrency
    }
    
    // Convert home currency to foreign currency
    func convertFromHome(_ amount: Double) {
        guard !isUpdatingFromForeign else { return }
        isUpdatingFromHome = true
        
        // Handle unit: if unit > 1, the rate is for that many units
        // For example, JPY unit=100 means the rate is for 100 yen
        let ratePerUnit = exchangeRate.currentExchangeRate / Double(exchangeRate.unit)
        let converted = amount / ratePerUnit
        
        // Only update the converted field (foreignAmount), not the input field (homeAmount)
        foreignAmount = formatAmount(converted)
        isUpdatingFromHome = false
    }
    
    // Convert foreign currency to home currency
    func convertToHome(_ amount: Double) {
        guard !isUpdatingFromHome else { return }
        isUpdatingFromForeign = true
        
        // Handle unit: if unit > 1, the rate is for that many units
        let ratePerUnit = exchangeRate.currentExchangeRate / Double(exchangeRate.unit)
        let converted = amount * ratePerUnit
        
        // Only update the converted field (homeAmount), not the input field (foreignAmount)
        homeAmount = formatAmount(converted)
        isUpdatingFromForeign = false
    }
    
    // Format amount for display
    private func formatAmount(_ amount: Double) -> String {
        if amount == 0 {
            return ""
        }
        
        // Use appropriate decimal places based on amount size
        if amount >= 1000 {
            return String(format: "%.2f", amount)
        } else if amount >= 1 {
            return String(format: "%.2f", amount)
        } else if amount >= 0.01 {
            return String(format: "%.4f", amount)
        } else {
            return String(format: "%.6f", amount)
        }
    }
    
    // Update home currency amount and convert
    func updateHomeAmount(_ value: String) {
        // Don't update if this is coming from the conversion (circular update)
        guard !isUpdatingFromForeign else { return }
        
        // Allow user to type freely - don't format the input field
        homeAmount = value
        
        // Only update the converted field if we have a valid number
        if let amount = Double(value), amount > 0 {
            convertFromHome(amount)
        } else {
            // Clear the other field if input is empty or invalid
            foreignAmount = ""
        }
    }
    
    // Update foreign amount and convert
    func updateForeignAmount(_ value: String) {
        // Don't update if this is coming from the conversion (circular update)
        guard !isUpdatingFromHome else { return }
        
        // Allow user to type freely - don't format the input field
        foreignAmount = value
        
        // Only update the converted field if we have a valid number
        if let amount = Double(value), amount > 0 {
            convertToHome(amount)
        } else {
            // Clear the other field if input is empty or invalid
            homeAmount = ""
        }
    }
}

