//
//  BackgroundTaskManager.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import Foundation
import BackgroundTasks
import UserNotifications

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    
    private let taskIdentifier = "com.exchangerates.alertCheck"
    private let alertChecker = AlertCheckerService.shared
    private let notificationService = NotificationService.shared
    
    private init() {}
    
    /// Registers the background task
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleBackgroundCheck(task: task as! BGProcessingTask)
        }
    }
    
    /// Schedules the next background check
    func scheduleBackgroundCheck() {
        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        
        // Schedule for 2-6 hours from now (random interval)
        let hours = Double.random(in: 2...6)
        request.earliestBeginDate = Date(timeIntervalSinceNow: hours * 3600)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ [BackgroundTaskManager] Background check scheduled for \(hours) hours from now")
        } catch {
            print("❌ [BackgroundTaskManager] Failed to schedule background check: \(error)")
        }
    }
    
    /// Handles the background check task
    private func handleBackgroundCheck(task: BGProcessingTask) {
        // Schedule the next check before starting
        scheduleBackgroundCheck()
        
        // Set expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform the check
        Task {
            do {
                let triggeredAlerts = try await alertChecker.checkAlerts()
                
                // Send notifications for triggered alerts
                for alert in triggeredAlerts {
                    // Fetch current rate for notification
                    let currentRate = try await alertChecker.fetchRateForPair(
                        base: alert.baseCurrency,
                        target: alert.targetCurrency
                    )
                    
                    // Check notification permission
                    let status = await notificationService.getAuthorizationStatus()
                    if status == .authorized {
                        notificationService.scheduleNotification(
                            for: alert,
                            currentRate: currentRate.currentExchangeRate
                        )
                    }
                }
                
                task.setTaskCompleted(success: true)
                print("✅ [BackgroundTaskManager] Background check completed. Triggered \(triggeredAlerts.count) alerts")
            } catch {
                print("❌ [BackgroundTaskManager] Background check failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
    }
}

