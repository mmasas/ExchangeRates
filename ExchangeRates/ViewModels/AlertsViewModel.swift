//
//  AlertsViewModel.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import Foundation
import Combine
import UserNotifications
import UIKit

class AlertsViewModel: ObservableObject {
    @Published var alerts: [CurrencyAlert] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let alertManager = CurrencyAlertManager.shared
    private let alertChecker = AlertCheckerService.shared
    private let notificationService = NotificationService.shared
    
    var currencyAlerts: [CurrencyAlert] {
        alerts.filter { $0.alertType == .currency }
    }
    
    var cryptoAlerts: [CurrencyAlert] {
        alerts.filter { $0.alertType == .crypto }
    }
    
    var triggeredAlertsCount: Int {
        alerts.filter { $0.status == .triggered }.count
    }
    
    init() {
        loadAlerts()
    }
    
    func loadAlerts() {
        alerts = alertManager.getAllAlerts()
        updateBadge()
    }
    
    private func updateBadge() {
        let count = triggeredAlertsCount
        notificationService.setBadge(count: count)
        // Notify MainTabView to update badge
        NotificationCenter.default.post(name: NSNotification.Name("AlertsUpdated"), object: nil)
    }
    
    func deleteAlert(_ id: UUID) {
        alertManager.deleteAlert(id)
        // Update array directly to preserve scroll position
        alerts.removeAll { $0.id == id }
        updateBadge()
    }
    
    func toggleAlert(_ id: UUID) {
        guard let index = alerts.firstIndex(where: { $0.id == id }) else { return }
        var alert = alerts[index]
        alert.toggleEnabled()
        alertManager.updateAlert(alert)
        // Update array directly to preserve scroll position
        alerts[index] = alert
        updateBadge()
    }
    
    func resetAlert(_ id: UUID) {
        guard let index = alerts.firstIndex(where: { $0.id == id }) else { return }
        var alert = alerts[index]
        alert.reset()
        alertManager.updateAlert(alert)
        // Update array directly to preserve scroll position
        alerts[index] = alert
        updateBadge()
    }
    
    func checkAlertsNow() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Check notification permission first
            let status = await notificationService.getAuthorizationStatus()
            if status != .authorized {
                // Request permission if not authorized
                let hasPermission = await notificationService.requestPermission()
                if !hasPermission {
                    await MainActor.run {
                        errorMessage = String(localized: "notification_permission_required", defaultValue: "Notification permission is required to check alerts. Please enable notifications in Settings.")
                        isLoading = false
                    }
                    return
                }
            }
            
            let triggeredAlerts = try await alertChecker.checkAlerts()
            
            LogManager.shared.log("Found \(triggeredAlerts.count) triggered alerts", level: .info, source: "AlertsViewModel")
            
            // Send notifications for triggered alerts
            for alert in triggeredAlerts {
                let currentRate: Double
                if alert.alertType == .crypto {
                    // Fetch crypto price
                    guard let cryptoId = alert.cryptoId else {
                        LogManager.shared.log("Crypto alert \(alert.id) missing cryptoId", level: .warning, source: "AlertsViewModel")
                        continue
                    }
                    currentRate = try await alertChecker.fetchCryptoPrice(id: cryptoId)
                    LogManager.shared.log("Sending notification for \(alert.currencyPair) at price \(currentRate)", level: .info, source: "AlertsViewModel")
                } else {
                    // Fetch currency rate
                    let rate = try await alertChecker.fetchRateForPair(
                        base: alert.baseCurrency,
                        target: alert.targetCurrency
                    )
                    currentRate = rate.currentExchangeRate
                    LogManager.shared.log("Sending notification for \(alert.currencyPair) at rate \(currentRate)", level: .info, source: "AlertsViewModel")
                }
                notificationService.scheduleNotification(
                    for: alert,
                    currentRate: currentRate
                )
            }
            
            await MainActor.run {
                loadAlerts()
                isLoading = false
                if !triggeredAlerts.isEmpty {
                    errorMessage = nil // Success - alerts triggered
                    LogManager.shared.log("Successfully checked alerts, \(triggeredAlerts.count) triggered", level: .success, source: "AlertsViewModel")
                } else {
                    LogManager.shared.log("No alerts triggered", level: .info, source: "AlertsViewModel")
                }
                // Badge is updated in loadAlerts()
            }
        } catch {
            await MainActor.run {
                errorMessage = String(format: String(localized: "error_checking_alerts", defaultValue: "Error checking alerts: %@"), error.localizedDescription)
                isLoading = false
                LogManager.shared.log("Error checking alerts: \(error)", level: .error, source: "AlertsViewModel")
            }
        }
    }
    
    func getAvailableCurrencies() -> [String] {
        return Locale.commonISOCurrencyCodes.sorted()
    }
}

