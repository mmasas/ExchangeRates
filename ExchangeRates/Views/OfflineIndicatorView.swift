//
//  OfflineIndicatorView.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 02/01/2026.
//

import SwiftUI

struct OfflineIndicatorView: View {
    let lastUpdateDate: Date?
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    private var relativeTimeString: String {
        guard let date = lastUpdateDate else {
            return String(localized: "never_updated", defaultValue: "Never updated")
        }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        let minutes = Int(timeInterval / 60)
        let hours = Int(timeInterval / 3600)
        let days = Int(timeInterval / 86400)
        
        if minutes < 1 {
            return String(localized: "updated_just_now", defaultValue: "Updated just now")
        } else if minutes < 60 {
            return String(localized: "updated_minutes_ago", defaultValue: "Updated \(minutes)m ago")
        } else if hours < 24 {
            return String(localized: "updated_hours_ago", defaultValue: "Updated \(hours)h ago")
        } else {
            return String(localized: "updated_days_ago", defaultValue: "Updated \(days)d ago")
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.orange)
            
            Text(String(localized: "offline_mode", defaultValue: "Offline"))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            if lastUpdateDate != nil {
                Text("•")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(relativeTimeString)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    VStack {
        OfflineIndicatorView(lastUpdateDate: Date().addingTimeInterval(-3600))
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}

