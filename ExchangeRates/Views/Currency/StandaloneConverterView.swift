//
//  StandaloneConverterView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 09/01/2026.
//

import SwiftUI

struct StandaloneConverterView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: StandaloneConverterViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @FocusState private var focusedField: Field?
    
    @State private var showSourcePicker = false
    @State private var showTargetPicker = false
    
    enum Field {
        case source, target
    }
    
    private var theme: AppTheme { themeManager.currentTheme }
    private var primaryColor: Color { theme.usesSystemColors ? .primary : theme.primaryTextColor }
    private var secondaryColor: Color { theme.usesSystemColors ? .secondary : theme.secondaryTextColor }
    private var cardBackground: Color { theme.usesSystemColors ? Color(.systemBackground) : theme.cardBackgroundColor }
    private var backgroundColor: Color { theme.usesSystemColors ? Color(.systemGroupedBackground) : theme.backgroundColor }
    
    init(exchangeRates: [ExchangeRate]) {
        _viewModel = StateObject(wrappedValue: StandaloneConverterViewModel(exchangeRates: exchangeRates))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Exchange rate display
                    VStack(spacing: 8) {
                        Text("1 \(viewModel.sourceCurrency) = \(viewModel.formattedCrossRate) \(viewModel.targetCurrency)")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(secondaryColor)
                    }
                    .padding(.top, 16)
                    
                    // Conversion fields
                    VStack(spacing: 16) {
                        // Source Currency Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(String(localized: "source_currency", defaultValue: "From")) - \(CurrencyFlagHelper.currencyName(for: viewModel.sourceCurrency))")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(secondaryColor)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            
                            HStack(spacing: 12) {
                                // Currency selector button
                                Button {
                                    focusedField = nil
                                    showSourcePicker = true
                                } label: {
                                    HStack(spacing: 8) {
                                        CurrencyFlagHelper.circularFlag(for: viewModel.sourceCurrency, size: 28)
                                        
                                        Text(viewModel.sourceCurrency)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(primaryColor)
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(secondaryColor)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(theme.usesSystemColors ? Color(.systemGray5) : theme.secondaryBackgroundColor)
                                    )
                                }
                                
                                // Amount input
                                TextField("0", text: Binding(
                                    get: { viewModel.sourceAmount },
                                    set: { viewModel.updateSourceAmount($0) }
                                ))
                                .keyboardType(.decimalPad)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(primaryColor)
                                .focused($focusedField, equals: .source)
                                .environment(\.layoutDirection, .leftToRight)
                                .multilineTextAlignment(.trailing)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(secondaryColor.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            )
                        }
                        
                        // Swap button
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.swapCurrencies()
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(theme.accentColor)
                                .background(
                                    Circle()
                                        .fill(cardBackground)
                                        .frame(width: 32, height: 32)
                                )
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Target Currency Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(String(localized: "target_currency", defaultValue: "To")) - \(CurrencyFlagHelper.currencyName(for: viewModel.targetCurrency))")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(secondaryColor)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            
                            HStack(spacing: 12) {
                                // Currency selector button
                                Button {
                                    focusedField = nil
                                    showTargetPicker = true
                                } label: {
                                    HStack(spacing: 8) {
                                        CurrencyFlagHelper.circularFlag(for: viewModel.targetCurrency, size: 28)
                                        
                                        Text(viewModel.targetCurrency)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(primaryColor)
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(secondaryColor)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(theme.usesSystemColors ? Color(.systemGray5) : theme.secondaryBackgroundColor)
                                    )
                                }
                                
                                // Amount input
                                TextField("0", text: Binding(
                                    get: { viewModel.targetAmount },
                                    set: { viewModel.updateTargetAmount($0) }
                                ))
                                .keyboardType(.decimalPad)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(primaryColor)
                                .focused($focusedField, equals: .target)
                                .environment(\.layoutDirection, .leftToRight)
                                .multilineTextAlignment(.trailing)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(secondaryColor.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
            }
            .scrollDismissesKeyboard(.never)
            .onTapGesture {
                focusedField = nil
            }
            .background(backgroundColor)
            .navigationTitle(String(localized: "currency_converter_title", defaultValue: "Currency Converter"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.usesSystemColors ? .automatic : .visible, for: .navigationBar)
            .toolbarBackground(theme.usesSystemColors ? Color.clear : theme.secondaryBackgroundColor, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "close", defaultValue: "Close")) {
                        dismiss()
                    }
                }
                
                // Done button above keyboard
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(String(localized: "ok")) {
                        focusedField = nil
                    }
                }
            }
            .sheet(isPresented: $showSourcePicker) {
                CurrencyPickerSheet(
                    selectedCurrency: $viewModel.sourceCurrency,
                    availableCurrencies: viewModel.getAvailableCurrencies(),
                    title: String(localized: "select_currency", defaultValue: "Select Currency")
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showTargetPicker) {
                CurrencyPickerSheet(
                    selectedCurrency: $viewModel.targetCurrency,
                    availableCurrencies: viewModel.getAvailableCurrencies(),
                    title: String(localized: "select_currency", defaultValue: "Select Currency")
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: viewModel.sourceCurrency) { _, _ in
                // Recalculate when currency changes
                if !viewModel.sourceAmount.isEmpty {
                    viewModel.updateSourceAmount(viewModel.sourceAmount)
                }
            }
            .onChange(of: viewModel.targetCurrency) { _, _ in
                // Recalculate when currency changes
                if !viewModel.sourceAmount.isEmpty {
                    viewModel.updateSourceAmount(viewModel.sourceAmount)
                }
            }
        }
    }
}

#Preview {
    StandaloneConverterView(exchangeRates: [
        ExchangeRate(key: "USD", currentExchangeRate: 3.682, currentChange: 0.32, unit: 1, lastUpdate: "2025-12-24T13:21:03.7337919Z"),
        ExchangeRate(key: "EUR", currentExchangeRate: 3.92, currentChange: -0.15, unit: 1, lastUpdate: "2025-12-24T13:21:03.7337919Z"),
        ExchangeRate(key: "GBP", currentExchangeRate: 4.65, currentChange: 0.22, unit: 1, lastUpdate: "2025-12-24T13:21:03.7337919Z")
    ])
}
