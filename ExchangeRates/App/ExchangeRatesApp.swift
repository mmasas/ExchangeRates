//
//  ExchangeRatesApp.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 26/12/2025.
//

import SwiftUI
import Combine
import UIKit

@main
struct ExchangeRatesApp: App {
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var colorScheme: ColorScheme? = ColorSchemeManager.shared.getColorScheme().colorScheme
    @State private var showLaunchScreen = true
    @State private var currentLocale: Locale = LanguageManager.shared.currentLocale
    
    init() {
        // Initialize notification service early to set up delegate
        _ = NotificationService.shared
        
        // Register background task on app launch (must be done before app finishes launching)
        BackgroundTaskManager.shared.registerBackgroundTask()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showLaunchScreen {
                    LaunchScreenView()
                        .preferredColorScheme(colorScheme)
                        .environment(\.locale, currentLocale)
                        .transition(.opacity)
                        .zIndex(1)
                } else {
                    MainTabView()
                        .preferredColorScheme(colorScheme)
                        .environment(\.locale, currentLocale)
                        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ColorSchemeChanged"))) { _ in
                            colorScheme = ColorSchemeManager.shared.getColorScheme().colorScheme
                        }
                        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
                            // Update locale when language changes
                            currentLocale = LanguageManager.shared.currentLocale
                        }
                }
            }
            .onAppear {
                // Show launch screen for 1.8 seconds, then fade to main content
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showLaunchScreen = false
                    }
                }
                
                // Update badge count when app opens
                updateBadgeCount()
                
                // Schedule background check after app has appeared
                // This runs on MainActor and checks availability before scheduling
                scheduleBackgroundTaskIfAvailable()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                // Reschedule background task when app enters background
                scheduleBackgroundTaskIfAvailable()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                // Disconnect WebSocket when app goes to background (but keep subscriptions for reconnection)
                BinanceWebSocketService.shared.disconnect(clearSubscriptions: false)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Reconnect WebSocket when app becomes active (only if enabled)
                let websocketManager = WebSocketManager.shared
                if websocketManager.isWebSocketEnabled {
                    let symbols = MainCryptoHelper.getWebSocketSymbols()
                    if !symbols.isEmpty {
                        BinanceWebSocketService.shared.connect(symbols: symbols)
                    }
                }
            }
        }
    }
    
    /// Schedules background task only if background refresh is available
    @MainActor
    private func scheduleBackgroundTaskIfAvailable() {
        let status = BackgroundTaskManager.shared.getBackgroundRefreshStatus()
        
        switch status {
        case .available:
            BackgroundTaskManager.shared.scheduleBackgroundCheck()
        case .denied:
            LogManager.shared.log(
                "Background refresh is disabled by user. Alerts will only be checked when app is open.",
                level: .warning,
                source: "ExchangeRatesApp"
            )
        case .restricted:
            LogManager.shared.log(
                "Background refresh is restricted on this device.",
                level: .warning,
                source: "ExchangeRatesApp"
            )
        case .unknown:
            LogManager.shared.log(
                "Background refresh status is unknown.",
                level: .warning,
                source: "ExchangeRatesApp"
            )
        }
    }
    
    /// Updates the badge count based on triggered alerts
    @MainActor
    private func updateBadgeCount() {
        let alertManager = CurrencyAlertManager.shared
        let allAlerts = alertManager.getAllAlerts()
        let triggeredCount = allAlerts.filter { $0.status == .triggered }.count
        NotificationService.shared.setBadge(count: triggeredCount)
        // Notify MainTabView to update badge
        NotificationCenter.default.post(name: NSNotification.Name("AlertsUpdated"), object: nil)
    }
}
