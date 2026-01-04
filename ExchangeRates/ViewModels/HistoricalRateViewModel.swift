//
//  HistoricalRateViewModel.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import Foundation
import SwiftUI
import Combine

class HistoricalRateViewModel: ObservableObject {
    @Published var baseCurrency: String
    @Published var targetCurrency: String
    @Published var selectedDate: Date = Date()
    @Published var historicalRate: ExchangeRate?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let currencyService = CustomCurrencyService.shared
    private let networkMonitor = NetworkMonitor.shared
    
    init(baseCurrency: String, targetCurrency: String) {
        self.baseCurrency = baseCurrency
        self.targetCurrency = targetCurrency
        // Set default date to yesterday to avoid issues with today's data availability
        self.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    }
    
    func fetchHistoricalRate() {
        guard !baseCurrency.isEmpty, !targetCurrency.isEmpty, baseCurrency != targetCurrency else {
            errorMessage = String(localized: "base_and_target_must_differ", defaultValue: "Base currency and target currency must be different")
            return
        }
        
        // Check if offline - historical rates require network
        if !networkMonitor.isConnected {
            isLoading = false
            errorMessage = String(localized: "offline_historical_rates_unavailable", defaultValue: "Historical rates are not available offline. Please connect to the internet.")
            historicalRate = nil
            return
        }
        
        // Ensure date is not in the future
        let maxDate = Date()
        let dateToFetch = selectedDate > maxDate ? maxDate : selectedDate
        
        isLoading = true
        errorMessage = nil
        historicalRate = nil
        
        Task {
            do {
                let rate = try await currencyService.fetchHistoricalRate(
                    for: baseCurrency,
                    target: targetCurrency,
                    date: dateToFetch
                )
                
                await MainActor.run {
                    self.historicalRate = rate
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.historicalRate = nil
                    self.isLoading = false
                    if let urlError = error as? URLError, urlError.code == .badServerResponse {
                        self.errorMessage = String(localized: "no_data_for_date", defaultValue: "No data available for this date")
                    } else {
                        self.errorMessage = String(format: String(localized: "failed_to_load_exchange_rate", defaultValue: "Failed to load exchange rate: %@"), error.localizedDescription)
                    }
                }
            }
        }
    }
    
    func swapCurrencies() {
        guard !baseCurrency.isEmpty && !targetCurrency.isEmpty && baseCurrency != targetCurrency else {
            return
        }
        
        let tempCurrency = baseCurrency
        baseCurrency = targetCurrency
        targetCurrency = tempCurrency
        
        // Clear current rate when swapping
        historicalRate = nil
        errorMessage = nil
    }
}

