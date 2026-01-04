//
//  NetworkMonitor.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 02/01/2026.
//

import Foundation
import Network
import Combine

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected: Bool = true
    
    // Debug mode: allows simulating offline state for testing
    private var simulateOffline: Bool = false {
        didSet {
            updateConnectionStatus()
        }
    }
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var actualConnectionStatus: Bool = true
    
    private init() {
        startMonitoring()
        
        // Listen for debug simulation requests
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SimulateOffline"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.simulateOffline = true
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SimulateOnline"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.simulateOffline = false
        }
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let wasConnected = self.isConnected
                self.actualConnectionStatus = path.status == .satisfied
                self.updateConnectionStatus()
                
                // Post notification when status changes
                if wasConnected != self.isConnected {
                    NotificationCenter.default.post(name: NSNotification.Name("NetworkStatusChanged"), object: nil)
                }
            }
        }
        monitor.start(queue: queue)
        
        // Set initial status
        actualConnectionStatus = monitor.currentPath.status == .satisfied
        updateConnectionStatus()
    }
    
    private func updateConnectionStatus() {
        // If simulating offline, force disconnected state
        // Otherwise use actual network status
        isConnected = simulateOffline ? false : actualConnectionStatus
    }
}

