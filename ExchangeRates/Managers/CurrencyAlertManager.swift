//
//  CurrencyAlertManager.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import Foundation

class CurrencyAlertManager {
    static let shared = CurrencyAlertManager()
    
    private let userDefaults = UserDefaults.standard
    private let alertsKey = "currencyAlerts"
    
    private init() {}
    
    func getAllAlerts() -> [CurrencyAlert] {
        guard let data = userDefaults.data(forKey: alertsKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([CurrencyAlert].self, from: data)
        } catch {
            print("❌ [CurrencyAlertManager] Failed to decode alerts: \(error)")
            return []
        }
    }
    
    func saveAlert(_ alert: CurrencyAlert) {
        var alerts = getAllAlerts()
        
        // Remove existing alert with same ID if it exists
        alerts.removeAll { $0.id == alert.id }
        
        // Add the new/updated alert
        alerts.append(alert)
        
        saveAlerts(alerts)
    }
    
    func deleteAlert(_ id: UUID) {
        var alerts = getAllAlerts()
        alerts.removeAll { $0.id == id }
        saveAlerts(alerts)
    }
    
    func updateAlert(_ alert: CurrencyAlert) {
        saveAlert(alert)
    }
    
    func getActiveAlerts() -> [CurrencyAlert] {
        return getAllAlerts().filter { $0.isActive }
    }
    
    private func saveAlerts(_ alerts: [CurrencyAlert]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(alerts)
            userDefaults.set(data, forKey: alertsKey)
        } catch {
            print("❌ [CurrencyAlertManager] Failed to encode alerts: \(error)")
        }
    }
}

