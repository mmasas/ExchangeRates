//
//  AlertCheckerService.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import Foundation

class AlertCheckerService {
    static let shared = AlertCheckerService()
    
    private let alertManager = CurrencyAlertManager.shared
    private let customCurrencyService = CustomCurrencyService.shared
    
    private init() {}
    
    /// Checks all active alerts and returns those that were triggered
    func checkAlerts() async throws -> [CurrencyAlert] {
        let activeAlerts = alertManager.getActiveAlerts()
        var triggeredAlerts: [CurrencyAlert] = []
        
        LogManager.shared.log("Checking \(activeAlerts.count) active alerts", level: .info, source: "AlertCheckerService")
        
        // Check each alert
        for alert in activeAlerts {
            do {
                // Fetch current rate for the currency pair
                let currentRate = try await fetchRateForPair(
                    base: alert.baseCurrency,
                    target: alert.targetCurrency
                )
                
                let rate = currentRate.currentExchangeRate
                let targetValue = Double(truncating: alert.targetValue as NSDecimalNumber)
                
                LogManager.shared.log("Alert \(alert.currencyPair): current=\(rate), target=\(targetValue), condition=\(alert.condition.displayName)", level: .info, source: "AlertCheckerService")
                
                // Check if alert condition is satisfied
                if alert.condition.isSatisfied(by: rate) {
                    // Alert triggered
                    var triggeredAlert = alert
                    triggeredAlert.markAsTriggered()
                    alertManager.updateAlert(triggeredAlert)
                    triggeredAlerts.append(triggeredAlert)
                    LogManager.shared.log("Alert TRIGGERED: \(alert.currencyPair)", level: .success, source: "AlertCheckerService")
                } else {
                    LogManager.shared.log("Alert not triggered: \(alert.currencyPair)", level: .info, source: "AlertCheckerService")
                }
            } catch {
                LogManager.shared.log("Failed to check alert \(alert.id): \(error.localizedDescription)", level: .warning, source: "AlertCheckerService")
                // Continue checking other alerts even if one fails
            }
        }
        
        // Check for auto-reset
        await checkAutoReset()
        
        LogManager.shared.log("Total triggered: \(triggeredAlerts.count)", level: .info, source: "AlertCheckerService")
        return triggeredAlerts
    }
    
    /// Checks a single alert condition against a current rate
    func checkAlert(_ alert: CurrencyAlert, currentRate: Double) -> Bool {
        return alert.condition.isSatisfied(by: currentRate)
    }
    
    /// Fetches exchange rate for any currency pair
    func fetchRateForPair(base: String, target: String) async throws -> ExchangeRate {
        // Use CustomCurrencyService which supports any currency pair
        return try await customCurrencyService.fetchExchangeRate(for: base, target: target)
    }
    
    /// Checks and resets alerts that have passed their auto-reset time
    private func checkAutoReset() async {
        let allAlerts = alertManager.getAllAlerts()
        let now = Date()
        
        for alert in allAlerts {
            guard alert.status == .triggered,
                  let triggeredAt = alert.triggeredAt,
                  let autoResetHours = alert.autoResetAfterHours else {
                continue
            }
            
            let hoursSinceTrigger = now.timeIntervalSince(triggeredAt) / 3600
            if hoursSinceTrigger >= Double(autoResetHours) {
                var resetAlert = alert
                resetAlert.reset()
                alertManager.updateAlert(resetAlert)
                LogManager.shared.log("Auto-reset alert \(alert.id) after \(autoResetHours) hours", level: .success, source: "AlertCheckerService")
            }
        }
    }
}

