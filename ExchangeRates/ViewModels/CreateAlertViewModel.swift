//
//  CreateAlertViewModel.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import Foundation
import SwiftUI
import Combine

enum ConditionType: String, CaseIterable {
    case above = "above"
    case below = "below"
    
    var localizedDisplayName: String {
        switch self {
        case .above:
            return String(localized: "above", defaultValue: "Above")
        case .below:
            return String(localized: "below", defaultValue: "Below")
        }
    }
}

class CreateAlertViewModel: ObservableObject {
    @Published var alertType: AlertType = .currency {
        didSet {
            // Reset selections when switching types
            if oldValue != alertType {
                baseCurrency = ""
                targetCurrency = ""
                selectedCrypto = nil
                currentRate = nil
            }
        }
    }
    @Published var baseCurrency: String = "" {
        didSet {
            if alertType == .currency && !baseCurrency.isEmpty && !targetCurrency.isEmpty && oldValue != baseCurrency {
                loadCurrentRate()
            }
        }
    }
    @Published var targetCurrency: String = "" {
        didSet {
            if alertType == .currency && !baseCurrency.isEmpty && !targetCurrency.isEmpty && oldValue != targetCurrency {
                loadCurrentRate()
            }
        }
    }
    @Published var selectedCrypto: String? = nil {
        didSet {
            if alertType == .crypto && selectedCrypto != nil && oldValue != selectedCrypto {
                loadCurrentRate()
            }
        }
    }
    @Published var conditionType: ConditionType = .above
    @Published var targetValue: String = ""
    @Published var isEnabled: Bool = true
    @Published var autoResetHours: Int? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentRate: Double?
    @Published var isLoadingRate: Bool = false
    
    private let alertManager = CurrencyAlertManager.shared
    private let alertChecker = AlertCheckerService.shared
    private let cryptoService = CryptoService.shared
    var editingAlert: CurrencyAlert?
    
    // Cached currencies list - computed once on initialization
    private lazy var cachedCurrencies: [String] = computeAvailableCurrencies()
    
    init(editingAlert: CurrencyAlert? = nil) {
        self.editingAlert = editingAlert
        if let alert = editingAlert {
            loadAlertForEditing(alert)
        }
    }
    
    func loadAlertForEditing(_ alert: CurrencyAlert) {
        alertType = alert.alertType
        baseCurrency = alert.baseCurrency
        targetCurrency = alert.targetCurrency
        selectedCrypto = alert.cryptoId
        switch alert.condition {
        case .above:
            conditionType = .above
        case .below:
            conditionType = .below
        }
        targetValue = String(describing: alert.targetValue)
        isEnabled = alert.isEnabled
        autoResetHours = alert.autoResetAfterHours
        editingAlert = alert
        
        // Load current rate when editing
        if alertType == .currency && !baseCurrency.isEmpty && !targetCurrency.isEmpty {
            loadCurrentRate()
        } else if alertType == .crypto, selectedCrypto != nil {
            loadCurrentRate()
        }
    }
    
    func saveAlert() -> Bool {
        guard validateInput() else {
            return false
        }
        
        guard let targetValueDecimal = Decimal(string: targetValue) else {
            errorMessage = String(localized: "invalid_target_value", defaultValue: "Invalid target value")
            return false
        }
        
        // Update condition with the target value
        let updatedCondition: AlertCondition
        let targetDouble = Double(truncating: targetValueDecimal as NSDecimalNumber)
        switch conditionType {
        case .above:
            updatedCondition = .above(targetDouble)
        case .below:
            updatedCondition = .below(targetDouble)
        }
        
        // Get crypto info if it's a crypto alert
        let cryptoId: String?
        let cryptoSymbol: String?
        if alertType == .crypto {
            cryptoId = selectedCrypto
            // Get symbol from crypto list
            if let id = selectedCrypto, let crypto = getAvailableCryptos().first(where: { $0.id == id }) {
                cryptoSymbol = crypto.symbol.uppercased()
            } else {
                cryptoSymbol = nil
            }
        } else {
            cryptoId = nil
            cryptoSymbol = nil
        }
        
        let alert: CurrencyAlert
        if let editing = editingAlert {
            // Update existing alert
            alert = CurrencyAlert(
                id: editing.id,
                alertType: alertType,
                baseCurrency: alertType == .crypto ? "USD" : baseCurrency,
                targetCurrency: alertType == .crypto ? "USD" : targetCurrency,
                condition: updatedCondition,
                targetValue: targetValueDecimal,
                isEnabled: isEnabled,
                status: editing.status,
                triggeredAt: editing.triggeredAt,
                createdAt: editing.createdAt,
                autoResetAfterHours: autoResetHours,
                cryptoId: cryptoId,
                cryptoSymbol: cryptoSymbol
            )
        } else {
            // Create new alert
            alert = CurrencyAlert(
                alertType: alertType,
                baseCurrency: alertType == .crypto ? "USD" : baseCurrency,
                targetCurrency: alertType == .crypto ? "USD" : targetCurrency,
                condition: updatedCondition,
                targetValue: targetValueDecimal,
                isEnabled: isEnabled,
                autoResetAfterHours: autoResetHours,
                cryptoId: cryptoId,
                cryptoSymbol: cryptoSymbol
            )
        }
        
        alertManager.saveAlert(alert)
        return true
    }
    
    func validateInput() -> Bool {
        errorMessage = nil
        
        if alertType == .crypto {
            guard selectedCrypto != nil else {
                errorMessage = String(localized: "please_select_crypto", defaultValue: "Please select a cryptocurrency")
                return false
            }
        } else {
            guard !baseCurrency.isEmpty else {
                errorMessage = String(localized: "please_select_base_currency", defaultValue: "Please select a base currency")
                return false
            }
            
            guard !targetCurrency.isEmpty else {
                errorMessage = String(localized: "please_select_target_currency", defaultValue: "Please select a target currency")
                return false
            }
            
            guard baseCurrency != targetCurrency else {
                errorMessage = String(localized: "base_and_target_must_differ", defaultValue: "Base currency and target currency must be different")
                return false
            }
        }
        
        guard !targetValue.isEmpty else {
            errorMessage = String(localized: "please_enter_target_value", defaultValue: "Please enter a target value")
            return false
        }
        
        guard let value = Decimal(string: targetValue), value > 0 else {
            errorMessage = String(localized: "target_value_must_be_positive", defaultValue: "Target value must be a positive number")
            return false
        }
        
        return true
    }
    
    func getAvailableCurrencies() -> [String] {
        return cachedCurrencies
    }
    
    private func computeAvailableCurrencies() -> [String] {
        let customCurrencies = CustomCurrencyManager.shared.getCustomCurrencies()
        return MainCurrenciesHelper.getAllCurrenciesIncludingCustom(customCurrencies: customCurrencies)
    }
    
    func loadCurrentRate() {
        isLoadingRate = true
        
        Task {
            do {
                if alertType == .crypto {
                    guard let cryptoId = selectedCrypto else {
                        await MainActor.run {
                            currentRate = nil
                            isLoadingRate = false
                        }
                        return
                    }
                    let price = try await alertChecker.fetchCryptoPrice(id: cryptoId)
                    await MainActor.run {
                        currentRate = price
                        isLoadingRate = false
                    }
                } else {
                    guard !baseCurrency.isEmpty, !targetCurrency.isEmpty, baseCurrency != targetCurrency else {
                        await MainActor.run {
                            currentRate = nil
                            isLoadingRate = false
                        }
                        return
                    }
                    let rate = try await alertChecker.fetchRateForPair(
                        base: baseCurrency,
                        target: targetCurrency
                    )
                    await MainActor.run {
                        currentRate = rate.currentExchangeRate
                        isLoadingRate = false
                    }
                }
            } catch {
                await MainActor.run {
                    currentRate = nil
                    isLoadingRate = false
                    LogManager.shared.log("Failed to load current rate: \(error.localizedDescription)", level: .warning, source: "CreateAlertViewModel")
                }
            }
        }
    }
    
    func swapCurrencies() {
        guard alertType == .currency else { return }
        guard !baseCurrency.isEmpty && !targetCurrency.isEmpty && baseCurrency != targetCurrency else {
            return
        }
        
        // Swap currencies
        let tempCurrency = baseCurrency
        baseCurrency = targetCurrency
        targetCurrency = tempCurrency
        
        // Invert the current rate
        if let rate = currentRate, rate > 0 {
            currentRate = 1.0 / rate
        }
        
        // Invert the target value
        if let targetValueDecimal = Decimal(string: targetValue), targetValueDecimal > 0 {
            let invertedValue = Decimal(1) / targetValueDecimal
            targetValue = String(describing: invertedValue)
        }
        
        // Swap condition type (above ↔ below)
        conditionType = conditionType == .above ? .below : .above
    }
    
    func getAvailableCryptos() -> [Cryptocurrency] {
        // Return cached list - we'll need to fetch this from the service
        // For now, return empty and we'll populate it when needed
        return []
    }
    
    func getCryptoList() -> [(id: String, name: String, symbol: String)] {
        // Map of common crypto IDs to their symbols
        let cryptoSymbolMap: [String: String] = [
            "bitcoin": "BTC",
            "ethereum": "ETH",
            "tether": "USDT",
            "binancecoin": "BNB",
            "ripple": "XRP",
            "usd-coin": "USDC",
            "solana": "SOL",
            "staked-ether": "STETH",
            "tron": "TRX",
            "dogecoin": "DOGE",
            "cardano": "ADA",
            "wrapped-steth": "WSTETH",
            "whitebit": "WBT",
            "bitcoin-cash": "BCH",
            "wrapped-bitcoin": "WBTC",
            "wrapped-beacon-eth": "WBETH",
            "wrapped-eeth": "WEETH",
            "chainlink": "LINK",
            "usds": "USDS",
            "leo-token": "LEO",
            "weth": "WETH",
            "zcash": "ZEC",
            "monero": "XMR",
            "stellar": "XLM",
            "coinbase-wrapped-btc": "CBBTC",
            "ethena-usde": "USDE",
            "litecoin": "LTC",
            "sui": "SUI",
            "avalanche-2": "AVAX",
            "hyperliquid": "HYPE",
            "hedera-hashgraph": "HBAR",
            "shiba-inu": "SHIB",
            "the-open-network": "TON",
            "dai": "DAI",
            "uniswap": "UNI",
            "cronos": "CRO",
            "paypal-usd": "PYUSD",
            "polkadot": "DOT",
            "ethena-staked-usde": "SUSDE",
            "mantle": "MNT",
            "pepe": "PEPE",
            "aave": "AAVE",
            "bitget-token": "BGB",
            "okb": "OKB",
            "bittensor": "TAO",
            "tether-gold": "XAUT",
            "near": "NEAR",
            "ethereum-classic": "ETC",
            "jito-staked-sol": "JITOSOL",
            "ethena": "ENA",
            "internet-computer": "ICP",
            "wrapped-solana": "WSOL",
            "pax-gold": "PAXG",
            "worldcoin-wld": "WLD",
            "kucoin-shares": "KCS",
            "aptos": "APT",
            "binance-staked-sol": "BNSOL",
            "ondo-finance": "ONDO",
            "rocket-pool-eth": "RETH",
            "wbnb": "WBNB",
            "gatechain-token": "GT",
            "kaspa": "KAS",
            "arbitrum": "ARB",
            "polygon-ecosystem-token": "POL",
            "quant-network": "QNT",
            "algorand": "ALGO",
            "filecoin": "FIL",
            "cosmos": "ATOM",
            "official-trump": "TRUMP",
            "vechain": "VET",
            "render-token": "RENDER",
            "immutable-x": "IMX",
            "injective-protocol": "INJ",
            "optimism": "OP",
            "stacks": "STX",
            "the-graph": "GRT",
            "sei-network": "SEI",
            "celestia": "TIA",
            "maker": "MKR",
            "theta-token": "THETA",
            "fantom": "FTM",
            "flow": "FLOW",
            "floki": "FLOKI",
            "bonk": "BONK",
            "lido-dao": "LDO",
            "first-digital-usd": "FDUSD",
            "fetch-ai": "FET",
            "arweave": "AR",
            "gala": "GALA",
            "helium": "HNT",
            "jupiter-exchange-solana": "JUP",
            "pyth-network": "PYTH",
            "axie-infinity": "AXS",
            "eos": "EOS",
            "beam-2": "BEAM",
            "neo": "NEO",
            "core": "CORE",
            "thorchain": "RUNE",
            "pendle": "PENDLE",
            "dydx-chain": "DYDX"
        ]
        
        // Return list of main cryptos with their info
        return MainCryptoHelper.mainCryptos.map { id in
            let symbol = cryptoSymbolMap[id] ?? id.split(separator: "-").first?.uppercased() ?? id.uppercased()
            let name = id.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
            return (id: id, name: name, symbol: String(symbol))
        }
    }
}

