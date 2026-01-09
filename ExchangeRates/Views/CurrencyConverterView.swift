//
//  CurrencyConverterView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 26/12/2025.
//

import SwiftUI

struct CurrencyConverterView: View {
    @StateObject private var viewModel: CurrencyConverterViewModel
    @FocusState private var focusedField: Field?
    @State private var showHistoricalRate = false
    
    enum Field {
        case home, foreign
    }
    
    init(exchangeRate: ExchangeRate) {
        _viewModel = StateObject(wrappedValue: CurrencyConverterViewModel(exchangeRate: exchangeRate))
    }
    
    private var homeCurrencySymbol: String {
        CurrencyFlagHelper.currencySymbol(for: viewModel.homeCurrencyCode)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Flag and currency info at the top
                VStack(spacing: 16) {
                    // Flag
                    CurrencyFlagHelper.flagImage(for: viewModel.exchangeRate.key)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                    
                    // Currency pair and rate
                    VStack(spacing: 8) {
                        Text("\(viewModel.exchangeRate.key) / \(viewModel.homeCurrencyCode)")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(String(format: String(localized: "rate_label", defaultValue: "Rate: %@"), viewModel.exchangeRate.formattedRate))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 8)
                
                // Conversion fields
                VStack(spacing: 16) {
                            // Home Currency Input Field
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("\(viewModel.homeCurrencyCode)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                    
                                    Spacer()
                                    
                                    Text(CurrencyFlagHelper.currencyName(for: viewModel.homeCurrencyCode))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 12) {
                                    Text(homeCurrencySymbol)
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    TextField("0", text: Binding(
                                        get: { viewModel.homeAmount },
                                        set: { viewModel.updateHomeAmount($0) }
                                    ))
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.primary)
                                        .focused($focusedField, equals: .home)
                                        .environment(\.layoutDirection, .leftToRight)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                        )
                                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                                )
                            }
                            
                            // Arrow indicator
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.secondary.opacity(0.7))
                                .padding(.vertical, 4)
                                .frame(maxWidth: .infinity)
                            
                            // Foreign Currency Input Field
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(viewModel.exchangeRate.key)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                    
                                    Spacer()
                                    
                                    Text(CurrencyFlagHelper.currencyName(for: viewModel.exchangeRate.key))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 12) {
                                    CurrencyFlagHelper.flagImage(for: viewModel.exchangeRate.key)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 28, height: 28)
                                        .clipShape(Circle())
                                    
                                    TextField("0", text: Binding(
                                        get: { viewModel.foreignAmount },
                                        set: { viewModel.updateForeignAmount($0) }
                                    ))
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.primary)
                                        .focused($focusedField, equals: .foreign)
                                        .environment(\.layoutDirection, .leftToRight)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                        )
                                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                
                // Historical rate button
                Button {
                    focusedField = nil // Dismiss keyboard first
                    showHistoricalRate = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 16, weight: .medium))
                        Text(String(localized: "view_historical_rate", defaultValue: "View Historical Rate"))
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .padding(.top, 32)
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
        }
        .scrollDismissesKeyboard(.never)
        .onTapGesture {
            focusedField = nil
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Done button above keyboard
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: "ok")) {
                    focusedField = nil
                }
            }
        }
        .sheet(isPresented: $showHistoricalRate) {
            NavigationStack {
                HistoricalRateView(
                    baseCurrency: viewModel.exchangeRate.key,
                    targetCurrency: viewModel.homeCurrencyCode
                )
            }
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            // Auto-focus on the home currency field when view appears
            // Note: In simulator, keyboard may not appear automatically - use Cmd+K to toggle
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                focusedField = .home
            }
        }
    }
}

#Preview {
    NavigationStack {
        CurrencyConverterView(exchangeRate: ExchangeRate(
            key: "USD",
            currentExchangeRate: 3.682,
            currentChange: 0.32,
            unit: 1,
            lastUpdate: "2025-12-24T13:21:03.7337919Z"
        ))
    }
}

