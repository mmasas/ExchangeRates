//
//  AlertsViewModel.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import Foundation
import Combine
import UserNotifications

class AlertsViewModel: ObservableObject {
    @Published var alerts: [CurrencyAlert] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let alertManager = CurrencyAlertManager.shared
    private let alertChecker = AlertCheckerService.shared
    private let notificationService = NotificationService.shared
    
    init() {
        loadAlerts()
    }
    
    func loadAlerts() {
        alerts = alertManager.getAllAlerts()
    }
    
    func deleteAlert(_ id: UUID) {
        alertManager.deleteAlert(id)
        loadAlerts()
    }
    
    func toggleAlert(_ id: UUID) {
        guard var alert = alerts.first(where: { $0.id == id }) else { return }
        alert.toggleEnabled()
        alertManager.updateAlert(alert)
        loadAlerts()
    }
    
    func resetAlert(_ id: UUID) {
        guard var alert = alerts.first(where: { $0.id == id }) else { return }
        alert.reset()
        alertManager.updateAlert(alert)
        loadAlerts()
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
            
            print("🔔 [AlertsViewModel] Found \(triggeredAlerts.count) triggered alerts")
            
            // Send notifications for triggered alerts
            for alert in triggeredAlerts {
                let currentRate = try await alertChecker.fetchRateForPair(
                    base: alert.baseCurrency,
                    target: alert.targetCurrency
                )
                print("📱 [AlertsViewModel] Sending notification for \(alert.currencyPair) at rate \(currentRate.currentExchangeRate)")
                notificationService.scheduleNotification(
                    for: alert,
                    currentRate: currentRate.currentExchangeRate
                )
            }
            
            await MainActor.run {
                loadAlerts()
                isLoading = false
                if !triggeredAlerts.isEmpty {
                    errorMessage = nil // Success - alerts triggered
                    print("✅ [AlertsViewModel] Successfully checked alerts, \(triggeredAlerts.count) triggered")
                } else {
                    print("ℹ️ [AlertsViewModel] No alerts triggered")
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = String(format: String(localized: "error_checking_alerts", defaultValue: "Error checking alerts: %@"), error.localizedDescription)
                isLoading = false
                print("❌ [AlertsViewModel] Error checking alerts: \(error)")
            }
        }
    }
    
    func getAvailableCurrencies() -> [String] {
        return Locale.commonISOCurrencyCodes.sorted()
    }
}

