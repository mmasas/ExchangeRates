//
//  MainCryptoHelper.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import Foundation

class MainCryptoHelper {
    /// The top 50 cryptocurrencies by market cap (CoinGecko IDs)
    static let mainCryptos: [String] = [
        "bitcoin",
        "ethereum",
        "tether",
        "binancecoin",
        "solana",
        "ripple",
        "usd-coin",
        "cardano",
        "dogecoin",
        "avalanche-2",
        "tron",
        "chainlink",
        "polkadot",
        "polygon-ecosystem-token",
        "shiba-inu",
        "wrapped-bitcoin",
        "dai",
        "litecoin",
        "bitcoin-cash",
        "uniswap",
        "stellar",
        "leo-token",
        "monero",
        "ethereum-classic",
        "okb",
        "internet-computer",
        "kaspa",
        "hedera-hashgraph",
        "aptos",
        "filecoin",
        "cosmos",
        "mantle",
        "immutable-x",
        "cronos",
        "vechain",
        "render-token",
        "near",
        "injective-protocol",
        "optimism",
        "stacks",
        "the-graph",
        "bittensor",
        "sei-network",
        "celestia",
        "algorand",
        "maker",
        "arbitrum",
        "theta-token",
        "fantom",
        "flow"
    ]
    
    /// Check if a crypto is in the main list
    static func isMainCrypto(_ id: String) -> Bool {
        return mainCryptos.contains(id)
    }
    
    /// Get all crypto IDs as a comma-separated string for API requests
    static func getCryptoIdsString() -> String {
        return mainCryptos.joined(separator: ",")
    }
}

