//
//  CryptoView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import SwiftUI

struct CryptoView: View {
    @StateObject private var viewModel = CryptoViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Content - starts behind the header, scrolls underneath it
                if let errorMessage = viewModel.errorMessage, !viewModel.isLoading {
                    VStack {
                        Text(String(localized: "error"))
                            .font(.headline)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 60)
                } else {
                    List {
                        if viewModel.isLoading && viewModel.cryptocurrencies.isEmpty {
                            // Show skeleton rows when loading and no data exists
                            ForEach(0..<10, id: \.self) { _ in
                                CryptoRowSkeleton()
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                        } else {
                            // Show actual cryptocurrency data
                            ForEach(viewModel.cryptocurrencies) { crypto in
                                CryptoRow(cryptocurrency: crypto)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .contentMargins(.top, 60, for: .scrollContent)
                    .refreshable {
                        LogManager.shared.log("Pull to refresh triggered", level: .info, source: "CryptoView")
                        await viewModel.refreshCryptocurrencies()
                        LogManager.shared.log("Pull to refresh completed", level: .success, source: "CryptoView")
                    }
                }
                
                // Custom header with blur effect (like tab bar)
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        
                        Text(String(localized: "crypto_title", defaultValue: "Crypto"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .padding(.horizontal, 16)
                    
                    // Divider()
                }
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    CryptoView()
}

