//
//  ExchangeRatesApp.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 26/12/2025.
//

import SwiftUI
import Combine

@main
struct ExchangeRatesApp: App {
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var colorScheme: ColorScheme? = ColorSchemeManager.shared.getColorScheme().colorScheme
    @State private var showLaunchScreen = true
    @State private var currentLocale: Locale = LanguageManager.shared.currentLocale
    
    init() {
        // Initialize notification service early to set up delegate
        _ = NotificationService.shared
        
        // Register background task on app launch
        BackgroundTaskManager.shared.registerBackgroundTask()
        BackgroundTaskManager.shared.scheduleBackgroundCheck()
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
                    ContentView()
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
                
                // Clear badge when app opens
                NotificationService.shared.clearBadge()
            }
        }
    }
}
