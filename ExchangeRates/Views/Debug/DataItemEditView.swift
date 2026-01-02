//
//  DataItemEditView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import SwiftUI

struct DataItemEditView: View {
    let item: DataItem
    let onSave: (DataItem) -> Void
    
    @State private var stringValue: String = ""
    @State private var arrayValue: [String] = []
    @State private var jsonValue: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                switch item {
                case .homeCurrency:
                    Section {
                        TextField("Home Currency Code", text: $stringValue)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                    } footer: {
                        Text("Enter a 3-letter ISO currency code (e.g., USD, EUR, ILS)")
                    }
                    
                case .colorScheme:
                    Section {
                        Picker("Color Scheme", selection: $stringValue) {
                            ForEach(ColorSchemeOption.allCases, id: \.rawValue) { option in
                                Text(option.displayName).tag(option.rawValue)
                            }
                        }
                    }
                    
                case .language:
                    Section {
                        Picker("Language", selection: $stringValue) {
                            ForEach(AppLanguage.allCases, id: \.rawValue) { lang in
                                Text(lang.displayName).tag(lang.rawValue)
                            }
                        }
                    }
                    
                case .alert:
                    Section {
                        TextEditor(text: $jsonValue)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 300)
                    } header: {
                        Text("Alert JSON")
                    } footer: {
                        Text("Edit the JSON representation of the alert. Make sure it's valid JSON.")
                    }
                    
                case .customCurrencies:
                    Section {
                        ForEach(Array(arrayValue.enumerated()), id: \.offset) { index, currency in
                            HStack {
                                TextField("Currency Code", text: Binding(
                                    get: { currency },
                                    set: { newValue in
                                        arrayValue[index] = newValue.uppercased()
                                    }
                                ))
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                
                                Button(action: {
                                    arrayValue.remove(at: index)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            arrayValue.remove(atOffsets: indexSet)
                        }
                        
                        Button(action: {
                            arrayValue.append("")
                        }) {
                            Label("Add Currency", systemImage: "plus")
                        }
                    } header: {
                        Text("Custom Currencies")
                    } footer: {
                        Text("Enter 3-letter ISO currency codes")
                    }
                    
                case .currencyOrder:
                    Section {
                        ForEach(Array(arrayValue.enumerated()), id: \.offset) { index, currency in
                            HStack {
                                Text("\(index + 1).")
                                    .foregroundColor(.secondary)
                                    .frame(width: 30)
                                
                                TextField("Currency Code", text: Binding(
                                    get: { currency },
                                    set: { newValue in
                                        arrayValue[index] = newValue.uppercased()
                                    }
                                ))
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                
                                Button(action: {
                                    arrayValue.remove(at: index)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            arrayValue.remove(atOffsets: indexSet)
                        }
                        
                        Button(action: {
                            arrayValue.append("")
                        }) {
                            Label("Add Currency", systemImage: "plus")
                        }
                    } header: {
                        Text("Currency Order")
                    } footer: {
                        Text("Order of currencies as they appear in the app")
                    }
                }
            }
            .navigationTitle("Edit \(item.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                initializeValues()
            }
        }
    }
    
    private func initializeValues() {
        switch item {
        case .homeCurrency(let value):
            stringValue = value
            
        case .colorScheme(let value):
            stringValue = value
            
        case .language(let value):
            stringValue = value
            
        case .alert(let alert):
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            
            if let data = try? encoder.encode(alert),
               let jsonString = String(data: data, encoding: .utf8) {
                jsonValue = jsonString
            } else {
                jsonValue = "{}"
            }
            
        case .customCurrencies(let currencies):
            arrayValue = currencies
            
        case .currencyOrder(let order):
            arrayValue = order
        }
    }
    
    private func saveItem() {
        switch item {
        case .homeCurrency:
            let trimmed = stringValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            if trimmed.count == 3 {
                onSave(.homeCurrency(trimmed))
                dismiss()
            } else {
                errorMessage = "Currency code must be exactly 3 characters"
                showingError = true
            }
            
        case .colorScheme:
            if ColorSchemeOption(rawValue: stringValue) != nil {
                onSave(.colorScheme(stringValue))
                dismiss()
            } else {
                errorMessage = "Invalid color scheme option"
                showingError = true
            }
            
        case .language:
            if AppLanguage(rawValue: stringValue) != nil {
                onSave(.language(stringValue))
                dismiss()
            } else {
                errorMessage = "Invalid language option"
                showingError = true
            }
            
        case .alert:
            // Validate and parse JSON
            guard let jsonData = jsonValue.data(using: .utf8) else {
                errorMessage = "Invalid JSON encoding"
                showingError = true
                return
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                let alert = try decoder.decode(CurrencyAlert.self, from: jsonData)
                onSave(.alert(alert))
                dismiss()
            } catch {
                errorMessage = "Invalid JSON: \(error.localizedDescription)"
                showingError = true
            }
            
        case .customCurrencies:
            // Filter out empty strings and validate all are 3 characters
            let nonEmpty = arrayValue.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            let valid = nonEmpty.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).count == 3 }
            if valid {
                let cleaned = nonEmpty.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
                onSave(.customCurrencies(cleaned))
                dismiss()
            } else {
                errorMessage = "All currency codes must be exactly 3 characters"
                showingError = true
            }
            
        case .currencyOrder:
            // Filter out empty strings and validate all are 3 characters
            let nonEmpty = arrayValue.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            let valid = nonEmpty.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).count == 3 }
            if valid {
                let cleaned = nonEmpty.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
                onSave(.currencyOrder(cleaned))
                dismiss()
            } else {
                errorMessage = "All currency codes must be exactly 3 characters"
                showingError = true
            }
        }
    }
}

#Preview {
    DataItemEditView(item: .homeCurrency("USD")) { _ in }
}

