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
                // Header with currency info
                VStack(spacing: 12) {
                    Text(CurrencyFlagHelper.flag(for: viewModel.exchangeRate.key))
                        .font(.system(size: 64))
                    
                    Text("\(viewModel.exchangeRate.key) / \(viewModel.homeCurrencyCode)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("שער: \(viewModel.exchangeRate.formattedRate)")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)
                .padding(.bottom, 8)
                
                // Conversion fields
                VStack(spacing: 20) {
                    // Home Currency Input Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(viewModel.homeCurrencyCode)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(homeCurrencySymbol)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            TextField("0", text: Binding(
                                get: { viewModel.homeAmount },
                                set: { viewModel.updateHomeAmount($0) }
                            ))
                                .keyboardType(.decimalPad)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)
                                .focused($focusedField, equals: .home)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    
                    // Arrow indicator
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                    
                    // Foreign Currency Input Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.exchangeRate.key)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(CurrencyFlagHelper.flag(for: viewModel.exchangeRate.key))
                                .font(.system(size: 24))
                            
                            TextField("0", text: Binding(
                                get: { viewModel.foreignAmount },
                                set: { viewModel.updateForeignAmount($0) }
                            ))
                                .keyboardType(.decimalPad)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)
                                .focused($focusedField, equals: .foreign)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("ממיר מטבע")
                    .font(.headline)
            }
        }
        .onAppear {
            // Auto-focus on the home currency field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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

