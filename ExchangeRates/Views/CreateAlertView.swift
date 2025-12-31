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
                    Picker("מטבע בסיס", selection: $viewModel.baseCurrency) {
                        Text("בחר מטבע").tag("")
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
                                Text("הפוך סדר")
                                    .font(.system(size: 16))
                                Spacer()
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    Picker("מטבע יעד", selection: $viewModel.targetCurrency) {
                        Text("בחר מטבע").tag("")
                        ForEach(viewModel.getAvailableCurrencies(), id: \.self) { code in
                            Text("\(CurrencyFlagHelper.flag(for: code)) \(code) - \(CurrencyFlagHelper.countryName(for: code))")
                                .tag(code)
                        }
                    }
                    
                    if !viewModel.baseCurrency.isEmpty && !viewModel.targetCurrency.isEmpty && viewModel.baseCurrency != viewModel.targetCurrency {
                        HStack {
                            Text("שער נוכחי")
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
                    Text("זוג מטבעות")
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
                    Picker("תנאי", selection: $viewModel.conditionType) {
                        ForEach(ConditionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    HStack {
                        Text("ערך יעד")
                        Spacer()
                        TextField("0.0000", text: $viewModel.targetValue)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                } header: {
                    Text("תנאי התראה")
                }
                
                Section {
                    Toggle("הפעל התראה", isOn: $viewModel.isEnabled)
                    
                    Picker("איפוס אוטומטי", selection: $viewModel.autoResetHours) {
                        Text("ללא איפוס אוטומטי").tag(nil as Int?)
                        Text("אחרי 1 שעה").tag(1 as Int?)
                        Text("אחרי 6 שעות").tag(6 as Int?)
                        Text("אחרי 12 שעות").tag(12 as Int?)
                        Text("אחרי 24 שעות").tag(24 as Int?)
                        Text("אחרי 48 שעות").tag(48 as Int?)
                    }
                } header: {
                    Text("הגדרות נוספות")
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(viewModel.editingAlert != nil ? "ערוך התראה" : "התראה חדשה")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ביטול") {
                        dismiss()
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("שמור") {
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

