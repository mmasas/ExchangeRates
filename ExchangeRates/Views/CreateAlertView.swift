//
//  CreateAlertView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import SwiftUI

struct CreateAlertView: View {
    @StateObject private var viewModel: CreateAlertViewModel
    @Environment(\.dismiss) private var dismiss
    let onDismiss: () -> Void
    
    init(editingAlert: CurrencyAlert? = nil, onDismiss: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: CreateAlertViewModel(editingAlert: editingAlert))
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(String(localized: "base_currency"), selection: $viewModel.baseCurrency) {
                        Text(String(localized: "select_currency")).tag("")
                        ForEach(viewModel.getAvailableCurrencies(), id: \.self) { code in
                            Text("\(CurrencyFlagHelper.flag(for: code)) \(code) - \(CurrencyFlagHelper.countryName(for: code))")
                                .tag(code)
                        }
                    }
                    
                    if !viewModel.baseCurrency.isEmpty && !viewModel.targetCurrency.isEmpty && viewModel.baseCurrency != viewModel.targetCurrency {
                        Button(action: {
                            viewModel.swapCurrencies()
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 16, weight: .medium))
                                Text(String(localized: "swap_order"))
                                    .font(.system(size: 16))
                                Spacer()
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    Picker(String(localized: "target_currency"), selection: $viewModel.targetCurrency) {
                        Text(String(localized: "select_currency")).tag("")
                        ForEach(viewModel.getAvailableCurrencies(), id: \.self) { code in
                            Text("\(CurrencyFlagHelper.flag(for: code)) \(code) - \(CurrencyFlagHelper.countryName(for: code))")
                                .tag(code)
                        }
                    }
                    
                    if !viewModel.baseCurrency.isEmpty && !viewModel.targetCurrency.isEmpty && viewModel.baseCurrency != viewModel.targetCurrency {
                        HStack {
                            Text(String(localized: "current_rate"))
                                .foregroundColor(.secondary)
                            Spacer()
                            if viewModel.isLoadingRate {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if let rate = viewModel.currentRate {
                                Text(String(format: "%.4f", rate))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            } else {
                                Text("—")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text(String(localized: "currency_pair"))
                } footer: {
                    if !viewModel.baseCurrency.isEmpty && !viewModel.targetCurrency.isEmpty && viewModel.baseCurrency != viewModel.targetCurrency {
                        if let rate = viewModel.currentRate {
                            Text("\(viewModel.baseCurrency) → \(viewModel.targetCurrency): \(String(format: "%.4f", rate))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Picker(String(localized: "condition"), selection: $viewModel.conditionType) {
                        ForEach(ConditionType.allCases, id: \.self) { type in
                            Text(type.localizedDisplayName).tag(type)
                        }
                    }
                    
                    HStack {
                        Text(String(localized: "target_value"))
                        Spacer()
                        TextField("0.0000", text: $viewModel.targetValue)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .environment(\.layoutDirection, .leftToRight)
                            .frame(width: 120)
                    }
                } header: {
                    Text(String(localized: "alert_condition"))
                }
                
                Section {
                    Toggle(String(localized: "enable_alert"), isOn: $viewModel.isEnabled)
                    
                    Picker(String(localized: "auto_reset"), selection: $viewModel.autoResetHours) {
                        Text(String(localized: "no_auto_reset")).tag(nil as Int?)
                        Text(String(format: String(localized: "after_hours", defaultValue: "After %lld hours"), 1)).tag(1 as Int?)
                        Text(String(format: String(localized: "after_hours", defaultValue: "After %lld hours"), 6)).tag(6 as Int?)
                        Text(String(format: String(localized: "after_hours", defaultValue: "After %lld hours"), 12)).tag(12 as Int?)
                        Text(String(format: String(localized: "after_hours", defaultValue: "After %lld hours"), 24)).tag(24 as Int?)
                        Text(String(format: String(localized: "after_hours", defaultValue: "After %lld hours"), 48)).tag(48 as Int?)
                    }
                } header: {
                    Text(String(localized: "additional_settings"))
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(viewModel.editingAlert != nil ? String(localized: "edit_alert") : String(localized: "new_alert"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "cancel")) {
                        dismiss()
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "save")) {
                        if viewModel.saveAlert() {
                            dismiss()
                            onDismiss()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }
}

#Preview {
    CreateAlertView()
}

