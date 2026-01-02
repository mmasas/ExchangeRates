//
//  ExchangeRateRowSkeleton.swift
//  ExchangeRates
//
//  Created by Moshe Masas on 26/12/2025.
//

import SwiftUI

struct ExchangeRateRowSkeleton: View {
    var body: some View {
        HStack(spacing: 16) {
            // Flag placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 32, height: 32)
            
            // Currency code placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 16)
            
            Spacer()
            
            // Right side content placeholder
            VStack(alignment: .trailing, spacing: 4) {
                // Exchange rate placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 16)
                
                // Percentage change placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 14)
                
                // Timestamp placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
        .redacted(reason: .placeholder)
    }
}

#Preview {
    VStack(spacing: 12) {
        ExchangeRateRowSkeleton()
        ExchangeRateRowSkeleton()
        ExchangeRateRowSkeleton()
        ExchangeRateRowSkeleton()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

