//
//  WebSocketManager.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import Foundation
import Combine

class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()
    
    private let userDefaults = UserDefaults.standard
    private let websocketEnabledKey = "websocketEnabled"
    
    /// Notification name for when WebSocket preference changes
    static let websocketPreferenceChangedNotification = NSNotification.Name("WebSocketPreferenceChanged")
    
    @Published var isWebSocketEnabled: Bool {
        willSet {
            if isWebSocketEnabled != newValue {
                userDefaults.set(newValue, forKey: websocketEnabledKey)
                
                // Post notification when preference changes
                NotificationCenter.default.post(
                    name: WebSocketManager.websocketPreferenceChangedNotification,
                    object: nil,
                    userInfo: ["enabled": newValue]
                )
                
                LogManager.shared.log("WebSocket preference changed to: \(newValue ? "enabled" : "disabled")", level: .info, source: "WebSocketManager")
            }
        }
    }
    
    private init() {
        // Default value: true (enabled by default)
        let defaultValue = userDefaults.object(forKey: websocketEnabledKey) as? Bool ?? true
        self.isWebSocketEnabled = defaultValue
    }
    
    /// Set WebSocket enabled/disabled preference
    func setWebSocketEnabled(_ enabled: Bool) {
        isWebSocketEnabled = enabled
    }
}

