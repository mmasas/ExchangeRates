//
//  MainCryptoHelper.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import Foundation

class MainCryptoHelper {
    /// Page size for pagination
    static let pageSize = 50
    
    /// The top 100 cryptocurrencies by market cap (CoinGecko IDs)
    static let mainCryptos: [String] = [
        // Page 1 (1-50)
        "bitcoin",                          // 1. BTC
        "ethereum",                         // 2. ETH
        "tether",                           // 3. USDT
        "binancecoin",                      // 4. BNB
        "ripple",                           // 5. XRP
        "usd-coin",                         // 6. USDC
        "solana",                           // 7. SOL
        "staked-ether",                     // 8. STETH (Lido Staked Ether)
        "tron",                             // 9. TRX
        "dogecoin",                         // 10. DOGE
        "cardano",                          // 11. ADA
        "wrapped-steth",                    // 12. WSTETH
        "whitebit",                         // 13. WBT
        "bitcoin-cash",                     // 14. BCH
        "wrapped-bitcoin",                  // 15. WBTC
        "wrapped-beacon-eth",               // 16. WBETH
        "wrapped-eeth",                     // 17. WEETH
        "chainlink",                        // 18. LINK
        "usds",                             // 19. USDS
        "leo-token",                        // 20. LEO
        "weth",                             // 21. WETH
        "zcash",                            // 22. ZEC
        "monero",                           // 23. XMR
        "stellar",                          // 24. XLM
        "coinbase-wrapped-btc",             // 25. CBBTC
        "ethena-usde",                      // 26. USDE
        "litecoin",                         // 27. LTC
        "sui",                              // 28. SUI
        "avalanche-2",                      // 29. AVAX
        "hyperliquid",                      // 30. HYPE
        "hedera-hashgraph",                 // 31. HBAR
        "shiba-inu",                        // 32. SHIB
        "the-open-network",                 // 33. TON
        "dai",                              // 34. DAI
        "uniswap",                          // 35. UNI
        "cronos",                           // 36. CRO
        "paypal-usd",                       // 37. PYUSD
        "polkadot",                         // 38. DOT
        "ethena-staked-usde",               // 39. SUSDE
        "mantle",                           // 40. MNT
        "pepe",                             // 41. PEPE
        "aave",                             // 42. AAVE
        "bitget-token",                     // 43. BGB
        "okb",                              // 44. OKB
        "bittensor",                        // 45. TAO
        "tether-gold",                      // 46. XAUT
        "near",                             // 47. NEAR
        "ethereum-classic",                 // 48. ETC
        "jito-staked-sol",                  // 49. JITOSOL
        "ethena",                           // 50. ENA
        
        // Page 2 (51-100)
        "internet-computer",                // 51. ICP
        "wrapped-solana",                   // 52. Wrapped SOL
        "pax-gold",                         // 53. PAXG
        "worldcoin-wld",                    // 54. WLD
        "kucoin-shares",                    // 55. KCS
        "aptos",                            // 56. APT
        "binance-staked-sol",               // 57. BNSOL
        "ondo-finance",                     // 58. ONDO
        "rocket-pool-eth",                  // 59. RETH
        "wbnb",                             // 60. WBNB
        "gatechain-token",                  // 61. GT
        "kaspa",                            // 62. KAS
        "arbitrum",                         // 63. ARB
        "polygon-ecosystem-token",          // 64. POL
        "quant-network",                    // 65. QNT
        "algorand",                         // 66. ALGO
        "filecoin",                         // 67. FIL
        "cosmos",                           // 68. ATOM
        "official-trump",                   // 69. TRUMP
        "vechain",                          // 70. VET
        "render-token",                     // 71. RENDER
        "immutable-x",                      // 72. IMX
        "injective-protocol",               // 73. INJ
        "optimism",                         // 74. OP
        "stacks",                           // 75. STX
        "the-graph",                        // 76. GRT
        "sei-network",                      // 77. SEI
        "celestia",                         // 78. TIA
        "maker",                            // 79. MKR
        "theta-token",                      // 80. THETA
        "fantom",                           // 81. FTM
        "flow",                             // 82. FLOW
        "floki",                            // 83. FLOKI
        "bonk",                             // 84. BONK
        "lido-dao",                         // 85. LDO
        "first-digital-usd",                // 86. FDUSD
        "fetch-ai",                         // 87. FET
        "arweave",                          // 88. AR
        "gala",                             // 89. GALA
        "helium",                           // 90. HNT
        "jupiter-exchange-solana",          // 91. JUP
        "pyth-network",                     // 92. PYTH
        "axie-infinity",                    // 93. AXS
        "eos",                              // 94. EOS
        "beam-2",                           // 95. BEAM
        "neo",                              // 96. NEO
        "core",                             // 97. CORE
        "thorchain",                        // 98. RUNE
        "pendle",                           // 99. PENDLE
        "dydx-chain"                        // 100. DYDX
    ]
    
    /// Total number of pages
    static var totalPages: Int {
        return (mainCryptos.count + pageSize - 1) / pageSize
    }
    
    /// Get crypto IDs for a specific page (1-indexed)
    static func getCryptos(forPage page: Int) -> [String] {
        guard page >= 1 && page <= totalPages else { return [] }
        
        let startIndex = (page - 1) * pageSize
        let endIndex = min(startIndex + pageSize, mainCryptos.count)
        
        return Array(mainCryptos[startIndex..<endIndex])
    }
    
    /// Check if a crypto is in the main list
    static func isMainCrypto(_ id: String) -> Bool {
        return mainCryptos.contains(id)
    }
    
    /// Get all crypto IDs as a comma-separated string for API requests
    static func getCryptoIdsString() -> String {
        return mainCryptos.joined(separator: ",")
    }
}
