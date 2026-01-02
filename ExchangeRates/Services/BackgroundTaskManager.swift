//
//  BackgroundTaskManager.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import Foundation
import BackgroundTasks
import UserNotifications
import UIKit

/// Represents the current status of background task scheduling
enum BackgroundTaskStatus {
    case available
    case denied
    case restricted
    case unknown
    
    var description: String {
        switch self {
        case .available:
            return "Background refresh is available"
        case .denied:
            return "Background refresh is denied by user. Enable in Settings > General > Background App Refresh"
        case .restricted:
            return "Background refresh is restricted (parental controls or device management)"
        case .unknown:
            return "Background refresh status is unknown"
        }
    }
}

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    
    private let taskIdentifier = "com.exchangerates.alertCheck"
    private let alertChecker = AlertCheckerService.shared
    private let notificationService = NotificationService.shared
    
    /// Minimum interval between background refreshes (15 minutes is iOS minimum)
    private let minimumRefreshInterval: TimeInterval = 15 * 60
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Registers the background task with the system
    /// Must be called during app launch, before applicationDidFinishLaunching returns
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let appRefreshTask = task as? BGAppRefreshTask else {
                LogManager.shared.log("Received unexpected task type", level: .error, source: "BackgroundTaskManager")
                task.setTaskCompleted(success: false)
                return
            }
            self?.handleBackgroundCheck(task: appRefreshTask)
        }
        LogManager.shared.log("Background task registered with identifier: \(taskIdentifier)", level: .info, source: "BackgroundTaskManager")
    }
    
    /// Checks if background refresh is available
    @MainActor
    func getBackgroundRefreshStatus() -> BackgroundTaskStatus {
        switch UIApplication.shared.backgroundRefreshStatus {
        case .available:
            return .available
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .unknown
        }
    }
    
    /// Schedules the next background check if possible
    /// Returns true if scheduling was successful
    @MainActor
    @discardableResult
    func scheduleBackgroundCheck() -> Bool {
        // Check if background refresh is available
        let status = getBackgroundRefreshStatus()
        guard status == .available else {
            LogManager.shared.log("Cannot schedule background task: \(status.description)", level: .warning, source: "BackgroundTaskManager")
            return false
        }
        
        // Cancel any existing pending tasks before scheduling new one
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
        
        // Create app refresh task request (designed for periodic content updates)
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        
        // Schedule for minimum interval (iOS will decide actual execution time)
        // iOS may delay execution based on app usage patterns and system conditions
        request.earliestBeginDate = Date(timeIntervalSinceNow: minimumRefreshInterval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            let scheduledTime = Date(timeIntervalSinceNow: minimumRefreshInterval)
            LogManager.shared.log("Background check scheduled (earliest: \(scheduledTime.formatted()))", level: .success, source: "BackgroundTaskManager")
            return true
        } catch let error as BGTaskScheduler.Error {
            handleSchedulerError(error)
            return false
        } catch {
            LogManager.shared.log("Failed to schedule background check: \(error.localizedDescription)", level: .error, source: "BackgroundTaskManager")
            return false
        }
    }
    
    /// Cancels all pending background tasks
    func cancelAllPendingTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
        LogManager.shared.log("Cancelled all pending background tasks", level: .info, source: "BackgroundTaskManager")
    }
    
    // MARK: - Private Methods
    
    /// Handles specific BGTaskScheduler errors with appropriate logging
    private func handleSchedulerError(_ error: BGTaskScheduler.Error) {
        switch error.code {
        case .unavailable:
            LogManager.shared.log(
                "Background tasks unavailable. This can happen if: " +
                "1) Background App Refresh is disabled in Settings, " +
                "2) Low Power Mode is enabled, " +
                "3) The app is running in Simulator",
                level: .warning,
                source: "BackgroundTaskManager"
            )
        case .tooManyPendingTaskRequests:
            LogManager.shared.log(
                "Too many pending background task requests. Cancelling existing tasks.",
                level: .warning,
                source: "BackgroundTaskManager"
            )
            // Cancel existing and retry
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
        case .notPermitted:
            LogManager.shared.log(
                "Background task not permitted. Ensure '\(taskIdentifier)' is in BGTaskSchedulerPermittedIdentifiers in Info.plist",
                level: .error,
                source: "BackgroundTaskManager"
            )
        default:
            LogManager.shared.log(
                "Unknown background task scheduler error: \(error.localizedDescription)",
                level: .error,
                source: "BackgroundTaskManager"
            )
        }
    }
    
    /// Handles the background check task execution
    private func handleBackgroundCheck(task: BGAppRefreshTask) {
        LogManager.shared.log("Background check task started", level: .info, source: "BackgroundTaskManager")
        
        // Schedule the next check before starting work
        Task { @MainActor in
            scheduleBackgroundCheck()
        }
        
        // Create a task to perform the work
        let checkTask = Task {
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
                
                return triggeredAlerts.count
            } catch {
                throw error
            }
        }
        
        // Set expiration handler to cancel work if we run out of time
        task.expirationHandler = {
            checkTask.cancel()
            LogManager.shared.log("Background check task expired", level: .warning, source: "BackgroundTaskManager")
        }
        
        // Wait for completion and mark task as done
        Task {
            do {
                let alertCount = try await checkTask.value
                task.setTaskCompleted(success: true)
                LogManager.shared.log("Background check completed. Triggered \(alertCount) alerts", level: .success, source: "BackgroundTaskManager")
            } catch {
                if Task.isCancelled {
                    task.setTaskCompleted(success: false)
                    LogManager.shared.log("Background check was cancelled", level: .warning, source: "BackgroundTaskManager")
                } else {
                    task.setTaskCompleted(success: false)
                    LogManager.shared.log("Background check failed: \(error.localizedDescription)", level: .error, source: "BackgroundTaskManager")
                }
            }
        }
    }
}
