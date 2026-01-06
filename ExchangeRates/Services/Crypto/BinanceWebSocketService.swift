//
//  BinanceWebSocketService.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 01/01/2026.
//

import Foundation
import Combine

class BinanceWebSocketService: ObservableObject {
    static let shared = BinanceWebSocketService()
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    
    @Published var isConnected = false
    @Published var priceUpdates: [String: Double] = [:] // [symbol: price]
    
    // Set of symbols currently subscribed to
    private var subscribedSymbols: Set<String> = []
    
    private let websocketManager = WebSocketManager.shared
    
    private init() {
        // Listen to WebSocketManager notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(websocketPreferenceChanged),
            name: WebSocketManager.websocketPreferenceChangedNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        disconnect(clearSubscriptions: true)
    }
    
    /// Connect to Binance WebSocket and subscribe to selected symbols
    func connect(symbols: [String]) {
        // Check if WebSocket is enabled
        guard websocketManager.isWebSocketEnabled else {
            LogManager.shared.log("WebSocket is disabled, skipping connection", level: .info, source: "BinanceWebSocketService")
            return
        }
        
        guard !symbols.isEmpty else {
            LogManager.shared.log("No symbols provided for WebSocket connection", level: .warning, source: "BinanceWebSocketService")
            return
        }
        
        // Disconnect existing connection if any (but keep subscriptions for reconnection)
        if isConnected {
            disconnect(clearSubscriptions: false)
        }
        
        subscribedSymbols = Set(symbols)
        
        // Binance WebSocket URL for ticker stream
        // Format: wss://stream.binance.com:9443/stream?streams=btcusdt@ticker/ethusdt@ticker
        let streams = symbols.map { "\($0.lowercased())@ticker" }.joined(separator: "/")
        let urlString = "wss://stream.binance.com:9443/stream?streams=\(streams)"
        
        guard let url = URL(string: urlString) else {
            LogManager.shared.log("Invalid WebSocket URL: \(urlString)", level: .error, source: "BinanceWebSocketService")
            return
        }
        
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        urlSession = session
        
        LogManager.shared.log("WebSocket connecting for \(symbols.count) symbols: \(symbols.prefix(5).joined(separator: ", "))", level: .info, source: "BinanceWebSocketService")
        
        webSocketTask?.resume()
        
        // Wait for the connection to establish before starting to receive messages
        // This prevents the "socket is not connected" error that occurs when receive() is called too early
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self else { return }
            
            // Verify the task still exists and hasn't been cancelled
            guard self.webSocketTask != nil else {
                LogManager.shared.log("WebSocket task no longer valid, aborting connection", level: .warning, source: "BinanceWebSocketService")
                return
            }
            
            DispatchQueue.main.async {
                self.isConnected = true
                LogManager.shared.log("WebSocket connected for \(symbols.count) symbols", level: .success, source: "BinanceWebSocketService")
                self.receiveMessage()
            }
        }
    }
    
    /// Disconnect from WebSocket
    /// - Parameter clearSubscriptions: If true, clears subscribed symbols. Default is false to allow reconnection.
    func disconnect(clearSubscriptions: Bool = false) {
        guard webSocketTask != nil else { return }
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        urlSession = nil
        
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = false
        }
        
        if clearSubscriptions {
            subscribedSymbols.removeAll()
        }
        
        LogManager.shared.log("WebSocket disconnected", level: .info, source: "BinanceWebSocketService")
    }
    
    /// Handle WebSocket preference changes
    @objc private func websocketPreferenceChanged(_ notification: Notification) {
        guard let enabled = notification.userInfo?["enabled"] as? Bool else { return }
        
        if enabled {
            // If enabled and we have symbols, reconnect
            if !subscribedSymbols.isEmpty {
                connect(symbols: Array(subscribedSymbols))
            }
        } else {
            // If disabled, disconnect and clear subscriptions
            disconnect(clearSubscriptions: true)
        }
    }
    
    /// Receive messages from WebSocket
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                
                // Continue receiving messages
                if self.isConnected {
                    self.receiveMessage()
                }
                
            case .failure(let error):
                LogManager.shared.log("WebSocket error: \(error.localizedDescription)", level: .error, source: "BinanceWebSocketService")
                
                // Only attempt to reconnect if WebSocket is enabled
                if self.websocketManager.isWebSocketEnabled && !self.subscribedSymbols.isEmpty {
                    let symbolsToReconnect = Array(self.subscribedSymbols)
                    
                    // Mark disconnected immediately and tear down the current task
                    DispatchQueue.main.async { [weak self] in
                        self?.isConnected = false
                        self?.disconnect(clearSubscriptions: false)
                    }
                    
                    // Attempt to reconnect after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        if self.websocketManager.isWebSocketEnabled && !symbolsToReconnect.isEmpty {
                            LogManager.shared.log("Attempting WebSocket reconnection", level: .info, source: "BinanceWebSocketService")
                            self.connect(symbols: symbolsToReconnect)
                        }
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.isConnected = false
                    }
                }
            }
        }
    }
    
    /// Handle incoming WebSocket message
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let _ = json["stream"] as? String,
              let dataDict = json["data"] as? [String: Any],
              let symbol = dataDict["s"] as? String,
              let priceString = dataDict["c"] as? String,
              let price = Double(priceString) else {
            return
        }
        
        // Update price on main thread
        DispatchQueue.main.async { [weak self] in
            self?.priceUpdates[symbol] = price
        }
    }
}
