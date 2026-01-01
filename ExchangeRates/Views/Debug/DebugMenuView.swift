//
//  DebugMenuView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 27/12/2025.
//

import SwiftUI

struct DebugMenuView: View {
    var body: some View {
        List {
            NavigationLink(destination: LogsView()) {
                Label("View Logs", systemImage: "doc.text")
            }
            
            NavigationLink(destination: DataInspectorView()) {
                Label("View Stored Data", systemImage: "tray.full")
            }
        }
        .navigationTitle("Debug Menu")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        DebugMenuView()
    }
}

