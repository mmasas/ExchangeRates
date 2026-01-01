//
//  HistoricalRateView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import SwiftUI

struct HistoricalRateView: View {
    @StateObject private var viewModel: HistoricalRateViewModel
    @FocusState private var isFocused: Bool
    
    init(baseCurrency: String, targetCurrency: String) {
        _viewModel = StateObject(wrappedValue: HistoricalRateViewModel(
            baseCurrency: baseCurrency,
            targetCurrency: targetCurrency
        ))
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with currency info
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Text(CurrencyFlagHelper.flag(for: viewModel.baseCurrency))
                            .font(.system(size: 48))
                        Text("→")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                        Text(CurrencyFlagHelper.flag(for: viewModel.targetCurrency))
                            .font(.system(size: 48))
                    }
                    
                    Text("\(viewModel.baseCurrency) → \(viewModel.targetCurrency)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if viewModel.baseCurrency != viewModel.targetCurrency {
                        Button(action: {
                            viewModel.swapCurrencies()
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 14, weight: .medium))
                                Text(String(localized: "swap_order"))
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 8)
                
                // Date selection section
                VStack(alignment: .leading, spacing: 12) {
                    DatePicker(
                        String(localized: "select_date"),
                        selection: $viewModel.selectedDate,
                        in: ...Date(), // Only past dates allowed
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .onChange(of: viewModel.selectedDate) { _, _ in
                        // Dismiss the date picker popup
                        hideKeyboard()
                        // Fetch the historical rate
                        viewModel.fetchHistoricalRate()
                    }
                }
                .padding(.horizontal, 16)
                
                // Historical rate result section
                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                            .padding()
                    } else if let rate = viewModel.historicalRate {
                        VStack(spacing: 12) {
                            Text(String(localized: "historical_rate_result", defaultValue: "Historical Rate"))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            Text(rate.formattedRate)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text(dateFormatter.string(from: viewModel.selectedDate))
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text(String(localized: "select_date_to_view_rate", defaultValue: "Select a date to view the historical rate"))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
            }
            .padding(.vertical, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(
            Color(.systemGroupedBackground)
                .onTapGesture {
                    // Dismiss keyboard when tapping background
                    isFocused = false
                    hideKeyboard()
                }
        )
        .navigationTitle(String(localized: "historical_rate_title", defaultValue: "Historical Rate"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: "ok")) {
                    isFocused = false
                    hideKeyboard()
                }
            }
        }
        .onAppear {
            // Fetch rate when view appears
            viewModel.fetchHistoricalRate()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    NavigationStack {
        HistoricalRateView(baseCurrency: "USD", targetCurrency: "ILS")
    }
}

