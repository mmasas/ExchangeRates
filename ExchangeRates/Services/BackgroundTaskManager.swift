//
//  BackgroundTaskManager.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

// This file is only for the main app, not for app extensions
#if !WIDGET_EXTENSION

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
    private let alertManager = CurrencyAlertManager.shared
    private let widgetSyncService = WidgetDataSyncService.shared
    
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
                // 1. Check alerts (existing functionality)
                let triggeredAlerts = try await alertChecker.checkAlerts()
                
                // Send notifications for triggered alerts
                for alert in triggeredAlerts {
                    let currentRate: Double
                    if alert.alertType == .crypto {
                        // Fetch crypto price
                        guard let cryptoId = alert.cryptoId else {
                            LogManager.shared.log("Crypto alert \(alert.id) missing cryptoId", level: .warning, source: "BackgroundTaskManager")
                            continue
                        }
                        currentRate = try await alertChecker.fetchCryptoPrice(id: cryptoId)
                    } else {
                        // Fetch currency rate
                        let rate = try await alertChecker.fetchRateForPair(
                            base: alert.baseCurrency,
                            target: alert.targetCurrency
                        )
                        currentRate = rate.currentExchangeRate
                    }
                    
                    // Check notification permission
                    let status = await notificationService.getAuthorizationStatus()
                    if status == .authorized {
                        notificationService.scheduleNotification(
                            for: alert,
                            currentRate: currentRate
                        )
                    }
                }
                
                // Update badge count
                await MainActor.run {
                    updateBadgeCount()
                }
                
                // 2. Sync widget data (new functionality - battery efficient)
                await self.syncWidgetDataInBackground()
                
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
    
    /// Updates the badge count based on triggered alerts
    @MainActor
    private func updateBadgeCount() {
        let allAlerts = alertManager.getAllAlerts()
        let triggeredCount = allAlerts.filter { $0.status == .triggered }.count
        notificationService.setBadge(count: triggeredCount)
        // Notify MainTabView to update badge
        NotificationCenter.default.post(name: NSNotification.Name("AlertsUpdated"), object: nil)
    }
    
    // MARK: - Widget Sync
    
    /// Syncs widget data in background - fetches fresh prices and updates widget
    /// This is battery efficient because it runs as part of the existing background task
    private func syncWidgetDataInBackground() async {
        LogManager.shared.log("Starting widget data sync in background", level: .debug, source: "BackgroundTaskManager")
        
        do {
            // Fetch favorite crypto IDs
            let favoriteCryptoIds = FavoriteCryptoManager.shared.getFavorites()
            let favoriteCurrencyIds = FavoriteCurrencyManager.shared.getFavorites()
            
            // Only fetch if there are favorites
            if favoriteCryptoIds.isEmpty && favoriteCurrencyIds.isEmpty {
                LogManager.shared.log("No favorites to sync for widget", level: .debug, source: "BackgroundTaskManager")
                return
            }
            
            // Fetch crypto data if needed
            if !favoriteCryptoIds.isEmpty {
                let cryptos = try await fetchFavoriteCryptos(ids: favoriteCryptoIds)
                widgetSyncService.syncCryptoData(cryptos)
            }
            
            // Fetch currency data if needed
            if !favoriteCurrencyIds.isEmpty {
                let currencies = try await fetchFavoriteCurrencies(codes: favoriteCurrencyIds)
                await widgetSyncService.syncCurrencyData(currencies)
            }
            
            // Reload widget timelines
            widgetSyncService.reloadWidgets()
            
            LogManager.shared.log("Widget data sync completed in background", level: .success, source: "BackgroundTaskManager")
        } catch {
            LogManager.shared.log("Widget sync failed in background: \(error.localizedDescription)", level: .warning, source: "BackgroundTaskManager")
        }
    }
    
    /// Fetches cryptocurrency data for widget sync
    private func fetchFavoriteCryptos(ids: [String]) async throws -> [Cryptocurrency] {
        let idsString = ids.joined(separator: ",")
        let urlString = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=\(idsString)&order=market_cap_desc&sparkline=true&price_change_percentage=24h"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let cryptos = try JSONDecoder().decode([Cryptocurrency].self, from: data)
        
        LogManager.shared.log("Fetched \(cryptos.count) cryptos for widget", level: .debug, source: "BackgroundTaskManager")
        return cryptos
    }
    
    /// Fetches currency exchange rates for widget sync
    private func fetchFavoriteCurrencies(codes: [String]) async throws -> [ExchangeRate] {
        let homeCurrency = HomeCurrencyManager.shared.getHomeCurrency()
        let codesString = codes.joined(separator: ",")
        let urlString = "https://api.frankfurter.app/latest?from=\(homeCurrency)&to=\(codesString)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(FrankfurterLatestResponse.self, from: data)
        
        // Convert to ExchangeRate array
        // Use response date + current time for ISO8601 format
        let lastUpdateString = "\(response.date)T00:00:00.000Z"
        
        var rates: [ExchangeRate] = []
        for (code, rate) in response.rates {
            rates.append(ExchangeRate(
                key: code,
                currentExchangeRate: rate,
                currentChange: 0,
                unit: 1,
                lastUpdate: lastUpdateString
            ))
        }
        
        LogManager.shared.log("Fetched \(rates.count) currencies for widget", level: .debug, source: "BackgroundTaskManager")
        return rates
    }
}

/// Response model for Frankfurter API
private struct FrankfurterLatestResponse: Codable {
    let amount: Double
    let base: String
    let date: String
    let rates: [String: Double]
}

#endif // !WIDGET_EXTENSION
