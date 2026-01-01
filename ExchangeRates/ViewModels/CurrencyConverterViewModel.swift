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
    
    // Track which field is being actively edited
    private var activeField: ActiveField = .none
    
    private enum ActiveField {
        case none, home, foreign
    }
    
    private let homeCurrency: String
    
    init(exchangeRate: ExchangeRate) {
        self.exchangeRate = exchangeRate
        self.homeCurrency = HomeCurrencyManager.shared.getHomeCurrency()
    }
    
    var homeCurrencyCode: String {
        return homeCurrency
    }
    
    // Format amount for display
    private func formatAmount(_ amount: Double) -> String {
        if amount == 0 {
            return ""
        }
        
        // Use 3 decimal places like exchange rates to avoid precision mismatches
        if amount >= 1 {
            return String(format: "%.3f", amount)
        } else if amount >= 0.001 {
            return String(format: "%.4f", amount)
        } else {
            return String(format: "%.6f", amount)
        }
    }
    
    // Update home currency amount and convert
    func updateHomeAmount(_ value: String) {
        // If we're updating from foreign conversion, ignore
        guard activeField != .foreign else { return }
        
        // Mark home field as active
        activeField = .home
        
        // Allow user to type freely - don't format the input field
        homeAmount = value
        
        // Only update the converted field if we have a valid number
        if let amount = Double(value), amount > 0 {
            // Handle unit: if unit > 1, the rate is for that many units
            let ratePerUnit = exchangeRate.currentExchangeRate / Double(exchangeRate.unit)
            let converted = amount / ratePerUnit
            foreignAmount = formatAmount(converted)
        } else {
            // Clear the other field if input is empty or invalid
            foreignAmount = ""
        }
        
        // Reset active field after a short delay to allow SwiftUI to settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if self?.activeField == .home {
                self?.activeField = .none
            }
        }
    }
    
    // Update foreign amount and convert
    func updateForeignAmount(_ value: String) {
        // If we're updating from home conversion, ignore
        guard activeField != .home else { return }
        
        // Mark foreign field as active
        activeField = .foreign
        
        // Allow user to type freely - don't format the input field
        foreignAmount = value
        
        // Only update the converted field if we have a valid number
        if let amount = Double(value), amount > 0 {
            // Handle unit: if unit > 1, the rate is for that many units
            let ratePerUnit = exchangeRate.currentExchangeRate / Double(exchangeRate.unit)
            let converted = amount * ratePerUnit
            homeAmount = formatAmount(converted)
        } else {
            // Clear the other field if input is empty or invalid
            homeAmount = ""
        }
        
        // Reset active field after a short delay to allow SwiftUI to settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if self?.activeField == .foreign {
                self?.activeField = .none
            }
        }
    }
}

