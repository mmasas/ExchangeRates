//
//  CurrencyOrderManager.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import Foundation

class CurrencyOrderManager {
    static let shared = CurrencyOrderManager()
    
    private let userDefaults = UserDefaults.standard
    private let currencyOrderKey = "currencyOrder"
    
    private init() {}
    
    /// Get the saved order of currency codes
    func getOrderedCurrencies() -> [String] {
        return userDefaults.stringArray(forKey: currencyOrderKey) ?? []
    }
    
    /// Save the order of currency codes
    func saveOrder(_ currencies: [String]) {
        userDefaults.set(currencies, forKey: currencyOrderKey)
        print("💾 [CurrencyOrderManager] Saved order (first 5): \(Array(currencies.prefix(5))), total count: \(currencies.count)")
        // Verify the save was successful
        let saved = userDefaults.stringArray(forKey: currencyOrderKey) ?? []
        if saved != currencies {
            print("⚠️ [CurrencyOrderManager] WARNING: Saved order doesn't match what we tried to save!")
        }
    }
    
    /// Initialize order with given currencies (for first-time setup only)
    /// Should only be called when no order exists
    func initializeOrder(with currencies: [String]) {
        let existingOrder = getOrderedCurrencies()
        if !existingOrder.isEmpty {
            print("⚠️ [CurrencyOrderManager] initializeOrder called but order already exists (first 5): \(Array(existingOrder.prefix(5))), skipping initialization")
            return
        }
        print("🆕 [CurrencyOrderManager] Initializing order for first time with \(currencies.count) currencies")
        // First time setup - preserve the order as provided (main currencies first)
        saveOrder(currencies)
    }
    
    /// Reset order to use main currencies in their defined order
    func resetToDefaultOrder(with currencies: [String]) {
        print("🔄 [CurrencyOrderManager] Resetting order to default with \(currencies.count) currencies")
        saveOrder(currencies)
    }
    
    /// Reset order to default with current currencies (existing + custom)
    /// Combines existing currency codes with custom currencies, sorts them, and resets the order
    func resetToDefaultOrderWithCurrentCurrencies(existingCurrencyCodes: [String]) {
        // Get all current currencies (main + custom)
        let customCurrencies = CustomCurrencyManager.shared.getCustomCurrencies()
        let allCurrencies = existingCurrencyCodes + customCurrencies
        
        // Sort them using MainCurrenciesHelper to get default order (main currencies first, then alphabetical)
        let sortedCurrencies = MainCurrenciesHelper.sortCurrencies(allCurrencies)
        
        // Reset the order
        resetToDefaultOrder(with: sortedCurrencies)
    }
    
    /// Add a currency to the end of the order
    func addCurrency(_ code: String) {
        var order = getOrderedCurrencies()
        if !order.contains(code) {
            order.append(code)
            saveOrder(order)
        }
    }
    
    /// Remove a currency from the order
    func removeCurrency(_ code: String) {
        var order = getOrderedCurrencies()
        order.removeAll { $0 == code }
        saveOrder(order)
    }
    
    /// Update the order by moving a currency from one position to another
    func moveCurrency(from source: IndexSet, to destination: Int, currentOrder: [String]) {
        print("🔀 [CurrencyOrderManager] moveCurrency called - from: \(source), to: \(destination), currentOrder: \(currentOrder)")
        
        var order = currentOrder
        
        // Manual implementation of move operation
        var itemsToMove: [String] = []
        var indicesToRemove: [Int] = []
        
        // Collect items to move (in reverse order to maintain indices)
        for index in source.sorted(by: >) {
            itemsToMove.insert(order[index], at: 0)
            indicesToRemove.append(index)
        }
        
        // Remove items from their original positions
        for index in indicesToRemove.sorted(by: >) {
            order.remove(at: index)
        }
        
        // Calculate the correct destination index after removals
        var adjustedDestination = destination
        for index in indicesToRemove {
            if index < destination {
                adjustedDestination -= 1
            }
        }
        
        // Insert items at the new position
        for (offset, item) in itemsToMove.enumerated() {
            order.insert(item, at: adjustedDestination + offset)
        }
        
        print("💾 [CurrencyOrderManager] New order after move: \(order)")
        saveOrder(order)
    }
    
    /// Sync the order with current available currencies
    /// Removes currencies that no longer exist and adds new ones to the end
    /// Preserves the existing order of currencies that are still available
    func syncOrder(with availableCurrencies: [String]) {
        let currentOrder = getOrderedCurrencies()
        let availableSet = Set(availableCurrencies)
        let currentOrderSet = Set(currentOrder)
        
        print("🔄 [CurrencyOrderManager] syncOrder called - current saved order (first 5): \(Array(currentOrder.prefix(5))), available count: \(availableCurrencies.count)")
        
        // If the saved order already contains exactly the same currencies (same set),
        // don't modify the order at all - it's already correct
        if currentOrderSet == availableSet {
            print("✅ [CurrencyOrderManager] Saved order matches available currencies exactly, no sync needed")
            return
        }
        
        // Keep only currencies that are still available, maintaining their saved order
        var syncedOrder = currentOrder.filter { availableSet.contains($0) }
        
        // Add new currencies that aren't in the order yet (append at the end)
        let syncedSet = Set(syncedOrder)
        let newCurrencies = availableCurrencies.filter { !syncedSet.contains($0) }
        syncedOrder.append(contentsOf: newCurrencies)
        
        // Only save if the order actually changed
        if syncedOrder != currentOrder {
            print("📝 [CurrencyOrderManager] Order changed - old (first 3): \(Array(currentOrder.prefix(3))), new (first 3): \(Array(syncedOrder.prefix(3)))")
            saveOrder(syncedOrder)
        } else {
            print("✅ [CurrencyOrderManager] Order unchanged after sync, no need to save")
        }
    }
    
    /// Get sorted currencies according to the saved order
    /// If a currency is not in the order, it will be appended at the end
    func sortCurrencies(_ currencies: [String]) -> [String] {
        let order = getOrderedCurrencies()
        let orderMap = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($1, $0) })
        let orderSet = Set(order)
        
        // Split into ordered and unordered
        let ordered = currencies.filter { orderSet.contains($0) }
        let unordered = currencies.filter { !orderSet.contains($0) }
        
        // Sort ordered currencies by their position in the saved order
        let sortedOrdered = ordered.sorted { (first, second) -> Bool in
            let firstIndex = orderMap[first] ?? Int.max
            let secondIndex = orderMap[second] ?? Int.max
            return firstIndex < secondIndex
        }
        
        // Append unordered currencies (they will be added to order later)
        return sortedOrdered + unordered.sorted()
    }
}

