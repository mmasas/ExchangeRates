//
//  NotificationService.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import Foundation
import UserNotifications
import Combine

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    private let center = UNUserNotificationCenter.current()
    
    private override init() {
        super.init()
        // Set delegate to show notifications when app is in foreground
        center.delegate = self
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Show notification even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner, play sound, and update badge even when app is in foreground
        completionHandler([.banner, .sound, .badge])
        LogManager.shared.log("Showing notification in foreground: \(notification.request.content.body)", level: .info, source: "NotificationService")
    }
    
    /// Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        LogManager.shared.log("User tapped notification: \(response.notification.request.identifier)", level: .info, source: "NotificationService")
        completionHandler()
    }
    
    /// Requests notification permission from the user
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            LogManager.shared.log("Failed to request permission: \(error)", level: .error, source: "NotificationService")
            return false
        }
    }
    
    /// Schedules a local notification for a triggered alert
    func scheduleNotification(for alert: CurrencyAlert, currentRate: Double) {
        // Check authorization status first
        Task {
            let status = await getAuthorizationStatus()
            
            if status != .authorized {
                LogManager.shared.log("Not authorized to send notifications. Status: \(status.rawValue)", level: .warning, source: "NotificationService")
                // Try to request permission
                let granted = await requestPermission()
                if !granted {
                    LogManager.shared.log("Permission denied, cannot send notification", level: .error, source: "NotificationService")
                    return
                }
            }
            
            let content = UNMutableNotificationContent()
            content.title = String(localized: "currency_alert_notification_title", defaultValue: "Currency Rate Alert")
            content.body = createNotificationBody(for: alert, currentRate: currentRate)
            content.sound = .default
            content.badge = 1
            
            // Use alert ID as identifier to avoid duplicate notifications
            let identifier = alert.id.uuidString
            
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: nil // Immediate notification
            )
            
            do {
                try await center.add(request)
                LogManager.shared.log("Notification scheduled for alert \(alert.id)", level: .success, source: "NotificationService")
                LogManager.shared.log("Notification content: \(content.body)", level: .info, source: "NotificationService")
            } catch {
                LogManager.shared.log("Failed to schedule notification: \(error)", level: .error, source: "NotificationService")
            }
        }
    }
    
    /// Cancels a notification for a specific alert
    func cancelNotification(for alertId: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [alertId.uuidString])
        center.removeDeliveredNotifications(withIdentifiers: [alertId.uuidString])
    }
    
    /// Clears the app badge
    func clearBadge() {
        Task { @MainActor in
            UNUserNotificationCenter.current().setBadgeCount(0)
            LogManager.shared.log("Badge cleared", level: .success, source: "NotificationService")
        }
    }
    
    /// Sets the app badge to a specific count
    func setBadge(count: Int) {
        Task { @MainActor in
            UNUserNotificationCenter.current().setBadgeCount(count)
        }
    }
    
    /// Creates the notification body text
    private func createNotificationBody(for alert: CurrencyAlert, currentRate: Double) -> String {
        let pair = alert.currencyPair
        let conditionText = alert.condition.displayName
        let targetValue = Double(truncating: alert.targetValue as NSDecimalNumber)
        let formattedTarget = String(format: "%.4f", targetValue)
        let formattedCurrent = String(format: "%.4f", currentRate)
        
        return String(format: String(localized: "notification_body", defaultValue: "%@ crossed the value %@ %@. Current rate: %@"), pair, conditionText, formattedTarget, formattedCurrent)
    }
    
    /// Checks current notification authorization status
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
}

