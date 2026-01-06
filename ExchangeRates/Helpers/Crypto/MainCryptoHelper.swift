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
    
    // MARK: - WebSocket Configuration
    
    /// Cryptocurrencies that should use WebSocket for real-time updates
    /// These are typically the most popular/traded cryptocurrencies
    static let websocketEnabledCryptos: [String] = [
        "bitcoin",           // BTC
        "ethereum",          // ETH
        "binancecoin",       // BNB
        "ripple",            // XRP
       // "usd-coin",          // USDC
        "solana",            // SOL
        "cardano",           // ADA
        "dogecoin",          // DOGE
        "chainlink",         // LINK
        "litecoin",          // LTC
        "avalanche-2",       // AVAX
        "shiba-inu",         // SHIB
        "the-open-network",  // TON
        "uniswap",           // UNI
        "polkadot",          // DOT
        "pepe",              // PEPE
        "aave",              // AAVE
        "near",              // NEAR
        "internet-computer", // ICP
        "aptos"              // APT
    ]
     
    /// Check if a crypto should use WebSocket updates
    static func shouldUseWebSocket(_ id: String) -> Bool {
        return websocketEnabledCryptos.contains(id)
    }
    
    /// Get Binance symbols for WebSocket-enabled cryptos
    static func getWebSocketSymbols() -> [String] {
        return websocketEnabledCryptos.compactMap { coinGeckoToBinanceSymbol[$0] }
    }
    
    // MARK: - Binance Pairs
    
    /// Dictionary mapping Binance trading pair symbols to cryptocurrency names
    /// Contains 641 USDT trading pairs (bainance.json data embedded in code for backup)
    static let binancePairsDict: [String: String] = [
        "BTCUSDT": "bitcoin",
        "ETHUSDT": "ethereum",
        "BNBUSDT": "binance coin",
        "BCCUSDT": "bitcoin cash",
        "NEOUSDT": "neo",
        "LTCUSDT": "litecoin",
        "QTUMUSDT": "qtum",
        "ADAUSDT": "cardano",
        "XRPUSDT": "ripple",
        "EOSUSDT": "eos",
        "TUSDUSDT": "trueusd",
        "IOTAUSDT": "iota",
        "XLMUSDT": "stellar",
        "ONTUSDT": "ontology",
        "TRXUSDT": "tron",
        "ETCUSDT": "ethereum classic",
        "ICXUSDT": "icon",
        "NULSUSDT": "nuls",
        "VETUSDT": "vechain",  // VENUSDT removed - VET is the correct symbol
        "PAXUSDT": "pax",
        "BCHABCUSDT": "bchabc",
        "BCHSVUSDT": "bchsv",
        "USDCUSDT": "usdc",
        "LINKUSDT": "link",
        "WAVESUSDT": "waves",
        "BTTUSDT": "btt",
        "USDSUSDT": "usds",
        "ONGUSDT": "ong",
        "HOTUSDT": "hot",
        "ZILUSDT": "zil",
        "ZRXUSDT": "zrx",
        "FETUSDT": "fet",
        "BATUSDT": "bat",
        "XMRUSDT": "xmr",
        "ZECUSDT": "zec",
        "IOSTUSDT": "iost",
        "CELRUSDT": "celr",
        "DASHUSDT": "dash",
        "NANOUSDT": "nano",
        "OMGUSDT": "omg",
        "THETAUSDT": "theta",
        "ENJUSDT": "enj",
        "MITHUSDT": "mith",
        "MATICUSDT": "matic",
        "ATOMUSDT": "atom",
        "TFUELUSDT": "tfuel",
        "ONEUSDT": "one",
        "FTMUSDT": "ftm",
        "ALGOUSDT": "algo",
        "USDSBUSDT": "usdsb",
        "GTOUSDT": "gto",
        "ERDUSDT": "erd",
        "DOGEUSDT": "doge",
        "DUSKUSDT": "dusk",
        "ANKRUSDT": "ankr",
        "WINUSDT": "win",
        "COSUSDT": "cos",
        "NPXSUSDT": "npxs",
        "COCOSUSDT": "cocos",
        "MTLUSDT": "mtl",
        "TOMOUSDT": "tomo",
        "PERLUSDT": "perl",
        "DENTUSDT": "dent",
        "MFTUSDT": "mft",
        "KEYUSDT": "key",
        "STORMUSDT": "storm",
        "DOCKUSDT": "dock",
        "WANUSDT": "wan",
        "FUNUSDT": "fun",
        "CVCUSDT": "cvc",
        "CHZUSDT": "chz",
        "BANDUSDT": "band",
        "BUSDUSDT": "busd",
        "BEAMUSDT": "beam",
        "XTZUSDT": "xtz",
        "RENUSDT": "ren",
        "RVNUSDT": "rvn",
        "HCUSDT": "hc",
        "HBARUSDT": "hbar",
        "NKNUSDT": "nkn",
        "STXUSDT": "stx",
        "KAVAUSDT": "kava",
        "ARPAUSDT": "arpa",
        "IOTXUSDT": "iotx",
        "RLCUSDT": "rlc",
        "MCOUSDT": "mco",
        "CTXCUSDT": "ctxc",
        "BCHUSDT": "bch",
        "TROYUSDT": "troy",
        "VITEUSDT": "vite",
        "FTTUSDT": "ftt",
        "EURUSDT": "eur",
        "OGNUSDT": "ogn",
        "DREPUSDT": "drep",
        "BULLUSDT": "bull",
        "BEARUSDT": "bear",
        "ETHBULLUSDT": "ethbull",
        "ETHBEARUSDT": "ethbear",
        "TCTUSDT": "tct",
        "WRXUSDT": "wrx",
        "BTSUSDT": "bts",
        "LSKUSDT": "lsk",
        "BNTUSDT": "bnt",
        "LTOUSDT": "lto",
        "EOSBULLUSDT": "eosbull",
        "EOSBEARUSDT": "eosbear",
        "XRPBULLUSDT": "xrpbull",
        "XRPBEARUSDT": "xrpbear",
        "STRATUSDT": "strat",
        "AIONUSDT": "aion",
        "MBLUSDT": "mbl",
        "COTIUSDT": "coti",
        "BNBBULLUSDT": "bnbbull",
        "BNBBEARUSDT": "bnbbear",
        "STPTUSDT": "stpt",
        "WTCUSDT": "wtc",
        "DATAUSDT": "data",
        "XZCUSDT": "xzc",
        "SOLUSDT": "solana",
        "CTSIUSDT": "ctsi",
        "HIVEUSDT": "hive",
        "CHRUSDT": "chr",
        "BTCUPUSDT": "btcup",
        "BTCDOWNUSDT": "btcdown",
        "GXSUSDT": "gxs",
        "ARDRUSDT": "ardr",
        "LENDUSDT": "lend",
        "MDTUSDT": "mdt",
        "STMXUSDT": "stmx",
        "KNCUSDT": "knc",
        "REPUSDT": "rep",
        "LRCUSDT": "lrc",
        "PNTUSDT": "pnt",
        "COMPUSDT": "comp",
        "BKRWUSDT": "bkrw",
        "SCUSDT": "sc",
        "ZENUSDT": "zen",
        "SNXUSDT": "snx",
        "ETHUPUSDT": "ethup",
        "ETHDOWNUSDT": "ethdown",
        "ADAUPUSDT": "adaup",
        "ADADOWNUSDT": "adadown",
        "LINKUPUSDT": "linkup",
        "LINKDOWNUSDT": "linkdown",
        "VTHOUSDT": "vtho",
        "DGBUSDT": "dgb",
        "GBPUSDT": "gbp",
        "SXPUSDT": "sxp",
        "MKRUSDT": "mkr",
        "DAIUSDT": "dai",
        "DCRUSDT": "dcr",
        "STORJUSDT": "storj",
        "BNBUPUSDT": "bnbup",
        "BNBDOWNUSDT": "bnbdown",
        "XTZUPUSDT": "xtzup",
        "XTZDOWNUSDT": "xtzdown",
        "MANAUSDT": "mana",
        "AUDUSDT": "aud",
        "YFIUSDT": "yfi",
        "BALUSDT": "bal",
        "BLZUSDT": "blz",
        "IRISUSDT": "iris",
        "KMDUSDT": "kmd",
        "JSTUSDT": "jst",
        "SRMUSDT": "srm",
        "ANTUSDT": "ant",
        "CRVUSDT": "crv",
        "SANDUSDT": "sand",
        "OCEANUSDT": "ocean",
        "NMRUSDT": "nmr",
        "DOTUSDT": "polkadot",
        "LUNAUSDT": "luna",
        "RSRUSDT": "rsr",
        "PAXGUSDT": "paxg",
        "WNXMUSDT": "wnxm",
        "TRBUSDT": "trb",
        "BZRXUSDT": "bzrx",
        "SUSHIUSDT": "sushi",
        "YFIIUSDT": "yfii",
        "KSMUSDT": "ksm",
        "EGLDUSDT": "egld",
        "DIAUSDT": "dia",
        "RUNEUSDT": "rune",
        "FIOUSDT": "fio",
        "UMAUSDT": "uma",
        "EOSUPUSDT": "eosup",
        "EOSDOWNUSDT": "eosdown",
        "TRXUPUSDT": "trxup",
        "TRXDOWNUSDT": "trxdown",
        "XRPUPUSDT": "xrpup",
        "XRPDOWNUSDT": "xrpdown",
        "DOTUPUSDT": "dotup",
        "DOTDOWNUSDT": "dotdown",
        "BELUSDT": "bel",
        "WINGUSDT": "wing",
        "LTCUPUSDT": "ltcup",
        "LTCDOWNUSDT": "ltcdown",
        "UNIUSDT": "uni",
        "NBSUSDT": "nbs",
        "OXTUSDT": "oxt",
        "SUNUSDT": "sun",
        "AVAXUSDT": "avalanche-2",
        "HNTUSDT": "hnt",
        "FLMUSDT": "flm",
        "UNIUPUSDT": "uniup",
        "UNIDOWNUSDT": "unidown",
        "ORNUSDT": "orn",
        "UTKUSDT": "utk",
        "XVSUSDT": "xvs",
        "ALPHAUSDT": "alpha",
        "AAVEUSDT": "aave",
        "NEARUSDT": "near",
        "SXPUPUSDT": "sxpup",
        "SXPDOWNUSDT": "sxpdown",
        "FILUSDT": "fil",
        "FILUPUSDT": "filup",
        "FILDOWNUSDT": "fildown",
        "YFIUPUSDT": "yfiup",
        "YFIDOWNUSDT": "yfidown",
        "INJUSDT": "inj",
        "AUDIOUSDT": "audio",
        "CTKUSDT": "ctk",
        "BCHUPUSDT": "bchup",
        "BCHDOWNUSDT": "bchdown",
        "AKROUSDT": "akro",
        "AXSUSDT": "axs",
        "HARDUSDT": "hard",
        "DNTUSDT": "dnt",
        "STRAXUSDT": "strax",
        "UNFIUSDT": "unfi",
        "ROSEUSDT": "rose",
        "AVAUSDT": "ava",
        "XEMUSDT": "xem",
        "AAVEUPUSDT": "aaveup",
        "AAVEDOWNUSDT": "aavedown",
        "SKLUSDT": "skl",
        "SUSDUSDT": "susd",
        "SUSHIUPUSDT": "sushiup",
        "SUSHIDOWNUSDT": "sushidown",
        "XLMUPUSDT": "xlmup",
        "XLMDOWNUSDT": "xlmdown",
        "GRTUSDT": "grt",
        "JUVUSDT": "juv",
        "PSGUSDT": "psg",
        "1INCHUSDT": "1inch",
        "REEFUSDT": "reef",
        "OGUSDT": "og",
        "ATMUSDT": "atm",
        "ASRUSDT": "asr",
        "CELOUSDT": "celo",
        "RIFUSDT": "rif",
        "BTCSTUSDT": "btcst",
        "TRUUSDT": "tru",
        "CKBUSDT": "ckb",
        "TWTUSDT": "twt",
        "FIROUSDT": "firo",
        "LITUSDT": "lit",
        "SFPUSDT": "sfp",
        "DODOUSDT": "dodo",
        "CAKEUSDT": "cake",
        "ACMUSDT": "acm",
        "BADGERUSDT": "badger",
        "FISUSDT": "fis",
        "OMUSDT": "om",
        "PONDUSDT": "pond",
        "DEGOUSDT": "dego",
        "ALICEUSDT": "alice",
        "LINAUSDT": "lina",
        "PERPUSDT": "perp",
        "RAMPUSDT": "ramp",
        "SUPERUSDT": "super",
        "CFXUSDT": "cfx",
        "EPSUSDT": "eps",
        "AUTOUSDT": "auto",
        "TKOUSDT": "tko",
        "PUNDIXUSDT": "pundix",
        "TLMUSDT": "tlm",
        "1INCHUPUSDT": "1inchup",
        "1INCHDOWNUSDT": "1inchdown",
        "BTGUSDT": "btg",
        "MIRUSDT": "mir",
        "BARUSDT": "bar",
        "FORTHUSDT": "forth",
        "BAKEUSDT": "bake",
        "BURGERUSDT": "burger",
        "SLPUSDT": "slp",
        "SHIBUSDT": "shib",
        "ICPUSDT": "icp",
        "ARUSDT": "ar",
        "POLSUSDT": "pols",
        "MDXUSDT": "mdx",
        "MASKUSDT": "mask",
        "LPTUSDT": "lpt",
        "NUUSDT": "nu",
        "XVGUSDT": "xvg",
        "ATAUSDT": "ata",
        "GTCUSDT": "gtc",
        "TORNUSDT": "torn",
        "KEEPUSDT": "keep",
        "ERNUSDT": "ern",
        "KLAYUSDT": "klay",
        "PHAUSDT": "pha",
        "BONDUSDT": "bond",
        "MLNUSDT": "mln",
        "DEXEUSDT": "dexe",
        "C98USDT": "c98",
        "CLVUSDT": "clv",
        "QNTUSDT": "qnt",
        "FLOWUSDT": "flow",
        "TVKUSDT": "tvk",
        "MINAUSDT": "mina",
        "RAYUSDT": "ray",
        "FARMUSDT": "farm",
        "ALPACAUSDT": "alpaca",
        "QUICKUSDT": "quick",
        "MBOXUSDT": "mbox",
        "FORUSDT": "for",
        "REQUSDT": "req",
        "GHSTUSDT": "ghst",
        "WAXPUSDT": "waxp",
        "TRIBEUSDT": "tribe",
        "GNOUSDT": "gno",
        "XECUSDT": "xec",
        "ELFUSDT": "elf",
        "DYDXUSDT": "dydx",
        "POLYUSDT": "poly",
        "IDEXUSDT": "idex",
        "VIDTUSDT": "vidt",
        "USDPUSDT": "usdp",
        "GALAUSDT": "gala",
        "ILVUSDT": "ilv",
        "YGGUSDT": "ygg",
        "SYSUSDT": "sys",
        "DFUSDT": "df",
        "FIDAUSDT": "fida",
        "FRONTUSDT": "front",
        "CVPUSDT": "cvp",
        "AGLDUSDT": "agld",
        "RADUSDT": "rad",
        "BETAUSDT": "beta",
        "RAREUSDT": "rare",
        "LAZIOUSDT": "lazio",
        "CHESSUSDT": "chess",
        "ADXUSDT": "adx",
        "AUCTIONUSDT": "auction",
        "DARUSDT": "dar",
        "BNXUSDT": "bnx",
        "RGTUSDT": "rgt",
        "MOVRUSDT": "movr",
        "CITYUSDT": "city",
        "ENSUSDT": "ens",
        "KP3RUSDT": "kp3r",
        "QIUSDT": "qi",
        "PORTOUSDT": "porto",
        "POWRUSDT": "powr",
        "VGXUSDT": "vgx",
        "JASMYUSDT": "jasmy",
        "AMPUSDT": "amp",
        "PLAUSDT": "pla",
        "PYRUSDT": "pyr",
        "RNDRUSDT": "rndr",
        "ALCXUSDT": "alcx",
        "SANTOSUSDT": "santos",
        "MCUSDT": "mc",
        "ANYUSDT": "any",
        "BICOUSDT": "bico",
        "FLUXUSDT": "flux",
        "FXSUSDT": "fxs",
        "VOXELUSDT": "voxel",
        "HIGHUSDT": "high",
        "CVXUSDT": "cvx",
        "PEOPLEUSDT": "people",
        "OOKIUSDT": "ooki",
        "SPELLUSDT": "spell",
        "USTUSDT": "ust",
        "JOEUSDT": "joe",
        "ACHUSDT": "ach",
        "IMXUSDT": "imx",
        "GLMRUSDT": "glmr",
        "LOKAUSDT": "loka",
        "SCRTUSDT": "scrt",
        "API3USDT": "api3",
        "BTTCUSDT": "bttc",
        "ACAUSDT": "aca",
        "ANCUSDT": "anc",
        "XNOUSDT": "xno",
        "WOOUSDT": "woo",
        "ALPINEUSDT": "alpine",
        "TUSDT": "t",
        "ASTRUSDT": "astr",
        "NBTUSDT": "nbt",
        "GMTUSDT": "gmt",
        "KDAUSDT": "kda",
        "APEUSDT": "ape",
        "BSWUSDT": "bsw",
        "BIFIUSDT": "bifi",
        "MULTIUSDT": "multi",
        "STEEMUSDT": "steem",
        "MOBUSDT": "mob",
        "NEXOUSDT": "nexo",
        "REIUSDT": "rei",
        "GALUSDT": "gal",
        "LDOUSDT": "ldo",
        "EPXUSDT": "epx",
        "OPUSDT": "op",
        "LEVERUSDT": "lever",
        "STGUSDT": "stg",
        "LUNCUSDT": "lunc",
        "GMXUSDT": "gmx",
        "NEBLUSDT": "nebl",
        "POLYXUSDT": "polyx",
        "APTUSDT": "apt",
        "OSMOUSDT": "osmo",
        "HFTUSDT": "hft",
        "PHBUSDT": "phb",
        "HOOKUSDT": "hook",
        "MAGICUSDT": "magic",
        "HIFIUSDT": "hifi",
        "RPLUSDT": "rpl",
        "PROSUSDT": "pros",
        "AGIXUSDT": "agix",
        "GNSUSDT": "gns",
        "SYNUSDT": "syn",
        "VIBUSDT": "vib",
        "SSVUSDT": "ssv",
        "LQTYUSDT": "lqty",
        "AMBUSDT": "amb",
        "BETHUSDT": "beth",
        "USTCUSDT": "ustc",
        "GASUSDT": "gas",
        "GLMUSDT": "glm",
        "PROMUSDT": "prom",
        "QKCUSDT": "qkc",
        "UFTUSDT": "uft",
        "IDUSDT": "id",
        "ARBUSDT": "arb",
        "LOOMUSDT": "loom",
        "OAXUSDT": "oax",
        "RDNTUSDT": "rdnt",
        "WBTCUSDT": "wbtc",
        "EDUUSDT": "edu",
        "SUIUSDT": "sui",
        "AERGOUSDT": "aergo",
        "PEPEUSDT": "pepe",
        "FLOKIUSDT": "floki",
        "ASTUSDT": "ast",
        "SNTUSDT": "snt",
        "COMBOUSDT": "combo",
        "MAVUSDT": "mav",
        "PENDLEUSDT": "pendle",
        "ARKMUSDT": "arkm",
        "WBETHUSDT": "wbeth",
        "WLDUSDT": "wld",
        "FDUSDUSDT": "fdusd",
        "SEIUSDT": "sei",
        "CYBERUSDT": "cyber",
        "ARKUSDT": "ark",
        "CREAMUSDT": "cream",
        "GFTUSDT": "gft",
        "IQUSDT": "iq",
        "NTRNUSDT": "ntrn",
        "TIAUSDT": "tia",
        "MEMEUSDT": "meme",
        "ORDIUSDT": "ordi",
        "BEAMXUSDT": "beamx",
        "PIVXUSDT": "pivx",
        "VICUSDT": "vic",
        "BLURUSDT": "blur",
        "VANRYUSDT": "vanry",
        "AEURUSDT": "aeur",
        "JTOUSDT": "jto",
        "1000SATSUSDT": "1000sats",
        "BONKUSDT": "bonk",
        "ACEUSDT": "ace",
        "NFPUSDT": "nfp",
        "AIUSDT": "ai",
        "XAIUSDT": "xai",
        "MANTAUSDT": "manta",
        "ALTUSDT": "alt",
        "JUPUSDT": "jup",
        "PYTHUSDT": "pyth",
        "RONINUSDT": "ronin",
        "DYMUSDT": "dym",
        "PIXELUSDT": "pixel",
        "STRKUSDT": "strk",
        "PORTALUSDT": "portal",
        "PDAUSDT": "pda",
        "AXLUSDT": "axl",
        "WIFUSDT": "wif",
        "METISUSDT": "metis",
        "AEVOUSDT": "aevo",
        "BOMEUSDT": "bome",
        "ETHFIUSDT": "ethfi",
        "ENAUSDT": "ena",
        "WUSDT": "w",
        "TNSRUSDT": "tnsr",
        "SAGAUSDT": "saga",
        "TAOUSDT": "tao",
        "OMNIUSDT": "omni",
        "REZUSDT": "rez",
        "BBUSDT": "bb",
        "NOTUSDT": "not",
        "IOUSDT": "io",
        "ZKUSDT": "zk",
        "LISTAUSDT": "lista",
        "ZROUSDT": "zro",
        "GUSDT": "g",
        "BANANAUSDT": "banana",
        "RENDERUSDT": "render",
        "TONUSDT": "ton",
        "DOGSUSDT": "dogs",
        "EURIUSDT": "euri",
        "SLFUSDT": "slf",
        "POLUSDT": "pol",
        "NEIROUSDT": "neiro",
        "TURBOUSDT": "turbo",
        "1MBABYDOGEUSDT": "1mbabydoge",
        "CATIUSDT": "cati",
        "HMSTRUSDT": "hmstr",
        "EIGENUSDT": "eigen",
        "SCRUSDT": "scr",
        "BNSOLUSDT": "bnsol",
        "LUMIAUSDT": "lumia",
        "KAIAUSDT": "kaia",
        "COWUSDT": "cow",
        "CETUSUSDT": "cetus",
        "PNUTUSDT": "pnut",
        "ACTUSDT": "act",
        "USUALUSDT": "usual",
        "THEUSDT": "the",
        "ACXUSDT": "acx",
        "ORCAUSDT": "orca",
        "MOVEUSDT": "move",
        "MEUSDT": "me",
        "VELODROMEUSDT": "velodrome",
        "VANAUSDT": "vana",
        "1000CATUSDT": "1000cat",
        "PENGUUSDT": "pengu",
        "BIOUSDT": "bio",
        "DUSDT": "d",
        "AIXBTUSDT": "aixbt",
        "CGPTUSDT": "cgpt",
        "COOKIEUSDT": "cookie",
        "SUSDT": "s",
        "SOLVUSDT": "solv",
        "TRUMPUSDT": "trump",
        "ANIMEUSDT": "anime",
        "BERAUSDT": "bera",
        "1000CHEEMSUSDT": "1000cheems",
        "TSTUSDT": "tst",
        "LAYERUSDT": "layer",
        "HEIUSDT": "hei",
        "KAITOUSDT": "kaito",
        "SHELLUSDT": "shell",
        "REDUSDT": "red",
        "GPSUSDT": "gps",
        "EPICUSDT": "epic",
        "BMTUSDT": "bmt",
        "FORMUSDT": "form",
        "XUSDUSDT": "xusd",
        "NILUSDT": "nil",
        "PARTIUSDT": "parti",
        "MUBARAKUSDT": "mubarak",
        "TUTUSDT": "tut",
        "BROCCOLI714USDT": "broccoli714",
        "BANANAS31USDT": "bananas31",
        "GUNUSDT": "gun",
        "BABYUSDT": "baby",
        "ONDOUSDT": "ondo",
        "BIGTIMEUSDT": "bigtime",
        "VIRTUALUSDT": "virtual",
        "KERNELUSDT": "kernel",
        "WCTUSDT": "wct",
        "HYPERUSDT": "hyper",
        "INITUSDT": "init",
        "SIGNUSDT": "sign",
        "STOUSDT": "sto",
        "SYRUPUSDT": "syrup",
        "KMNOUSDT": "kmno",
        "SXTUSDT": "sxt",
        "NXPCUSDT": "nxpc",
        "AWEUSDT": "awe",
        "HAEDALUSDT": "haedal",
        "USD1USDT": "usd1",
        "HUMAUSDT": "huma",
        "AUSDT": "a",
        "SOPHUSDT": "soph",
        "RESOLVUSDT": "resolv",
        "HOMEUSDT": "home",
        "SPKUSDT": "spk",
        "NEWTUSDT": "newt",
        "SAHARAUSDT": "sahara",
        "LAUSDT": "la",
        "ERAUSDT": "era",
        "CUSDT": "c",
        "TREEUSDT": "tree",
        "A2ZUSDT": "a2z",
        "TOWNSUSDT": "towns",
        "PROVEUSDT": "prove",
        "BFUSDUSDT": "bfusd",
        "PLUMEUSDT": "plume",
        "DOLOUSDT": "dolo",
        "MITOUSDT": "mito",
        "WLFIUSDT": "wlfi",
        "SOMIUSDT": "somi",
        "OPENUSDT": "open",
        "USDEUSDT": "usde",
        "LINEAUSDT": "linea",
        "HOLOUSDT": "holo",
        "PUMPUSDT": "pump",
        "AVNTUSDT": "avnt",
        "ZKCUSDT": "zkc",
        "SKYUSDT": "sky",
        "BARDUSDT": "bard",
        "0GUSDT": "0g",
        "HEMIUSDT": "hemi",
        "XPLUSDT": "xpl",
        "MIRAUSDT": "mira",
        "FFUSDT": "ff",
        "EDENUSDT": "eden",
        "NOMUSDT": "nom",
        "2ZUSDT": "2z",
        "MORPHOUSDT": "morpho",
        "ASTERUSDT": "aster",
        "WALUSDT": "wal",
        "EULUSDT": "eul",
        "ENSOUSDT": "enso",
        "YBUSDT": "yb",
        "ZBTUSDT": "zbt",
        "TURTLEUSDT": "turtle",
        "GIGGLEUSDT": "giggle",
        "FUSDT": "f",
        "KITEUSDT": "kite",
        "MMTUSDT": "mmt",
        "SAPIENUSDT": "sapien",
        "ALLOUSDT": "allo",
        "BANKUSDT": "bank",
        "METUSDT": "met",
        "ATUSDT": "at",
        "KGSTUSDT": "kgst"
    ]
    
    /// Direct mapping from CoinGecko IDs to Binance trading pair symbols
    /// This ensures reliable chart data fetching by avoiding reverse lookup mismatches
    /// Only includes cryptocurrencies that have Binance USDT trading pairs
    static let coinGeckoToBinanceSymbol: [String: String] = [
        "bitcoin": "BTCUSDT",
        "ethereum": "ETHUSDT",
        "binancecoin": "BNBUSDT",
        "ripple": "XRPUSDT",
        "usd-coin": "USDCUSDT",
        "solana": "SOLUSDT",
        "tron": "TRXUSDT",
        "dogecoin": "DOGEUSDT",
        "cardano": "ADAUSDT",
        "bitcoin-cash": "BCHUSDT",
        "wrapped-bitcoin": "WBTCUSDT",
        "wrapped-beacon-eth": "WBETHUSDT",
        "chainlink": "LINKUSDT",
        "usds": "USDSUSDT",
        "zcash": "ZECUSDT",
        "monero": "XMRUSDT",
        "stellar": "XLMUSDT",
        "ethena-usde": "USDEUSDT",
        "litecoin": "LTCUSDT",
        "sui": "SUIUSDT",
        "avalanche-2": "AVAXUSDT",
        "hedera-hashgraph": "HBARUSDT",
        "shiba-inu": "SHIBUSDT",
        "the-open-network": "TONUSDT",
        "dai": "DAIUSDT",
        "uniswap": "UNIUSDT",
        "polkadot": "DOTUSDT",
        "pepe": "PEPEUSDT",
        "aave": "AAVEUSDT",
        "bittensor": "TAOUSDT",
        "near": "NEARUSDT",
        "ethereum-classic": "ETCUSDT",
        "ethena": "ENAUSDT",
        "internet-computer": "ICPUSDT",
        "pax-gold": "PAXGUSDT",
        "worldcoin-wld": "WLDUSDT",
        "aptos": "APTUSDT",
        "binance-staked-sol": "BNSOLUSDT",
        "ondo-finance": "ONDOUSDT",
        "arbitrum": "ARBUSDT",
        "polygon-ecosystem-token": "POLUSDT",
        "quant-network": "QNTUSDT",
        "algorand": "ALGOUSDT",
        "filecoin": "FILUSDT",
        "cosmos": "ATOMUSDT",
        "official-trump": "TRUMPUSDT",
        "vechain": "VETUSDT",
        "render-token": "RENDERUSDT",
        "immutable-x": "IMXUSDT",
        "injective-protocol": "INJUSDT",
        "optimism": "OPUSDT",
        "stacks": "STXUSDT",
        "the-graph": "GRTUSDT",
        "sei-network": "SEIUSDT",
        "celestia": "TIAUSDT",
        "maker": "MKRUSDT",
        "theta-token": "THETAUSDT",
        "fantom": "FTMUSDT",
        "flow": "FLOWUSDT",
        "floki": "FLOKIUSDT",
        "bonk": "BONKUSDT",
        "lido-dao": "LDOUSDT",
        "first-digital-usd": "FDUSDUSDT",
        "fetch-ai": "FETUSDT",
        "arweave": "ARUSDT",
        "gala": "GALAUSDT",
        "helium": "HNTUSDT",
        "jupiter-exchange-solana": "JUPUSDT",
        "pyth-network": "PYTHUSDT",
        "axie-infinity": "AXSUSDT",
        "eos": "EOSUSDT",
        "beam-2": "BEAMUSDT",
        "neo": "NEOUSDT",
        "thorchain": "RUNEUSDT",
        "pendle": "PENDLEUSDT",
        "dydx-chain": "DYDXUSDT"
    ]
    
    /// Get name (שם) for a given symbol (קוד)
    /// - Parameter symbol: The trading pair symbol (e.g., "BTCUSDT")
    /// - Returns: The name of the cryptocurrency (e.g., "bitcoin"), or nil if not found
    static func getName(for symbol: String) -> String? {
        return binancePairsDict[symbol]
    }
    
    /// Get symbol (קוד) for a given name (שם)
    /// - Parameter name: The cryptocurrency name (e.g., "bitcoin")
    /// - Returns: The trading pair symbol (e.g., "BTCUSDT"), or nil if not found
    static func getSymbol(for name: String) -> String? {
        // First, try direct mapping for reliable chart data fetching
        if let symbol = coinGeckoToBinanceSymbol[name.lowercased()] {
            return symbol
        }
        
        // Fall back to reverse lookup in binancePairsDict for backward compatibility
        return binancePairsDict.first(where: { $0.value.lowercased() == name.lowercased() })?.key
    }
    
    /// Check if a symbol exists in Binance pairs
    static func hasSymbol(_ symbol: String) -> Bool {
        return binancePairsDict[symbol] != nil
    }
    
    /// Get CoinGecko ID for a given Binance symbol (reverse lookup)
    /// - Parameter binanceSymbol: The Binance trading pair symbol (e.g., "BTCUSDT")
    /// - Returns: The CoinGecko ID (e.g., "bitcoin"), or nil if not found
    static func getCoinGeckoId(for binanceSymbol: String) -> String? {
        return binancePairsDict[binanceSymbol]
    }
    
    // MARK: - Image URLs
    
    /// Get CoinGecko image URL for a cryptocurrency
    /// All providers use CoinGecko images, so this is shared logic
    /// - Parameter coinGeckoId: The CoinGecko cryptocurrency ID (e.g., "bitcoin")
    /// - Returns: The image URL string
    static func getCoinGeckoImageURL(for coinGeckoId: String) -> String {
        return "https://assets.coingecko.com/coins/images/\(coinGeckoId)/large/\(coinGeckoId).png"
    }
}
