//
//  CryptoViewModel.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import Foundation
import SwiftUI
import Combine

class CryptoViewModel: ObservableObject {
    @Published var cryptocurrencies: [Cryptocurrency] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var currentTask: Task<Void, Never>?
    
    init() {
        loadCryptocurrencies()
    }
    
    func loadCryptocurrencies() {
        currentTask?.cancel()
        currentTask = Task {
            await loadCryptocurrenciesAsync()
        }
    }
    
    @MainActor
    func loadCryptocurrenciesAsync() async {
        let isInitialLoad = cryptocurrencies.isEmpty
        LogManager.shared.log("Starting crypto load - isInitialLoad: \(isInitialLoad)", level: .info, source: "CryptoViewModel")
        
        isLoading = isInitialLoad
        errorMessage = nil
        
        do {
            let cryptos = try await CryptoService.shared.fetchCryptoPrices()
            cryptocurrencies = cryptos
            isLoading = false
            LogManager.shared.log("Loaded \(cryptos.count) cryptocurrencies", level: .success, source: "CryptoViewModel")
        } catch {
            // Don't show error if task was cancelled
            if let urlError = error as? URLError, urlError.code == .cancelled {
                LogManager.shared.log("Request was cancelled", level: .warning, source: "CryptoViewModel")
                isLoading = false
                return
            }
            
            LogManager.shared.log("Error: \(error.localizedDescription)", level: .error, source: "CryptoViewModel")
            errorMessage = "Failed to load cryptocurrencies: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    @MainActor
    func refreshCryptocurrencies() async {
        LogManager.shared.log("Refreshing cryptocurrencies", level: .info, source: "CryptoViewModel")
        await loadCryptocurrenciesAsync()
    }
}

