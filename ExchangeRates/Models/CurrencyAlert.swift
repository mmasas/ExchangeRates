//
//  CurrencyAlert.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import Foundation

enum AlertCondition: Codable, Equatable {
    case above(Double)
    case below(Double)
    
    var displayName: String {
        switch self {
        case .above:
            return "מעל"
        case .below:
            return "מתחת"
        }
    }
    
    func isSatisfied(by rate: Double) -> Bool {
        switch self {
        case .above(let threshold):
            return rate >= threshold
        case .below(let threshold):
            return rate <= threshold
        }
    }
}

enum AlertStatus: String, Codable {
    case active
    case triggered
    case paused
}

struct CurrencyAlert: Codable, Identifiable {
    let id: UUID
    let baseCurrency: String
    let targetCurrency: String
    let condition: AlertCondition
    let targetValue: Decimal
    var isEnabled: Bool
    var status: AlertStatus
    var triggeredAt: Date?
    let createdAt: Date
    var autoResetAfterHours: Int?
    
    init(
        id: UUID = UUID(),
        baseCurrency: String,
        targetCurrency: String,
        condition: AlertCondition,
        targetValue: Decimal,
        isEnabled: Bool = true,
        status: AlertStatus = .active,
        triggeredAt: Date? = nil,
        createdAt: Date = Date(),
        autoResetAfterHours: Int? = nil
    ) {
        self.id = id
        self.baseCurrency = baseCurrency
        self.targetCurrency = targetCurrency
        self.condition = condition
        self.targetValue = targetValue
        self.isEnabled = isEnabled
        self.status = status
        self.triggeredAt = triggeredAt
        self.createdAt = createdAt
        self.autoResetAfterHours = autoResetAfterHours
    }
    
    var currencyPair: String {
        "\(baseCurrency) → \(targetCurrency)"
    }
    
    var isActive: Bool {
        isEnabled && status == .active
    }
    
    mutating func markAsTriggered() {
        status = .triggered
        triggeredAt = Date()
    }
    
    mutating func reset() {
        status = .active
        triggeredAt = nil
    }
    
    mutating func toggleEnabled() {
        isEnabled.toggle()
        if !isEnabled {
            status = .paused
        } else if status == .paused {
            status = .active
        }
    }
}

