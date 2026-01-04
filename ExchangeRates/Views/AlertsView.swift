//
//  AlertsView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import SwiftUI

struct AlertsView: View {
    @StateObject private var viewModel = AlertsViewModel()
    @State private var showingCreateAlert = false
    @State private var editingAlert: CurrencyAlert?
    
    var body: some View {
        List {
            if viewModel.alerts.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text(String(localized: "no_alerts_configured"))
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(String(localized: "add_alert_to_start"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            } else {
                // Currency Alerts Section
                if !viewModel.currencyAlerts.isEmpty {
                    Section {
                        ForEach(viewModel.currencyAlerts) { alert in
                            AlertRow(alert: alert) {
                                editingAlert = alert
                                showingCreateAlert = true
                            } onToggle: {
                                viewModel.toggleAlert(alert.id)
                            } onReset: {
                                viewModel.resetAlert(alert.id)
                            } onDelete: {
                                viewModel.deleteAlert(alert.id)
                            }
                        }
                    } header: {
                        Text(String(localized: "currency_alerts_section", defaultValue: "Currency Alerts"))
                    }
                }
                
                // Crypto Alerts Section
                if !viewModel.cryptoAlerts.isEmpty {
                    Section {
                        ForEach(viewModel.cryptoAlerts) { alert in
                            AlertRow(alert: alert) {
                                editingAlert = alert
                                showingCreateAlert = true
                            } onToggle: {
                                viewModel.toggleAlert(alert.id)
                            } onReset: {
                                viewModel.resetAlert(alert.id)
                            } onDelete: {
                                viewModel.deleteAlert(alert.id)
                            }
                        }
                    } header: {
                        Text(String(localized: "crypto_alerts_section", defaultValue: "Crypto Alerts"))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(String(localized: "alerts_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editingAlert = nil
                    showingCreateAlert = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    Task {
                        await viewModel.checkAlertsNow()
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isLoading)
            }
        }
        .sheet(isPresented: $showingCreateAlert, onDismiss: {
            // Reload alerts when sheet is dismissed
            viewModel.loadAlerts()
        }) {
            if let alert = editingAlert {
                CreateAlertView(editingAlert: alert) {
                    editingAlert = nil
                    viewModel.loadAlerts()
                }
            } else {
                CreateAlertView {
                    editingAlert = nil
                    viewModel.loadAlerts()
                }
            }
        }
        .onAppear {
            viewModel.loadAlerts()
            // Badge is updated in loadAlerts() to show count of triggered alerts
        }
        .alert(String(localized: "error"), isPresented: .constant(viewModel.errorMessage != nil)) {
            Button(String(localized: "ok"), role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

struct AlertRow: View {
    let alert: CurrencyAlert
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onReset: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: Currency pair with flags + Toggle
            HStack(alignment: .center) {
                // Flags and currency codes / Crypto info
                HStack(spacing: 8) {
                    if alert.alertType == .crypto {
                        // Crypto display
                        HStack(spacing: 4) {
                            Image(systemName: "bitcoinsign.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                            if let symbol = alert.cryptoSymbol {
                                Text(symbol)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                            } else if let cryptoId = alert.cryptoId {
                                Text(cryptoId.capitalized)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        // USD target
                        HStack(spacing: 4) {
                            Text(CurrencyFlagHelper.flag(for: "USD"))
                                .font(.system(size: 24))
                            Text("USD")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    } else {
                        // Currency display
                        // Base currency
                        HStack(spacing: 4) {
                            Text(CurrencyFlagHelper.flag(for: alert.baseCurrency))
                                .font(.system(size: 24))
                            Text(alert.baseCurrency)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        // Target currency
                        HStack(spacing: 4) {
                            Text(CurrencyFlagHelper.flag(for: alert.targetCurrency))
                                .font(.system(size: 24))
                            Text(alert.targetCurrency)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Spacer()
                
                // Toggle
                Toggle("", isOn: Binding(
                    get: { alert.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
                .tint(.green)
            }
            
            // Divider
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 1)
            
            // Bottom section: Condition + Status
            HStack(alignment: .top) {
                // Condition info
                VStack(alignment: .leading, spacing: 6) {
                    // Condition with value
                    HStack(spacing: 6) {
                        Text(conditionText)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text(formatValue(alert.targetValue))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    // Triggered info
                    if alert.status == .triggered, let triggeredAt = alert.triggeredAt {
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 11))
                                Text(formatDate(triggeredAt))
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.orange)
                            
                            Button {
                                onReset()
                            } label: {
                                Text(String(localized: "reset"))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.blue)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Auto reset info
                    if let autoReset = alert.autoResetAfterHours {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 10))
                            Text(String(format: String(localized: "auto_reset_after_hours", defaultValue: "Auto reset: %lld hours"), autoReset))
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status badge
                StatusBadge(status: alert.status)
            }
        }
        .padding(.vertical, 12)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(String(localized: "delete"), systemImage: "trash")
            }
            
            Button {
                onEdit()
            } label: {
                Label(String(localized: "edit"), systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
    
    private var conditionText: String {
        switch alert.condition {
        case .above:
            return String(localized: "above", defaultValue: "Above")
        case .below:
            return String(localized: "below", defaultValue: "Below")
        }
    }
    
    private func formatValue(_ value: Decimal) -> String {
        let doubleValue = Double(truncating: value as NSDecimalNumber)
        if alert.alertType == .crypto {
            // Format crypto prices with $ and appropriate decimal places
            if doubleValue >= 1.0 {
                return String(format: "$%.2f", doubleValue)
            } else {
                return String(format: "$%.4f", doubleValue)
            }
        } else {
            return String(format: "%.4f", doubleValue)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy, HH:mm"
        formatter.locale = LanguageManager.shared.currentLocale
        return formatter.string(from: date)
    }
}

struct StatusBadge: View {
    let status: AlertStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(statusColor.opacity(0.12))
        .clipShape(Capsule())
    }
    
    private var statusText: String {
        switch status {
        case .active:
            return String(localized: "active", defaultValue: "Active")
        case .triggered:
            return String(localized: "triggered", defaultValue: "Triggered")
        case .paused:
            return String(localized: "paused", defaultValue: "Paused")
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .active:
            return .green
        case .triggered:
            return .orange
        case .paused:
            return .gray
        }
    }
}

#Preview {
    NavigationStack {
        AlertsView()
    }
}

