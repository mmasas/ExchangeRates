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
                        Text("אין התראות מוגדרות")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("הוסף התראה חדשה כדי להתחיל")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            } else {
                ForEach(viewModel.alerts) { alert in
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
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("התראות שערי מטבע")
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
            // Clear badge when viewing alerts
            NotificationService.shared.clearBadge()
        }
        .alert("שגיאה", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("אישור", role: .cancel) {
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
        HStack(spacing: 12) {
            // Flags
            HStack(spacing: 4) {
                Text(CurrencyFlagHelper.flag(for: alert.baseCurrency))
                    .font(.system(size: 28))
                Text(CurrencyFlagHelper.flag(for: alert.targetCurrency))
                    .font(.system(size: 28))
            }
            
            // Currency info and condition
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(alert.currencyPair)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(statusText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(statusColor)
                }
                
                HStack(spacing: 4) {
                    Text(conditionText)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text(formatValue(alert.targetValue))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                if alert.status == .triggered, let triggeredAt = alert.triggeredAt {
                    HStack(spacing: 8) {
                        Text("הופעל: \(formatDate(triggeredAt))")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                        
                        Button("איפוס") {
                            onReset()
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.blue)
                    }
                }
                
                if let autoReset = alert.autoResetAfterHours {
                    Text("איפוס אוטומטי: \(autoReset) שעות")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: Binding(
                get: { alert.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("מחק", systemImage: "trash")
            }
            
            Button {
                onEdit()
            } label: {
                Label("ערוך", systemImage: "pencil")
            }
        }
    }
    
    private var statusText: String {
        switch alert.status {
        case .active:
            return "פעיל"
        case .triggered:
            return "הופעל"
        case .paused:
            return "מושהה"
        }
    }
    
    private var statusColor: Color {
        switch alert.status {
        case .active:
            return .green
        case .triggered:
            return .orange
        case .paused:
            return .gray
        }
    }
    
    private var conditionText: String {
        return alert.condition.displayName
    }
    
    private func formatValue(_ value: Decimal) -> String {
        let doubleValue = Double(truncating: value as NSDecimalNumber)
        return String(format: "%.4f", doubleValue)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "he_IL")
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        AlertsView()
    }
}

