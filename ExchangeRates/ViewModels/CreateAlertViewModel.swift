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
    case above = "מעל"
    case below = "מתחת"
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
            errorMessage = "ערך יעד לא תקין"
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
            errorMessage = "נא לבחור מטבע בסיס"
            return false
        }
        
        guard !targetCurrency.isEmpty else {
            errorMessage = "נא לבחור מטבע יעד"
            return false
        }
        
        guard baseCurrency != targetCurrency else {
            errorMessage = "מטבע בסיס ומטבע יעד חייבים להיות שונים"
            return false
        }
        
        guard !targetValue.isEmpty else {
            errorMessage = "נא להזין ערך יעד"
            return false
        }
        
        guard let value = Decimal(string: targetValue), value > 0 else {
            errorMessage = "ערך יעד חייב להיות מספר חיובי"
            return false
        }
        
        return true
    }
    
    func getAvailableCurrencies() -> [String] {
        return cachedCurrencies
    }
    
    private func computeAvailableCurrencies() -> [String] {
        // Main currencies (14 main currencies) - shown first
        let mainCurrencies = MainCurrenciesHelper.mainCurrencies
        
        // Custom currencies added by user
        let customCurrencies = CustomCurrencyManager.shared.getCustomCurrencies()
        
        // All other currencies from Locale
        let allLocaleCurrencies = Locale.commonISOCurrencyCodes
        
        // Combine all and remove duplicates
        let allCurrenciesSet = Set(mainCurrencies + customCurrencies + allLocaleCurrencies)
        
        // Separate into main, custom, and others
        let mainSet = Set(mainCurrencies)
        let customSet = Set(customCurrencies)
        let othersSet = allCurrenciesSet.subtracting(mainSet).subtracting(customSet)
        
        // Return: main currencies first (in order), then custom, then others (sorted)
        return mainCurrencies.filter { allCurrenciesSet.contains($0) } +
               customCurrencies.sorted() +
               Array(othersSet).sorted()
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
                    print("⚠️ [CreateAlertViewModel] Failed to load current rate: \(error.localizedDescription)")
                }
            }
        }
    }
}

