//
//  CryptoView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import SwiftUI

struct CryptoView: View {
    @StateObject private var viewModel = CryptoViewModel()
    @State private var isSearchActive = false
    @FocusState private var isSearchFocused: Bool
    
    /// The row index at which to trigger prefetching of the next page
    private let prefetchThreshold = 35
    
    var body: some View {
        NavigationStack {
            Group {
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
                            ForEach(Array(viewModel.filteredCryptocurrencies.enumerated()), id: \.element.id) { index, crypto in
                                CryptoRow(
                                    cryptocurrency: crypto,
                                    sparklinePrices: crypto.sparklinePrices
                                )
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .onAppear {
                                    // Trigger prefetch when reaching the threshold row (only when not searching)
                                    if viewModel.searchText.isEmpty && index == prefetchThreshold && viewModel.hasMorePages {
                                        viewModel.prefetchNextPage()
                                    }
                                }
                            }
                            
                            // Show loading indicator at bottom when loading next page
                            if viewModel.isLoadingNextPage {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding(.vertical, 16)
                                    Spacer()
                                }
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        LogManager.shared.log("Pull to refresh triggered", level: .info, source: "CryptoView")
                        await viewModel.refreshCryptocurrencies()
                        LogManager.shared.log("Pull to refresh completed", level: .success, source: "CryptoView")
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                // Custom header with blur effect
                VStack(spacing: 0) {
                    HStack {
                        // Search button (leading side)
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isSearchActive.toggle()
                                if isSearchActive {
                                    isSearchFocused = true
                                } else {
                                    viewModel.searchText = ""
                                    isSearchFocused = false
                                }
                            }
                        } label: {
                            Image(systemName: isSearchActive ? "xmark" : "magnifyingglass")
                                .foregroundColor(.primary)
                                .font(.system(size: 20))
                        }
                        .frame(width: 44, height: 44)
                        
                        Spacer()
                        
                        Text(String(localized: "crypto_title"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Empty spacer to balance the header
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, isSearchActive ? 8 : 12)
                    .padding(.horizontal, 16)
                    
                    // Search bar (only visible when active)
                    if isSearchActive {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            
                            TextField(String(localized: "search_crypto"), text: $viewModel.searchText)
                                .textFieldStyle(.plain)
                                .focused($isSearchFocused)
                            
                            if !viewModel.searchText.isEmpty {
                                Button {
                                    viewModel.searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .animation(.easeInOut(duration: 0.25), value: isSearchActive)
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    CryptoView()
}
