//
//  CreateAlertViewModel.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import Foundation
import SwiftUI
import Combine

enum ConditionType: String, CaseIterable {
    case above = "above"
    case below = "below"
    
    var localizedDisplayName: String {
        switch self {
        case .above:
            return String(localized: "above", defaultValue: "Above")
        case .below:
            return String(localized: "below", defaultValue: "Below")
        }
    }
}

class CreateAlertViewModel: ObservableObject {
    @Published var baseCurrency: String = "" {
        didSet {
            if !baseCurrency.isEmpty && !targetCurrency.isEmpty && oldValue != baseCurrency {
                loadCurrentRate()
            }
        }
    }
    @Published var targetCurrency: String = "" {
        didSet {
            if !baseCurrency.isEmpty && !targetCurrency.isEmpty && oldValue != targetCurrency {
                loadCurrentRate()
            }
        }
    }
    @Published var conditionType: ConditionType = .above
    @Published var targetValue: String = ""
    @Published var isEnabled: Bool = true
    @Published var autoResetHours: Int? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentRate: Double?
    @Published var isLoadingRate: Bool = false
    
    private let alertManager = CurrencyAlertManager.shared
    private let alertChecker = AlertCheckerService.shared
    var editingAlert: CurrencyAlert?
    
    // Cached currencies list - computed once on initialization
    private lazy var cachedCurrencies: [String] = computeAvailableCurrencies()
    
    init(editingAlert: CurrencyAlert? = nil) {
        self.editingAlert = editingAlert
        if let alert = editingAlert {
            loadAlertForEditing(alert)
        }
    }
    
    func loadAlertForEditing(_ alert: CurrencyAlert) {
        baseCurrency = alert.baseCurrency
        targetCurrency = alert.targetCurrency
        switch alert.condition {
        case .above:
            conditionType = .above
        case .below:
            conditionType = .below
        }
        targetValue = String(describing: alert.targetValue)
        isEnabled = alert.isEnabled
        autoResetHours = alert.autoResetAfterHours
        editingAlert = alert
        
        // Load current rate when editing
        if !baseCurrency.isEmpty && !targetCurrency.isEmpty {
            loadCurrentRate()
        }
    }
    
    func saveAlert() -> Bool {
        guard validateInput() else {
            return false
        }
        
        guard let targetValueDecimal = Decimal(string: targetValue) else {
            errorMessage = String(localized: "invalid_target_value", defaultValue: "Invalid target value")
            return false
        }
        
        // Update condition with the target value
        let updatedCondition: AlertCondition
        let targetDouble = Double(truncating: targetValueDecimal as NSDecimalNumber)
        switch conditionType {
        case .above:
            updatedCondition = .above(targetDouble)
        case .below:
            updatedCondition = .below(targetDouble)
        }
        
        let alert: CurrencyAlert
        if let editing = editingAlert {
            // Update existing alert
            alert = CurrencyAlert(
                id: editing.id,
                baseCurrency: baseCurrency,
                targetCurrency: targetCurrency,
                condition: updatedCondition,
                targetValue: targetValueDecimal,
                isEnabled: isEnabled,
                status: editing.status,
                triggeredAt: editing.triggeredAt,
                createdAt: editing.createdAt,
                autoResetAfterHours: autoResetHours
            )
        } else {
            // Create new alert
            alert = CurrencyAlert(
                baseCurrency: baseCurrency,
                targetCurrency: targetCurrency,
                condition: updatedCondition,
                targetValue: targetValueDecimal,
                isEnabled: isEnabled,
                autoResetAfterHours: autoResetHours
            )
        }
        
        alertManager.saveAlert(alert)
        return true
    }
    
    func validateInput() -> Bool {
        errorMessage = nil
        
        guard !baseCurrency.isEmpty else {
            errorMessage = String(localized: "please_select_base_currency", defaultValue: "Please select a base currency")
            return false
        }
        
        guard !targetCurrency.isEmpty else {
            errorMessage = String(localized: "please_select_target_currency", defaultValue: "Please select a target currency")
            return false
        }
        
        guard baseCurrency != targetCurrency else {
            errorMessage = String(localized: "base_and_target_must_differ", defaultValue: "Base currency and target currency must be different")
            return false
        }
        
        guard !targetValue.isEmpty else {
            errorMessage = String(localized: "please_enter_target_value", defaultValue: "Please enter a target value")
            return false
        }
        
        guard let value = Decimal(string: targetValue), value > 0 else {
            errorMessage = String(localized: "target_value_must_be_positive", defaultValue: "Target value must be a positive number")
            return false
        }
        
        return true
    }
    
    func getAvailableCurrencies() -> [String] {
        return cachedCurrencies
    }
    
    private func computeAvailableCurrencies() -> [String] {
        let customCurrencies = CustomCurrencyManager.shared.getCustomCurrencies()
        return MainCurrenciesHelper.getAllCurrenciesIncludingCustom(customCurrencies: customCurrencies)
    }
    
    func loadCurrentRate() {
        guard !baseCurrency.isEmpty, !targetCurrency.isEmpty, baseCurrency != targetCurrency else {
            currentRate = nil
            return
        }
        
        isLoadingRate = true
        
        Task {
            do {
                let rate = try await alertChecker.fetchRateForPair(
                    base: baseCurrency,
                    target: targetCurrency
                )
                await MainActor.run {
                    currentRate = rate.currentExchangeRate
                    isLoadingRate = false
                }
            } catch {
                await MainActor.run {
                    currentRate = nil
                    isLoadingRate = false
                    LogManager.shared.log("Failed to load current rate: \(error.localizedDescription)", level: .warning, source: "CreateAlertViewModel")
                }
            }
        }
    }
    
    func swapCurrencies() {
        guard !baseCurrency.isEmpty && !targetCurrency.isEmpty && baseCurrency != targetCurrency else {
            return
        }
        
        // Swap currencies
        let tempCurrency = baseCurrency
        baseCurrency = targetCurrency
        targetCurrency = tempCurrency
        
        // Invert the current rate
        if let rate = currentRate, rate > 0 {
            currentRate = 1.0 / rate
        }
        
        // Invert the target value
        if let targetValueDecimal = Decimal(string: targetValue), targetValueDecimal > 0 {
            let invertedValue = Decimal(1) / targetValueDecimal
            targetValue = String(describing: invertedValue)
        }
        
        // Swap condition type (above ↔ below)
        conditionType = conditionType == .above ? .below : .above
    }
}

